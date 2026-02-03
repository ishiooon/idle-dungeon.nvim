-- このモジュールは階層ごとの遭遇状態を純粋関数で生成する。
-- 同じ階層配下のprogressを参照する。
local enemies = require("idle_dungeon.game.floor.enemies")
local events = require("idle_dungeon.game.floor.events")
local floor_progress = require("idle_dungeon.game.floor.progress")
local stage_progress = require("idle_dungeon.game.stage_progress")
local util = require("idle_dungeon.util")

local M = {}

-- ステージ内の階層番号を1始まりで返す。
local function resolve_stage_floor_number(progress, floor_length)
  local distance = floor_progress.stage_floor_distance(progress, floor_length)
  return math.max((distance or 0) + 1, 1)
end

-- ステージ全体の階層数を取得する。
local function resolve_stage_total_floors(progress, config, floor_length)
  local _, stage = stage_progress.find_stage_index((config or {}).stages or {}, progress)
  if not stage then
    return nil
  end
  return floor_progress.stage_total_floors(stage, floor_length)
end

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
  local stage_floor_number = resolve_stage_floor_number(progress, floor_length)
  local boss_every = progress.boss_every or config.boss_every or 0
  local total_floors = resolve_stage_total_floors(progress, config, floor_length)
  local is_last_floor = total_floors and stage_floor_number >= total_floors or false
  -- ボス出現は間隔と最終フロアのどちらでも有効にする。
  local boss_pending = false
  if boss_every > 0 and stage_floor_number % boss_every == 0 then
    boss_pending = true
  end
  if is_last_floor then
    boss_pending = true
  end
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
-- 遭遇開始位置は間合い分だけ手前に補正して返す。
local function find_enemy_in_path(progress, floor_length, start_distance, end_distance, encounter_gap)
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
  local gap = math.max(tonumber(encounter_gap) or 0, 0)
  for _, enemy in ipairs(progress.floor_enemies or {}) do
    if not enemy.defeated then
      local enemy_distance = resolve_enemy_distance(floor_start, enemy)
      local encounter_distance = math.max(enemy_distance - (gap + 1), floor_start)
      if encounter_distance >= base_distance and encounter_distance <= range_end then
        if not closest_distance or encounter_distance < closest_distance then
          closest = enemy
          closest_distance = encounter_distance
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
