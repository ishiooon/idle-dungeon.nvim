-- このモジュールは戦闘に関わる遷移処理を純粋関数でまとめる。
local battle = require("idle_dungeon.game.battle")
local content = require("idle_dungeon.content")
local floor_state = require("idle_dungeon.game.floor.state")
local player = require("idle_dungeon.game.player")
local util = require("idle_dungeon.util")

local M = {}

-- 装備中の武器から属性タイプを解決する。
local function resolve_weapon_element(state, items)
  local weapon_id = (state.equipment or {}).weapon
  if not weapon_id then
    return "normal"
  end
  for _, item in ipairs(items or {}) do
    if item.id == weapon_id then
      return item.element or "normal"
    end
  end
  return "normal"
end

-- 攻撃結果に攻撃者情報と属性相性を付与して返す。
local function build_attack_result(seed, atk, def, accuracy, attacker, element_id, defender_element, config)
  local result, next_seed = battle.resolve_attack(seed, atk, def, accuracy, element_id, defender_element, config)
  local enriched = util.merge_tables(result, { attacker = attacker, element = element_id })
  return enriched, next_seed
end

-- 戦闘の命中判定と体力更新を行う。
local function tick_battle(state, config)
  local enemy = state.combat.enemy
  local battle_config = config.battle or {}
  local hero_element = resolve_weapon_element(state, content.items)
  local enemy_element = enemy.element or "normal"
  local seed = state.progress.rng_seed or 1
  local hero_result
  hero_result, seed = build_attack_result(seed, state.actor.atk, enemy.def or 0, battle_config.accuracy or 90, "hero", hero_element, enemy_element, config)
  local next_enemy_hp = enemy.hp - hero_result.damage
  local enemy_result = {
    hit = false,
    damage = 0,
    blocked = false,
    attacker = "enemy",
    element = enemy_element,
    effectiveness = "neutral",
    element_multiplier = 1.0,
  }
  local next_actor_hp = state.actor.hp
  if next_enemy_hp > 0 then
    local enemy_accuracy = enemy.accuracy or battle_config.enemy_accuracy or 85
    enemy_result, seed = build_attack_result(seed, enemy.atk, state.actor.def, enemy_accuracy, "enemy", enemy_element, hero_element, config)
    next_actor_hp = state.actor.hp - enemy_result.damage
  end
  local next_actor = util.merge_tables(state.actor, { hp = math.max(0, next_actor_hp) })
  local next_enemy = util.merge_tables(enemy, { hp = math.max(0, next_enemy_hp), element = enemy_element })
  local next_combat = util.merge_tables(state.combat or {}, { enemy = next_enemy, last_turn = { hero = hero_result, enemy = enemy_result } })
  local next_progress = util.merge_tables(state.progress, { rng_seed = seed })
  if next_enemy_hp <= 0 then
    local next_ui = { mode = "reward" }
    return util.merge_tables(state, {
      actor = next_actor,
      combat = next_combat,
      progress = next_progress,
      ui = util.merge_tables(state.ui, next_ui),
    })
  end
  if next_actor_hp <= 0 then
    local next_ui = { mode = "defeat" }
    return util.merge_tables(state, {
      actor = next_actor,
      combat = next_combat,
      progress = next_progress,
      ui = util.merge_tables(state.ui, next_ui),
    })
  end
  return util.merge_tables(state, { actor = next_actor, combat = next_combat, progress = next_progress })
end

-- 戦闘勝利時の報酬と階層状態を更新する。
local function tick_reward(state, config)
  local reward_exp = (config.battle or {}).reward_exp or 0
  local reward_gold = (config.battle or {}).reward_gold or 0
  local leveled = player.add_exp(state.actor, reward_exp)
  local applied = player.apply_equipment(leveled, state.equipment, content.items)
  local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold + reward_gold })
  local source_enemy = state.combat and state.combat.source or nil
  local updated_progress = floor_state.mark_enemy_defeated(state.progress, source_enemy)
  local next_state = util.merge_tables(state, { actor = applied, currency = next_currency, combat = nil, progress = updated_progress })
  return util.merge_tables(next_state, { ui = util.merge_tables(state.ui, { mode = "move", event_id = nil, battle_message = nil }) })
end

-- 敗北時は進行位置を戻し、階層状態も初期化する。
local function tick_defeat(state, config)
  local reset_progress = util.merge_tables(state.progress, {
    distance = state.progress.stage_start,
    floor_enemies = nil,
    floor_index = nil,
    floor_encounters_total = nil,
    floor_encounters_remaining = nil,
    floor_boss_pending = nil,
  })
  local refreshed = floor_state.refresh(reset_progress, config)
  local actor = util.merge_tables(state.actor, { hp = state.actor.max_hp })
  local next_state = util.merge_tables(state, { progress = refreshed, actor = actor, combat = nil })
  return util.merge_tables(next_state, { ui = util.merge_tables(state.ui, { mode = "move", event_id = nil, battle_message = nil }) })
end

M.tick_battle = tick_battle
M.tick_reward = tick_reward
M.tick_defeat = tick_defeat

return M
