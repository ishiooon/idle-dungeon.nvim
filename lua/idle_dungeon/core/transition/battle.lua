-- このモジュールは戦闘に関わる遷移処理を純粋関数でまとめる。
local battle = require("idle_dungeon.game.battle")
local content = require("idle_dungeon.content")
local floor_state = require("idle_dungeon.game.floor.state")
local inventory = require("idle_dungeon.game.inventory")
local loot = require("idle_dungeon.game.loot")
local player = require("idle_dungeon.game.player")
local state_dex = require("idle_dungeon.game.dex.state")
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

-- 攻撃速度は1以上の整数として扱い、無効値は既定値に丸める。
local function resolve_speed(value, fallback)
  local speed = tonumber(value)
  if not speed or speed < 1 then
    speed = tonumber(fallback) or 1
  end
  return math.max(speed, 1)
end

-- 攻撃間隔の待機秒数を計算する。
local function resolve_turn_wait(speed)
  return math.max((tonumber(speed) or 1) - 1, 0)
end

-- 撃破や敗北の演出を最低1ティックは維持する。
local function resolve_outcome_wait(battle_config, tick_seconds)
  local base = tonumber((battle_config or {}).outcome_wait) or 0
  local seconds = tonumber((battle_config or {}).outcome_seconds) or 0.4
  local tick = math.max(tonumber(tick_seconds) or 1, 0.1)
  local derived = math.ceil(seconds / tick)
  return math.max(base, derived, 1)
end

-- 攻撃演出の継続フレーム数を計算する。
local function resolve_attack_frames(battle_config, tick_seconds)
  local seconds = tonumber((battle_config or {}).attack_seconds) or 0.6
  local tick = math.max(tonumber(tick_seconds) or 1, 0.1)
  local frames = math.ceil(seconds / tick)
  return math.max(frames, 2)
end

-- 攻撃時の前進演出フレーム数を計算する。
local function resolve_attack_step_frames(battle_config, tick_seconds)
  local seconds = tonumber((battle_config or {}).attack_step_seconds) or 0.2
  local tick = math.max(tonumber(tick_seconds) or 1, 0.1)
  local frames = math.ceil(seconds / tick)
  return math.max(frames, 1)
end

-- 旧形式の攻撃フレームを新しい形式へ補正する。
local function normalize_attack_state(combat)
  local legacy = combat and combat.attack_frame or nil
  if legacy == nil or (combat.attack_effect ~= nil or combat.attack_step ~= nil) then
    return combat
  end
  local effect = math.max(tonumber(legacy) or 0, 0)
  local step = math.max(effect - 1, 0)
  return util.merge_tables(combat, { attack_effect = effect, attack_step = step })
end

-- 攻撃演出の残り回数を減らし、終了時に攻撃情報も消す。
local function decay_attack_frame(combat)
  local effect = tonumber((combat or {}).attack_effect or 0) or 0
  local step = tonumber((combat or {}).attack_step or 0) or 0
  if effect <= 0 then
    return combat
  end
  local next_effect = effect - 1
  local next_step = step
  if step > 0 then
    next_step = step - 1
  end
  local updates = {
    attack_effect = math.max(next_effect, 0),
    attack_step = math.max(next_step, 0),
  }
  if next_effect <= 0 then
    -- 演出が終わったら攻撃情報も掃除して次の演出に備える。
    updates.last_turn = nil
  end
  return util.merge_tables(combat, updates)
end

-- 勇者の攻撃速度を取得する。
local function resolve_actor_speed(state, config)
  local battle_config = config.battle or {}
  local actor = state.actor or {}
  return resolve_speed(actor.speed or actor.base_speed, battle_config.hero_speed or 2)
end

-- 敵の攻撃速度を取得する。
local function resolve_enemy_speed(enemy, config)
  local battle_config = config.battle or {}
  return resolve_speed(enemy.speed, battle_config.enemy_speed or 2)
end

-- 速度が高い側を先制として扱い、同速なら勇者を優先する。
local function resolve_initial_turn(combat, hero_speed, enemy_speed)
  local current = combat and combat.turn or nil
  if current == "hero" or current == "enemy" then
    return current
  end
  if (enemy_speed or 1) > (hero_speed or 1) then
    return "enemy"
  end
  return "hero"
end

-- 攻撃ターンの記録をまとめて作成する。
local function resolve_tick_seconds(state, config)
  local boost = state and state.ui and state.ui.speed_boost or nil
  if boost and boost.remaining_ticks and boost.remaining_ticks > 0 and boost.tick_seconds then
    return boost.tick_seconds
  end
  return (config and config.tick_seconds) or 1
end

local function build_last_turn(attacker, result, state, config)
  local base_time = (state.metrics or {}).time_sec or 0
  -- 速度上昇中のティック秒数も反映して演出タイミングを合わせる。
  local tick = resolve_tick_seconds(state, config)
  -- 描画時点の時刻と合わせるため、次のティック時刻を記録する。
  local time_sec = base_time + tick
  return { attacker = attacker, result = result, time_sec = time_sec }
end

-- 戦闘の命中判定と体力更新を行う。
local function tick_battle(state, config)
  local combat = normalize_attack_state(state.combat or {})
  -- 攻撃演出が残っている場合は戦闘進行を一時停止する。
  if combat.attack_effect and combat.attack_effect > 0 then
    local decayed = decay_attack_frame(combat)
    if (decayed.attack_effect or 0) > 0 then
      return util.merge_tables(state, { combat = decayed })
    end
    combat = decayed
  end
  local enemy = combat.enemy
  local battle_config = config.battle or {}
  local hero_element = resolve_weapon_element(state, content.items)
  local enemy_element = enemy.element or "normal"
  local seed = state.progress.rng_seed or 1
  local outcome = combat.outcome
  local outcome_wait = combat.outcome_wait or 0
  if outcome then
    if outcome_wait > 0 then
      local next_combat = util.merge_tables(combat, { outcome_wait = outcome_wait - 1 })
      return util.merge_tables(state, { combat = next_combat })
    end
    if outcome == "reward" then
      local next_ui = { mode = "reward" }
      return util.merge_tables(state, { ui = util.merge_tables(state.ui, next_ui), progress = util.merge_tables(state.progress, { rng_seed = seed }) })
    end
    if outcome == "defeat" then
      local next_ui = { mode = "defeat" }
      return util.merge_tables(state, { ui = util.merge_tables(state.ui, next_ui), progress = util.merge_tables(state.progress, { rng_seed = seed }) })
    end
  end
  local wait = combat.turn_wait or 0
  if wait > 0 then
    local next_combat = util.merge_tables(combat, { turn_wait = wait - 1 })
    return util.merge_tables(state, { combat = next_combat })
  end
  local hero_speed = resolve_actor_speed(state, config)
  local enemy_speed = resolve_enemy_speed(enemy, config)
  local turn = resolve_initial_turn(combat, hero_speed, enemy_speed)
  local tick_seconds = resolve_tick_seconds(state, config)
  local attack_effect_frames = resolve_attack_frames(battle_config, tick_seconds)
  local attack_step_frames = resolve_attack_step_frames(battle_config, tick_seconds)
  local next_actor = state.actor
  local next_enemy = enemy
  local last_turn
  local next_turn = turn
  local next_wait = 0
  local next_progress = util.merge_tables(state.progress, { rng_seed = seed })
  if turn == "hero" then
    local hero_result
    hero_result, seed = build_attack_result(seed, state.actor.atk, enemy.def or 0, battle_config.accuracy or 90, "hero", hero_element, enemy_element, config)
    local next_enemy_hp = enemy.hp - hero_result.damage
    next_enemy = util.merge_tables(enemy, { hp = math.max(0, next_enemy_hp), element = enemy_element })
    last_turn = build_last_turn("hero", hero_result, state, config)
    next_turn = "enemy"
    next_wait = resolve_turn_wait(enemy_speed)
    next_progress = util.merge_tables(state.progress, { rng_seed = seed })
    if next_enemy_hp <= 0 then
      -- 撃破時に戦利品の抽選を行い、報酬画面で表示できるように保持する。
      local drop
      drop, seed = loot.roll_drop(seed, config, content.items, enemy)
      local gold_bonus
      gold_bonus, seed = loot.roll_gold(seed, enemy)
      next_progress = util.merge_tables(state.progress, { rng_seed = seed })
      local next_combat = util.merge_tables(combat, {
        enemy = next_enemy,
        pending_drop = drop,
        pending_gold = gold_bonus,
        last_turn = last_turn,
        -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
        attack_effect = attack_effect_frames,
        attack_step = attack_step_frames,
        outcome = "reward",
        outcome_wait = resolve_outcome_wait(battle_config, tick_seconds),
      })
      return util.merge_tables(state, { combat = next_combat, progress = next_progress })
    end
  else
    local enemy_accuracy = enemy.accuracy or battle_config.enemy_accuracy or 85
    local enemy_result
    enemy_result, seed = build_attack_result(seed, enemy.atk, state.actor.def, enemy_accuracy, "enemy", enemy_element, hero_element, config)
    local next_actor_hp = state.actor.hp - enemy_result.damage
    next_actor = util.merge_tables(state.actor, { hp = math.max(0, next_actor_hp) })
    last_turn = build_last_turn("enemy", enemy_result, state, config)
    next_turn = "hero"
    next_wait = resolve_turn_wait(hero_speed)
    next_progress = util.merge_tables(state.progress, { rng_seed = seed })
    if next_actor_hp <= 0 then
      local next_combat = util.merge_tables(combat, {
        enemy = next_enemy,
        last_turn = last_turn,
        -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
        attack_effect = attack_effect_frames,
        attack_step = attack_step_frames,
        outcome = "defeat",
        outcome_wait = resolve_outcome_wait(battle_config, tick_seconds),
      })
      return util.merge_tables(state, { actor = next_actor, combat = next_combat, progress = next_progress })
    end
  end
  local next_combat = util.merge_tables(combat, {
    enemy = next_enemy,
    last_turn = last_turn,
    -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
    attack_effect = attack_effect_frames,
    attack_step = attack_step_frames,
    turn = next_turn,
    turn_wait = next_wait,
  })
  return util.merge_tables(state, { actor = next_actor, combat = next_combat, progress = next_progress })
end

-- 戦闘勝利時の報酬と階層状態を更新する。
local function tick_reward(state, config)
  local reward_exp = (config.battle or {}).reward_exp or 0
  local base_gold = (config.battle or {}).reward_gold or 0
  local bonus_gold = (state.combat or {}).pending_gold or 0
  local reward_gold = base_gold + bonus_gold
  local pending_drop = state.combat and state.combat.pending_drop or nil
  local leveled = player.add_exp(state.actor, reward_exp)
  local applied = player.apply_equipment(leveled, state.equipment, content.items)
  local current_gold = (state.currency and state.currency.gold) or 0
  local next_currency = util.merge_tables(state.currency, { gold = current_gold + reward_gold })
  local source_enemy = state.combat and state.combat.source or nil
  local next_inventory = state.inventory
  local next_state = util.merge_tables(state, { actor = applied, currency = next_currency })
  if pending_drop and pending_drop.id then
    -- 戦利品が出た場合は所持品と図鑑を更新する。
    next_inventory = inventory.add_item(state.inventory, pending_drop.id, 1)
    next_state = util.merge_tables(next_state, { inventory = next_inventory })
    next_state = state_dex.record_item(next_state, pending_drop.id, 1)
  end
  local updated_progress = floor_state.mark_enemy_defeated(state.progress, source_enemy)
  next_state = util.merge_tables(next_state, { combat = nil, progress = updated_progress })
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
