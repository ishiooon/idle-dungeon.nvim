-- このモジュールはNeovimの右下に表示するための処理を担当する。
-- 描画関連の参照先はui配下に統一する。
local image_sprites = require("idle_dungeon.ui.image_sprites")
local render = require("idle_dungeon.ui.render")
local sprite_highlight = require("idle_dungeon.ui.sprite_highlight")

local M = {}

local ui_state = { buf = nil, win = nil, on_click = nil }
local highlight_ns = vim.api.nvim_create_namespace("IdleDungeonSprites")

local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function calculate_position(height, width)
  local lines = vim.o.lines
  local columns = vim.o.columns
  local cmdheight = vim.o.cmdheight
  local row = math.max(lines - height - cmdheight - 1, 0)
  local col = math.max(columns - width - 1, 0)
  return row, col
end

local function clamp_lines(lines, max_height)
  if #lines <= max_height then
    return lines
  end
  -- 表示行数を上限に合わせて切り詰める。
  local trimmed = {}
  for index = 1, max_height do
    trimmed[index] = lines[index]
  end
  return trimmed
end

local function ensure_window(height, width)
  if is_valid_window(ui_state.win) and is_valid_buffer(ui_state.buf) then
    return ui_state.win, ui_state.buf
  end
  -- 画面の右下に表示するための浮動ウィンドウを作成する。
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  local row, col = calculate_position(height, width)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    focusable = false,
    noautocmd = true,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", false, { win = win })
  ui_state.buf = buf
  ui_state.win = win
  if ui_state.on_click then
    -- 左クリックでメニューを開くためのバッファローカルマッピングを設定する。
    vim.keymap.set("n", "<LeftMouse>", function()
      ui_state.on_click()
    end, { buffer = buf, silent = true, nowait = true })
  end
  return win, buf
end

local function render_ui(state, config)
  local max_height = math.min((config.ui or {}).max_height or 2, 2)
  local preferred_height = (config.ui or {}).height or max_height
  -- 表示行数は設定の希望値を優先し、最大2行までに制限する。
  local height_limit = math.min(preferred_height, max_height)
  local lines = clamp_lines(render.build_lines(state, config), height_limit)
  -- 表示行数は最大2行までに制限する。
  local height = math.max(math.min(#lines, height_limit), 1)
  local width = (config.ui or {}).width or 36
  local win, buf = ensure_window(height, width)
  local row, col = calculate_position(height, width)
  -- ウィンドウの位置を更新して右下を保つ。
  vim.api.nvim_win_set_config(win, { relative = "editor", row = row, col = col, width = width, height = height })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  -- ハイライトと画像スプライトの描画を更新する。
  local highlights = sprite_highlight.build(state, config, lines)
  sprite_highlight.apply(buf, highlight_ns, highlights, config)
  image_sprites.render(state, config, buf)
end

local function close()
  if is_valid_window(ui_state.win) then
    -- 表示を終了するためにウィンドウを閉じる。
    image_sprites.clear(ui_state.buf)
    vim.api.nvim_win_close(ui_state.win, true)
  end
  ui_state.win = nil
  ui_state.buf = nil
end

local function set_on_click(callback)
  ui_state.on_click = callback
  if is_valid_buffer(ui_state.buf) and callback then
    -- 既存の表示がある場合はクリック用マッピングを再設定する。
    vim.keymap.set("n", "<LeftMouse>", function()
      ui_state.on_click()
    end, { buffer = ui_state.buf, silent = true, nowait = true })
  end
end

M.render = render_ui
M.close = close
M.set_on_click = set_on_click

return M
