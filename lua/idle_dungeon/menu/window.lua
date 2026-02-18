-- このモジュールはメニュー表示用のウィンドウ操作をまとめる。

local M = {}

local namespace = vim.api.nvim_create_namespace("IdleDungeonMenu")
local MAIN_ZINDEX = 50
local HIDDEN_CURSOR = "a:IdleDungeonMenuHiddenCursor"
local cursor_state = { hidden_count = 0, previous = nil }

local function palette_group_name(key)
  local safe = tostring(key or "default"):gsub("[^%w_]", "_")
  return "IdleDungeonMenuPalette_" .. safe
end

local function resolve_wrap_lines(opts)
  if opts == nil then
    return true
  end
  return opts.wrap_lines == true
end

-- テーマ設定に応じてハイライトを直接指定またはリンクする。
local function apply_highlight(group, spec, fallback_link, inherit)
  local has_color = spec and (spec.fg or spec.bg or spec.sp or spec.ctermfg or spec.ctermbg)
  local has_style = spec and (spec.bold or spec.italic or spec.underline or spec.undercurl or spec.reverse)
  if has_color then
    vim.api.nvim_set_hl(0, group, spec)
    return
  end
  if inherit and fallback_link then
    vim.api.nvim_set_hl(0, group, { link = fallback_link })
    return
  end
  if has_style then
    vim.api.nvim_set_hl(0, group, spec)
    return
  end
  vim.api.nvim_set_hl(0, group, spec or {})
end

local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function ensure_highlights(theme)
  -- メニュー表示用のハイライトを定義して視認性を保つ。
  local safe = theme or {}
  local inherit = safe.inherit ~= false
  -- triforce風に役割ごとに色を分け、未指定時はテーマ側の代表グループへ委譲する。
  apply_highlight("IdleDungeonMenuTitle", { fg = safe.title or safe.accent, bold = true }, "Keyword", inherit)
  apply_highlight("IdleDungeonMenuTabs", { fg = safe.muted }, "Comment", inherit)
  apply_highlight("IdleDungeonMenuTabActive", { fg = safe.text, bold = true }, "PmenuSel", inherit)
  apply_highlight("IdleDungeonMenuTabInactive", { fg = safe.text }, "Pmenu", inherit)
  apply_highlight("IdleDungeonMenuDivider", { fg = safe.divider or safe.border }, "Comment", inherit)
  apply_highlight("IdleDungeonMenuSelected", { fg = safe.selected_fg, bold = true }, "PmenuSel", inherit)
  apply_highlight(
    "IdleDungeonMenuSelectedPulse",
    { fg = safe.title or safe.accent or safe.selected_fg, bold = true },
    "PmenuSel",
    inherit
  )
  apply_highlight("IdleDungeonMenuBorder", { fg = safe.border }, "String", inherit)
  apply_highlight("IdleDungeonMenuNormal", { fg = safe.text, bg = safe.background }, "NormalFloat", inherit)
  -- Enter説明は本文や通常フッターと見分けやすい色へ寄せる。
  apply_highlight("IdleDungeonMenuHint", { fg = safe.accent or safe.title, italic = true }, "SpecialComment", inherit)
  -- 危険度表示は視認性を優先して段階別の色を割り当てる。
  apply_highlight("IdleDungeonMenuDangerHigh", { fg = "#ea6962", bold = true }, "DiagnosticError", inherit)
  apply_highlight("IdleDungeonMenuDangerMedium", { fg = "#d8a657", bold = true }, "DiagnosticWarn", inherit)
  apply_highlight("IdleDungeonMenuDangerLow", { fg = "#a9b665", bold = true }, "DiagnosticOk", inherit)
  -- カーソル色は背景を持たせず透過寄りにして、選択記号の見た目を崩さない。
  apply_highlight("IdleDungeonMenuCursor", { fg = "NONE", bg = "NONE", blend = 100, nocombine = true }, "NormalFloat", inherit)
  apply_highlight(
    "IdleDungeonMenuHiddenCursor",
    { fg = "NONE", bg = "NONE", blend = 100, nocombine = true },
    "NormalFloat",
    inherit
  )
  apply_highlight("IdleDungeonMenuMuted", { fg = safe.muted }, "Comment", inherit)
  apply_highlight("IdleDungeonMenuSection", { fg = safe.accent or safe.title, bold = true }, "Question", inherit)
end

local function ensure_palette_highlights(palette)
  -- 図鑑で使う属性色をメニュー上でも再利用できるよう、動的ハイライトを定義する。
  for key, spec in pairs(palette or {}) do
    if type(spec) == "table" and spec.fg then
      apply_highlight(palette_group_name(key), { fg = spec.fg, bg = "NONE" }, nil, false)
    end
  end
end

local function get_guicursor()
  if vim.api.nvim_get_option_value then
    return vim.api.nvim_get_option_value("guicursor", {})
  end
  return vim.o.guicursor
end

local function set_guicursor(value)
  if vim.api.nvim_set_option_value then
    vim.api.nvim_set_option_value("guicursor", value, {})
    return
  end
  vim.o.guicursor = value
end

local function hide_cursor()
  -- メニュー表示中はカーソルの見た目を隠し、選択記号だけで現在位置を示す。
  if cursor_state.hidden_count == 0 then
    cursor_state.previous = get_guicursor()
    set_guicursor(HIDDEN_CURSOR)
  end
  cursor_state.hidden_count = cursor_state.hidden_count + 1
end

local function restore_cursor()
  -- すべてのメニューを閉じた時点で元のカーソル設定へ戻す。
  if cursor_state.hidden_count <= 0 then
    return
  end
  cursor_state.hidden_count = cursor_state.hidden_count - 1
  if cursor_state.hidden_count == 0 then
    set_guicursor(cursor_state.previous or "")
    cursor_state.previous = nil
  end
end

local function calculate_center(height, width)
  local lines = vim.o.lines
  local columns = vim.o.columns
  local cmdheight = vim.o.cmdheight
  local row = math.max(math.floor((lines - cmdheight - height) / 2), 0)
  local col = math.max(math.floor((columns - width) / 2), 0)
  return row, col
end

local function open_window(height, width, border, theme, opts)
  -- 新しいバッファと浮動ウィンドウを作成してメニューを表示する。
  ensure_highlights(theme)
  hide_cursor()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  local row, col = calculate_center(height, width)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = border,
    focusable = true,
    noautocmd = true,
    -- メニュー本体の重なり順を固定して表示を安定させる。
    zindex = MAIN_ZINDEX,
  })
  local wrap_lines = resolve_wrap_lines(opts)
  -- 必要に応じて折り返しを切り替え、行レイアウトを安定させる。
  vim.api.nvim_set_option_value("wrap", wrap_lines, { win = win })
  vim.api.nvim_set_option_value("linebreak", wrap_lines, { win = win })
  -- 行全体の着色は使わず、選択記号で現在行を示す。
  vim.api.nvim_set_option_value("cursorline", false, { win = win })
  -- グローバルscrolloffの影響を受けないよう、メニュー内の縦横スクロール余白を固定する。
  vim.api.nvim_set_option_value("scrolloff", 0, { win = win })
  vim.api.nvim_set_option_value("sidescrolloff", 0, { win = win })
  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:IdleDungeonMenuNormal,FloatBorder:IdleDungeonMenuBorder,Cursor:IdleDungeonMenuCursor",
    { win = win }
  )
  return win, buf
end

local function ensure_window(win, buf, height, width, border, theme, opts)
  local wrap_lines = resolve_wrap_lines(opts)
  if is_valid_window(win) and is_valid_buffer(buf) then
    vim.api.nvim_set_option_value("wrap", wrap_lines, { win = win })
    vim.api.nvim_set_option_value("linebreak", wrap_lines, { win = win })
    -- 再描画時もスクロール余白を維持し、上部表示が押し流される現象を防ぐ。
    vim.api.nvim_set_option_value("scrolloff", 0, { win = win })
    vim.api.nvim_set_option_value("sidescrolloff", 0, { win = win })
    return win, buf
  end
  -- 既存の表示が無い場合は新規ウィンドウを作る。
  return open_window(height, width, border, theme, opts)
end

local function update_window(win, height, width)
  local row, col = calculate_center(height, width)
  -- 画面サイズ変更に追従して中央位置を更新する。
  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    zindex = MAIN_ZINDEX,
  })
end

local function set_lines(buf, lines)
  -- バッファの内容を更新してメニュー表示を反映する。
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function apply_highlights(buf, highlights)
  -- ハイライトを更新して見出し行を強調する。
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if type(highlights) == "table" then
    for _, item in ipairs(highlights) do
      if type(item) == "number" then
        vim.api.nvim_buf_add_highlight(buf, namespace, "IdleDungeonMenuTitle", item - 1, 0, -1)
      elseif type(item) == "table" and item.line then
        vim.api.nvim_buf_add_highlight(
          buf,
          namespace,
          item.group or "IdleDungeonMenuTitle",
          item.line - 1,
          item.start_col or 0,
          item.end_col or -1
        )
      end
    end
    return
  end
  if highlights then
    vim.api.nvim_buf_add_highlight(buf, namespace, "IdleDungeonMenuTitle", highlights - 1, 0, -1)
  end
end

local function close_window(win, prev_win)
  if win then
    restore_cursor()
  end
  if is_valid_window(win) then
    -- メニュー表示を終了し、開く前のウィンドウへ戻す。
    vim.api.nvim_win_close(win, true)
  end
  if prev_win and is_valid_window(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

M.ensure_window = ensure_window
M.update_window = update_window
M.set_lines = set_lines
M.apply_highlights = apply_highlights
M.close_window = close_window
M.is_valid_window = is_valid_window
M.is_valid_buffer = is_valid_buffer
M.ensure_palette_highlights = ensure_palette_highlights
M.palette_group_name = palette_group_name

return M
