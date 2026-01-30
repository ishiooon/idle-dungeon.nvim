-- このモジュールは購入と売却の処理をまとめる。
-- ショップの参照先はgameとmenuの領域へ整理する。
local content = require("idle_dungeon.content")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local menu_view = require("idle_dungeon.menu.view")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local M = {}

local function format_item_label(item, owned, unlocked, gold, lang)
  local status = unlocked and i18n.t("status_unlocked", lang) or i18n.t("status_locked", lang)
  local count = i18n.t("status_owned", lang) .. (owned or 0)
  local price = i18n.t("status_price", lang) .. item.price
  local afford = gold >= item.price and i18n.t("status_affordable", lang) or i18n.t("status_unaffordable", lang)
  return string.format("%s (%s %s %s %s)", item.name, status, count, price, afford)
end

local function is_item_unlocked(state, item_id)
  return (state.unlocks.items or {})[item_id] or (state.inventory or {})[item_id]
end

local function open_purchase_menu(get_state, set_state, lang, config)
  local state = get_state()
  local choices = {}
  for _, item in ipairs(content.items) do
    table.insert(choices, item)
  end
  -- 購入対象を選ぶための中央メニューを表示する。
  menu_view.select(choices, {
    prompt = i18n.t("prompt_purchase", lang),
    format_item = function(item)
      local owned = state.inventory[item.id] or 0
      local unlocked = is_item_unlocked(state, item.id)
      return format_item_label(item, owned, unlocked, state.currency.gold, lang)
    end,
  }, function(item)
    if not item then
      return
    end
    if not is_item_unlocked(state, item.id) then
      return
    end
    if state.currency.gold < item.price then
      return
    end
    local next_inventory = inventory.add_item(state.inventory, item.id, 1)
    local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold - item.price })
    local next_state = state_module.with_inventory(state_module.with_currency(state, next_currency), next_inventory)
    -- 購入した装備を図鑑へ記録する。
    set_state(state_dex.record_item(next_state, item.id, 1))
  end, config)
end

local function open_sell_menu(get_state, set_state, lang, config)
  local state = get_state()
  local choices = {}
  for _, item in ipairs(content.items) do
    local owned = state.inventory[item.id] or 0
    if owned > 0 and state.equipment[item.slot] ~= item.id then
      table.insert(choices, item)
    end
  end
  -- 売却対象を選ぶための中央メニューを表示する。
  menu_view.select(choices, {
    prompt = i18n.t("prompt_sell", lang),
    format_item = function(item)
      return string.format("%s (%s%d)", item.name, i18n.t("status_owned", lang), state.inventory[item.id] or 0)
    end,
  }, function(item)
    if not item then
      return
    end
    local next_inventory = inventory.remove_item(state.inventory, item.id, 1)
    local price = math.floor(item.price * 0.5)
    local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold + price })
    local next_state = state_module.with_inventory(state_module.with_currency(state, next_currency), next_inventory)
    set_state(next_state)
  end, config)
end

M.open_purchase_menu = open_purchase_menu
M.open_sell_menu = open_sell_menu

return M
