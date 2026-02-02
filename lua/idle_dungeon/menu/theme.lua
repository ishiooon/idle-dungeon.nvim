-- このモジュールはメニュー配色の既定値と解決処理を純粋関数で提供する。

local util = require("idle_dungeon.util")

local M = {}

local function default_theme()
  return {
    -- 既定はテーマ色へ寄せるため、色指定は最小限に留める。
    inherit = true,
    accent = nil,
    title = nil,
    text = nil,
    muted = nil,
    border = nil,
    divider = nil,
    background = nil,
    selected_bg = nil,
    selected_fg = nil,
  }
end

local function resolve(config)
  local menu = ((config or {}).ui or {}).menu or {}
  local theme = menu.theme or {}
  return util.merge_tables(default_theme(), theme)
end

M.default_theme = default_theme
M.resolve = resolve

return M
