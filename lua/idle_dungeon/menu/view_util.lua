-- このモジュールはメニュー表示の共通計算をまとめる純粋関数を提供する。
-- レイアウト計算はmenu/layoutへ統一する。
local layout = require("idle_dungeon.menu.layout")
local util = require("idle_dungeon.util")
local M = {}

local function clamp_selected(selected, total)
  if total <= 0 then
    return 0
  end
  return math.min(math.max(selected, 1), total)
end

local function adjust_offset(selected, offset, visible, total)
  if total <= visible then
    return 0
  end
  local next_offset = offset
  if selected < next_offset + 1 then
    next_offset = selected - 1
  elseif selected > next_offset + visible then
    next_offset = selected - visible
  end
  return layout.normalize_offset(next_offset, total, visible)
end

local function menu_config(config)
  local ui = (config or {}).ui or {}
  local menu = ui.menu or {}
  return {
    width = menu.width or 72,
    max_height = menu.max_height or 22,
    padding = menu.padding or 1,
    border = menu.border or "single",
    tabs_position = menu.tabs_position or "top",
  }
end

local function build_tabs_sections(opts, config, tabs_line, built, max_width)
  local padding = math.max(config.padding or 0, 0)
  local pad = string.rep(" ", padding)
  local title = (opts or {}).title or ""
  local title_line = title ~= "" and util.clamp_line(pad .. title, max_width) or nil
  local tabs_text = util.clamp_line(pad .. tabs_line, max_width)
  local width = math.max(built.width, #tabs_text, title_line and #title_line or 0, 1)
  local divider = pad .. string.rep("-", math.max(width - padding, 1))
  local divider_line = util.clamp_line(divider, max_width)
  local header_lines, footer_lines = {}, {}
  if config.tabs_position == "bottom" then
    if title_line then table.insert(header_lines, title_line) end
    table.insert(header_lines, divider_line)
    table.insert(footer_lines, divider_line)
    table.insert(footer_lines, tabs_text)
  else
    if title_line then table.insert(header_lines, title_line) end
    table.insert(header_lines, tabs_text)
    table.insert(header_lines, divider_line)
  end
  return { header_lines = header_lines, footer_lines = footer_lines, width = width }
end

M.clamp_selected = clamp_selected
M.adjust_offset = adjust_offset
M.menu_config = menu_config
M.build_tabs_sections = build_tabs_sections

return M
