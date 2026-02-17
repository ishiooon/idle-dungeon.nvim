-- このモジュールは子メニューの2ペイン表示と操作を提供する。

local frame = require("idle_dungeon.menu.frame")
local menu_locale = require("idle_dungeon.menu.locale")
local selection_fx = require("idle_dungeon.menu.selection_fx")
local menu_view_util = require("idle_dungeon.menu.view_util")
local util = require("idle_dungeon.util")
local window = require("idle_dungeon.menu.window")

local M = {}

local BACK_ITEM_ID = "__menu_back"

local ui_state = {
  win = nil,
  buf = nil,
  prev_win = nil,
  items = {},
  labels = {},
  selected = 1,
  offset = 0,
  opts = {},
  config = {},
  on_choice = nil,
  meta = nil,
  selection_fx = {},
}
local shared_context = { get_state = nil, config = nil }

local function close()
  selection_fx.stop(ui_state.selection_fx)
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
  ui_state.items = {}
  ui_state.labels = {}
end

local function is_back_item(item)
  return type(item) == "table" and item.id == BACK_ITEM_ID
end

local function decorate_items(items, opts, lang)
  local rows = {}
  if opts.add_back_item ~= false then
    table.insert(rows, { id = BACK_ITEM_ID, label = lang == "ja" and "戻る" or "Back" })
  end
  for _, item in ipairs(items or {}) do
    table.insert(rows, item)
  end
  return rows
end

local function current_choice()
  local total = #ui_state.items
  if total <= 0 then
    return nil
  end
  return ui_state.items[ui_state.selected]
end

local function build_labels(items, opts)
  local labels = {}
  for _, item in ipairs(items or {}) do
    if is_back_item(item) then
      table.insert(labels, item.label or "Back")
    else
      local label = opts.format_item and opts.format_item(item) or tostring(item)
      table.insert(labels, label)
    end
  end
  return labels
end

local function can_execute_choice(choice, opts)
  if not choice or is_back_item(choice) then
    return false
  end
  if type((opts or {}).can_execute_on_enter) == "function" then
    return (opts.can_execute_on_enter(choice)) == true
  end
  return true
end

local function normalize_enter_hint_lines(lines)
  if type(lines) == "string" then
    local text = tostring(lines or "")
    if text == "" then
      return {}
    end
    return { text }
  end
  if type(lines) ~= "table" then
    return {}
  end
  local normalized = {}
  for _, line in ipairs(lines) do
    local text = tostring(line or "")
    if text ~= "" then
      table.insert(normalized, text)
    end
  end
  return normalized
end

-- サブメニュー下部へ表示するEnter説明を、選択項目と画面状態から組み立てる。
local function resolve_enter_hint_lines(choice, opts, lang, static_view)
  if static_view then
    return {}
  end
  local lines = {}
  if type((opts or {}).enter_hint_provider) == "function" then
    lines = normalize_enter_hint_lines(opts.enter_hint_provider(choice, lang))
  end
  if #lines > 0 then
    return lines
  end
  if not choice then
    if lang == "ja" or lang == "jp" then
      return { "󰌑 Enterで操作する項目を選択してください。" }
    end
    return { "󰌑 Select a row to execute with Enter." }
  end
  if is_back_item(choice) then
    if lang == "ja" or lang == "jp" then
      return { "󰁍 Enter: 前の画面へ戻ります。" }
    end
    return { "󰁍 Enter: Return to previous menu." }
  end
  if not can_execute_choice(choice, opts) then
    if lang == "ja" or lang == "jp" then
      return { "󰇀 この行は表示専用です。Enterでは何も起きません。" }
    end
    return { "󰇀 This row is display-only. Enter does nothing." }
  end
  local keep_open = (opts or {}).keep_open == true or (type(choice) == "table" and choice.keep_open == true)
  if keep_open then
    if lang == "ja" or lang == "jp" then
      return { "󰌑 Enter: 適用してこの画面を維持します。" }
    end
    return { "󰌑 Enter: Apply and keep this menu open." }
  end
  if lang == "ja" or lang == "jp" then
    return { "󰌑 Enter: 実行してこの画面を閉じます。" }
  end
  return { "󰌑 Enter: Execute and close this menu." }
end

-- 詳細表示オブジェクトを安全な形式へ正規化する。
local function normalize_detail(detail)
  if type(detail) ~= "table" then
    return nil
  end
  local title = tostring(detail.title or "")
  local lines = {}
  for _, line in ipairs(detail.lines or {}) do
    table.insert(lines, tostring(line or ""))
  end
  if title == "" and #lines == 0 then
    return nil
  end
  return { title = title, lines = lines }
end

local function has_detail_lines(lines)
  for _, line in ipairs(lines or {}) do
    if tostring(line or "") ~= "" then
      return true
    end
  end
  return false
end

-- 項目から詳細プレビューを生成する。比較情報がない場合でも説明文を補う。
local function resolve_detail(item, opts, lang)
  if not item then
    return nil
  end
  if is_back_item(item) then
    if lang == "ja" then
      return {
        title = "戻る",
        lines = {
          "この選択で前の画面に戻ります。",
          "現在の変更内容は保持されます。",
        },
      }
    end
    return {
      title = "Back",
      lines = {
        "Return to the previous menu.",
        "Current changes remain applied.",
      },
    }
  end
  local detail = nil
  if type(opts.detail_provider) == "function" then
    detail = normalize_detail(opts.detail_provider(item))
  end
  if (not detail) and type(item) == "table" and type(item.detail_lines) == "table" then
    detail = normalize_detail({
      title = item.detail_title or item.label or "",
      lines = item.detail_lines,
    })
  end
  if detail then
    return detail
  end
  if lang == "ja" then
    return {
      title = tostring((item and item.label) or "項目"),
      lines = {
        "Enterでこの項目を適用します。",
        "変化がない場合はそのまま閉じます。",
      },
    }
  end
  return {
    title = tostring((item and item.label) or "Item"),
    lines = {
      "Press Enter to apply this item.",
      "If nothing changes, the view stays as-is.",
    },
  }
end

-- 下部詳細欄の長文を、指定幅に収まる行へ分割する。
local function wrap_detail_footer_line(line, width)
  local safe_width = math.max(tonumber(width) or 0, 1)
  local text = tostring(line or "")
  if text == "" then
    return { "" }
  end
  if util.display_width(text) <= safe_width then
    return { text }
  end
  local chunks = {}
  local current = ""
  local tokens = {}
  for token in text:gmatch("%S+") do
    table.insert(tokens, token)
  end
  if #tokens == 0 then
    return { util.clamp_line(text, safe_width) }
  end
  local function flush()
    if current ~= "" then
      table.insert(chunks, current)
      current = ""
    end
  end
  local function split_long_token(token)
    local piece = ""
    for _, char in ipairs(util.split_utf8(token)) do
      local candidate = piece .. char
      if util.display_width(candidate) > safe_width then
        if piece ~= "" then
          table.insert(chunks, piece)
        end
        piece = char
      else
        piece = candidate
      end
    end
    if piece ~= "" then
      current = piece
    end
  end
  for _, token in ipairs(tokens) do
    local candidate = current == "" and token or (current .. " " .. token)
    if util.display_width(candidate) <= safe_width then
      current = candidate
    else
      flush()
      if util.display_width(token) <= safe_width then
        current = token
      else
        split_long_token(token)
      end
    end
  end
  flush()
  return chunks
end

-- サブメニュー下部へ、選択項目の詳細を圧縮表示する。
local function build_detail_footer_lines(detail, lang, width)
  if not detail or not has_detail_lines(detail.lines) then
    return {}
  end
  local safe_width = math.max(tonumber(width) or 0, 1)
  local is_ja = lang == "ja" or lang == "jp"
  local title_prefix = is_ja and "󰋼 詳細: " or "󰋼 Detail: "
  local lines = { util.clamp_line(title_prefix .. tostring(detail.title or "-"), safe_width) }
  local flattened = {}
  for _, line in ipairs(detail.lines or {}) do
    for _, piece in ipairs(wrap_detail_footer_line(line, safe_width - 2)) do
      local safe_piece = tostring(piece or "")
      if safe_piece ~= "" then
        table.insert(flattened, safe_piece)
      end
    end
  end
  local max_body_rows = 3
  for index = 1, math.min(#flattened, max_body_rows) do
    table.insert(lines, util.clamp_line("  " .. flattened[index], safe_width))
  end
  return lines
end

-- 右ペインへ表示するプレビュー行を本文高さに合わせて構築する。
local function build_detail_preview_lines(detail, visible)
  local rows = {}
  if detail and detail.title and detail.title ~= "" then
    table.insert(rows, detail.title)
    table.insert(rows, string.rep("·", 24))
  end
  for _, line in ipairs((detail and detail.lines) or {}) do
    table.insert(rows, line)
  end
  local filled = {}
  for index = 1, math.max(visible, 0) do
    filled[index] = rows[index] or ""
  end
  return filled
end

-- サブメニューで詳細比較を表示すべきかを判定する。
local function should_show_detail_panel(opts, items, static_view)
  if static_view then
    return false
  end
  if type((opts or {}).detail_provider) == "function" then
    return true
  end
  for _, item in ipairs(items or {}) do
    if type(item) == "table" and type(item.detail_lines) == "table" then
      return true
    end
  end
  return false
end

-- 静的詳細表示では本文を優先し、通常メニューより縦幅を広く使う。
local function resolve_static_height(config, screen_height, line_count)
  local safe_screen = math.max(tonumber(screen_height) or 0, 12)
  local min_height = math.max(tonumber(config.min_height) or 16, 12)
  local configured_max = tonumber(config.max_static_height) or safe_screen
  local max_height = math.max(math.min(configured_max, safe_screen), min_height)
  -- 詳細画面は通常メニューの高さ制約より本文を優先して広く確保する。
  local desired_visible = math.max(tonumber(line_count) or 0, math.floor(safe_screen * 0.6), 22)
  local desired_height = desired_visible + 1 -- フッター行を1行確保する。
  return math.max(math.min(desired_height, max_height), min_height)
end

-- 静的詳細表示では内容幅へ寄せ、余白で左寄りに見える状態を防ぐ。
local function resolve_static_width(config, width_lines)
  local available = math.max(tonumber(config.available_width) or tonumber(config.width) or 48, 24)
  -- 詳細画面はカード実幅を優先し、不要な右余白を作らない。
  local min_width = math.max(tonumber(config.static_min_width) or 20, 20)
  local max_width = math.max(math.min(tonumber(config.static_max_width) or available, available), min_width)
  -- 詳細カードの見た目を揃えるため、余分な右側余白を足さず本文幅へ合わせる。
  local content_width = menu_view_util.max_line_width(width_lines)
  return math.max(math.min(content_width, max_width), min_width)
end

local function render()
  local config = menu_view_util.menu_config(ui_state.config)
  local lang = ui_state.meta.lang
  local static_view = ui_state.opts.static_view == true
  -- サブメニューでは上部の進捗表示を省き、選択操作へ集中できるようにする。
  local top_lines = {}
  local labels = build_labels(ui_state.items, ui_state.opts)
  local title = ui_state.opts.prompt_provider and ui_state.opts.prompt_provider()
    or ui_state.opts.prompt
    or (lang == "ja" and "メニュー" or "Menu")
  if static_view then
    title = ""
  elseif title ~= "" then
    -- サブメニューはゲーム風の見出しアイコンを付けて画面としての統一感を出す。
    title = string.format("󰮫 %s", title)
  end
  local hints = ui_state.opts.footer_hints or menu_locale.submenu_footer_hints(lang)
  local tabs_line = ui_state.opts.tabs_line or ""
  local selected_item = current_choice()
  local detail_notes = {}
  if not static_view then
    local detail_width = tonumber(config.min_width) or 56
    detail_notes = build_detail_footer_lines(resolve_detail(selected_item, ui_state.opts, lang), lang, detail_width)
  end
  local enter_notes = resolve_enter_hint_lines(selected_item, ui_state.opts, lang, static_view)
  local footer_notes = {}
  for _, line in ipairs(detail_notes or {}) do
    table.insert(footer_notes, line)
  end
  for _, line in ipairs(enter_notes or {}) do
    table.insert(footer_notes, line)
  end
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
  local width = menu_view_util.resolve_compact_width(config, top_lines, tabs_line)
  local height
  if static_view then
    height = resolve_static_height(config, screen_height, #labels)
  else
    height = menu_view_util.resolve_compact_height(
      config,
      screen_height,
      #labels,
      top_lines,
      tabs_line ~= "",
      #footer_notes
    )
  end
  local visible = frame.resolve_content_height({
    height = height,
    tabs_line = tabs_line,
    top_lines = top_lines,
    footer_notes = footer_notes,
    hide_title = static_view,
    hide_divider = static_view,
  })
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local left_lines, selected_row = menu_view_util.build_select_lines({
    labels = labels,
    items = ui_state.items,
    selected = ui_state.selected,
    offset = ui_state.offset,
    visible = visible,
    prefix = ui_state.opts.item_prefix or config.item_prefix or "󰜴 ",
    non_select_prefix = ui_state.opts.non_select_prefix or "  ",
    is_selectable = function(item)
      if static_view then
        return false
      end
      return not is_back_item(item)
    end,
    render_line = function(label, item, mark)
      if static_view then
        return label
      end
      if is_back_item(item) then
        return mark .. "↩ " .. label
      end
      return mark .. label
    end,
  })
  local right_lines = {}
  local width_lines = { title, tabs_line }
  local show_detail = false
  if ui_state.opts.detail_layout == "split" then
    -- 2カラム指定時のみ右側に詳細を描画し、通常サブメニューは1カラムを維持する。
    show_detail = should_show_detail_panel(ui_state.opts, ui_state.items, static_view)
  end
  if show_detail then
    local detail = resolve_detail(current_choice(), ui_state.opts, lang)
    right_lines = build_detail_preview_lines(detail, visible)
  end
  for _, line in ipairs(left_lines or {}) do
    table.insert(width_lines, line)
  end
  for _, line in ipairs(right_lines or {}) do
    table.insert(width_lines, line)
  end
  for _, line in ipairs(footer_notes or {}) do
    table.insert(width_lines, line)
  end
  if static_view then
    -- ヒント行は長くなりやすいため、詳細カード本体の幅へ合わせる。
    width = resolve_static_width(config, left_lines or {})
  else
    width = menu_view_util.resolve_display_width(config, width, width_lines)
  end
  if show_detail then
    -- 2カラム時は左右ペインを成立させる最小幅を確保する。
    width = math.max(width, 96)
  end
  local shell = frame.compose({
    title = title,
    top_lines = top_lines,
    tabs_line = tabs_line,
    left_lines = left_lines,
    right_lines = right_lines,
    show_right = show_detail,
    footer_notes = footer_notes,
    footer_hints = hints,
    width = width,
    height = height,
    hide_title = static_view,
    hide_divider = static_view,
  })
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, width, config.border, config.theme, ui_state.opts)
  window.update_window(win, height, width)
  window.set_lines(buf, shell.lines)
  local highlights = {
    { line = shell.title_line_index, group = "IdleDungeonMenuTitle" },
    { line = shell.footer_hint_line, group = "IdleDungeonMenuMuted" },
  }
  if shell.footer_note_divider_line then
    table.insert(highlights, { line = shell.footer_note_divider_line, group = "IdleDungeonMenuDivider" })
  end
  if shell.footer_note_start_line and shell.footer_note_end_line then
    for line = shell.footer_note_start_line, shell.footer_note_end_line do
      table.insert(highlights, { line = line, group = "IdleDungeonMenuHint" })
    end
  end
  if shell.tabs_line_index then
    table.insert(highlights, { line = shell.tabs_line_index, group = "IdleDungeonMenuTabs" })
  end
  local selected_marker_width = 0
  if selected_row then
    local marker_width = string.len(config.item_prefix or "󰜴 ")
    selected_marker_width = marker_width
    table.insert(highlights, {
      line = shell.body_start + selected_row - 1,
      group = selection_fx.selected_group(ui_state.selection_fx),
      start_col = shell.left_col - 1,
      end_col = (shell.left_col - 1) + marker_width,
    })
  end
  window.apply_highlights(buf, highlights)
  if ui_state.selected > 0 and not static_view then
    local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
    local cursor_col = (shell.left_col - 1) + math.max(selected_marker_width, 2)
    vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), cursor_col })
  end
  ui_state.labels = labels
  ui_state.win = win
  ui_state.buf = buf
end

local function move(delta)
  local total = #ui_state.labels
  if total <= 0 then
    return
  end
  -- 項目選択は上下端で循環させ、連続入力でも移動方向を維持する。
  ui_state.selected = menu_view_util.wrap_selected(ui_state.selected + delta, total)
  render()
  selection_fx.start(ui_state.selection_fx, render)
end

local function cancel()
  local callback = ui_state.on_choice
  close()
  if callback then
    callback(nil)
  end
end

local function select_current()
  if ui_state.opts.static_view == true then
    cancel()
    return
  end
  local choice = current_choice()
  if is_back_item(choice) then
    cancel()
    return
  end
  if not can_execute_choice(choice, ui_state.opts) then
    -- 実行対象ではない行はEnterを無視し、画面を閉じない。
    return
  end
  local callback = ui_state.on_choice
  local keep_open = ui_state.opts.keep_open == true or (type(choice) == "table" and choice.keep_open == true)
  if keep_open then
    if callback then
      callback(choice)
    end
    render()
    return
  end
  close()
  if callback then
    callback(choice)
  end
end

local function set_keymaps(buf)
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "gg", function()
      ui_state.selected = menu_view_util.clamp_selected(1, #ui_state.items)
      render()
      selection_fx.start(ui_state.selection_fx, render)
    end },
    { "G", function()
      ui_state.selected = menu_view_util.clamp_selected(#ui_state.items, #ui_state.items)
      render()
      selection_fx.start(ui_state.selection_fx, render)
    end },
    { "<CR>", select_current },
    { "b", cancel },
    { "<BS>", cancel },
    { "<Left>", cancel },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
end

local function select(items, opts, on_choice, config)
  close()
  local safe_opts = opts or {}
  local lang = safe_opts.lang or (((config or {}).ui or {}).language or "en")
  local rows = decorate_items(items, safe_opts, lang)
  local selected = safe_opts.add_back_item == false and 1 or math.min(#rows, 2)
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.items = rows
  ui_state.opts = safe_opts
  ui_state.on_choice = on_choice
  ui_state.config = config or {}
  ui_state.selected = menu_view_util.clamp_selected(selected, #rows)
  ui_state.offset = 0
  ui_state.meta = { lang = lang }
  ui_state.selection_fx = {}
  render()
  if ui_state.buf then
    set_keymaps(ui_state.buf)
  end
end

M.select = select
M.close = close
M.set_context = function(get_state, config)
  shared_context.get_state = get_state
  shared_context.config = config
end

return M
