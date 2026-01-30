-- このモジュールは階層進行に関する計算を純粋関数で提供する。

local M = {}

local function resolve_floor_length(config)
  local ui_length = (config.ui or {}).track_length
  local value = tonumber(config.floor_length or ui_length or 18) or 18
  return math.max(1, math.floor(value))
end

local function floor_index(distance, floor_length)
  local length = math.max(floor_length or 1, 1)
  return math.floor((distance or 0) / length)
end

local function floor_step(distance, floor_length)
  local length = math.max(floor_length or 1, 1)
  local step = (distance or 0) % length
  if step < 0 then
    step = step + length
  end
  return step
end

local function floor_start_distance(index, floor_length)
  local length = math.max(floor_length or 1, 1)
  return math.max(0, math.floor(index or 0)) * length
end

local function stage_start_floor(progress, floor_length)
  return floor_index(progress.stage_start or 0, floor_length)
end

local function stage_floor_distance(progress, floor_length)
  return floor_index(progress.distance or 0, floor_length) - stage_start_floor(progress, floor_length)
end

local function stage_total_floors(stage, floor_length)
  if stage and stage.floors then
    return stage.floors
  end
  if stage and stage.length then
    return math.max(1, math.ceil(stage.length / math.max(floor_length, 1)))
  end
  return nil
end

local function stage_length_steps(stage, floor_length)
  if stage and stage.floors then
    return stage.floors * math.max(floor_length, 1)
  end
  if stage and stage.length then
    return stage.length
  end
  return nil
end

M.resolve_floor_length = resolve_floor_length
M.floor_index = floor_index
M.floor_step = floor_step
M.floor_start_distance = floor_start_distance
M.stage_start_floor = stage_start_floor
M.stage_floor_distance = stage_floor_distance
M.stage_total_floors = stage_total_floors
M.stage_length_steps = stage_length_steps

return M
