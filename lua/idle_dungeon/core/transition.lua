-- このモジュールは状態遷移の計算を純粋関数としてまとめる。
-- ゲーム進行の依存先はgame配下にまとめる。
local content = require("idle_dungeon.content")
local battle = require("idle_dungeon.game.battle")
-- 階層内の遭遇状態はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local player = require("idle_dungeon.game.player")
local state_dex = require("idle_dungeon.game.dex.state")
local stage_progress = require("idle_dungeon.game.stage_progress")
local rules = require("idle_dungeon.core.transition_rules")
local util = require("idle_dungeon.util")
local M = {}

-- 戦闘開始時に図鑑へ記録し、戦闘状態へ切り替える。
local function start_battle(state, progress, enemy)
  local next_ui = { mode = "battle", event_id = nil }
  local next_state = util.merge_tables(state, {
    progress = progress,
    ui = util.merge_tables(state.ui, next_ui),
    combat = { enemy = enemy },
  })
  return state_dex.record_enemy(next_state, enemy.id or enemy.name)
end
local function tick_move(state, config)
  local move_step = config.move_step or 1
  local next_distance = state.progress.distance + move_step
  local progress = util.merge_tables(state.progress, { distance = next_distance })
  local advanced_progress, advanced = stage_progress.advance_if_needed(progress, config)
  if advanced then
    -- ステージ終端に達した場合は次のステージ情報へ切り替える。
    local next_ui = { mode = "move", event_id = nil }
    local refreshed = floor_state.refresh(advanced_progress, config)
    return util.merge_tables(state, { progress = refreshed, ui = util.merge_tables(state.ui, next_ui) })
  end
  local refreshed = floor_state.refresh(progress, config)
  local event = rules.find_event_by_distance(next_distance, refreshed)
  if event or rules.is_event_distance(next_distance, refreshed, config) then
    local ratio = state.actor.dialogue_ratio or 1
    local seconds = math.floor((config.dialogue_seconds or 60) * ratio)
    local event_id = event and event.id or nil
    if seconds <= 0 then
      -- 会話待機が0秒の場合は停止せずにメッセージだけ残す。
      local next_ui = { mode = "move", dialogue_remaining = 0, event_id = event_id }
      return util.merge_tables(state, { progress = refreshed, ui = util.merge_tables(state.ui, next_ui) })
    end
    local next_ui = { mode = "dialogue", dialogue_remaining = seconds, event_id = event_id }
    return util.merge_tables(state, { progress = refreshed, ui = util.merge_tables(state.ui, next_ui) })
  end
  if rules.should_start_boss(refreshed, config) then
    -- ボス階層では通常遭遇に優先してボス戦を開始する。
    local enemy = battle.build_enemy(next_distance, config)
    enemy.is_boss = true
    enemy.name = "boss"
    local boss_progress = floor_state.clear_boss_pending(refreshed)
    return start_battle(state, boss_progress, enemy)
  end
  if rules.should_start_floor_encounter(refreshed, config) then
    -- 階層内の遭遇を消費して戦闘へ切り替える。
    local encounter_progress = floor_state.consume_encounter(refreshed)
    local enemy = battle.build_enemy(next_distance, config)
    return start_battle(state, encounter_progress, enemy)
  end
  local floor_enabled = (config.floor_encounters or {}).enabled ~= false
  if not floor_enabled then
    local encounter_every = config.encounter_every or 0
    if encounter_every > 0 and next_distance > 0 and next_distance % encounter_every == 0 then
      local enemy = battle.build_enemy(next_distance, config)
      return start_battle(state, refreshed, enemy)
    end
  end
  return util.merge_tables(state, { progress = refreshed, ui = util.merge_tables(state.ui, { event_id = nil }) })
end
local function tick_dialogue(state, config)
  local tick_seconds = config.tick_seconds or 1
  local remaining = state.ui.dialogue_remaining - tick_seconds
  if remaining <= 0 then
    local next_ui = { mode = "move", dialogue_remaining = 0, event_id = nil }
    return util.merge_tables(state, { ui = util.merge_tables(state.ui, next_ui) })
  end
  return util.merge_tables(state, { ui = util.merge_tables(state.ui, { dialogue_remaining = remaining }) })
end
local function tick_battle(state, config)
  local enemy = state.combat.enemy
  local player_damage = battle.calc_damage(state.actor.atk, enemy.def or 0)
  local next_enemy_hp = enemy.hp - player_damage
  local next_actor_hp = state.actor.hp
  if next_enemy_hp > 0 then
    local enemy_damage = battle.calc_damage(enemy.atk, state.actor.def)
    next_actor_hp = state.actor.hp - enemy_damage
  end
  local next_actor = util.merge_tables(state.actor, { hp = math.max(0, next_actor_hp) })
  if next_enemy_hp <= 0 then
    local next_ui = { mode = "reward" }
    return util.merge_tables(state, { actor = next_actor, combat = { enemy = util.merge_tables(enemy, { hp = 0 }) }, ui = util.merge_tables(state.ui, next_ui) })
  end
  if next_actor_hp <= 0 then
    local next_ui = { mode = "defeat" }
    return util.merge_tables(state, { actor = next_actor, ui = util.merge_tables(state.ui, next_ui) })
  end
  return util.merge_tables(state, { actor = next_actor, combat = { enemy = util.merge_tables(enemy, { hp = next_enemy_hp }) } })
end
local function tick_reward(state, config)
  local reward_exp = (config.battle or {}).reward_exp or 0
  local reward_gold = (config.battle or {}).reward_gold or 0
  local leveled = player.add_exp(state.actor, reward_exp)
  local applied = player.apply_equipment(leveled, state.equipment, content.items)
  local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold + reward_gold })
  local next_state = util.merge_tables(state, { actor = applied, currency = next_currency, combat = nil })
  return util.merge_tables(next_state, { ui = util.merge_tables(state.ui, { mode = "move", event_id = nil }) })
end
local function tick_defeat(state, config)
  local progress = util.merge_tables(state.progress, { distance = state.progress.stage_start })
  -- 敗北時は階層の遭遇状態も初期化する。
  local refreshed = floor_state.refresh(progress, config)
  local actor = util.merge_tables(state.actor, { hp = state.actor.max_hp })
  local next_state = util.merge_tables(state, { progress = refreshed, actor = actor, combat = nil })
  return util.merge_tables(next_state, { ui = util.merge_tables(state.ui, { mode = "move", event_id = nil }) })
end
local function tick(state, config)
  if state.ui.mode == "move" then
    return tick_move(state, config)
  end
  if state.ui.mode == "dialogue" then
    return tick_dialogue(state, config)
  end
  if state.ui.mode == "battle" then
    return tick_battle(state, config)
  end
  if state.ui.mode == "reward" then
    return tick_reward(state, config)
  end
  if state.ui.mode == "defeat" then
    return tick_defeat(state, config)
  end
  return state
end
M.tick = tick
return M
