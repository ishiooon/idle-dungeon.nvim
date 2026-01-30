-- このモジュールは階層ごとの遭遇状態を純粋関数で生成する。
-- 同じ階層配下のprogressを参照する。
local floor_progress = require("idle_dungeon.game.floor.progress")
local rng = require("idle_dungeon.rng")
local util = require("idle_dungeon.util")

local M = {}

local function resolve_encounter_range(config, floor_length)
  local floor_encounters = config.floor_encounters or {}
  if floor_encounters.enabled == false then
    return 0, 0
  end
  local min_value = tonumber(floor_encounters.min) or 1
  local max_value = tonumber(floor_encounters.max) or 5
  if min_value < 0 then
    min_value = 0
  end
  if max_value < min_value then
    max_value = min_value
  end
  local max_allowed = math.max(floor_length - 1, 0)
  min_value = math.min(min_value, max_allowed)
  max_value = math.min(max_value, max_allowed)
  return min_value, max_value
end

local function build_floor_state(progress, config, floor_index)
  local floor_length = floor_progress.resolve_floor_length(config)
  local min_value, max_value = resolve_encounter_range(config, floor_length)
  local seed = progress.rng_seed or 1
  local encounters, next_seed = rng.next_int(seed, min_value, max_value)
  local floor_number = floor_index + 1
  local boss_every = progress.boss_every or config.boss_every or 0
  local boss_pending = boss_every > 0 and floor_number % boss_every == 0
  return util.merge_tables(progress, {
    floor_index = floor_index,
    floor_encounters_total = encounters,
    floor_encounters_remaining = encounters,
    floor_boss_pending = boss_pending,
    rng_seed = next_seed,
  })
end

local function refresh(progress, config)
  local floor_length = floor_progress.resolve_floor_length(config)
  local current_index = floor_progress.floor_index(progress.distance or 0, floor_length)
  if progress.floor_index == current_index
    and progress.floor_encounters_total ~= nil
    and progress.floor_encounters_remaining ~= nil
    and progress.floor_boss_pending ~= nil then
    return progress
  end
  return build_floor_state(progress, config, current_index)
end

local function consume_encounter(progress)
  local remaining = math.max((progress.floor_encounters_remaining or 0) - 1, 0)
  return util.merge_tables(progress, { floor_encounters_remaining = remaining })
end

local function clear_boss_pending(progress)
  if not progress.floor_boss_pending then
    return progress
  end
  return util.merge_tables(progress, { floor_boss_pending = false })
end

M.refresh = refresh
M.consume_encounter = consume_encounter
M.clear_boss_pending = clear_boss_pending

return M
