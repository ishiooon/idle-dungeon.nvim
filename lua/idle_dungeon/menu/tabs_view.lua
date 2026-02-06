-- このモジュールはタブ付きメニューを2ペイン構成で描画する。

local frame = require("idle_dungeon.menu.frame")
local menu_tabs = require("idle_dungeon.menu.tabs")
local menu_view_util = require("idle_dungeon.menu.view_util")
local util = require("idle_dungeon.util")
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
}

-- 表示中のタブメニューを閉じる。
local function close()
  local callback = ui_state.on_close
  ui_state.on_close = nil
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
  if callback then
    callback()
  end
end

-- 現在のタブを取得する。
local function current_tab()
  return ui_state.tabs[ui_state.active]
end

-- 項目が選択対象かどうかを判定する。
local function is_selectable(item)
  if not item then
    return false
  end
  return not (item.id == "header" or item.id == "empty" or item.id == "art" or item.id == "spacer")
end

-- 現在のタブ項目を表示行へ整形する。
local function build_tab_lines(tab, config)
  local lines = {}
  for _, item in ipairs((tab and tab.items) or {}) do
    local format_item = tab and tab.format_item or nil
    local label = format_item and format_item(item) or (item and item.label) or ""
    if item and item.id == "header" then
      table.insert(lines, (config.section_prefix or "◆ ") .. label)
    elseif item and item.id == "empty" then
      table.insert(lines, (config.empty_prefix or "· ") .. label)
    elseif item and item.id == "spacer" then
      table.insert(lines, "")
    else
      table.insert(lines, label)
    end
  end
  return lines
end

-- 選択可能なインデックス一覧を返す。
local function selectable_indexes(tab)
  local result = {}
  for index, item in ipairs((tab and tab.items) or {}) do
    if is_selectable(item) then
      table.insert(result, index)
    end
  end
  return result
end

-- 現在選択中の項目を返す。
local function current_choice(tab)
  local item = (tab and tab.items or {})[ui_state.selected]
  if is_selectable(item) then
    return item
  end
  return nil
end

-- 詳細ペインの内容を構築する。
local function build_detail_lines(tab, choice)
  if tab and tab.detail_provider then
    local detail = tab.detail_provider(choice) or {}
    local lines = { detail.title or "", "" }
    for _, line in ipairs(detail.lines or {}) do
      table.insert(lines, tostring(line))
    end
    return lines
  end
  if choice and choice.detail_lines then
    local lines = { choice.detail_title or "", "" }
    for _, line in ipairs(choice.detail_lines or {}) do
      table.insert(lines, tostring(line))
    end
    return lines
  end
  return {
    "Detail",
    "",
    "Enter: Select",
    "Tab: Switch tab",
    "b: Close menu",
  }
end

-- 左ペインの可視行を構築する。
local function build_left_lines(labels, selected, offset, visible)
  local lines = {}
  for index = 1, visible do
    local absolute = (offset or 0) + index
    local label = labels[absolute] or ""
    local prefix = absolute == selected and "▶ " or "  "
    lines[index] = prefix .. label
  end
  return lines
end

-- 選択位置を妥当な範囲へ寄せる。
local function ensure_selection(tab)
  local indexes = selectable_indexes(tab)
  if #indexes == 0 then
    ui_state.selected = 1
    return
  end
  local selected = menu_view_util.clamp_selected(ui_state.selected, #(tab.items or {}))
  local selected_item = (tab.items or {})[selected]
  if is_selectable(selected_item) then
    ui_state.selected = selected
    return
  end
  ui_state.selected = indexes[1]
end

-- タブメニューを再描画する。
local function render()
  local tab = current_tab()
  if not tab then
    return
  end
  ensure_selection(tab)
  local config = menu_view_util.menu_config(ui_state.config)
  local tabs_line = menu_tabs.build_tabs_line(ui_state.tabs, ui_state.active, config.tabs_style)
  local title = (ui_state.opts and ui_state.opts.title) or "Idle Dungeon"
  local footer_hints = (ui_state.opts and ui_state.opts.footer_hints) or {}
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  local height = math.min(config.height, screen_height)
  local visible = frame.resolve_content_height({ height = height, tabs_line = tabs_line })

  local labels = build_tab_lines(tab, config)
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local left_lines = build_left_lines(labels, ui_state.selected, ui_state.offset, visible)
  local right_lines = build_detail_lines(tab, current_choice(tab))
  local shell = frame.compose({
    title = title,
    tabs_line = tabs_line,
    left_lines = left_lines,
    right_lines = right_lines,
    footer_hints = footer_hints,
    width = config.width,
    height = height,
  })

  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, config.width, config.border, config.theme)
  window.update_window(win, height, config.width)
  window.set_lines(buf, shell.lines)

  local highlights = {
    { line = shell.title_line_index, group = "IdleDungeonMenuTitle" },
    { line = shell.footer_hint_line, group = "IdleDungeonMenuMuted" },
  }
  if shell.tabs_line_index then
    table.insert(highlights, { line = shell.tabs_line_index, group = "IdleDungeonMenuTabs" })
  end
  window.apply_highlights(buf, highlights)

  local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
  vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), shell.left_col - 1 })

  ui_state.labels = labels
  ui_state.tabs_line_index = shell.tabs_line_index
  ui_state.tab_segments = {}
  if shell.tabs_line_index then
    for _, segment in ipairs(menu_tabs.build_tabs_segments(ui_state.tabs, ui_state.active, config.tabs_style)) do
      table.insert(ui_state.tab_segments, {
        index = segment.index,
        start_col = segment.start_col + 2,
        end_col = segment.end_col + 2,
      })
    end
  end
  ui_state.win = win
  ui_state.buf = buf
end

-- 同一タブ内で上下移動する。
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
end

-- タブを切り替える。
local function switch_tab(delta)
  ui_state.active = menu_tabs.shift_index(ui_state.active, delta, #ui_state.tabs)
  ui_state.offset = 0
  ui_state.selected = 1
  render()
end

-- 現在の項目を確定する。
local function select_current()
  local tab = current_tab()
  if not tab or not tab.on_choice then
    return
  end
  local choice = current_choice(tab)
  if choice and choice.keep_open then
    tab.on_choice(choice)
    render()
    return
  end
  close()
  tab.on_choice(choice)
end

-- タブメニューを閉じる。
local function cancel()
  close()
end

-- キーマップを設定する。
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
    end, { buffer = buf, silent = true })
  end
end

-- 開いているタブメニューを更新する。
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

-- タブメニューを開く。
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
  render()
  if ui_state.buf then
    set_keymaps(ui_state.buf)
  end
end

M.select = select
M.update = update
M.close = close

return M
