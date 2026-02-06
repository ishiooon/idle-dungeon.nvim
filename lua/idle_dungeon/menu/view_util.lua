-- このモジュールはメニュー表示の共通計算をまとめる純粋関数を提供する。
-- レイアウト計算はmenu/layoutへ統一する。
local layout = require("idle_dungeon.menu.layout")
local theme = require("idle_dungeon.menu.theme")
local util = require("idle_dungeon.util")
local M = {}

-- テスト環境でも安全に使えるよう画面行数の既定値を用意する。
local function safe_lines()
  if _G.vim and vim.o and vim.o.lines then
    return vim.o.lines
  end
  return 40
end

-- テスト環境でも安全に使えるよう画面列数の既定値を用意する。
local function safe_columns()
  if _G.vim and vim.o and vim.o.columns then
    return vim.o.columns
  end
  return 120
end

-- コマンドライン高さの取得も安全にフォールバックさせる。
local function safe_cmdheight()
  if _G.vim and vim.o and vim.o.cmdheight then
    return vim.o.cmdheight
  end
  return 1
end

-- 数値の範囲を安全に丸めて無効値を防ぐ。
local function clamp_number(value, min_value, max_value)
  local safe = tonumber(value) or 0
  local min_v = tonumber(min_value) or 0
  local max_v = max_value ~= nil and tonumber(max_value) or nil
  if safe < min_v then
    safe = min_v
  end
  if max_v and safe > max_v then
    safe = max_v
  end
  return safe
end

-- 比率指定と固定値の両方を受け取り、画面サイズ内へ収める。
local function resolve_dimension(value, ratio, min_value, max_value, screen_value)
  local base = tonumber(value)
  if not base then
    local safe_ratio = tonumber(ratio) or 0.7
    base = math.floor(math.max(screen_value or 0, 0) * safe_ratio)
  end
  local clamped = clamp_number(base, min_value, max_value)
  if screen_value ~= nil then
    clamped = math.min(clamped, math.max(screen_value, 0))
  end
  return clamped
end

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
  -- 画面サイズに応じた大きめのメニュー寸法を算出する。
  local screen_width = math.max(safe_columns() - 4, 20)
  local screen_height = math.max(safe_lines() - safe_cmdheight() - 4, 10)
  local width = resolve_dimension(menu.width, menu.width_ratio or 0.62, menu.min_width or 64, menu.max_width, screen_width)
  local height = resolve_dimension(menu.height, menu.height_ratio or 0.6, menu.min_height or 20, menu.max_height, screen_height)
  local min_width = clamp_number(menu.min_width or 64, 20, screen_width)
  local min_height = clamp_number(menu.min_height or 20, 10, screen_height)
  local max_width = clamp_number(menu.max_width or width, min_width, screen_width)
  local max_height = clamp_number(menu.max_height or height, min_height, screen_height)
  return {
    width = width,
    height = height,
    min_width = min_width,
    max_width = max_width,
    min_height = min_height,
    max_height = max_height,
    padding = menu.padding or 2,
    border = menu.border or "rounded",
    tabs_position = menu.tabs_position or "top",
    tabs_style = menu.tabs or {},
    item_prefix = menu.item_prefix or "≫ ",
    section_prefix = menu.section_prefix or "◆ ",
    empty_prefix = menu.empty_prefix or "  · ",
    theme = theme.resolve(config),
  }
end

-- 指定行の表示幅の最大値を返す。
local function max_line_width(lines)
  local width = 0
  for _, line in ipairs(lines or {}) do
    width = math.max(width, util.display_width(line or ""))
  end
  return width
end

-- ライブヘッダーとタブの幅を基準に、過不足の少ないメニュー幅を求める。
local function resolve_compact_width(config, top_lines, tabs_line)
  local min_width = tonumber(config.min_width) or 64
  local max_width = tonumber(config.max_width) or tonumber(config.width) or min_width
  local base_width = tonumber(config.width) or max_width
  local top_width = max_line_width(top_lines)
  local tabs_width = util.display_width(tabs_line or "")
  local target = math.max(top_width, tabs_width) + 6
  local clamped = clamp_number(target, min_width, max_width)
  return math.min(clamped, base_width)
end

-- 行数に応じて高さを詰め、下方向の空白を減らす。
local function resolve_compact_height(config, screen_height, visible_rows, top_lines, has_tabs)
  local min_height = tonumber(config.min_height) or 16
  local max_height = tonumber(config.max_height) or tonumber(config.height) or min_height
  local top_count = #(top_lines or {})
  local fixed = 5 + top_count + (top_count > 0 and 1 or 0) + (has_tabs and 1 or 0)
  local body = clamp_number(visible_rows or 0, 6, 14)
  local target = fixed + body
  local clamped = clamp_number(target, min_height, max_height)
  return math.min(clamped, math.max(screen_height or clamped, min_height))
end

-- 選択リストの行を共通形式で生成する。
local function build_select_lines(options)
  local opts = options or {}
  local labels = opts.labels or {}
  local items = opts.items or {}
  local selected = opts.selected or 0
  local offset = opts.offset or 0
  local visible = math.max(opts.visible or #labels, 0)
  local prefix = opts.prefix or "≫ "
  local blank_prefix = string.rep(" ", util.display_width(prefix))
  local non_select_prefix = opts.non_select_prefix or "  "
  local is_selectable = opts.is_selectable or function()
    return true
  end
  local render_line = opts.render_line or function(label, _, mark)
    return mark .. (label or "")
  end
  local lines = {}
  local selected_row = nil
  for index = 1, visible do
    local absolute = offset + index
    local label = labels[absolute] or ""
    local item = items[absolute]
    local selectable = is_selectable(item)
    local current = absolute == selected
    local mark = current and prefix or blank_prefix
    if not selectable then
      mark = non_select_prefix
    end
    lines[index] = render_line(label, item, mark, current, selectable, absolute)
    if current then
      selected_row = index
    end
  end
  return lines, selected_row
end

M.clamp_selected = clamp_selected
M.adjust_offset = adjust_offset
M.menu_config = menu_config
M.max_line_width = max_line_width
M.resolve_compact_width = resolve_compact_width
M.resolve_compact_height = resolve_compact_height
M.build_select_lines = build_select_lines

return M
