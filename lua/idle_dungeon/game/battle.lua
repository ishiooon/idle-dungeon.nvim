-- このモジュールは戦闘時の敵生成とダメージ計算を提供する。
-- 階層計算はgame/floor/progressに委譲して整理する。
local content = require("idle_dungeon.content")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local element = require("idle_dungeon.game.element")
local floor_progress = require("idle_dungeon.game.floor.progress")
local rng = require("idle_dungeon.rng")

local M = {}

-- 設定のIDから図鑑用の表示名を解決する。
local function resolve_enemy_name(enemy_id)
  local enemy = enemy_catalog.find_enemy(enemy_id)
  if enemy then
    return enemy.name_en or enemy.name_ja or enemy.id
  end
  return enemy_id
end

-- 敵IDを距離と指定情報から決める。
local function resolve_enemy_id(distance, names, enemy_spec)
  if enemy_spec and enemy_spec.id then
    return enemy_spec.id
  end
  local list = names or { "enemy" }
  local index = (distance % #list) + 1
  return list[index]
end

-- 敵の属性タイプを指定情報から決める。
local function resolve_enemy_element(enemy_spec)
  if enemy_spec and enemy_spec.element then
    return enemy_spec.element
  end
  return "normal"
end

-- 距離から現在のステージとインデックスを解決する。
local function resolve_stage_context(distance, config)
  local stages = (config or {}).stages or {}
  local floor_length = floor_progress.resolve_floor_length(config or {})
  if #stages == 0 then
    return nil, 1, floor_length
  end
  local cursor = tonumber(distance) or 0
  local fallback = stages[#stages]
  local fallback_index = #stages
  for index, stage in ipairs(stages) do
    local start = stage.start or 0
    local length = floor_progress.stage_length_steps(stage, floor_length)
    local finish = length and (start + length) or nil
    if stage.infinite then
      finish = nil
    end
    if cursor >= start and (not finish or cursor < finish) then
      return stage, index, floor_length
    end
  end
  return fallback, fallback_index, floor_length
end

-- 敵の成長レベルを計算する。
local function resolve_growth_level(distance, config, is_boss)
  local stage, stage_index, floor_length = resolve_stage_context(distance, config)
  local battle_config = (config or {}).battle or {}
  local base = battle_config.growth_base or 1
  local floor_growth = battle_config.growth_floor or 2
  local stage_growth = battle_config.growth_stage or 12
  local stage_start = stage and stage.start or 0
  local stage_floor = floor_progress.floor_index((distance or 0) - stage_start, floor_length)
  local level = base + math.max(stage_floor, 0) * floor_growth + math.max((stage_index or 1) - 1, 0) * stage_growth
  local boss_multiplier = battle_config.growth_boss_multiplier or 1.5
  if is_boss then
    level = math.floor(level * boss_multiplier + 0.5)
  end
  return math.max(level, 1)
end

-- 敵のステータスを距離と設定から構築する。
local function build_enemy(distance, config, enemy_spec)
  local names = (config or {}).enemy_names or { "enemy" }
  local enemy_id = resolve_enemy_id(distance or 0, names, enemy_spec)
  local enemy_data = enemy_catalog.find_enemy(enemy_id) or {}
  local is_boss = enemy_spec and enemy_spec.is_boss or false
  -- ステージとフロアの進行度で成長を計算する。
  local growth = resolve_growth_level(distance or 0, config, is_boss)
  local battle = config.battle or { enemy_hp = 5, enemy_atk = 1 }
  local stats = enemy_data.stats or {}
  local base_hp = stats.hp or battle.enemy_hp
  local base_atk = stats.atk or battle.enemy_atk
  local base_def = stats.def or 0
  -- 敵の攻撃速度は定義値を優先し、無い場合は既定値を使う。
  local base_speed = stats.speed or battle.enemy_speed or 2
  local growth_hp = battle.growth_hp or 2
  local growth_atk = battle.growth_atk or 1
  local growth_def = battle.growth_def or 0.5
  local scaled_hp = base_hp + math.max(0, math.floor(growth * growth_hp))
  local scaled_atk = base_atk + math.max(0, math.floor(growth * growth_atk))
  local scaled_def = base_def + math.max(0, math.floor(growth * growth_def))
  return {
    id = enemy_id,
    name = resolve_enemy_name(enemy_id),
    element = resolve_enemy_element(enemy_spec),
    hp = scaled_hp,
    -- 最大体力を保持して表示に使う。
    max_hp = scaled_hp,
    atk = scaled_atk,
    def = scaled_def,
    accuracy = stats.accuracy,
    speed = math.max(tonumber(base_speed) or 1, 1),
    is_boss = is_boss,
    level = growth,
    -- 敵固有の戦利品候補を保持してドロップ抽選に渡す。
    drops = enemy_data.drops,
  }
end

-- 攻撃と防御の差分からダメージ量を計算する。
local function calc_damage(atk, def)
  return math.max(1, (atk or 0) - (def or 0))
end

-- 命中判定とダメージ量をまとめて返す。
local function resolve_attack(seed, atk, def, accuracy, attacker_element, defender_element, config)
  local base_seed = seed or 1
  local rate = math.max(0, math.min(100, accuracy or 100))
  local roll, next_seed = rng.next_int(base_seed, 1, 100)
  if roll > rate then
    return { hit = false, damage = 0, blocked = false }, next_seed
  end
  local base_damage = calc_damage(atk, def)
  -- 属性相性を適用してダメージを最小1に調整する。
  local multiplier, relation = element.effectiveness(attacker_element, defender_element, config)
  local damage = math.max(1, math.floor(base_damage * multiplier + 0.5))
  local blocked = damage <= 1 and (def or 0) > 0
  return { hit = true, damage = damage, blocked = blocked, effectiveness = relation, element_multiplier = multiplier }, next_seed
end

M.build_enemy = build_enemy
M.calc_damage = calc_damage
M.resolve_attack = resolve_attack

return M
