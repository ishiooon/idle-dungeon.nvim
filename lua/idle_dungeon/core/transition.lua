-- このモジュールは状態遷移の計算を純粋関数としてまとめる。
-- ゲーム進行の依存先はgame配下にまとめる。
local battle = require("idle_dungeon.game.battle")
-- 戦闘中の遷移は専用モジュールに委譲して整理する。
local battle_flow = require("idle_dungeon.core.transition.battle")
local floor_progress = require("idle_dungeon.game.floor.progress")
local floor_state = require("idle_dungeon.game.floor.state")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local story = require("idle_dungeon.game.story")
local state_dex = require("idle_dungeon.game.dex.state")
local stage_progress = require("idle_dungeon.game.stage_progress")
local rules = require("idle_dungeon.core.transition_rules")
local util = require("idle_dungeon.util")

local M = {}

-- 戦闘開始時に図鑑へ記録し、戦闘状態へ切り替える。
local function start_battle(state, progress, enemy, enemy_spec)
  local next_ui = { mode = "battle", event_id = nil, battle_message = nil }
  local next_state = util.merge_tables(state, {
    progress = progress,
    ui = util.merge_tables(state.ui, next_ui),
    combat = { enemy = enemy, source = enemy_spec, last_turn = nil },
  })
  return state_dex.record_enemy(next_state, enemy.id or enemy.name, enemy.element)
end

-- 移動中の進行を計算して次状態へ進める。
local function tick_move(state, config)
  local intro_state, intro_event_id = story.apply_stage_intro(state, state.progress)
  local base_state = intro_state
  local move_step = config.move_step or 1
  local next_distance = base_state.progress.distance + move_step
  local progress = util.merge_tables(base_state.progress, { distance = next_distance })
  local advanced_progress, advanced = stage_progress.advance_if_needed(progress, config)
  if advanced then
    -- ステージ終端に達した場合は次のステージ情報へ切り替える。
    local refreshed = floor_state.refresh(advanced_progress, config)
    local intro_state2, stage_intro_id = story.apply_stage_intro(base_state, refreshed)
    local next_unlocks = stage_unlock.unlock_next((base_state.unlocks or {}).stages, config.stages or {}, base_state.progress.stage_id)
    local merged_unlocks = util.merge_tables(intro_state2.unlocks or {}, { stages = next_unlocks })
    local next_ui = { mode = "move", event_id = stage_intro_id, battle_message = nil }
    return util.merge_tables(intro_state2, {
      progress = refreshed,
      unlocks = merged_unlocks,
      ui = util.merge_tables(intro_state2.ui, next_ui),
    })
  end
  local refreshed = floor_state.refresh(progress, config)
  local event = rules.find_event_by_distance(next_distance, refreshed)
  if event or rules.is_event_distance(next_distance, refreshed, config) then
    local ratio = base_state.actor.dialogue_ratio or 1
    local seconds = math.floor((config.dialogue_seconds or 60) * ratio)
    local event_id = intro_event_id or (event and event.id or nil)
    if seconds <= 0 then
      -- 会話待機が0秒の場合は停止せずにメッセージだけ残す。
      local next_ui = { mode = "move", dialogue_remaining = 0, event_id = event_id }
      return util.merge_tables(base_state, { progress = refreshed, ui = util.merge_tables(base_state.ui, next_ui) })
    end
    local next_ui = { mode = "dialogue", dialogue_remaining = seconds, event_id = event_id }
    return util.merge_tables(base_state, { progress = refreshed, ui = util.merge_tables(base_state.ui, next_ui) })
  end
  if rules.should_start_boss(refreshed, config) then
    -- ボス階層では通常遭遇に優先してボス戦を開始する。
    local enemy = battle.build_enemy(next_distance, config, { id = "boss", element = "dark", is_boss = true })
    enemy.name = "Boss"
    local boss_progress = floor_state.clear_boss_pending(refreshed)
    return start_battle(base_state, boss_progress, enemy, { id = enemy.id, element = enemy.element, is_boss = true })
  end
  local floor_length = floor_progress.resolve_floor_length(config)
  local floor_step = floor_progress.floor_step(next_distance, floor_length)
  local enemy_spec = floor_state.find_enemy_ahead(refreshed, floor_step)
  if enemy_spec then
    -- 階層内の敵が目前に来たら戦闘へ切り替える。
    local enemy = battle.build_enemy(next_distance, config, enemy_spec)
    return start_battle(base_state, refreshed, enemy, enemy_spec)
  end
  local floor_enabled = (config.floor_encounters or {}).enabled ~= false
  if not floor_enabled then
    local encounter_every = config.encounter_every or 0
    if encounter_every > 0 and next_distance > 0 and next_distance % encounter_every == 0 then
      local enemy = battle.build_enemy(next_distance, config)
      return start_battle(base_state, refreshed, enemy, nil)
    end
  end
  local final_event_id = intro_event_id
  return util.merge_tables(base_state, {
    progress = refreshed,
    ui = util.merge_tables(base_state.ui, { event_id = final_event_id, battle_message = nil }),
  })
end

-- 会話待機中の残り時間を減らす。
local function tick_dialogue(state, config)
  local tick_seconds = config.tick_seconds or 1
  local remaining = state.ui.dialogue_remaining - tick_seconds
  if remaining <= 0 then
    local next_ui = { mode = "move", dialogue_remaining = 0, event_id = nil }
    return util.merge_tables(state, { ui = util.merge_tables(state.ui, next_ui) })
  end
  return util.merge_tables(state, { ui = util.merge_tables(state.ui, { dialogue_remaining = remaining }) })
end

-- 状態に応じた進行処理を振り分ける。
local function tick(state, config)
  if state.ui.mode == "move" then
    return tick_move(state, config)
  end
  if state.ui.mode == "dialogue" then
    return tick_dialogue(state, config)
  end
  if state.ui.mode == "battle" then
    return battle_flow.tick_battle(state, config)
  end
  if state.ui.mode == "reward" then
    return battle_flow.tick_reward(state, config)
  end
  if state.ui.mode == "defeat" then
    return battle_flow.tick_defeat(state, config)
  end
  return state
end

M.tick = tick

return M
