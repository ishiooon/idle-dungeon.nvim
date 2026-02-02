-- このモジュールはメニュー内の個別操作をまとめる。
-- メニュー操作に必要な参照先を関心ごとに整理する。
local content = require("idle_dungeon.content")
-- 階層状態の再計算はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_view = require("idle_dungeon.menu.view")
local player = require("idle_dungeon.game.player")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local M = {}

-- 設定系の操作は別モジュールへ委譲する。
local function apply_equipment(state, slot, item_id)
  local next_equipment = util.merge_tables(state.equipment, { [slot] = item_id })
  local next_actor = player.apply_equipment(state.actor, next_equipment, content.items)
  return state_module.with_actor(state_module.with_equipment(state, next_equipment), next_actor)
end

local function open_character_menu(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local entries = {}
  for _, character in ipairs(content.characters) do
    table.insert(entries, character)
  end
  -- キャラクター選択のメニューを表示する。
  menu_view.select(entries, {
    prompt = i18n.t("prompt_character", lang),
    format_item = function(item)
      return string.format("%s (%s)", item.name, item.role)
    end,
  }, function(choice)
    if not choice then
      return
    end
    local next_state = state_module.change_character(get_state(), choice.id)
    set_state(next_state)
  end, config)
end

local function open_stage_menu(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local entries = config.stages or {}
  local initial_state = get_state()
  local unlocks = (initial_state.unlocks or {}).stages or {}
  local first_stage = (config.stages or {})[1]
  -- 開始ダンジョンを選択するためのメニューを表示する。
  menu_view.select(entries, {
    prompt = i18n.t("prompt_stage", lang),
    format_item = function(item)
      local unlocked = stage_unlock.is_unlocked(unlocks, item.id)
        or item.id == (initial_state.progress or {}).stage_id
        or (first_stage and item.id == first_stage.id)
      local label = unlocked and i18n.t("status_unlocked", lang) or i18n.t("status_locked", lang)
      return string.format("%s [%s]", item.name, label)
    end,
  }, function(choice)
    if not choice then
      return
    end
    local current = get_state()
    local current_unlocks = (current.unlocks or {}).stages or {}
    local is_current = choice.id == (current.progress or {}).stage_id
    local is_first = first_stage and choice.id == first_stage.id
    if not (stage_unlock.is_unlocked(current_unlocks, choice.id) or is_current or is_first) then
      return
    end
    local progress = util.merge_tables(current.progress, {
      stage_id = choice.id,
      stage_name = choice.name,
      distance = choice.start,
      stage_start = choice.start,
      stage_infinite = choice.infinite or false,
      boss_every = choice.boss_every or config.boss_every,
      boss_milestones = choice.boss_milestones or {},
    })
    -- 開始階層の遭遇状態を再計算して反映する。
    local refreshed = floor_state.refresh(progress, config)
    set_state(util.merge_tables(current, { progress = refreshed }))
  end, config)
end

local function open_equip_menu(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local slots = { "weapon", "armor", "accessory", "companion" }
  -- 装備枠を選択するためのメニューを表示する。
  menu_view.select(slots, {
    prompt = i18n.t("prompt_slot", lang),
    format_item = function(item)
      return menu_locale.slot_label(item, lang)
    end,
  }, function(slot)
    if not slot then
      return
    end
    local state = get_state()
    local choices = {}
    for _, item in ipairs(content.items) do
      if item.slot == slot and inventory.has_item(state.inventory, item.id) then
        table.insert(choices, item)
      end
    end
    -- 選択可能な装備を表示する。
    menu_view.select(choices, {
      prompt = i18n.t("prompt_equipment", lang),
      format_item = function(item)
        return item.name
      end,
    }, function(item)
      if not item then
        return
      end
      local next_state = apply_equipment(state, slot, item.id)
      set_state(next_state)
    end, config)
  end, config)
end

M.open_character_menu = open_character_menu
M.open_stage_menu = open_stage_menu
M.open_equip_menu = open_equip_menu

return M
