-- このモジュールは状態構造と遷移を純粋関数として定義する。
-- 参照先は新しい関心領域の階層に合わせて整理する。
local content = require("idle_dungeon.content")
-- 階層内の遭遇状態はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local helpers = require("idle_dungeon.core.state_helpers")
local inventory = require("idle_dungeon.game.inventory")
local metrics = require("idle_dungeon.game.metrics")
local player = require("idle_dungeon.game.player")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local state_dex = require("idle_dungeon.game.dex.state")
local transition = require("idle_dungeon.core.transition")
local util = require("idle_dungeon.util")
local M = {}
local function new_state(config)
  local stage = (config.stages or {})[1] or { id = 1, name = config.stage_name or "dungeon1-1", start = 0 }
  local character = helpers.find_character(config.default_character_id)
  local actor = player.new_actor(character)
  local equipment = helpers.ensure_equipment(character.starter_items)
  local inventory_items = inventory.new_inventory(character.starter_items)
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
    ui = {
      mode = "move",
      dialogue_remaining = 0,
      render_mode = (config.ui or {}).render_mode or "visual",
      auto_start = (config.ui or {}).auto_start ~= false,
      language = (config.ui or {}).language or "en",
      event_id = nil,
      battle_message = nil,
    },
    metrics = metrics.new_metrics(),
    unlocks = {
      items = {},
      titles = {},
      characters = {},
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
local function tick(state, config)
  return transition.tick(state, config)
end
local function change_character(state, character_id)
  local character = helpers.find_character(character_id)
  local actor = player.new_actor(character)
  local leveled = player.apply_level(actor, state.actor.level, state.actor.exp, state.actor.next_level)
  local next_equipment = util.merge_tables(state.equipment, {})
  local next_inventory = util.merge_tables(state.inventory, {})
  for slot, item_id in pairs(character.starter_items or {}) do
    if not next_equipment[slot] then
      next_equipment[slot] = item_id
    end
    if not inventory.has_item(next_inventory, item_id) then
      next_inventory = inventory.add_item(next_inventory, item_id, 1)
    end
  end
  local applied = player.apply_equipment(leveled, next_equipment, content.items)
  local next_state = util.merge_tables(state, { actor = applied, equipment = next_equipment, inventory = next_inventory })
  -- 新たに追加された所持品だけ図鑑へ記録する。
  return state_dex.apply_inventory_delta(next_state, state.inventory, next_inventory)
end

M.new_state = new_state
M.reset_state = reset_state
M.set_render_mode = set_render_mode
M.toggle_render_mode = toggle_render_mode
M.set_language = set_language
M.set_auto_start = set_auto_start
M.set_ui_mode = set_ui_mode
M.with_metrics = with_metrics
M.with_unlocks = with_unlocks
M.with_currency = with_currency
M.with_equipment = with_equipment
M.with_inventory = with_inventory
M.with_actor = with_actor
M.tick = tick
M.change_character = change_character

return M
