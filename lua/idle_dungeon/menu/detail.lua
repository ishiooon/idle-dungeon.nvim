-- このモジュールはメニュー右側に表示する詳細情報を整形する。

local element = require("idle_dungeon.game.element")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")

local M = {}

local function rarity_label(rarity, lang)
  if rarity == "rare" then
    return i18n.t("dex_rarity_rare", lang)
  end
  if rarity == "pet" then
    return i18n.t("dex_rarity_pet", lang)
  end
  return i18n.t("dex_rarity_common", lang)
end

-- 装備の詳細情報を行配列で返す。
local function build_item_detail(item, state, lang)
  if not item then
    return nil
  end
  local lines = {}
  local name_label = i18n.t("dex_detail_name", lang)
  local slot_label = i18n.t("dex_detail_slot", lang)
  local rarity_text = i18n.t("dex_detail_rarity", lang)
  local count_label = i18n.t("status_owned", lang)
  local price_label = i18n.t("status_price", lang)
  local element_label = i18n.t("dex_detail_element", lang)
  local flavor_label = i18n.t("dex_detail_flavor", lang)
  local owned = state and state.inventory and state.inventory[item.id] or 0
  table.insert(lines, string.format("%s %s", name_label, item.name or ""))
  table.insert(lines, string.format("%s %s", slot_label, menu_locale.slot_label(item.slot, lang)))
  table.insert(lines, string.format("%s %s", rarity_text, rarity_label(item.rarity, lang)))
  table.insert(lines, string.format("%s %d", count_label, owned))
  if item.price then
    table.insert(lines, string.format("%s %d", price_label, item.price))
  end
  if item.element then
    table.insert(lines, string.format("%s %s", element_label, element.label(item.element, lang)))
  end
  if item.hp and item.hp > 0 then
    table.insert(lines, string.format("%s %d", i18n.t("label_hp", lang), item.hp))
  end
  if item.atk and item.atk > 0 then
    table.insert(lines, string.format("%s %d", i18n.t("label_atk", lang), item.atk))
  end
  if item.def and item.def > 0 then
    table.insert(lines, string.format("%s %d", i18n.t("label_def", lang), item.def))
  end
  if item.flavor then
    local flavor = type(item.flavor) == "table" and (item.flavor[lang] or item.flavor.en or item.flavor.ja) or item.flavor
    if flavor and flavor ~= "" then
      table.insert(lines, string.format("%s %s", flavor_label, flavor))
    end
  end
  return { title = item.name or "", lines = lines }
end

M.build_item_detail = build_item_detail

return M
