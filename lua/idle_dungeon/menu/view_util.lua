-- このモジュールはメニュー表示の共通計算をまとめる純粋関数を提供する。
-- レイアウト計算はmenu/layoutへ統一する。
local layout = require("idle_dungeon.menu.layout")
local theme = require("idle_dungeon.menu.theme")
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
  local width = resolve_dimension(menu.width, menu.width_ratio or 0.72, menu.min_width or 72, menu.max_width, screen_width)
  local height = resolve_dimension(menu.height, menu.height_ratio or 0.75, menu.min_height or 24, menu.max_height, screen_height)
  -- 詳細表示は右側に開くため、メニュー幅とは別に算出する。
  local detail_width = resolve_dimension(menu.detail_width, menu.detail_width_ratio or 0.3, menu.detail_min_width or 28, menu.detail_max_width, screen_width)
  local detail_gap = clamp_number(menu.detail_gap or 2, 0, 10)
  return {
    width = width,
    height = height,
    max_height = menu.max_height or height,
    padding = menu.padding or 2,
    border = menu.border or "rounded",
    tabs_position = menu.tabs_position or "top",
    tabs_style = menu.tabs or {},
    item_prefix = menu.item_prefix or "  • ",
    section_prefix = menu.section_prefix or "◆ ",
    empty_prefix = menu.empty_prefix or "  · ",
    theme = theme.resolve(config),
    detail_width = detail_width,
    detail_gap = detail_gap,
  }
end

M.clamp_selected = clamp_selected
M.adjust_offset = adjust_offset
M.menu_config = menu_config

return M
