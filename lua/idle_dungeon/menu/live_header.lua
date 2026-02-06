-- このモジュールはメニュー上部に表示するライブトラックを生成する。

local render = require("idle_dungeon.ui.render")
local util = require("idle_dungeon.util")

local M = {}

local function force_visual_state(state)
  local ui = util.merge_tables(state.ui or {}, { render_mode = "visual" })
  return util.merge_tables(state, { ui = ui })
end

local function build_lines(state, config, _lang)
  if not state then
    return {}
  end
  local visual_state = force_visual_state(state)
  local rendered = render.build_lines(visual_state, config)
  return {
    rendered[1] or "",
    rendered[2] or "",
  }
end

M.build_lines = build_lines

return M
