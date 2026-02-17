-- このモジュールは戦闘に関わる遷移処理を純粋関数でまとめる。
local battle = require("idle_dungeon.game.battle")
local balance = require("idle_dungeon.game.balance")
local content = require("idle_dungeon.content")
local floor_state = require("idle_dungeon.game.floor.state")
local game_speed = require("idle_dungeon.core.game_speed")
local inventory = require("idle_dungeon.game.inventory")
local loot = require("idle_dungeon.game.loot")
local pets = require("idle_dungeon.game.pets")
local player = require("idle_dungeon.game.player")
local rng = require("idle_dungeon.rng")
local helpers = require("idle_dungeon.core.state_helpers")
local skills = require("idle_dungeon.game.skills")
local state_dex = require("idle_dungeon.game.dex.state")
local util = require("idle_dungeon.util")

local M = {}
local SPEED_WAIT_BASE = 5
local MIN_TICK_SECONDS = 0.001

-- pet_partyは配列として管理するため、状態更新時は明示代入で置き換える。
local function merge_with_pet_party(state, updates, pet_party)
  local next_state = util.merge_tables(state, updates or {})
  if updates and type(updates.combat) == "table" then
    -- 戦闘状態は前ターンの残留データを避けるため、深いマージではなく丸ごと置換する。
    next_state.combat = updates.combat
  end
  next_state.pet_party = pet_party or {}
  return next_state
end

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

-- 行動後に次回行動まで待つティック数を相対速度から計算する。
local function resolve_action_interval(speed, opponent_speed)
  local safe_speed = math.max(tonumber(speed) or 1, 1)
  local safe_opponent = math.max(tonumber(opponent_speed) or 1, 1)
  -- 絶対値ではなく相対比で待機を決め、双方が同倍率で速くなっても全体テンポを保つ。
  local total = safe_speed + safe_opponent
  local scaled = (SPEED_WAIT_BASE * total) / (2 * safe_speed)
  return math.max(math.floor(scaled + 0.5), 1)
end

-- 撃破や敗北の演出を最低1ティックは維持する。
local function resolve_scaled_seconds(seconds, speed_multiplier)
  local base_seconds = math.max(tonumber(seconds) or 0, 0)
  local multiplier = math.max(tonumber(speed_multiplier) or 1, 1)
  return base_seconds / multiplier
end

-- 撃破や敗北の演出を最低1ティックは維持する。
local function resolve_outcome_wait(battle_config, tick_seconds, speed_multiplier)
  local base = tonumber((battle_config or {}).outcome_wait) or 0
  local seconds = resolve_scaled_seconds(tonumber((battle_config or {}).outcome_seconds) or 0.4, speed_multiplier)
  local tick = math.max(tonumber(tick_seconds) or 1, MIN_TICK_SECONDS)
  local derived = math.ceil(seconds / tick)
  return math.max(base, derived, 1)
end

-- 攻撃演出の継続フレーム数を計算する。
local function resolve_attack_frames(battle_config, tick_seconds, speed_multiplier)
  local seconds = resolve_scaled_seconds(tonumber((battle_config or {}).attack_seconds) or 0.6, speed_multiplier)
  local tick = math.max(tonumber(tick_seconds) or 1, MIN_TICK_SECONDS)
  local frames = math.ceil(seconds / tick)
  return math.max(frames, 2)
end

-- 攻撃時の前進演出フレーム数を計算する。
local function resolve_attack_step_frames(battle_config, tick_seconds, speed_multiplier)
  local seconds = resolve_scaled_seconds(tonumber((battle_config or {}).attack_step_seconds) or 0.2, speed_multiplier)
  local tick = math.max(tonumber(tick_seconds) or 1, MIN_TICK_SECONDS)
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

-- 旧形式の待機情報と新形式の待機情報を統一して取得する。
local function resolve_actor_waits(combat, hero_speed, enemy_speed)
  local hero_wait = combat and combat.hero_turn_wait or nil
  local enemy_wait = combat and combat.enemy_turn_wait or nil
  if hero_wait == nil and enemy_wait == nil then
    local legacy_turn = combat and combat.turn or nil
    local legacy_wait = tonumber(combat and combat.turn_wait or nil) or 0
    if legacy_turn == "hero" and legacy_wait > 0 then
      hero_wait = legacy_wait
      enemy_wait = 0
    elseif legacy_turn == "enemy" and legacy_wait > 0 then
      hero_wait = 0
      enemy_wait = legacy_wait
    else
      hero_wait = resolve_action_interval(hero_speed, enemy_speed)
      enemy_wait = resolve_action_interval(enemy_speed, hero_speed)
    end
  end
  if hero_wait == nil then
    hero_wait = resolve_action_interval(hero_speed, enemy_speed)
  end
  if enemy_wait == nil then
    enemy_wait = resolve_action_interval(enemy_speed, hero_speed)
  end
  return math.max(tonumber(hero_wait) or 0, 0), math.max(tonumber(enemy_wait) or 0, 0)
end

-- 1ティック経過した分だけ両者の待機を進める。
local function step_actor_waits(hero_wait, enemy_wait)
  return math.max((tonumber(hero_wait) or 0) - 1, 0), math.max((tonumber(enemy_wait) or 0) - 1, 0)
end

-- 現在の待機状態から行動者を決める。
local function resolve_turn_from_waits(hero_wait, enemy_wait, hero_speed, enemy_speed, last_turn)
  local hero_ready = (tonumber(hero_wait) or 0) <= 0
  local enemy_ready = (tonumber(enemy_wait) or 0) <= 0
  if not hero_ready and not enemy_ready then
    return nil
  end
  if hero_ready and not enemy_ready then
    return "hero"
  end
  if enemy_ready and not hero_ready then
    return "enemy"
  end
  -- 同時に行動可能なら直前の行動者と反対側を優先して偏りを防ぐ。
  if last_turn and last_turn.attacker == "hero" then
    return "enemy"
  end
  if last_turn and last_turn.attacker == "enemy" then
    return "hero"
  end
  -- 初回の同時行動だけは速度が速い側を優先する。
  if (tonumber(hero_speed) or 1) > (tonumber(enemy_speed) or 1) then
    return "hero"
  end
  if (tonumber(enemy_speed) or 1) > (tonumber(hero_speed) or 1) then
    return "enemy"
  end
  return "hero"
end

-- ゲーム進行ティックを蓄積し、戦闘ティック到達時のみ戦闘を進める。
local function advance_battle_clock(combat, game_tick_seconds, battle_tick_seconds)
  local buffer = math.max(tonumber((combat or {}).battle_tick_buffer) or 0, 0)
  local elapsed = math.max(tonumber(game_tick_seconds) or 0, 0)
  local tick = math.max(tonumber(battle_tick_seconds) or 0.5, MIN_TICK_SECONDS)
  local charged = buffer + elapsed
  if charged + 1e-9 < tick then
    return false, charged
  end
  return true, math.max(charged - tick, 0)
end

-- 攻撃ターンの記録をまとめて作成する。
local function build_last_turn(attacker, result, state, elapsed_seconds)
  local base_time = (state.metrics or {}).time_sec or 0
  -- 描画時点の時刻と合わせるため、今回の経過時間を加算して記録する。
  local time_sec = base_time + math.max(tonumber(elapsed_seconds) or 0, 0)
  return { attacker = attacker, result = result, time_sec = time_sec }
end

-- last_turnは深いマージを避け、毎ターンの結果で丸ごと差し替える。
local function merge_combat_with_last_turn(combat, updates, last_turn)
  local next_combat = util.merge_tables(combat or {}, updates or {})
  next_combat.last_turn = last_turn
  return next_combat
end

-- 敵がペットを狙うかどうかを抽選して対象を返す。
local function choose_enemy_target(seed, party, rate)
  if #(party or {}) == 0 then
    return "hero", nil, seed
  end
  local chance = math.max(tonumber(rate) or 0, 0)
  if chance <= 0 then
    return "hero", nil, seed
  end
  local threshold = math.min(math.floor(chance * 100 + 0.5), 100)
  local roll, next_seed = rng.next_int(seed or 1, 1, 100)
  if roll > threshold then
    return "hero", nil, next_seed
  end
  local index, seeded = rng.next_int(next_seed, 1, #party)
  return "pet", index, seeded
end

-- 勇者ターン時に保持中ペットの追撃を適用する。
local function apply_pet_follow_up(seed, enemy, party, enemy_def, enemy_element, config)
  local next_seed = seed
  local next_enemy = util.merge_tables(enemy or {}, {})
  local total_damage = 0
  local attacked = false
  for _, pet in ipairs(party or {}) do
    if (pet.hp or 0) > 0 then
      local result
      result, next_seed = build_attack_result(
        next_seed,
        math.max(math.floor((pet.atk or 1) + 0.5), 1),
        math.floor(enemy_def + 0.5),
        math.floor((pet.accuracy or 90) + 0.5),
        "pet",
        pet.element or "normal",
        enemy_element,
        config
      )
      local damage = math.max(tonumber(result.damage) or 0, 0)
      if damage > 0 then
        attacked = true
      end
      total_damage = total_damage + damage
      local next_hp = math.max((next_enemy.hp or 0) - damage, 0)
      next_enemy = util.merge_tables(next_enemy, { hp = next_hp })
      if next_hp <= 0 then
        break
      end
    end
  end
  return next_enemy, next_seed, total_damage, attacked
end

-- 戦闘の命中判定と体力更新を行う。
local function tick_battle(state, config)
  local combat = normalize_attack_state(state.combat or {})
  local game_tick_seconds = game_speed.resolve_runtime_tick_seconds(state, config)
  local battle_tick_seconds = game_speed.resolve_battle_tick_seconds(state, config)
  local speed_multiplier = game_speed.resolve_game_speed_multiplier(state, config)
  local can_step, buffered = advance_battle_clock(combat, game_tick_seconds, battle_tick_seconds)
  if not can_step then
    local waiting_combat = util.merge_tables(combat, { battle_tick_buffer = buffered })
    return util.merge_tables(state, { combat = waiting_combat })
  end
  combat = util.merge_tables(combat, { battle_tick_buffer = buffered })
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
  local companion_icon = ((config.ui or {}).icons or {}).companion
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
  local hero_speed = resolve_actor_speed(state, config)
  local enemy_speed = resolve_enemy_speed(enemy, config)
  local hero_wait, enemy_wait = resolve_actor_waits(combat, hero_speed, enemy_speed)
  hero_wait, enemy_wait = step_actor_waits(hero_wait, enemy_wait)
  local turn = resolve_turn_from_waits(hero_wait, enemy_wait, hero_speed, enemy_speed, combat.last_turn)
  if not turn then
    local waiting = util.merge_tables(combat, {
      hero_turn_wait = hero_wait,
      enemy_turn_wait = enemy_wait,
      turn = nil,
      turn_wait = 0,
    })
    return util.merge_tables(state, { combat = waiting })
  end
  -- スキルのパッシブ効果を戦闘計算に反映する。
  local passive_bonus = skills.resolve_passive_bonus(state.skills, state.skill_settings, content.jobs)
  -- 敵側のパッシブスキルも倍率として反映する。
  local enemy_passive = skills.resolve_passive_bonus_from_list(enemy and enemy.skills or {})
  local hero_atk = (state.actor.atk or 0) * (passive_bonus.atk or 1)
  local hero_def = (state.actor.def or 0) * (passive_bonus.def or 1)
  local hero_accuracy = (battle_config.accuracy or 90) * (passive_bonus.accuracy or 1)
  local enemy_def = (enemy.def or 0) * (enemy_passive.def or 1)
  local attack_effect_frames = resolve_attack_frames(battle_config, battle_tick_seconds, speed_multiplier)
  local attack_step_frames = resolve_attack_step_frames(battle_config, battle_tick_seconds, speed_multiplier)
  local next_actor = state.actor
  local next_enemy = enemy
  local next_pet_party = pets.normalize_party(state.pet_party, content.enemies, companion_icon)
  local last_turn
  local next_progress = util.merge_tables(state.progress, { rng_seed = seed })
  local enemy_skill_rate = battle_config.enemy_skill_rate or battle_config.skill_active_rate or 0
  if turn == "hero" then
    local hero_result
    local active_skill
    active_skill = nil
    active_skill, seed = skills.choose_active_skill(state.skills, state.skill_settings, content.jobs, seed, battle_config.skill_active_rate)
    local skill_power = active_skill and (active_skill.power or 1) or 1
    local skill_accuracy = active_skill and (active_skill.accuracy or 0) or 0
    hero_result, seed = build_attack_result(
      seed,
      math.floor(hero_atk * skill_power + 0.5),
      math.floor(enemy_def + 0.5),
      math.floor(hero_accuracy + skill_accuracy + 0.5),
      "hero",
      hero_element,
      enemy_element,
      config
    )
    hero_result.skill = active_skill
    local next_enemy_hp = enemy.hp - hero_result.damage
    next_enemy = util.merge_tables(enemy, { hp = math.max(0, next_enemy_hp), element = enemy_element })
    if (next_enemy.hp or 0) > 0 and #next_pet_party > 0 then
      -- 勇者の行動後に保持中ペットの追撃を適用する。
      local pet_damage, pet_attacked
      next_enemy, seed, pet_damage, pet_attacked = apply_pet_follow_up(seed, next_enemy, next_pet_party, enemy_def, enemy_element, config)
      if pet_attacked then
        hero_result.pet_damage = pet_damage
      end
    end
    last_turn = build_last_turn("hero", hero_result, state, game_tick_seconds)
    hero_wait = resolve_action_interval(hero_speed, enemy_speed)
    next_progress = util.merge_tables(state.progress, { rng_seed = seed })
    if (next_enemy.hp or 0) <= 0 then
      -- 撃破時に戦利品の抽選を行い、報酬画面で表示できるように保持する。
      local drop
      drop, seed = loot.roll_drop(seed, config, content.items, enemy)
      local gold_bonus
      gold_bonus, seed = loot.roll_gold(seed, enemy)
      local reward_exp = balance.resolve_exp_reward(battle_config.reward_exp, enemy)
      next_progress = util.merge_tables(state.progress, { rng_seed = seed })
      local next_combat = merge_combat_with_last_turn(combat, {
        enemy = next_enemy,
        pending_drop = drop,
        pending_gold = gold_bonus,
        pending_exp = reward_exp,
        -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
        attack_effect = attack_effect_frames,
        attack_step = attack_step_frames,
        hero_turn_wait = hero_wait,
        enemy_turn_wait = enemy_wait,
        turn = "hero",
        turn_wait = 0,
        outcome = "reward",
        outcome_wait = resolve_outcome_wait(battle_config, battle_tick_seconds, speed_multiplier),
      }, last_turn)
      return merge_with_pet_party(state, { combat = next_combat, progress = next_progress }, next_pet_party)
    end
  else
    -- 敵のスキルも抽選し、能力補正を反映する。
    local enemy_skill
    enemy_skill, seed = skills.choose_active_skill_from_list(enemy.skills or {}, seed, enemy_skill_rate)
    local enemy_skill_power = enemy_skill and (enemy_skill.power or 1) or 1
    local enemy_skill_accuracy = enemy_skill and (enemy_skill.accuracy or 0) or 0
    local enemy_atk = (enemy.atk or 0) * (enemy_passive.atk or 1)
    local enemy_accuracy = (enemy.accuracy or battle_config.enemy_accuracy or 85) * (enemy_passive.accuracy or 1)
    local enemy_result
    local target_kind, target_index
    target_kind, target_index, seed = choose_enemy_target(seed, next_pet_party, battle_config.pet_target_rate or 0)
    if target_kind == "pet" and target_index then
      local target_pet = next_pet_party[target_index]
      enemy_result, seed = build_attack_result(
        seed,
        math.floor(enemy_atk * enemy_skill_power + 0.5),
        math.floor((target_pet and target_pet.def or 0) + 0.5),
        math.floor(enemy_accuracy + enemy_skill_accuracy + 0.5),
        "enemy",
        enemy_element,
        (target_pet and target_pet.element) or "normal",
        config
      )
      enemy_result.target = "pet"
      local damaged_state
      damaged_state, enemy_result.defeated_pet = pets.damage_pet(
        util.merge_tables(state, { pet_party = next_pet_party }),
        enemy_result.damage,
        target_index,
        content.enemies,
        companion_icon
      )
      next_pet_party = damaged_state.pet_party or {}
    else
      enemy_result, seed = build_attack_result(
        seed,
        math.floor(enemy_atk * enemy_skill_power + 0.5),
        math.floor(hero_def + 0.5),
        math.floor(enemy_accuracy + enemy_skill_accuracy + 0.5),
        "enemy",
        enemy_element,
        hero_element,
        config
      )
      enemy_result.target = "hero"
    end
    enemy_result.skill = enemy_skill
    local next_actor_hp = state.actor.hp
    if enemy_result.target == "hero" then
      next_actor_hp = state.actor.hp - enemy_result.damage
      next_actor = util.merge_tables(state.actor, { hp = math.max(0, next_actor_hp) })
    end
    last_turn = build_last_turn("enemy", enemy_result, state, game_tick_seconds)
    enemy_wait = resolve_action_interval(enemy_speed, hero_speed)
    next_progress = util.merge_tables(state.progress, { rng_seed = seed })
    if next_actor_hp <= 0 then
      local next_combat = merge_combat_with_last_turn(combat, {
        enemy = next_enemy,
        -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
        attack_effect = attack_effect_frames,
        attack_step = attack_step_frames,
        hero_turn_wait = hero_wait,
        enemy_turn_wait = enemy_wait,
        turn = "enemy",
        turn_wait = 0,
        outcome = "defeat",
        outcome_wait = resolve_outcome_wait(battle_config, battle_tick_seconds, speed_multiplier),
      }, last_turn)
      return merge_with_pet_party(state, { actor = next_actor, combat = next_combat, progress = next_progress }, next_pet_party)
    end
  end
  local next_combat = merge_combat_with_last_turn(combat, {
    enemy = next_enemy,
    -- 攻撃演出はフレーム数を保持し、前進演出も別で持つ。
    attack_effect = attack_effect_frames,
    attack_step = attack_step_frames,
    hero_turn_wait = hero_wait,
    enemy_turn_wait = enemy_wait,
    turn = turn,
    turn_wait = 0,
  }, last_turn)
  return merge_with_pet_party(state, { actor = next_actor, combat = next_combat, progress = next_progress }, next_pet_party)
end

-- 戦闘勝利時の報酬と階層状態を更新する。
local function tick_reward(state, config)
  local combat_enemy = (state.combat or {}).enemy
  local reward_exp = (state.combat and state.combat.pending_exp)
  if reward_exp == nil then
    reward_exp = balance.resolve_exp_reward((config.battle or {}).reward_exp or 0, combat_enemy)
  end
  local base_gold = (config.battle or {}).reward_gold or 0
  local bonus_gold = (state.combat or {}).pending_gold or 0
  local reward_gold = balance.resolve_gold_reward(base_gold, bonus_gold, combat_enemy)
  local pending_drop = state.combat and state.combat.pending_drop or nil
  -- 現在のジョブ進行度を更新して経験値に反映する。
  local current_job = helpers.find_job(state.actor and state.actor.id)
  local job_levels = util.merge_tables(state.job_levels or {}, {})
  local job_progress = job_levels[current_job.id] or player.default_job_progress()
  local leveled, next_job = player.add_exp_with_job(state.actor, reward_exp, job_progress, current_job)
  local applied = player.apply_equipment(leveled, state.equipment, content.items)
  job_levels[current_job.id] = next_job
  local learned_skills = skills.unlock_from_job(state.skills or skills.empty(), current_job, next_job)
  local skill_settings = skills.ensure_enabled(state.skill_settings, learned_skills)
  local current_gold = (state.currency and state.currency.gold) or 0
  local next_currency = util.merge_tables(state.currency, { gold = current_gold + reward_gold })
  local source_enemy = state.combat and state.combat.source or nil
  local next_inventory = state.inventory
  local companion_icon = ((config.ui or {}).icons or {}).companion
  local next_state = util.merge_tables(state, {
    actor = applied,
    currency = next_currency,
    job_levels = job_levels,
    skills = learned_skills,
    skill_settings = skill_settings,
  })
  if pending_drop and pending_drop.id then
    -- ペット枠のドロップは保持中ペットとして登録する。
    if pending_drop.rarity == "pet" then
      next_state = pets.add_pet(
        next_state,
        pending_drop.id,
        content.enemies,
        content.jobs,
        companion_icon,
        state.combat and state.combat.enemy or nil
      )
    else
      -- 通常の戦利品は所持品へ追加する。
      next_inventory = inventory.add_item(state.inventory, pending_drop.id, 1)
      next_state = util.merge_tables(next_state, { inventory = next_inventory })
    end
    next_state = state_dex.record_item(next_state, pending_drop.id, 1)
  end
  -- スキル変化後の保持上限を超えないように補正する。
  next_state = pets.enforce_capacity(next_state, content.jobs, content.enemies, companion_icon)
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
  -- 勇者が倒れた時点で保持中ペットはすべて離脱する。
  local next_state = merge_with_pet_party(state, { progress = refreshed, actor = actor, combat = nil }, {})
  return util.merge_tables(next_state, { ui = util.merge_tables(state.ui, { mode = "move", event_id = nil, battle_message = nil }) })
end

M.tick_battle = tick_battle
M.tick_reward = tick_reward
M.tick_defeat = tick_defeat

return M
