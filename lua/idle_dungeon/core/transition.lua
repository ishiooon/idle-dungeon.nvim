-- このモジュールは状態遷移の計算を純粋関数としてまとめる。
-- ゲーム進行の依存先はgame配下にまとめる。
local battle = require("idle_dungeon.game.battle")
-- 戦闘中の遷移は専用モジュールに委譲して整理する。
local battle_flow = require("idle_dungeon.core.transition.battle")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local event_catalog = require("idle_dungeon.game.event_catalog")
local event_choice = require("idle_dungeon.game.event_choice")
local event_effects = require("idle_dungeon.game.event_effects")
local floor_progress = require("idle_dungeon.game.floor.progress")
local floor_state = require("idle_dungeon.game.floor.state")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local story = require("idle_dungeon.game.story")
local state_dex = require("idle_dungeon.game.dex.state")
local stage_progress = require("idle_dungeon.game.stage_progress")
local rules = require("idle_dungeon.core.transition_rules")
local util = require("idle_dungeon.util")

local M = {}

-- ステージIDから該当ステージを取得する。
local function find_stage(config, stage_id)
  for _, stage in ipairs((config or {}).stages or {}) do
    if stage.id == stage_id then
      return stage
    end
  end
  return nil
end

-- ボスの敵情報をステージ設定と敵定義から解決する。
local function resolve_boss_spec(progress, config)
  local stage = find_stage(config, progress and progress.stage_id or nil)
  local boss_id = stage and stage.boss_id or "boss"
  local boss_data = enemy_catalog.find_enemy(boss_id) or {}
  local element = boss_data.element
  if not element and type(boss_data.elements) == "table" and #boss_data.elements > 0 then
    element = boss_data.elements[1]
  end
  return { id = boss_id, element = element or "dark", is_boss = true }
end

-- 戦闘開始時に図鑑へ記録し、戦闘状態へ切り替える。
local function start_battle(state, progress, enemy, enemy_spec)
  local next_ui = { mode = "battle", event_id = nil, battle_message = nil }
  local next_state = util.merge_tables(state, {
    progress = progress,
    ui = util.merge_tables(state.ui, next_ui),
  })
  -- 戦闘開始時は前回の戦闘状態を持ち越さないように初期化する。
  next_state.combat = { enemy = enemy, source = enemy_spec, last_turn = nil, turn = "hero", turn_wait = 0 }
  return state_dex.record_enemy(next_state, enemy.id or enemy.name, enemy.element)
end

-- ステージ開始のアスキーアートを表示する状態へ切り替える。
local function start_stage_intro(state, progress, event_id, config)
  local seconds = math.max(math.floor(config.stage_intro_seconds or 1), 0)
  local next_ui = { mode = "stage_intro", event_id = event_id, stage_intro_remaining = seconds, battle_message = nil }
  return util.merge_tables(state, { progress = progress, ui = util.merge_tables(state.ui, next_ui) })
end

-- 移動中の進行を計算して次状態へ進める。
local function tick_move(state, config)
  local intro_state, intro_event_id = story.apply_stage_intro(state, state.progress)
  -- 進行中の階層状態を確実に生成してから移動距離を計算する。
  local base_progress = floor_state.refresh(intro_state.progress, config)
  local base_state = intro_state
  if intro_event_id and (config.stage_intro_seconds or 0) > 0 then
    return start_stage_intro(base_state, base_progress, intro_event_id, config)
  end
  local move_step = config.move_step or 1
  local next_distance = base_progress.distance + move_step
  local floor_length = floor_progress.resolve_floor_length(config)
  local event_spec, event_distance = floor_state.find_event_in_path(base_progress, floor_length, base_progress.distance, next_distance)
  local encounter_gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
  local enemy_spec, enemy_distance = floor_state.find_enemy_in_path(base_progress, floor_length, base_progress.distance, next_distance, encounter_gap)
  if event_spec and (not enemy_distance or event_distance <= enemy_distance) then
    local event_data = event_catalog.find_event(event_spec.id)
    local progress_for_event = util.merge_tables(base_progress, { distance = event_distance or base_progress.distance })
    if event_choice.is_choice_event(event_data) then
      -- 選択イベントは移動を停止して選択待ちへ遷移する。
      local next_state = event_choice.start_choice(base_state, event_data, config)
      return util.merge_tables(next_state, { progress = progress_for_event })
    end
    local applied_state, next_seed = event_effects.apply_event(base_state, event_data, config, base_progress.rng_seed or 1)
    local marked_progress = floor_state.mark_event_resolved(progress_for_event)
    local next_progress = util.merge_tables(marked_progress, { rng_seed = next_seed })
    return util.merge_tables(applied_state, {
      progress = next_progress,
      ui = util.merge_tables(applied_state.ui, { mode = "move", event_id = nil, battle_message = nil }),
    })
  end
  if enemy_spec then
    -- 移動量が大きい場合でも敵に遭遇したら必ず戦闘を開始する。
    local progress_for_battle = util.merge_tables(base_progress, { distance = enemy_distance })
    local enemy = battle.build_enemy(enemy_distance, config, enemy_spec)
    return start_battle(base_state, progress_for_battle, enemy, enemy_spec)
  end
  local progress = util.merge_tables(base_progress, { distance = next_distance })
  local advanced_progress, advanced = stage_progress.advance_if_needed(progress, config)
  if advanced then
    -- ステージ終端に達した場合は次のステージ情報へ切り替える。
    local refreshed = floor_state.refresh(advanced_progress, config)
    local intro_state2, stage_intro_id = story.apply_stage_intro(base_state, refreshed)
    local next_unlocks = stage_unlock.unlock_next((base_state.unlocks or {}).stages, config.stages or {}, base_state.progress.stage_id)
    local merged_unlocks = util.merge_tables(intro_state2.unlocks or {}, { stages = next_unlocks })
    if stage_intro_id and (config.stage_intro_seconds or 0) > 0 then
      local staged = util.merge_tables(intro_state2, { unlocks = merged_unlocks })
      return start_stage_intro(staged, refreshed, stage_intro_id, config)
    end
    local next_ui = { mode = "move", event_id = nil, battle_message = nil }
    return util.merge_tables(intro_state2, { progress = refreshed, unlocks = merged_unlocks, ui = util.merge_tables(intro_state2.ui, next_ui) })
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
    local boss_spec = resolve_boss_spec(refreshed, config)
    local encounter_gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
    -- ボス戦も間合い分だけ手前で開始する。
    local boss_distance = math.max((refreshed.distance or next_distance) - (encounter_gap + 1), base_progress.distance)
    local enemy = battle.build_enemy(next_distance, config, boss_spec)
    local boss_progress = util.merge_tables(floor_state.clear_boss_pending(refreshed), { distance = boss_distance })
    return start_battle(base_state, boss_progress, enemy, boss_spec)
  end
  local floor_enabled = (config.floor_encounters or {}).enabled ~= false
  if not floor_enabled then
    local encounter_every = config.encounter_every or 0
    if encounter_every > 0 and next_distance > 0 and next_distance % encounter_every == 0 then
      local encounter_gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
      -- 一定距離遭遇でも間合い分の手前から戦闘開始する。
      local encounter_distance = math.max(next_distance - (encounter_gap + 1), base_progress.distance)
      local enemy = battle.build_enemy(next_distance, config)
      return start_battle(base_state, util.merge_tables(refreshed, { distance = encounter_distance }), enemy, nil)
    end
  end
  local final_event_id = intro_event_id
  return util.merge_tables(base_state, {
    progress = refreshed,
    ui = util.merge_tables(base_state.ui, { event_id = final_event_id, battle_message = nil }),
  })
end

-- ステージ開始演出の残り時間を減らす。
local function tick_stage_intro(state, config)
  local tick_seconds = config.tick_seconds or 1
  local remaining = (state.ui.stage_intro_remaining or 0) - tick_seconds
  if remaining <= 0 then
    local next_ui = { mode = "move", stage_intro_remaining = 0, event_id = nil }
    return util.merge_tables(state, { ui = util.merge_tables(state.ui, next_ui) })
  end
  return util.merge_tables(state, { ui = util.merge_tables(state.ui, { stage_intro_remaining = remaining }) })
end

-- 選択イベントの残り時間を減らし、期限切れなら自動選択する。
local function tick_choice(state, config)
  local tick_seconds = config.tick_seconds or 1
  local remaining = (state.ui.choice_remaining or 0) - tick_seconds
  if remaining > 0 then
    return util.merge_tables(state, { ui = util.merge_tables(state.ui, { choice_remaining = remaining }) })
  end
  -- 選択が行われなかった場合はランダムに決定する。
  local event = event_catalog.find_event(state.ui.event_id)
  if not event_choice.is_choice_event(event) then
    local next_ui = util.merge_tables(state.ui, { mode = "move", event_id = nil, choice_remaining = 0 })
    return util.merge_tables(state, { ui = next_ui })
  end
  return event_choice.apply_choice_event(state, event, config, nil)
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
  if state.ui.mode == "stage_intro" then
    return tick_stage_intro(state, config)
  end
  if state.ui.mode == "dialogue" then
    return tick_dialogue(state, config)
  end
  if state.ui.mode == "choice" then
    return tick_choice(state, config)
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
