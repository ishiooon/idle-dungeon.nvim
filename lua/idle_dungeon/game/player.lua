-- このモジュールはキャラクターと装備による能力値を算出する。

local util = require("idle_dungeon.util")

local M = {}

local function new_actor(character)
  local base = character.base
  return {
    id = character.id,
    name = character.name,
    role = character.role,
    level = 1,
    exp = 0,
    next_level = 10,
    base_hp = base.hp,
    base_atk = base.atk,
    base_def = base.def,
    max_hp = base.hp,
    hp = base.hp,
    atk = base.atk,
    def = base.def,
    dialogue_ratio = character.dialogue_ratio or 1.0,
  }
end

local function apply_equipment(actor, equipment, items)
  local bonus_hp, bonus_atk, bonus_def = 0, 0, 0
  for _, item in pairs(items or {}) do
    if equipment[item.slot] == item.id then
      bonus_hp = bonus_hp + (item.hp or 0)
      bonus_atk = bonus_atk + (item.atk or 0)
      bonus_def = bonus_def + (item.def or 0)
    end
  end
  local next_actor = util.merge_tables(actor, {})
  next_actor.max_hp = next_actor.base_hp + bonus_hp
  next_actor.atk = next_actor.base_atk + bonus_atk
  next_actor.def = next_actor.base_def + bonus_def
  if next_actor.hp > next_actor.max_hp then
    next_actor.hp = next_actor.max_hp
  end
  return next_actor
end

local function add_exp(actor, amount)
  local next_actor = util.merge_tables(actor, {})
  next_actor.exp = next_actor.exp + amount
  while next_actor.exp >= next_actor.next_level do
    next_actor.exp = next_actor.exp - next_actor.next_level
    next_actor.level = next_actor.level + 1
    next_actor.base_hp = next_actor.base_hp + 1
    next_actor.base_atk = next_actor.base_atk + 1
    next_actor.base_def = next_actor.base_def + 1
    next_actor.next_level = math.floor(next_actor.next_level * 1.2) + 1
  end
  return next_actor
end

local function apply_level(actor, level, exp, next_level)
  local next_actor = util.merge_tables(actor, {})
  local level_value = math.max(level or 1, 1)
  local gain = level_value - 1
  next_actor.level = level_value
  next_actor.exp = exp or 0
  next_actor.next_level = next_level or next_actor.next_level
  next_actor.base_hp = next_actor.base_hp + gain
  next_actor.base_atk = next_actor.base_atk + gain
  next_actor.base_def = next_actor.base_def + gain
  next_actor.max_hp = next_actor.base_hp
  next_actor.hp = math.min(next_actor.hp, next_actor.max_hp)
  next_actor.atk = next_actor.base_atk
  next_actor.def = next_actor.base_def
  return next_actor
end

M.new_actor = new_actor
M.apply_equipment = apply_equipment
M.add_exp = add_exp
M.apply_level = apply_level

return M
