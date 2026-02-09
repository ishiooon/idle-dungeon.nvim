-- このモジュールはタブ付きメニュー本体の描画と操作を提供する。

local frame = require("idle_dungeon.menu.frame")
local live_header = require("idle_dungeon.menu.live_header")
local menu_locale = require("idle_dungeon.menu.locale")
local selection_fx = require("idle_dungeon.menu.selection_fx")
local menu_view = require("idle_dungeon.menu.view")
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
  opts = {},
  config = {},
  on_close = nil,
  tabs_line_index = nil,
  tab_segments = {},
  visible_items = {},
  layout = { width = nil, height = nil },
  selection_fx = {},
}
local shared_context = { get_state = nil, config = nil }

local function close()
  local callback = ui_state.on_close
  ui_state.on_close = nil
  selection_fx.stop(ui_state.selection_fx)
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
  ui_state.tabs = {}
  ui_state.tab_segments = {}
  if callback then
    callback()
  end
end

local function current_tab()
  return ui_state.tabs[ui_state.active]
end

local function is_selectable(item)
  if not item then
    return false
  end
  return not (item.id == "header" or item.id == "empty" or item.id == "art" or item.id == "spacer")
end

local function selectable_indexes(tab)
  local rows = {}
  for index, item in ipairs((tab and tab.items) or {}) do
    if is_selectable(item) then
      table.insert(rows, index)
    end
  end
  return rows
end

local function ensure_selection(tab)
  local indexes = selectable_indexes(tab)
  if #indexes == 0 then
    ui_state.selected = 1
    return
  end
  local current = menu_view_util.clamp_selected(ui_state.selected, #(tab.items or {}))
  if is_selectable((tab.items or {})[current]) then
    ui_state.selected = current
    return
  end
  ui_state.selected = indexes[1]
end

local function current_choice(tab)
  local item = (tab and tab.items or {})[ui_state.selected]
  if is_selectable(item) then
    return item
  end
  return nil
end

local function build_tab_lines(tab, config)
  local lines = {}
  local visible_items = {}
  for _, item in ipairs((tab and tab.items) or {}) do
    local format_item = tab and tab.format_item or nil
    local label = format_item and format_item(item) or (item and item.label) or ""
    if item and item.id == "header" then
      table.insert(lines, string.format("  %s", config.section_prefix or "󰉖 "))
      lines[#lines] = lines[#lines] .. label
      table.insert(visible_items, item)
    elseif item and item.id == "empty" then
      table.insert(lines, string.format("  %s%s", config.empty_prefix or "󰇘 ", label))
      table.insert(visible_items, item)
    elseif item and item.id == "spacer" then
      table.insert(lines, "")
      table.insert(visible_items, item)
    else
      table.insert(lines, label)
      table.insert(visible_items, item)
    end
  end
  return lines, visible_items
end

local function build_formatted_lines(tab, config)
  local labels = {}
  for _, item in ipairs((tab and tab.items) or {}) do
    local format_item = tab and tab.format_item or nil
    local label = format_item and format_item(item) or (item and item.label) or ""
    if item and item.id == "header" then
      label = string.format("  %s%s", config.section_prefix or "󰉖 ", label)
    elseif item and item.id == "empty" then
      label = string.format("  %s%s", config.empty_prefix or "󰇘 ", label)
    elseif item and item.id == "spacer" then
      label = ""
    end
    table.insert(labels, label)
  end
  return labels
end

local function build_width_lines(title, tabs_line, footer_hints, top_lines, left_lines, all_tabs, config)
  local lines = { title, tabs_line, table.concat(footer_hints or {}, "   ") }
  for _, line in ipairs(top_lines or {}) do
    table.insert(lines, line)
  end
  for _, line in ipairs(left_lines or {}) do
    table.insert(lines, line)
  end
  -- タブ切替時の横幅ジャンプを避けるため、全タブの本文長も幅計算へ含める。
  for _, tab in ipairs(all_tabs or {}) do
    for _, line in ipairs(build_formatted_lines(tab, config)) do
      table.insert(lines, line)
    end
  end
  return lines
end

local function resolve_stable_layout(config, width, height)
  local max_width = tonumber(config.available_width) or width
  local max_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 10)
  local next_width = math.max(ui_state.layout.width or 0, width)
  local next_height = math.max(ui_state.layout.height or 0, height)
  ui_state.layout.width = math.min(next_width, max_width)
  ui_state.layout.height = math.min(next_height, max_height)
  return ui_state.layout.width, ui_state.layout.height
end

local function has_detail_lines(lines)
  for _, line in ipairs(lines or {}) do
    if line and tostring(line) ~= "" then
      return true
    end
  end
  return false
end

local function render()
  local tab = current_tab()
  if not tab then
    return
  end
  ensure_selection(tab)
  local config = menu_view_util.menu_config(ui_state.config)
  local lang = (((shared_context.get_state and shared_context.get_state()) or {}).ui or {}).language
    or ((shared_context.config or {}).ui or {}).language
    or "en"
  local top_lines = live_header.build_lines(
    shared_context.get_state and shared_context.get_state() or nil,
    shared_context.config or ui_state.config,
    lang
  )
  local tabs_line = menu_tabs.build_tabs_line(ui_state.tabs, ui_state.active, config.tabs_style)
  local base_title = (ui_state.opts and ui_state.opts.title) or "Idle Dungeon"
  local title = string.format("󰀘 %s", base_title)
  local footer_hints = (ui_state.opts and ui_state.opts.footer_hints) or {}
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  local labels, visible_items = build_tab_lines(tab, config)
  local width = menu_view_util.resolve_compact_width(config, top_lines, tabs_line)
  local height = menu_view_util.resolve_compact_height(config, screen_height, #labels, top_lines, tabs_line ~= "")
  local visible = frame.resolve_content_height({ height = height, tabs_line = tabs_line, top_lines = top_lines })
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local left_lines, selected_row = menu_view_util.build_select_lines({
    labels = labels,
    items = visible_items,
    selected = ui_state.selected,
    offset = ui_state.offset,
    visible = visible,
    prefix = config.item_prefix or "󰜴 ",
    non_select_prefix = "  ",
    is_selectable = is_selectable,
    render_line = function(label, _, mark, _, selectable)
      if selectable then
        return mark .. label
      end
      return "  " .. label
    end,
  })
  local width_lines = build_width_lines(title, tabs_line, footer_hints, top_lines, left_lines, ui_state.tabs, config)
  width = menu_view_util.resolve_display_width(config, width, width_lines)
  width, height = resolve_stable_layout(config, width, height)
  local shell = frame.compose({
    title = title,
    top_lines = top_lines,
    tabs_line = tabs_line,
    left_title = "MENU",
    left_lines = left_lines,
    show_right = false,
    footer_hints = footer_hints,
    width = width,
    height = height,
  })
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, width, config.border, config.theme, {
    -- メイン画面は折り返さず1行で表示して視認性を保つ。
    wrap_lines = false,
  })
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
  local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
  local cursor_col = (shell.left_col - 1) + math.max(selected_marker_width, 2)
  vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), cursor_col })
  ui_state.labels = labels
  ui_state.visible_items = visible_items
  ui_state.tabs_line_index = shell.tabs_line_index
  ui_state.tab_segments = {}
  if shell.tabs_line_index then
    for _, segment in ipairs(menu_tabs.build_tabs_segments(ui_state.tabs, ui_state.active, config.tabs_style)) do
      table.insert(ui_state.tab_segments, {
        index = segment.index,
        start_col = segment.start_col,
        end_col = segment.end_col,
      })
      table.insert(highlights, {
        line = shell.tabs_line_index,
        group = segment.index == ui_state.active and "IdleDungeonMenuTabActive" or "IdleDungeonMenuTabInactive",
        start_col = math.max(segment.start_col - 1, 0),
        end_col = segment.end_col,
      })
    end
  end
  window.apply_highlights(buf, highlights)
  ui_state.win = win
  ui_state.buf = buf
end

local function open_detail_page(tab, choice)
  if not choice then
    return false
  end
  local detail = nil
  if tab and tab.detail_provider then
    detail = tab.detail_provider(choice)
  end
  if not detail and choice.detail_lines then
    detail = {
      title = choice.detail_title or (choice.label or ""),
      lines = choice.detail_lines,
    }
  end
  if not detail or not has_detail_lines(detail.lines) then
    return false
  end
  local state = shared_context.get_state and shared_context.get_state() or {}
  local lang = ((state.ui or {}).language) or ((shared_context.config or {}).ui or {}).language or "en"
  menu_view.select(detail.lines, {
    prompt = detail.title or "",
    lang = lang,
    keep_open = true,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    format_item = function(line)
      return tostring(line)
    end,
  }, function()
  end, ui_state.config)
  return true
end

local function move(delta)
  local tab = current_tab()
  if not tab then
    return
  end
  local indexes = selectable_indexes(tab)
  if #indexes == 0 then
    return
  end
  local cursor = 1
  for index, value in ipairs(indexes) do
    if value == ui_state.selected then
      cursor = index
      break
    end
  end
  local next_cursor = math.max(math.min(cursor + delta, #indexes), 1)
  ui_state.selected = indexes[next_cursor]
  render()
  selection_fx.start(ui_state.selection_fx, render)
end

local function switch_tab(delta)
  ui_state.active = menu_tabs.shift_index(ui_state.active, delta, #ui_state.tabs)
  ui_state.offset = 0
  ui_state.selected = 1
  render()
  selection_fx.start(ui_state.selection_fx, render)
end

local function select_current()
  local tab = current_tab()
  if not tab then
    return
  end
  local choice = current_choice(tab)
  if open_detail_page(tab, choice) then
    return
  end
  if not tab.on_choice then
    return
  end
  local keep_open = choice and choice.keep_open == true
  if keep_open then
    tab.on_choice(choice)
    render()
    return
  end
  close()
  tab.on_choice(choice)
end

local function cancel()
  close()
end

local function set_keymaps(buf)
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "<Tab>", function() switch_tab(1) end },
    { "<S-Tab>", function() switch_tab(-1) end },
    { "<Right>", function() switch_tab(1) end },
    { "<Left>", function() switch_tab(-1) end },
    { "h", function() switch_tab(-1) end },
    { "l", function() switch_tab(1) end },
    { "gg", function() ui_state.selected = 1 render() end },
    { "G", function()
      local tab = current_tab()
      ui_state.selected = #(tab and tab.items or {})
      render()
    end },
    { "<CR>", select_current },
    { "<LeftMouse>", function()
      local pos = vim.fn.getmousepos()
      if pos.winid ~= ui_state.win or pos.line ~= ui_state.tabs_line_index then
        return
      end
      for _, segment in ipairs(ui_state.tab_segments or {}) do
        if pos.column >= segment.start_col and pos.column <= segment.end_col then
          ui_state.active = menu_view_util.clamp_selected(segment.index, #ui_state.tabs)
          ui_state.selected = 1
          ui_state.offset = 0
          render()
          selection_fx.start(ui_state.selection_fx, render)
          return
        end
      end
    end },
    { "b", cancel },
    { "<BS>", cancel },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
  for index = 1, #ui_state.tabs do
    vim.keymap.set("n", tostring(index), function()
      ui_state.active = index
      ui_state.selected = 1
      ui_state.offset = 0
      render()
      selection_fx.start(ui_state.selection_fx, render)
    end, { buffer = buf, silent = true })
  end
end

local function update(tabs)
  if not window.is_valid_window(ui_state.win) or not window.is_valid_buffer(ui_state.buf) then
    return
  end
  if tabs and #tabs > 0 then
    ui_state.tabs = tabs
  end
  ui_state.active = menu_view_util.clamp_selected(ui_state.active, #ui_state.tabs)
  render()
end

local function select(tabs, opts, config)
  close()
  if not tabs or #tabs == 0 then
    return
  end
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.tabs = tabs
  ui_state.opts = opts or {}
  ui_state.config = config or {}
  ui_state.on_close = ui_state.opts.on_close
  local active = ui_state.opts.active or 1
  if ui_state.opts.active_id then
    for index, tab in ipairs(tabs) do
      if tab.id == ui_state.opts.active_id then
        active = index
        break
      end
    end
  end
  ui_state.active = menu_view_util.clamp_selected(active, #tabs)
  ui_state.selected = 1
  ui_state.offset = 0
  ui_state.layout = { width = nil, height = nil }
  ui_state.selection_fx = {}
  render()
  if ui_state.buf then
    set_keymaps(ui_state.buf)
  end
end

M.select = select
M.update = update
M.close = close
M.set_context = function(get_state, config)
  shared_context.get_state = get_state
  shared_context.config = config
end

return M
