-- このモジュールは状態構造と遷移を純粋関数として定義する。
-- 参照先は新しい関心領域の階層に合わせて整理する。
local content = require("idle_dungeon.content")
-- 階層内の遭遇状態はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local helpers = require("idle_dungeon.core.state_helpers")
local inventory = require("idle_dungeon.game.inventory")
local metrics = require("idle_dungeon.game.metrics")
local pets = require("idle_dungeon.game.pets")
local player = require("idle_dungeon.game.player")
local skills = require("idle_dungeon.game.skills")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local state_dex = require("idle_dungeon.game.dex.state")
local transition = require("idle_dungeon.core.transition")
local util = require("idle_dungeon.util")
local M = {}
local function new_state(config)
  local stage = (config.stages or {})[1] or { id = 1, name = config.stage_name or "dungeon1-1", start = 0 }
  -- 既定ジョブを基準に初期能力値と装備を構築する。
  local job = helpers.find_job(config.default_job_id)
  local hero_progress = player.default_progress()
  local job_levels = {}
  for _, entry in ipairs(content.jobs or {}) do
    job_levels[entry.id] = player.default_progress()
  end
  local job_progress = job_levels[job.id] or player.default_progress()
  local actor = player.new_actor(job, hero_progress, job_progress)
  -- 開始ジョブのスキルを解放状態に反映する。
  local learned_skills = skills.unlock_from_job(skills.empty(), job, job_progress)
  local skill_settings = skills.ensure_enabled(nil, learned_skills)
  local equipment = helpers.ensure_equipment(job.starter_items)
  local inventory_items = inventory.new_inventory(job.starter_items)
  local applied_actor = player.apply_equipment(actor, equipment, content.items)
  local base_state = {
    -- 進行中ステージの情報とボス節目を保持する。
    progress = {
      stage_id = stage.id,
      stage_name = stage.name,
      distance = stage.start,
      stage_start = stage.start,
      stage_infinite = stage.infinite or false,
      boss_every = stage.boss_every or config.boss_every,
      boss_milestones = stage.boss_milestones or {},
    },
    actor = applied_actor,
    equipment = equipment,
    inventory = inventory_items,
    currency = { gold = 0 },
    combat = nil,
    -- 戦闘に参加する保持中ペットを管理する。
    pet_party = {},
    -- ジョブごとの成長を保持する。
    job_levels = job_levels,
    skills = learned_skills,
    skill_settings = skill_settings,
    ui = {
      mode = "move",
      dialogue_remaining = 0,
      render_mode = (config.ui or {}).render_mode or "visual",
      auto_start = (config.ui or {}).auto_start ~= false,
      language = (config.ui or {}).language or "en",
      -- 右下表示の行数は設定値を初期値として保持する。
      display_lines = (config.ui or {}).height or 2,
      -- 戦闘時のHP分母表示は設定値を初期値として保持する。
      battle_hp_show_max = (config.ui or {}).battle_hp_show_max == true,
      event_id = nil,
      battle_message = nil,
      stage_intro_remaining = 0,
      event_message = nil,
      event_message_remaining = 0,
      -- 選択イベントの残り秒数を保持する。
      choice_remaining = 0,
      speed_boost = nil,
    },
    metrics = metrics.new_metrics(),
    unlocks = {
      items = {},
      titles = {},
      -- ジョブ解放は拡張予定のため枠だけ用意する。
      jobs = {},
      -- ステージ解放の状態を保持する。
      stages = stage_unlock.initial_unlocks(config.stages or {}),
    },
    -- ストーリー表示の既読状態を保持する。
    story = { stage_intro = {} },
  }
  -- 初期階層の遭遇状態を反映して返す。
  local with_floor = util.merge_tables(base_state, { progress = floor_state.refresh(base_state.progress, config) })
  -- 初期所持品を図鑑へ反映して返す。
  return state_dex.apply_inventory_initial(with_floor, inventory_items)
end
local function reset_state(config)
  -- 状態を初期化して最初からの進行に戻す。
  return new_state(config)
end
local function normalize_state(state)
  if not state then
    return state
  end
  local unlocks = state.unlocks or {}
  local next_state = state
  if unlocks.characters and not unlocks.jobs then
    -- 旧キャラクター解放情報はジョブ解放へ移し替える。
    local next_unlocks = util.shallow_copy(unlocks)
    next_unlocks.jobs = next_unlocks.characters
    next_unlocks.characters = nil
    next_state = util.merge_tables(state, { unlocks = next_unlocks })
  end
  local job_levels = util.merge_tables(next_state.job_levels or {}, {})
  for _, job in ipairs(content.jobs or {}) do
    if not job_levels[job.id] then
      job_levels[job.id] = player.default_progress()
    end
  end
  local actor = next_state.actor or {}
  local job_id = actor.id
  local job = job_id and helpers.find_job(job_id) or helpers.find_job(nil)
  local hero_progress = {
    level = actor.level or 1,
    exp = actor.exp or 0,
    next_level = actor.next_level or 10,
  }
  local job_progress = job_levels[job.id] or player.default_progress()
  if actor.job_level or actor.job_exp or actor.job_next_level then
    -- 旧保存でジョブ進行がactor側にある場合は取り込む。
    job_progress = {
      level = actor.job_level or job_progress.level,
      exp = actor.job_exp or job_progress.exp,
      next_level = actor.job_next_level or job_progress.next_level,
    }
  end
  job_levels[job.id] = job_progress
  local rebuilt_actor = player.new_actor(job, hero_progress, job_progress, actor.hp)
  local applied_actor = player.apply_equipment(rebuilt_actor, next_state.equipment or {}, content.items)
  local learned_skills = next_state.skills and skills.normalize(next_state.skills)
    or skills.unlock_from_job(skills.empty(), job, job_progress)
  local skill_settings = skills.ensure_enabled(next_state.skill_settings, learned_skills)
  local normalized = util.merge_tables(next_state, {
    job_levels = job_levels,
    actor = applied_actor,
    skills = learned_skills,
    skill_settings = skill_settings,
  })
  -- 旧データ互換のためペット保持情報も正規化する。
  return pets.enforce_capacity(normalized, content.jobs, content.items, nil)
end
local function set_render_mode(state, mode)
  return helpers.update_section(state, "ui", { render_mode = mode })
end
local function toggle_render_mode(state)
  local next_mode = state.ui.render_mode == "visual" and "text" or "visual"
  return set_render_mode(state, next_mode)
end
local function set_language(state, language)
  return helpers.update_section(state, "ui", { language = language })
end
local function set_auto_start(state, auto_start)
  return helpers.update_section(state, "ui", { auto_start = auto_start })
end
local function set_display_lines(state, lines)
  local next_lines = math.max(math.min(tonumber(lines) or 2, 2), 0)
  return helpers.update_section(state, "ui", { display_lines = next_lines })
end
local function set_battle_hp_show_max(state, enabled)
  local next_enabled = enabled == true
  return helpers.update_section(state, "ui", { battle_hp_show_max = next_enabled })
end
local function set_ui_mode(state, mode, updates)
  return helpers.update_section(helpers.update_section(state, "ui", { mode = mode }), "ui", updates or {})
end
local function with_metrics(state, next_metrics)
  return util.merge_tables(state, { metrics = next_metrics })
end
local function with_unlocks(state, next_unlocks)
  return util.merge_tables(state, { unlocks = next_unlocks })
end
local function with_currency(state, next_currency)
  return util.merge_tables(state, { currency = next_currency })
end
local function with_equipment(state, next_equipment)
  return util.merge_tables(state, { equipment = next_equipment })
end
local function with_inventory(state, next_inventory)
  return util.merge_tables(state, { inventory = next_inventory })
end
local function with_actor(state, next_actor)
  return util.merge_tables(state, { actor = next_actor })
end

-- 一時的なUI効果の残り時間を進める。
local function apply_ui_timers(state)
  local ui = state.ui or {}
  local updated = {}
  local changed = false
  if ui.event_message_remaining and ui.event_message_remaining > 0 then
    local next_remaining = ui.event_message_remaining - 1
    updated.event_message_remaining = math.max(next_remaining, 0)
    if next_remaining <= 0 then
      updated.event_message = nil
    end
    changed = true
  end
  if ui.speed_boost and ui.speed_boost.remaining_ticks and ui.speed_boost.remaining_ticks > 0 then
    local next_ticks = ui.speed_boost.remaining_ticks - 1
    if next_ticks <= 0 then
      updated.speed_boost = nil
    else
      updated.speed_boost = util.merge_tables(ui.speed_boost, { remaining_ticks = next_ticks })
    end
    changed = true
  end
  if not changed then
    return state
  end
  return util.merge_tables(state, { ui = util.merge_tables(ui, updated) })
end
local function tick(state, config)
  local next_state = transition.tick(state, config)
  local applied = apply_ui_timers(next_state)
  -- スキル切り替え後も保持上限を常に満たすよう補正する。
  return pets.enforce_capacity(applied, content.jobs, content.items, ((config.ui or {}).icons or {}).companion)
end
local function change_job(state, job_id)
  local job = helpers.find_job(job_id)
  local hero_progress = {
    level = (state.actor and state.actor.level) or 1,
    exp = (state.actor and state.actor.exp) or 0,
    next_level = (state.actor and state.actor.next_level) or 10,
  }
  local job_levels = util.merge_tables(state.job_levels or {}, {})
  local job_progress = job_levels[job.id] or player.default_progress()
  if not job_levels[job.id] then
    -- 未登録のジョブは初期進行度を追加する。
    job_levels[job.id] = job_progress
  end
  local actor = player.new_actor(job, hero_progress, job_progress, state.actor and state.actor.hp)
  local learned_skills = skills.unlock_from_job(state.skills or skills.empty(), job, job_progress)
  local skill_settings = skills.ensure_enabled(state.skill_settings, learned_skills)
  local next_equipment = util.merge_tables(state.equipment, {})
  local next_inventory = util.merge_tables(state.inventory, {})
  for slot, item_id in pairs(job.starter_items or {}) do
    if not next_equipment[slot] then
      next_equipment[slot] = item_id
    end
    if not inventory.has_item(next_inventory, item_id) then
      next_inventory = inventory.add_item(next_inventory, item_id, 1)
    end
  end
  local applied = player.apply_equipment(actor, next_equipment, content.items)
  local next_state = util.merge_tables(state, {
    actor = applied,
    equipment = next_equipment,
    inventory = next_inventory,
    job_levels = job_levels,
    skills = learned_skills,
    skill_settings = skill_settings,
  })
  -- ジョブ変更で保持上限が変わるため保持ペット数を補正する。
  local adjusted = pets.enforce_capacity(next_state, content.jobs, content.items, nil)
  -- 新たに追加された所持品だけ図鑑へ記録する。
  return state_dex.apply_inventory_delta(adjusted, state.inventory, next_inventory)
end

M.new_state = new_state
M.reset_state = reset_state
M.normalize_state = normalize_state
M.set_render_mode = set_render_mode
M.toggle_render_mode = toggle_render_mode
M.set_language = set_language
M.set_auto_start = set_auto_start
M.set_display_lines = set_display_lines
M.set_battle_hp_show_max = set_battle_hp_show_max
M.set_ui_mode = set_ui_mode
M.with_metrics = with_metrics
M.with_unlocks = with_unlocks
M.with_currency = with_currency
M.with_equipment = with_equipment
M.with_inventory = with_inventory
M.with_actor = with_actor
M.tick = tick
M.change_job = change_job

return M
