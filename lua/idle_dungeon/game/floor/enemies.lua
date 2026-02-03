-- このモジュールは階層内の敵配置を純粋関数で生成する。
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local rng = require("idle_dungeon.rng")

local M = {}

-- 最初の階層だけは固定の敵を最初に配置する。
local function should_force_first_enemy(progress, config)
  local safe_progress = progress or {}
  local distance = safe_progress.distance or 0
  local stage_start = safe_progress.stage_start or 0
  if distance ~= stage_start then
    return false
  end
  local stages = (config or {}).stages or {}
  if #stages == 0 then
    return true
  end
  local first_stage = stages[1]
  if not first_stage or first_stage.id == nil then
    return true
  end
  return safe_progress.stage_id == first_stage.id
end

-- 最初の敵を差し替える場合は属性が定義内にあるか確認する。
local function normalize_first_enemy_element(element_id, enemy_data)
  local list = (enemy_data and enemy_data.elements) or {}
  if #list == 0 then
    return element_id or "normal"
  end
  for _, value in ipairs(list) do
    if value == element_id then
      return element_id
    end
  end
  return list[1]
end

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

local function resolve_position_range(config, floor_length)
  local max_pos = math.max(floor_length - 1, 1)
  local encounter_gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
  -- 戦闘開始時に2マスの間合いが確保できるよう初期配置を調整する。
  local min_pos = math.min(encounter_gap + 2, max_pos)
  if max_pos < min_pos then
    return max_pos, max_pos
  end
  return min_pos, max_pos
end

local function pick_unique_position(seed, used, min_pos, max_pos)
  if max_pos < min_pos then
    return min_pos, seed
  end
  local attempts = math.max((max_pos - min_pos + 1) * 2, 1)
  local next_seed = seed
  for _ = 1, attempts do
    local pos
    pos, next_seed = rng.next_int(next_seed, min_pos, max_pos)
    if not used[pos] then
      used[pos] = true
      return pos, next_seed
    end
  end
  for pos = min_pos, max_pos do
    if not used[pos] then
      used[pos] = true
      return pos, next_seed
    end
  end
  return min_pos, next_seed
end

local function build_floor_enemies(progress, config, floor_length)
  local min_value, max_value = resolve_encounter_range(config, floor_length)
  local seed = progress.rng_seed or 1
  local total, next_seed = rng.next_int(seed, min_value, max_value)
  local enemies = {}
  local used = {}
  local min_pos, max_pos = resolve_position_range(config, floor_length)
  for _ = 1, total do
    local pos
    pos, next_seed = pick_unique_position(next_seed, used, min_pos, max_pos)
    local enemy_id
    enemy_id, next_seed = enemy_catalog.pick_enemy_id(next_seed, progress, config)
    local enemy_data = enemy_catalog.find_enemy(enemy_id)
    local element_id
    element_id, next_seed = enemy_catalog.pick_element(enemy_data, next_seed, config)
    table.insert(enemies, {
      id = enemy_id,
      element = element_id,
      position = pos,
      defeated = false,
    })
  end
  table.sort(enemies, function(a, b)
    return a.position < b.position
  end)
  if total > 0 and should_force_first_enemy(progress, config) then
    local first = enemies[1]
    local forced = enemy_catalog.find_enemy("dust_slime")
    if first and forced then
      local element_id = normalize_first_enemy_element(first.element, forced)
      -- 先頭の敵のみIDを差し替えて最初の遭遇を固定する。
      enemies[1] = {
        id = forced.id or "dust_slime",
        element = element_id,
        position = first.position,
        defeated = first.defeated,
      }
    end
  end
  return enemies, next_seed
end

M.build_floor_enemies = build_floor_enemies

return M
