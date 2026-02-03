-- このモジュールは階層内の隠しイベント配置を純粋関数で生成する。

local event_catalog = require("idle_dungeon.game.event_catalog")
local rng = require("idle_dungeon.rng")

local M = {}

local function resolve_settings(config)
  return (config and config.floor_events) or {}
end

local function should_spawn_event(seed, floor_number, settings, boss_pending)
  if settings.enabled == false then
    return false, seed
  end
  if boss_pending then
    return false, seed
  end
  local min_floor = tonumber(settings.min_floor) or 1
  if floor_number < min_floor then
    return false, seed
  end
  local chance = tonumber(settings.chance) or 0
  if chance <= 0 then
    return false, seed
  end
  local roll, next_seed = rng.next_int(seed or 1, 1, 100)
  return roll <= chance, next_seed
end

local function resolve_position_range(floor_length)
  local max_pos = math.max(floor_length - 1, 1)
  local min_pos = math.min(2, max_pos)
  if max_pos < min_pos then
    return max_pos, max_pos
  end
  return min_pos, max_pos
end

local function pick_position(seed, used_positions, floor_length)
  local min_pos, max_pos = resolve_position_range(floor_length)
  local next_seed = seed or 1
  local attempts = math.max((max_pos - min_pos + 1) * 2, 1)
  for _ = 1, attempts do
    local pos
    pos, next_seed = rng.next_int(next_seed, min_pos, max_pos)
    if not used_positions[pos] then
      return pos, next_seed
    end
  end
  for pos = min_pos, max_pos do
    if not used_positions[pos] then
      return pos, next_seed
    end
  end
  return min_pos, next_seed
end

-- 階層内の隠しイベントを生成する。
local function build_floor_event(progress, config, floor_length, used_positions, boss_pending)
  local settings = resolve_settings(config)
  local seed = progress.rng_seed or 1
  local floor_number = (progress.floor_index or 0) + 1
  local spawn, next_seed = should_spawn_event(seed, floor_number, settings, boss_pending)
  if not spawn then
    return nil, next_seed
  end
  local event
  event, next_seed = event_catalog.pick_event(next_seed, progress)
  if not event then
    return nil, next_seed
  end
  local pos
  pos, next_seed = pick_position(next_seed, used_positions or {}, floor_length)
  return { id = event.id, position = pos, resolved = false }, next_seed
end

M.build_floor_event = build_floor_event

return M
