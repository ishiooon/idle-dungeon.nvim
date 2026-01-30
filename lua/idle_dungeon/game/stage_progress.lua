-- このモジュールはステージ進行の判定と更新を純粋関数で提供する。
-- 階層進行の参照先はgame/floorにまとめる。
local floor_progress = require("idle_dungeon.game.floor.progress")
local util = require("idle_dungeon.util")

local M = {}

local function find_stage_index(stages, progress)
  for index, stage in ipairs(stages or {}) do
    if stage.id == progress.stage_id or stage.name == progress.stage_name then
      return index, stage
    end
  end
  return nil, nil
end

local function stage_length(stage, config)
  -- 階層の横幅を基準にステージの歩数を換算する。
  local floor_length = floor_progress.resolve_floor_length(config or {})
  return floor_progress.stage_length_steps(stage, floor_length)
end

local function should_advance(progress, stage, config)
  local length = stage_length(stage, config)
  if not length or stage.infinite then
    return false
  end
  local start = progress.stage_start or 0
  return (progress.distance or 0) >= (start + length)
end

local function apply_stage(progress, stage, config)
  local start = stage.start or 0
  local boss_every = stage.boss_every or (config or {}).boss_every
  return util.merge_tables(progress, {
    stage_id = stage.id,
    stage_name = stage.name,
    distance = start,
    stage_start = start,
    stage_infinite = stage.infinite or false,
    boss_every = boss_every,
    boss_milestones = stage.boss_milestones or {},
  })
end

local function advance_if_needed(progress, config)
  local stages = config.stages or {}
  local index, stage = find_stage_index(stages, progress)
  if not stage or not index then
    return progress, false
  end
  if not should_advance(progress, stage, config) then
    return progress, false
  end
  local next_stage = stages[index + 1]
  if not next_stage then
    return progress, false
  end
  -- ステージ終端に達した場合は次のステージへ進む。
  return apply_stage(progress, next_stage, config), true
end

M.find_stage_index = find_stage_index
M.stage_length = stage_length
M.advance_if_needed = advance_if_needed

return M
