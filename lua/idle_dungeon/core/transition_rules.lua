-- このモジュールは遷移判定に必要な条件計算を純粋関数として提供する。
-- 階層進行の参照先はgame/floorに統一する。
local content = require("idle_dungeon.content")
-- 階層進行の計算はgame/floor/progressに委譲して整理する。
local floor_progress = require("idle_dungeon.game.floor.progress")

local M = {}

local function find_event_by_distance(distance, progress)
  for _, event in ipairs(content.events) do
    if event.distance == distance and (not event.stage_id or event.stage_id == progress.stage_id) then
      return event
    end
  end
  return nil
end

local function is_event_distance(distance, progress, config)
  for _, value in ipairs(config.event_distances or {}) do
    if type(value) == "table" then
      if value.distance == distance and (not value.stage_id or value.stage_id == progress.stage_id) then
        return true
      end
    elseif value == distance then
      return true
    end
  end
  return false
end

local function is_boss_distance(distance, progress)
  for _, value in ipairs(progress.boss_milestones or {}) do
    if value == distance then
      return true
    end
  end
  return false
end

local function floor_encounters_enabled(config)
  local floor_encounters = config.floor_encounters or {}
  return floor_encounters.enabled ~= false
end

local function encounter_interval(total, floor_length)
  return math.max(1, math.floor(floor_length / (total + 1)))
end

local function should_start_floor_encounter(progress, config)
  if not floor_encounters_enabled(config) then
    return false
  end
  local remaining = progress.floor_encounters_remaining or 0
  local total = progress.floor_encounters_total or 0
  if remaining <= 0 or total <= 0 then
    return false
  end
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local step = floor_progress.floor_step(progress.distance or 0, floor_length)
  if step == 0 then
    return false
  end
  local interval = encounter_interval(total, floor_length)
  return step % interval == 0
end

local function should_start_boss(progress, config)
  local boss_every = progress.boss_every or config.boss_every
  if boss_every and boss_every > 0 then
    return progress.floor_boss_pending and (progress.floor_encounters_remaining or 0) <= 0
  end
  return is_boss_distance(progress.distance, progress)
end

M.find_event_by_distance = find_event_by_distance
M.is_event_distance = is_event_distance
M.should_start_floor_encounter = should_start_floor_encounter
M.should_start_boss = should_start_boss

return M
