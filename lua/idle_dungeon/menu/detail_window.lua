-- このモジュールはメニュー右側に詳細ウィンドウを表示する。

local util = require("idle_dungeon.util")
local window = require("idle_dungeon.menu.window")

local M = {}

local function resolve_number(value)
  if type(value) == "number" then
    return value
  end
  if type(value) == "table" and value[1] then
    return tonumber(value[1]) or 0
  end
  return tonumber(value) or 0
end

local function resolve_position(main_win, detail_width, gap)
  local config = vim.api.nvim_win_get_config(main_win)
  local row = math.max(resolve_number(config.row), 0)
  local col = math.max(resolve_number(config.col), 0)
  local width = math.max(tonumber(config.width) or 1, 1)
  local height = math.max(tonumber(config.height) or 1, 1)
  local screen_cols = vim.o.columns or 80
  local offset = math.max(gap or 0, 0) + 2
  local right_col = col + width + offset
  local left_col = col - detail_width - offset
  local target_col = right_col
  if right_col + detail_width > screen_cols and left_col >= 0 then
    target_col = left_col
  elseif right_col + detail_width > screen_cols then
    target_col = math.max(screen_cols - detail_width - 1, 0)
  end
  return row, target_col, height
end

local function build_lines(detail, width, padding)
  local pad = string.rep(" ", math.max(padding or 0, 0))
  local lines = {}
  local title = detail and detail.title or ""
  if title ~= "" then
    table.insert(lines, util.clamp_line(pad .. title, width))
    table.insert(lines, util.clamp_line(pad .. string.rep("-", math.max(width - #pad, 1)), width))
  end
  for _, line in ipairs((detail and detail.lines) or {}) do
    table.insert(lines, util.clamp_line(pad .. tostring(line), width))
  end
  return lines
end

local function render(detail_state, main_win, config, detail)
  if not main_win or not window.is_valid_window(main_win) then
    return { win = nil, buf = nil }
  end
  if not detail or not detail.lines or #detail.lines == 0 then
    if detail_state and detail_state.win then
      window.close_window(detail_state.win, nil)
    end
    return { win = nil, buf = nil }
  end
  local detail_width = math.max(config.detail_width or 36, 20)
  local detail_gap = config.detail_gap or 2
  local row, col, height = resolve_position(main_win, detail_width, detail_gap)
  local win, buf = window.ensure_window_at(
    detail_state and detail_state.win or nil,
    detail_state and detail_state.buf or nil,
    row,
    col,
    height,
    detail_width,
    config.border,
    config.theme,
    false
  )
  window.update_window_at(win, row, col, height, detail_width)
  local lines = build_lines(detail, detail_width, config.padding)
  while #lines < height do
    table.insert(lines, "")
  end
  if #lines > height then
    local trimmed = {}
    for index = 1, height do
      trimmed[index] = lines[index]
    end
    lines = trimmed
  end
  window.set_lines(buf, lines)
  local highlights = {}
  if detail.title and detail.title ~= "" then
    highlights[#highlights + 1] = { line = 1, group = "IdleDungeonMenuTitle" }
    highlights[#highlights + 1] = { line = 2, group = "IdleDungeonMenuDivider" }
  end
  window.apply_highlights(buf, highlights)
  return { win = win, buf = buf }
end

local function close(detail_state)
  if detail_state and detail_state.win then
    window.close_window(detail_state.win, nil)
  end
  return { win = nil, buf = nil }
end

M.render = render
M.close = close

return M
