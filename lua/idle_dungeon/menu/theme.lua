-- このモジュールはメニュー配色の既定値と解決処理を純粋関数で提供する。

local util = require("idle_dungeon.util")

local M = {}

local function default_theme()
  return {
    -- 既定配色はgruvbox-material系の落ち着いたコントラストに寄せる。
    inherit = true,
    accent = "#7daea3",
    title = "#d8a657",
    text = "#e2cca9",
    muted = "#928374",
    border = "#3c3836",
    divider = "#504945",
    background = "#202324",
    selected_bg = "#32363a",
    selected_bg_alt = "#40464b",
    selected_fg = "#f5e6c8",
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
