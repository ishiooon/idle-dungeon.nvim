-- このモジュールは画面中央にメニューを表示するためのUIを提供する。
-- 画面表示の参照先はmenu配下で統一する。
local detail_window = require("idle_dungeon.menu.detail_window")
local layout = require("idle_dungeon.menu.layout")
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
  detail = { win = nil, buf = nil },
}

local function close()
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.detail = detail_window.close(ui_state.detail)
  ui_state.win = nil
  ui_state.buf = nil
end

local function render()
  local config = menu_view_util.menu_config(ui_state.config)
  local labels = layout.build_labels(ui_state.items, ui_state.opts.format_item)
  -- 表示タイトルは必要に応じて動的に生成する。
  local title = ui_state.opts.prompt_provider and ui_state.opts.prompt_provider() or (ui_state.opts.prompt or "")
  local title_lines = title ~= "" and 1 or 0
  local max_height = math.max(config.max_height, title_lines + 1)
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 4)
  local height_limit = math.min(max_height, screen_height)
  local visible = math.max(height_limit - title_lines, 1)
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
  ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
  local max_width = math.max(math.min(config.width, vim.o.columns - 4), 20)
  local built = layout.build_lines(title, labels, {
    padding = config.padding,
    offset = ui_state.offset,
    max_items = visible,
    max_width = max_width,
  })
  local height = math.max(#built.lines, 1)
  local width = math.min(built.width, max_width)
  -- 画面中央のメニュー表示を更新する。
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, width, config.border, config.theme)
  window.update_window(win, height, width)
  window.set_lines(buf, built.lines)
  if title ~= "" then
  window.apply_highlights(buf, { { line = 1, group = "IdleDungeonMenuTitle" } })
  else
    window.apply_highlights(buf, nil)
  end
  if ui_state.selected > 0 then
    local line = built.items_start + (ui_state.selected - built.offset) - 1
    vim.api.nvim_win_set_cursor(win, { math.max(line, 1), 0 })
  end
  -- 選択中の項目に合わせて詳細ウィンドウを更新する。
  if ui_state.opts.detail_provider then
    local choice = #ui_state.items > 0 and ui_state.items[ui_state.selected] or nil
    local detail = ui_state.opts.detail_provider(choice)
    ui_state.detail = detail_window.render(ui_state.detail, win, config, detail)
  else
    ui_state.detail = detail_window.close(ui_state.detail)
  end
  ui_state.labels = labels
  ui_state.win = win
  ui_state.buf = buf
end

local function move(delta)
  local total = #ui_state.labels
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, total)
  render()
end

local function select_current()
  local total = #ui_state.items
  local choice = total > 0 and ui_state.items[ui_state.selected] or nil
  local callback = ui_state.on_choice
  if ui_state.opts.keep_open then
    -- 選択後もメニューを閉じずに連続操作できるようにする。
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

local function cancel()
  local callback = ui_state.on_choice
  close()
  if callback then
    callback(nil)
  end
end

local function set_keymaps(buf)
  -- メニュー操作用のキーマップをバッファローカルに設定する。
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "gg", function()
      ui_state.selected = clamp_selected(1, #ui_state.items)
      render()
    end },
    { "G", function()
      ui_state.selected = clamp_selected(#ui_state.items, #ui_state.items)
      render()
    end },
    { "<CR>", select_current },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
end

local function select(items, opts, on_choice, config)
  close()
  -- メニューの状態を初期化して表示する。
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.items = items or {}
  ui_state.opts = opts or {}
  ui_state.on_choice = on_choice
  ui_state.config = config or {}
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #ui_state.items)
  ui_state.offset = 0
  render()
  local buf = ui_state.buf
  if buf then
    set_keymaps(buf)
  end
end

M.select = select
M.close = close

return M
