-- このモジュールは子メニューの2ペイン表示と操作を提供する。

local frame = require("idle_dungeon.menu.frame")
local menu_locale = require("idle_dungeon.menu.locale")
local selection_fx = require("idle_dungeon.menu.selection_fx")
local menu_view_util = require("idle_dungeon.menu.view_util")
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
  end
  local hints = ui_state.opts.footer_hints or menu_locale.submenu_footer_hints(lang)
  local tabs_line = ui_state.opts.tabs_line or ""
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
  local width = menu_view_util.resolve_compact_width(config, top_lines, tabs_line)
  local height
  if static_view then
    height = resolve_static_height(config, screen_height, #labels)
  else
    height = menu_view_util.resolve_compact_height(config, screen_height, #labels, top_lines, tabs_line ~= "")
  end
  local visible = frame.resolve_content_height({
    height = height,
    tabs_line = tabs_line,
    top_lines = top_lines,
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
  local width_lines = { title, tabs_line }
  for _, line in ipairs(left_lines or {}) do
    table.insert(width_lines, line)
  end
  if static_view then
    -- ヒント行は長くなりやすいため、詳細カード本体の幅へ合わせる。
    width = resolve_static_width(config, left_lines or {})
  else
    width = menu_view_util.resolve_display_width(config, width, width_lines)
  end
  local shell = frame.compose({
    title = title,
    top_lines = top_lines,
    tabs_line = tabs_line,
    left_lines = left_lines,
    show_right = false,
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
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, #ui_state.labels)
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
