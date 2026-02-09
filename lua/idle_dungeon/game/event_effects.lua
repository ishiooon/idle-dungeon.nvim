-- このモジュールはイベント効果の適用を純粋関数として提供する。

local inventory = require("idle_dungeon.game.inventory")
local pets = require("idle_dungeon.game.pets")
local state_dex = require("idle_dungeon.game.dex.state")
local util = require("idle_dungeon.util")
local rng = require("idle_dungeon.rng")
local content = require("idle_dungeon.content")

local M = {}

local function resolve_lang(state, config)
  return (state.ui and state.ui.language) or (config.ui or {}).language or "en"
end

local function resolve_text(value, lang)
  if type(value) == "table" then
    return value[lang] or value.en or value.ja or ""
  end
  return value or ""
end

local function build_message(event, state, config)
  local lang = resolve_lang(state, config)
  local text = resolve_text(event and event.message, lang)
  if text ~= "" then
    return text
  end
  return resolve_text(event and event.title, lang)
end

local function set_event_message(state, message, config)
  if not message or message == "" then
    return state
  end
  local ticks = math.max(tonumber(config.event_message_ticks) or 2, 1)
  local next_ui = util.merge_tables(state.ui or {}, { event_message = message, event_message_remaining = ticks })
  return util.merge_tables(state, { ui = next_ui })
end

local function resolve_amount(effect, seed)
  if effect.amount then
    return effect.amount, seed
  end
  if effect.min or effect.max then
    local min_value = tonumber(effect.min) or 0
    local max_value = tonumber(effect.max) or min_value
    return rng.next_int(seed or 1, min_value, max_value)
  end
  return 0, seed
end

local function apply_heal(state, effect, seed)
  local amount
  amount, seed = resolve_amount(effect or {}, seed)
  local current = state.actor.hp or 0
  local max_hp = state.actor.max_hp or current
  local next_actor = util.merge_tables(state.actor, { hp = math.min(current + amount, max_hp) })
  return util.merge_tables(state, { actor = next_actor }), seed
end

local function apply_damage(state, effect, seed)
  local amount
  amount, seed = resolve_amount(effect or {}, seed)
  local current = state.actor.hp or 0
  local next_actor = util.merge_tables(state.actor, { hp = math.max(current - amount, 0) })
  return util.merge_tables(state, { actor = next_actor }), seed
end

local function apply_speed(state, effect)
  local duration = math.max(tonumber(effect.duration_ticks) or 3, 1)
  local tick_seconds = tonumber(effect.tick_seconds) or nil
  local boost = {
    remaining_ticks = duration,
    tick_seconds = tick_seconds,
  }
  local next_ui = util.merge_tables(state.ui or {}, { speed_boost = boost })
  return util.merge_tables(state, { ui = next_ui })
end

local function apply_item(state, effect)
  local item_id = effect.item_id
  if not item_id or item_id == "" then
    return state
  end
  local next_inventory = inventory.add_item(state.inventory, item_id, 1)
  local next_state = util.merge_tables(state, { inventory = next_inventory })
  return state_dex.record_item(next_state, item_id, 1)
end

local function apply_pet(state, effect, config)
  local item_id = effect.item_id
  if not item_id or item_id == "" then
    return state
  end
  local companion_icon = ((config.ui or {}).icons or {}).companion
  local next_state = pets.add_pet(state, item_id, content.enemies, content.jobs, companion_icon)
  return state_dex.record_item(next_state, item_id, 1)
end

local function apply_effect(state, effect, config, seed)
  local kind = effect and effect.kind or ""
  if kind == "heal" then
    return apply_heal(state, effect, seed)
  end
  if kind == "damage" then
    return apply_damage(state, effect, seed)
  end
  if kind == "speed" then
    return apply_speed(state, effect), seed
  end
  if kind == "item" then
    return apply_item(state, effect), seed
  end
  if kind == "pet" then
    return apply_pet(state, effect, config), seed
  end
  return state, seed
end

-- イベント効果を適用し、メッセージ表示も更新する。
local function apply_event(state, event, config, seed)
  local message = build_message(event, state, config)
  local next_state, next_seed = state, seed
  if event and event.effect then
    next_state, next_seed = apply_effect(next_state, event.effect, config, next_seed)
  end
  if event and event.effects then
    for _, effect in ipairs(event.effects) do
      next_state, next_seed = apply_effect(next_state, effect, config, next_seed)
    end
  end
  next_state = set_event_message(next_state, message, config)
  return next_state, next_seed
end

M.apply_event = apply_event

return M
