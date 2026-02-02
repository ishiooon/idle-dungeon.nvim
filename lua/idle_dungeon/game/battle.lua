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

-- 敵のステータスを距離と設定から構築する。
local function build_enemy(distance, config, enemy_spec)
  local names = (config or {}).enemy_names or { "enemy" }
  local enemy_id = resolve_enemy_id(distance or 0, names, enemy_spec)
  local enemy_data = enemy_catalog.find_enemy(enemy_id) or {}
  -- 階層数を基準に敵の成長を計算する。
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local floor_index = floor_progress.floor_index(distance or 0, floor_length)
  local growth = floor_index
  local battle = config.battle or { enemy_hp = 5, enemy_atk = 1 }
  local stats = enemy_data.stats or {}
  local base_hp = stats.hp or battle.enemy_hp
  local base_atk = stats.atk or battle.enemy_atk
  local base_def = stats.def or 0
  return {
    id = enemy_id,
    name = resolve_enemy_name(enemy_id),
    element = resolve_enemy_element(enemy_spec),
    hp = base_hp + growth,
    -- 最大体力を保持して表示に使う。
    max_hp = base_hp + growth,
    atk = base_atk + math.floor(growth / 2),
    def = base_def + math.floor(growth / 3),
    accuracy = stats.accuracy,
    is_boss = enemy_spec and enemy_spec.is_boss or false,
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
