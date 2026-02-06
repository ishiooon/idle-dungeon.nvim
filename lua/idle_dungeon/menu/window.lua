-- このモジュールはメニュー表示用のウィンドウ操作をまとめる。

local M = {}

local namespace = vim.api.nvim_create_namespace("IdleDungeonMenu")
local MAIN_ZINDEX = 50
local DETAIL_ZINDEX = 60

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
  apply_highlight("IdleDungeonMenuTabs", { fg = safe.accent, bold = true }, "String", inherit)
  apply_highlight("IdleDungeonMenuTabActive", { fg = safe.selected_fg or safe.accent, bg = safe.selected_bg, bold = true }, "PmenuSel", inherit)
  apply_highlight("IdleDungeonMenuTabInactive", { fg = safe.muted }, "Pmenu", inherit)
  apply_highlight("IdleDungeonMenuDivider", { fg = safe.divider or safe.border }, "Comment", inherit)
  apply_highlight("IdleDungeonMenuSelected", { fg = safe.selected_fg, bg = safe.selected_bg, bold = true }, "PmenuSel", inherit)
  apply_highlight("IdleDungeonMenuBorder", { fg = safe.border }, "String", inherit)
  apply_highlight("IdleDungeonMenuNormal", { fg = safe.text, bg = safe.background }, "NormalFloat", inherit)
  apply_highlight("IdleDungeonMenuCursor", { fg = safe.background, bg = safe.background }, "NormalFloat", inherit)
  apply_highlight("IdleDungeonMenuMuted", { fg = safe.muted }, "Comment", inherit)
  apply_highlight("IdleDungeonMenuSection", { fg = safe.accent or safe.title, bold = true }, "Question", inherit)
end

local function calculate_center(height, width)
  local lines = vim.o.lines
  local columns = vim.o.columns
  local cmdheight = vim.o.cmdheight
  local row = math.max(math.floor((lines - cmdheight - height) / 2), 0)
  local col = math.max(math.floor((columns - width) / 2), 0)
  return row, col
end

local function open_window(height, width, border, theme)
  -- 新しいバッファと浮動ウィンドウを作成してメニューを表示する。
  ensure_highlights(theme)
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
    -- 詳細表示より下に配置して重なり順を安定させる。
    zindex = MAIN_ZINDEX,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  -- 行全体の着色は使わず、選択記号で現在行を示す。
  vim.api.nvim_set_option_value("cursorline", false, { win = win })
  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:IdleDungeonMenuNormal,FloatBorder:IdleDungeonMenuBorder,Cursor:IdleDungeonMenuCursor",
    { win = win }
  )
  return win, buf
end

local function open_window_at(row, col, height, width, border, theme, focusable)
  -- 任意位置に詳細表示用のウィンドウを作成する。
  ensure_highlights(theme)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  local enter = focusable == true
  local win = vim.api.nvim_open_win(buf, enter, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = border,
    focusable = focusable == true,
    noautocmd = true,
    -- 左右どちらに表示しても見えるよう前面に出す。
    zindex = DETAIL_ZINDEX,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", false, { win = win })
  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:IdleDungeonMenuNormal,FloatBorder:IdleDungeonMenuBorder,Cursor:IdleDungeonMenuCursor",
    { win = win }
  )
  return win, buf
end

local function ensure_window(win, buf, height, width, border, theme)
  if is_valid_window(win) and is_valid_buffer(buf) then
    return win, buf
  end
  -- 既存の表示が無い場合は新規ウィンドウを作る。
  return open_window(height, width, border, theme)
end

local function ensure_window_at(win, buf, row, col, height, width, border, theme, focusable)
  if is_valid_window(win) and is_valid_buffer(buf) then
    return win, buf
  end
  -- 既存の表示が無い場合は新規ウィンドウを作る。
  return open_window_at(row, col, height, width, border, theme, focusable)
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

local function update_window_at(win, row, col, height, width)
  -- 詳細ウィンドウは指定位置を保ったまま更新する。
  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    zindex = DETAIL_ZINDEX,
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
  if is_valid_window(win) then
    -- メニュー表示を終了し、開く前のウィンドウへ戻す。
    vim.api.nvim_win_close(win, true)
  end
  if prev_win and is_valid_window(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

M.ensure_window = ensure_window
M.ensure_window_at = ensure_window_at
M.update_window = update_window
M.update_window_at = update_window_at
M.set_lines = set_lines
M.apply_highlights = apply_highlights
M.close_window = close_window
M.is_valid_window = is_valid_window
M.is_valid_buffer = is_valid_buffer

return M
