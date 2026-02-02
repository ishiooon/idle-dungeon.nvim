-- このモジュールはステージ開始時のアスキーアート表示を担当する。

local menu_theme = require("idle_dungeon.menu.theme")
local render_event = require("idle_dungeon.ui.render_event")
local util = require("idle_dungeon.util")

local M = {}

local ui_state = { win = nil, buf = nil }
local INTRO_ZINDEX = 80

local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function resolve_language(state, config)
  return (state.ui and state.ui.language) or (config.ui or {}).language or "en"
end

local function resolve_lines(state, config)
  local event = render_event.find_event_by_id(state.ui and state.ui.event_id or nil)
  local lang = resolve_language(state, config)
  local art = render_event.resolve_event_art(event, lang)
  if type(art) == "table" and #art > 0 then
    return art
  end
  local title = render_event.resolve_event_title(event, lang)
  if title ~= "" then
    return { title }
  end
  return {}
end

local function calculate_center(height, width)
  local lines = vim.o.lines
  local columns = vim.o.columns
  local cmdheight = vim.o.cmdheight
  local row = math.max(math.floor((lines - cmdheight - height) / 2), 0)
  local col = math.max(math.floor((columns - width) / 2), 0)
  return row, col
end

local function ensure_highlights(config)
  local theme = menu_theme.resolve(config)
  if theme.inherit ~= false then
    -- 既存テーマ色を使うためリンク設定で揃える。
    vim.api.nvim_set_hl(0, "IdleDungeonIntroNormal", { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "IdleDungeonIntroBorder", { link = "FloatBorder" })
    return
  end
  vim.api.nvim_set_hl(0, "IdleDungeonIntroNormal", { fg = theme.text, bg = theme.background })
  vim.api.nvim_set_hl(0, "IdleDungeonIntroBorder", { fg = theme.border })
end

local function ensure_window(height, width, config)
  if is_valid_window(ui_state.win) and is_valid_buffer(ui_state.buf) then
    return ui_state.win, ui_state.buf
  end
  ensure_highlights(config)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  local row, col = calculate_center(height, width)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
    zindex = INTRO_ZINDEX,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:IdleDungeonIntroNormal,FloatBorder:IdleDungeonIntroBorder",
    { win = win }
  )
  ui_state.win = win
  ui_state.buf = buf
  return win, buf
end

local function build_lines(lines, width, padding)
  local pad = string.rep(" ", math.max(padding or 0, 0))
  local built = {}
  for _, line in ipairs(lines or {}) do
    table.insert(built, util.clamp_line(pad .. line, width))
  end
  return built
end

local function render(state, config)
  if not state.ui or state.ui.mode ~= "stage_intro" then
    return
  end
  local lines = resolve_lines(state, config)
  if #lines == 0 then
    close()
    return
  end
  local padding = 1
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, util.display_width(line))
  end
  local width = math.max(max_width + padding * 2, 10)
  local height = math.max(#lines, 1)
  local win, buf = ensure_window(height, width, config)
  local row, col = calculate_center(height, width)
  vim.api.nvim_win_set_config(win, { relative = "editor", row = row, col = col, width = width, height = height, zindex = INTRO_ZINDEX })
  local built = build_lines(lines, width, padding)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, built)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function close()
  if is_valid_window(ui_state.win) then
    -- 表示を終了するためにウィンドウを閉じる。
    vim.api.nvim_win_close(ui_state.win, true)
  end
  ui_state.win = nil
  ui_state.buf = nil
end

M.render = render
M.close = close

return M
