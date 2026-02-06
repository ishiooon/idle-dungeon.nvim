-- このモジュールは子メニューの2ペイン表示と操作を提供する。

local frame = require("idle_dungeon.menu.frame")
local menu_locale = require("idle_dungeon.menu.locale")
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
}
local shared_context = { get_state = nil, config = nil }

local function close()
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
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

local function render()
  local config = menu_view_util.menu_config(ui_state.config)
  local lang = ui_state.meta.lang
  -- サブメニューでは上部の進捗表示を省き、選択操作へ集中できるようにする。
  local top_lines = {}
  local labels = build_labels(ui_state.items, ui_state.opts)
  local title = ui_state.opts.prompt_provider and ui_state.opts.prompt_provider()
    or ui_state.opts.prompt
    or (lang == "ja" and "メニュー" or "Menu")
  local hints = ui_state.opts.footer_hints or menu_locale.submenu_footer_hints(lang)
  local tabs_line = ui_state.opts.tabs_line or (lang == "ja" and "Sub Menu" or "Sub Menu")
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
  local width = menu_view_util.resolve_compact_width(config, top_lines, tabs_line)
  local height = menu_view_util.resolve_compact_height(config, screen_height, #labels, top_lines, tabs_line ~= "")
  local visible = frame.resolve_content_height({ height = height, tabs_line = tabs_line, top_lines = top_lines })
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local left_lines, selected_row = menu_view_util.build_select_lines({
    labels = labels,
    items = ui_state.items,
    selected = ui_state.selected,
    offset = ui_state.offset,
    visible = visible,
    prefix = config.item_prefix or "≫ ",
    render_line = function(label, item, mark)
      if is_back_item(item) then
        return mark .. "↩ " .. label
      end
      return mark .. label
    end,
  })
  local shell = frame.compose({
    title = title,
    top_lines = top_lines,
    tabs_line = tabs_line,
    left_lines = left_lines,
    show_right = false,
    footer_hints = hints,
    width = width,
    height = height,
  })
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, width, config.border, config.theme)
  window.update_window(win, height, width)
  window.set_lines(buf, shell.lines)
  local highlights = {
    { line = shell.title_line_index, group = "IdleDungeonMenuTitle" },
    { line = shell.footer_hint_line, group = "IdleDungeonMenuMuted" },
  }
  if shell.tabs_line_index then
    table.insert(highlights, { line = shell.tabs_line_index, group = "IdleDungeonMenuTabs" })
  end
  if selected_row then
    local marker_width = string.len(config.item_prefix or "≫ ")
    table.insert(highlights, {
      line = shell.body_start + selected_row - 1,
      group = "IdleDungeonMenuSelected",
      start_col = shell.left_col - 1,
      end_col = (shell.left_col - 1) + marker_width,
    })
  end
  window.apply_highlights(buf, highlights)
  if ui_state.selected > 0 then
    local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
    vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), shell.left_col - 1 })
  end
  ui_state.labels = labels
  ui_state.win = win
  ui_state.buf = buf
end

local function move(delta)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, #ui_state.labels)
  render()
end

local function cancel()
  local callback = ui_state.on_choice
  close()
  if callback then
    callback(nil)
  end
end

local function select_current()
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
    { "gg", function() ui_state.selected = menu_view_util.clamp_selected(1, #ui_state.items) render() end },
    { "G", function() ui_state.selected = menu_view_util.clamp_selected(#ui_state.items, #ui_state.items) render() end },
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
