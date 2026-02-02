-- このモジュールはストーリー表示の制御を純粋関数で提供する。
local content = require("idle_dungeon.content")
local util = require("idle_dungeon.util")

local M = {}

local function find_stage_intro(stage_id)
  for _, intro in ipairs(content.stage_intros or {}) do
    if intro.stage_id == stage_id then
      return intro
    end
  end
  return nil
end

local function apply_stage_intro(state, progress)
  local safe_progress = progress or {}
  if safe_progress.distance ~= safe_progress.stage_start then
    return state, nil
  end
  local stage_id = safe_progress.stage_id
  if not stage_id then
    return state, nil
  end
  local story = state.story or {}
  local seen = story.stage_intro or {}
  if seen[stage_id] then
    return state, nil
  end
  local intro = find_stage_intro(stage_id)
  if not intro then
    return state, nil
  end
  local next_seen = util.merge_tables(seen, { [stage_id] = true })
  local next_story = util.merge_tables(story, { stage_intro = next_seen })
  local next_state = util.merge_tables(state, { story = next_story })
  return next_state, intro.id
end

M.apply_stage_intro = apply_stage_intro

return M
