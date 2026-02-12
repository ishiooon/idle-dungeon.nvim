-- このモジュールは戦闘時の敵生成とダメージ計算を提供する。
-- 階層計算はgame/floor/progressに委譲して整理する。
local balance = require("idle_dungeon.game.balance")
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

-- 乗算・加算補正を反映して最終的な能力値へ丸める。
local function apply_stat_tuning(base_value, mul, add, minimum)
  local value = (tonumber(base_value) or 0) * (tonumber(mul) or 1) + (tonumber(add) or 0)
  return math.max(math.floor(value + 0.5), tonumber(minimum) or 0)
end

-- 敵の成長レベルを計算する。
local function resolve_growth_level(distance, config, is_boss)
  local stage, stage_index, floor_length = resolve_stage_context(distance, config)
  local growth = balance.resolve_enemy_growth(config)
  local base = growth.growth_base
  local floor_growth = growth.growth_floor
  local stage_growth = growth.growth_stage
  local stage_start = stage and stage.start or 0
  local stage_floor = floor_progress.floor_index((distance or 0) - stage_start, floor_length)
  local level = base + math.max(stage_floor, 0) * floor_growth + math.max((stage_index or 1) - 1, 0) * stage_growth
  local boss_multiplier = growth.growth_boss_multiplier
  if is_boss then
    level = math.floor(level * boss_multiplier + 0.5)
  end
  return math.max(level, 1), stage
end

-- 敵のステータスを距離と設定から構築する。
local function build_enemy(distance, config, enemy_spec)
  local names = (config or {}).enemy_names or { "enemy" }
  local enemy_id = resolve_enemy_id(distance or 0, names, enemy_spec)
  local enemy_data = enemy_catalog.find_enemy(enemy_id) or {}
  local is_boss = enemy_spec and enemy_spec.is_boss or false
  -- ステージとフロアの進行度で成長を計算する。
  local growth, stage = resolve_growth_level(distance or 0, config, is_boss)
  local tuning = balance.resolve_stage_tuning(stage)
  local battle = config.battle or { enemy_hp = 5, enemy_atk = 1 }
  local growth_config = balance.resolve_enemy_growth(config)
  local stats = enemy_data.stats or {}
  local base_hp = stats.hp or battle.enemy_hp
  local base_atk = stats.atk or battle.enemy_atk
  local base_def = stats.def or 0
  -- 敵の攻撃速度は定義値を優先し、無い場合は既定値を使う。
  local base_speed = stats.speed or battle.enemy_speed or 2
  local growth_hp = growth_config.growth_hp
  local growth_atk = growth_config.growth_atk
  local growth_def = growth_config.growth_def
  local growth_speed = growth_config.growth_speed
  local tuned_growth = math.max((tonumber(growth) or 1) * tuning.growth_mul, 1)
  local scaled_hp = base_hp + math.max(0, math.floor(tuned_growth * growth_hp))
  local scaled_atk = base_atk + math.max(0, math.floor(tuned_growth * growth_atk))
  local scaled_def = base_def + math.max(0, math.floor(tuned_growth * growth_def))
  -- 進行が進むほどspeedを上げ、行動頻度も増えるようにする。
  local scaled_speed = base_speed + math.max(0, math.floor(math.max(tuned_growth - 1, 0) * growth_speed))
  local final_hp = apply_stat_tuning(scaled_hp, tuning.hp_mul, tuning.hp_add, 1)
  local final_atk = apply_stat_tuning(scaled_atk, tuning.atk_mul, tuning.atk_add, 1)
  local final_def = apply_stat_tuning(scaled_def, tuning.def_mul, tuning.def_add, 0)
  local final_speed = apply_stat_tuning(scaled_speed, tuning.speed_mul, tuning.speed_add, 1)
  return {
    id = enemy_id,
    name = resolve_enemy_name(enemy_id),
    element = resolve_enemy_element(enemy_spec),
    hp = final_hp,
    -- 最大体力を保持して表示に使う。
    max_hp = final_hp,
    atk = final_atk,
    def = final_def,
    accuracy = stats.accuracy,
    speed = math.max(tonumber(final_speed) or 1, 1),
    is_boss = is_boss,
    level = growth,
    -- 敵ごとの経験値倍率にステージ補正を掛けて報酬計算に使う。
    exp_multiplier = math.max((enemy_data.exp_multiplier or 1) * tuning.exp_mul, 0),
    -- ステージごとの経験値上限を保持し、序盤の過剰成長を抑える。
    exp_cap = tuning.exp_cap,
    -- ステージごとのゴールド補正を保持し、報酬計算に使う。
    gold_mul = tuning.gold_mul,
    gold_add = tuning.gold_add,
    -- 敵スキルは戦闘演出と計算に使う。
    skills = enemy_data.skills,
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
