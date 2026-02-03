-- このモジュールは階層ごとの遭遇状態を純粋関数で生成する。
-- 同じ階層配下のprogressを参照する。
local enemies = require("idle_dungeon.game.floor.enemies")
local events = require("idle_dungeon.game.floor.events")
local floor_progress = require("idle_dungeon.game.floor.progress")
local util = require("idle_dungeon.util")

local M = {}

local function build_floor_state(progress, config, floor_index)
  local floor_length = floor_progress.resolve_floor_length(config)
  -- 敵の配置生成は専用モジュールに委譲して読みやすさを保つ。
  local floor_enemies, next_seed = enemies.build_floor_enemies(progress, config, floor_length)
  local used = {}
  for _, enemy in ipairs(floor_enemies or {}) do
    if enemy.position then
      used[enemy.position] = true
    end
  end
  local floor_number = floor_index + 1
  local boss_every = progress.boss_every or config.boss_every or 0
  local boss_pending = boss_every > 0 and floor_number % boss_every == 0
  local next_progress = util.merge_tables(progress, { rng_seed = next_seed })
  local floor_event, final_seed = events.build_floor_event(next_progress, config, floor_length, used, boss_pending)
  local stored_event = floor_event or false
  return util.merge_tables(progress, {
    floor_index = floor_index,
    floor_enemies = floor_enemies,
    floor_encounters_total = #floor_enemies,
    floor_encounters_remaining = #floor_enemies,
    floor_boss_pending = boss_pending,
    floor_event = stored_event,
    rng_seed = final_seed,
  })
end

local function refresh(progress, config)
  local floor_length = floor_progress.resolve_floor_length(config)
  local current_index = floor_progress.floor_index(progress.distance or 0, floor_length)
  if progress.floor_index == current_index
    and progress.floor_enemies ~= nil
    and progress.floor_encounters_total ~= nil
    and progress.floor_encounters_remaining ~= nil
    and progress.floor_boss_pending ~= nil
    and progress.floor_event ~= nil then
    return progress
  end
  return build_floor_state(progress, config, current_index)
end

-- 敵の位置から距離を計算する。
local function resolve_enemy_distance(floor_start, enemy)
  return floor_start + math.max((enemy.position or 0) - 1, 0)
end

-- 移動範囲内の敵を検出し、最初に遭遇する敵を返す。
local function find_enemy_in_path(progress, floor_length, start_distance, end_distance)
  local base_distance = start_distance or (progress.distance or 0)
  local next_distance = end_distance or base_distance
  if next_distance <= base_distance then
    return nil, nil
  end
  local length = math.max(floor_length or 1, 1)
  local floor_index = progress.floor_index or floor_progress.floor_index(base_distance, length)
  local floor_start = floor_progress.floor_start_distance(floor_index, length)
  local floor_end = floor_start + math.max(length - 1, 0)
  local range_end = math.min(next_distance, floor_end)
  local closest = nil
  local closest_distance = nil
  for _, enemy in ipairs(progress.floor_enemies or {}) do
    if not enemy.defeated then
      local enemy_distance = resolve_enemy_distance(floor_start, enemy)
      if enemy_distance >= base_distance and enemy_distance <= range_end then
        if not closest_distance or enemy_distance < closest_distance then
          closest = enemy
          closest_distance = enemy_distance
        end
      end
    end
  end
  return closest, closest_distance
end

-- 階層内の隠しイベントを検出する。
local function resolve_event_distance(floor_start, event)
  return floor_start + math.max((event.position or 0) - 1, 0)
end

local function find_event_in_path(progress, floor_length, start_distance, end_distance)
  local event = progress.floor_event
  if not event or event == false or event.resolved then
    return nil, nil
  end
  local base_distance = start_distance or (progress.distance or 0)
  local next_distance = end_distance or base_distance
  if next_distance < base_distance then
    return nil, nil
  end
  local length = math.max(floor_length or 1, 1)
  local floor_index = progress.floor_index or floor_progress.floor_index(base_distance, length)
  local floor_start = floor_progress.floor_start_distance(floor_index, length)
  local floor_end = floor_start + math.max(length - 1, 0)
  local range_end = math.min(next_distance, floor_end)
  local event_distance = resolve_event_distance(floor_start, event)
  if event_distance >= base_distance and event_distance <= range_end then
    return event, event_distance
  end
  return nil, nil
end

local function mark_enemy_defeated(progress, enemy)
  if not enemy then
    return progress
  end
  local updated = {}
  local remaining = 0
  for _, entry in ipairs(progress.floor_enemies or {}) do
    if entry.position == enemy.position
      and entry.id == enemy.id
      and (entry.element or "normal") == (enemy.element or "normal") then
      table.insert(updated, util.merge_tables(entry, { defeated = true }))
    else
      table.insert(updated, entry)
    end
  end
  for _, entry in ipairs(updated) do
    if not entry.defeated then
      remaining = remaining + 1
    end
  end
  return util.merge_tables(progress, { floor_enemies = updated, floor_encounters_remaining = remaining })
end

local function clear_boss_pending(progress)
  if not progress.floor_boss_pending then
    return progress
  end
  return util.merge_tables(progress, { floor_boss_pending = false })
end

local function mark_event_resolved(progress)
  if not progress.floor_event or progress.floor_event == false then
    return progress
  end
  local updated = util.merge_tables(progress.floor_event, { resolved = true })
  return util.merge_tables(progress, { floor_event = updated })
end

M.refresh = refresh
M.find_enemy_in_path = find_enemy_in_path
M.find_event_in_path = find_event_in_path
M.mark_enemy_defeated = mark_enemy_defeated
M.clear_boss_pending = clear_boss_pending
M.mark_event_resolved = mark_event_resolved

return M
