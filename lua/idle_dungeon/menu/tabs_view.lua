-- このモジュールはタブ付きの中央メニュー表示を提供する。
-- タブ描画の参照先はmenu配下に統一する。
local layout = require("idle_dungeon.menu.layout")
local menu_tabs = require("idle_dungeon.menu.tabs")
local menu_view_util = require("idle_dungeon.menu.view_util")
local window = require("idle_dungeon.menu.window")
local M = {}
local ui_state = {
  win = nil,
  buf = nil,
  prev_win = nil,
  tabs = {},
  active = 1,
  selected = 1,
  offset = 0,
  labels = {},
  items = {},
  opts = {},
  config = {},
  on_close = nil,
}
local function close()
  local callback = ui_state.on_close
  ui_state.on_close = nil
  -- 表示中のメニューウィンドウを閉じる。
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
  if callback then callback() end
end
local function render()
  local tab = ui_state.tabs[ui_state.active]
  if not tab then return end
  local config = menu_view_util.menu_config(ui_state.config); local labels = layout.build_labels(tab.items, tab.format_item)
  local tabs_line = menu_tabs.build_tabs_line(ui_state.tabs, ui_state.active); local title = (ui_state.opts or {}).title or ""
  local header_count = (title ~= "" and 1 or 0) + (config.tabs_position == "bottom" and 1 or 2); local footer_count = config.tabs_position == "bottom" and 2 or 0
  local max_height = math.max(config.max_height, header_count + footer_count + 1); local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 4)
  local height_limit = math.min(max_height, screen_height); local visible = math.max(height_limit - header_count - footer_count, 1)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels); ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local max_width = math.max(math.min(config.width, vim.o.columns - 4), 24); local built = layout.build_lines("", labels, {
    padding = config.padding,
    offset = ui_state.offset,
    max_items = visible,
    max_width = max_width,
  })
  local sections = menu_view_util.build_tabs_sections(ui_state.opts, config, tabs_line, built, max_width)
  local lines = {}
  for _, line in ipairs(sections.header_lines) do table.insert(lines, line) end
  for _, line in ipairs(built.lines) do table.insert(lines, line) end
  for _, line in ipairs(sections.footer_lines) do table.insert(lines, line) end
  local height = math.max(#lines, 1)
  -- タブ付きの中央メニュー表示を更新する。
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, sections.width, config.border)
  window.update_window(win, height, sections.width)
  window.set_lines(buf, lines)
  local highlight_lines = {}; if title ~= "" then highlight_lines[1] = 1 end
  local tabs_line_index = config.tabs_position == "bottom" and (#sections.header_lines + #built.lines + #sections.footer_lines) or (title ~= "" and 2 or 1)
  highlight_lines[#highlight_lines + 1] = tabs_line_index
  window.apply_highlights(buf, highlight_lines)
  if ui_state.selected > 0 and #labels > 0 then
    vim.api.nvim_win_set_cursor(win, { math.max(#sections.header_lines + (ui_state.selected - built.offset), 1), 0 })
  end
  ui_state.labels, ui_state.items = labels, (tab.items or {})
  ui_state.win, ui_state.buf = win, buf
end
local function move(delta)
  if #ui_state.labels == 0 then return end
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, #ui_state.labels)
  render()
end
local function switch_tab(delta)
  local total = #ui_state.tabs
  if total <= 0 then return end
  ui_state.active = menu_tabs.shift_index(ui_state.active, delta, total)
  local tab = ui_state.tabs[ui_state.active] or {}
  ui_state.selected = menu_view_util.clamp_selected(1, #(tab.items or {}))
  ui_state.offset = 0
  render()
end
local function select_current()
  local tab = ui_state.tabs[ui_state.active]
  if not tab or not tab.on_choice then return end
  local choice = #ui_state.items > 0 and ui_state.items[ui_state.selected] or nil
  local callback = tab.on_choice
  close()
  callback(choice)
end
local function cancel()
  close()
end
local function set_keymaps(buf)
  -- タブ付きメニュー操作用のキーマップを設定する。
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "<Tab>", function() switch_tab(1) end },
    { "<S-Tab>", function() switch_tab(-1) end },
    { "<Right>", function() switch_tab(1) end },
    { "<Left>", function() switch_tab(-1) end },
    { "gg", function() ui_state.selected = menu_view_util.clamp_selected(1, #ui_state.items) render() end },
    { "G", function() ui_state.selected = menu_view_util.clamp_selected(#ui_state.items, #ui_state.items) render() end },
    { "<CR>", select_current },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
end

local function update(tabs)
  if not window.is_valid_window(ui_state.win) or not window.is_valid_buffer(ui_state.buf) then return end
  if tabs and #tabs > 0 then ui_state.tabs = tabs end
  ui_state.active = menu_view_util.clamp_selected(ui_state.active, #ui_state.tabs)
  local active_items = ui_state.tabs[ui_state.active] and ui_state.tabs[ui_state.active].items or {}
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #active_items)
  -- 最新の内容に合わせてメニュー表示を再描画する。
  render()
end
local function select(tabs, opts, config)
  close()
  if not tabs or #tabs == 0 then return end
  -- タブ付きメニューの状態を初期化して表示する。
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.tabs = tabs
  ui_state.opts = opts or {}
  ui_state.config = config or {}
  local active = ui_state.opts.active or 1
  if ui_state.opts.active_id then
    for index, tab in ipairs(tabs) do
      if tab.id == ui_state.opts.active_id then active = index break end
    end
  end
  ui_state.active = menu_view_util.clamp_selected(active, #tabs)
  ui_state.selected = 1
  ui_state.offset = 0
  ui_state.on_close = ui_state.opts.on_close
  render()
  local buf = ui_state.buf
  if buf then set_keymaps(buf) end
end
M.select = select
M.update = update
M.close = close
return M
