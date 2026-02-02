-- このモジュールは遷移判定に必要な条件計算を純粋関数として提供する。
local content = require("idle_dungeon.content")

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

local function should_start_boss(progress, config)
  local boss_every = progress.boss_every or config.boss_every
  if boss_every and boss_every > 0 then
    return progress.floor_boss_pending and (progress.floor_encounters_remaining or 0) <= 0
  end
  return is_boss_distance(progress.distance, progress)
end

M.find_event_by_distance = find_event_by_distance
M.is_event_distance = is_event_distance
M.should_start_boss = should_start_boss

return M
