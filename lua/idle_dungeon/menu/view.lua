-- このモジュールは子メニューを2ペイン表示で描画する。

local frame = require("idle_dungeon.menu.frame")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_view_util = require("idle_dungeon.menu.view_util")
local window = require("idle_dungeon.menu.window")

local M = {}

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
}

-- 現在表示中の子メニューを閉じる。
local function close()
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
end

-- 現在の選択項目を取得する。
local function current_choice()
  local total = #ui_state.items
  if total <= 0 then
    return nil
  end
  return ui_state.items[ui_state.selected]
end

-- 子メニュー左ペインの行を構築する。
local function build_left_lines(labels, selected, offset, visible)
  local lines = {}
  for index = 1, visible do
    local label = labels[(offset or 0) + index]
    if not label then
      lines[index] = ""
    else
      local absolute = (offset or 0) + index
      local prefix = absolute == selected and "▶ " or "  "
      lines[index] = prefix .. label
    end
  end
  return lines
end

-- 詳細ペインの行を構築する。
local function build_right_lines(opts, choice)
  if opts.detail_provider then
    local detail = opts.detail_provider(choice) or {}
    local lines = {}
    lines[1] = detail.title or ""
    lines[2] = ""
    for _, line in ipairs(detail.lines or {}) do
      table.insert(lines, tostring(line))
    end
    return lines
  end
  local lines = {}
  lines[1] = "Detail"
  lines[2] = ""
  lines[3] = "Enter: Select"
  lines[4] = "b: Back"
  lines[5] = "q: Close"
  return lines
end

-- 子メニューを再描画する。
local function render()
  local config = menu_view_util.menu_config(ui_state.config)
  local labels = {}
  for _, item in ipairs(ui_state.items) do
    local label = ui_state.opts.format_item and ui_state.opts.format_item(item) or tostring(item)
    table.insert(labels, label)
  end
  local lang = ui_state.opts.lang or (((ui_state.config or {}).ui or {}).language or "en")
  local hints = ui_state.opts.footer_hints or menu_locale.submenu_footer_hints(lang)
  local title = ui_state.opts.prompt_provider and ui_state.opts.prompt_provider() or (ui_state.opts.prompt or "Menu")
  local tabs_line = ui_state.opts.tabs_line or "Sub Menu"
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  local height = math.min(config.height, screen_height)
  local visible = frame.resolve_content_height({ height = height, tabs_line = tabs_line })

  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local left_lines = build_left_lines(labels, ui_state.selected, ui_state.offset, visible)
  local right_lines = build_right_lines(ui_state.opts, current_choice())
  local shell = frame.compose({
    title = title,
    tabs_line = tabs_line,
    left_lines = left_lines,
    right_lines = right_lines,
    footer_hints = hints,
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
  if ui_state.selected > 0 then
    local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
    vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), shell.left_col - 1 })
  end
  ui_state.labels = labels
  ui_state.win = win
  ui_state.buf = buf
end

-- 項目選択カーソルを上下移動する。
local function move(delta)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, #ui_state.labels)
  render()
end

-- 現在項目を確定する。
local function select_current()
  local choice = current_choice()
  local callback = ui_state.on_choice
  if ui_state.opts.keep_open then
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

-- キャンセル時の処理を行う。
local function cancel()
  local callback = ui_state.on_choice
  close()
  if callback then
    callback(nil)
  end
end

-- キーマップをバッファへ設定する。
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

-- 子メニューを開く。
local function select(items, opts, on_choice, config)
  close()
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.items = items or {}
  ui_state.opts = opts or {}
  ui_state.on_choice = on_choice
  ui_state.config = config or {}
  ui_state.selected = menu_view_util.clamp_selected(1, #ui_state.items)
  ui_state.offset = 0
  render()
  if ui_state.buf then
    set_keymaps(ui_state.buf)
  end
end

M.select = select
M.close = close

return M
