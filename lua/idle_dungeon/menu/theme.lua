-- このモジュールはメニュー配色の既定値と解決処理を純粋関数で提供する。

local util = require("idle_dungeon.util")

local M = {}

local function default_theme()
  return {
    -- 既定配色はgruvbox-material系の落ち着いたコントラストに寄せる。
    inherit = true,
    accent = "#a9b665",
    title = "#d8a657",
    text = "#d4be98",
    muted = "#928374",
    border = "#665c54",
    divider = "#504945",
    background = "#282828",
    selected_bg = "#3c3836",
    selected_fg = "#fbf1c7",
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
