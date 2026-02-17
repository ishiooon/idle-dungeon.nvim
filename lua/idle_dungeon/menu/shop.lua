-- このモジュールは購入と売却の処理をまとめる。
-- ショップの参照先はgameとmenuの領域へ整理する。
local content = require("idle_dungeon.content")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_logging = require("idle_dungeon.menu.logging")
local menu_unlock = require("idle_dungeon.menu.unlock")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")
local icon_module = require("idle_dungeon.ui.icon")
local util = require("idle_dungeon.util")

local M = {}

-- 購入メニューのカテゴリは装備スロット順で統一する。
local PURCHASE_SLOTS = { "weapon", "armor", "accessory" }

-- 未解放装備の詳細表示は共通の解放条件表示で統一する。
local function build_locked_detail(item, state, config, lang)
  local lines = menu_unlock.build_unlock_section(item, state, config, lang)
  return { title = i18n.t("dex_unknown", lang), lines = lines }
end

local function format_item_label(item, owned, unlocked, gold, lang, icon)
  local name = unlocked and (item.name or "") or i18n.t("dex_unknown", lang)
  if icon and icon ~= "" then
    name = string.format("%s %s", icon, name)
  end
  local marker = unlocked and "✓" or "?"
  local price_value = unlocked and (item.price or 0) or i18n.t("dex_unknown", lang)
  local afford = unlocked and "✗" or " "
  if unlocked then
    local current_gold = gold or 0
    afford = current_gold >= (item.price or 0) and "✓" or "✗"
  end
  return string.format("%s %-32s x%-3d $%-6s %s", marker, name, owned or 0, tostring(price_value), afford)
end

-- 購入画面の見出しに現在の所持金を含める。
local function build_gold_prompt(base_label, state, lang)
  local gold_label = i18n.t("label_gold", lang)
  local gold = (state.currency or {}).gold or 0
  return string.format("%s (%s %d)", base_label, gold_label, gold)
end

-- 通常装備は常時購入可能にし、レア以上は解錠で購入できるようにする。
local function is_item_unlocked(state, item)
  if not item then
    return false
  end
  if item.rarity == "common" or item.rarity == nil then
    return true
  end
  local item_id = item.id
  local unlocks = (state and state.unlocks) or {}
  local unlocked = (unlocks.items or {})[item_id] ~= nil
  local owned = ((state and state.inventory) or {})[item_id] ~= nil
  return unlocked or owned
end

-- 装備をスロット単位で抽出して価格順に整列する。
local function filter_items_by_slot(items, slot)
  local result = {}
  for _, item in ipairs(items or {}) do
    if item.slot == slot then
      table.insert(result, item)
    end
  end
  table.sort(result, function(a, b)
    local price_a = tonumber(a.price) or 0
    local price_b = tonumber(b.price) or 0
    if price_a == price_b then
      return (a.name or "") < (b.name or "")
    end
    return price_a < price_b
  end)
  return result
end

-- 購入カテゴリの表示名をスロットから組み立てる。
local function build_purchase_categories(lang)
  local categories = {}
  for _, slot in ipairs(PURCHASE_SLOTS) do
    table.insert(categories, { id = slot, label = menu_locale.slot_label(slot, lang) })
  end
  return categories
end

-- 購入詳細は未解放時に条件表示へ切り替える。
local function build_purchase_detail(menu_detail, item, state, config, lang)
  if not item then
    return nil
  end
  if not is_item_unlocked(state, item) then
    return build_locked_detail(item, state, config, lang)
  end
  return menu_detail.build_item_detail(item, state, lang, config)
end

local function open_purchase_menu(get_state, set_state, lang, config, on_close)
  local menu_detail = require("idle_dungeon.menu.detail")
  local menu_view = require("idle_dungeon.menu.view")
  local icons = icon_module.config(config)
  local function open_categories()
    local categories = build_purchase_categories(lang)
    -- 購入カテゴリを選ぶメニューを表示する。
    menu_view.select(categories, {
      prompt_provider = function()
        return build_gold_prompt(i18n.t("prompt_purchase", lang), get_state(), lang)
      end,
      lang = lang,
      footer_hints = menu_locale.submenu_footer_hints(lang),
      keep_open = true,
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        if on_close then
          on_close()
        end
        return
      end
      local slot = choice.id
      local slot_items = filter_items_by_slot(content.items, slot)
      -- カテゴリごとの装備を購入するメニューを表示する。
      menu_view.select(slot_items, {
        prompt_provider = function()
          return build_gold_prompt(menu_locale.slot_label(slot, lang), get_state(), lang)
        end,
        lang = lang,
        footer_hints = menu_locale.submenu_footer_hints(lang),
        -- 連続購入できるように購入後もメニューを閉じない。
        keep_open = true,
        format_item = function(item)
          local state = get_state()
          local owned = state.inventory[item.id] or 0
          local unlocked = is_item_unlocked(state, item)
          local gold = ((state.currency or {}).gold) or 0
          local icon = icon_module.resolve_slot_icon(item.slot, icons)
          return format_item_label(item, owned, unlocked, gold, lang, icon)
        end,
        detail_provider = function(item)
          return build_purchase_detail(menu_detail, item, get_state(), config, lang)
        end,
      }, function(item)
        if not item then
          -- カテゴリ選択へ戻る。
          return open_categories()
        end
        local state = get_state()
        if not is_item_unlocked(state, item) then
          return
        end
        local gold = ((state.currency or {}).gold) or 0
        if gold < item.price then
          return
        end
        local next_inventory = inventory.add_item(state.inventory, item.id, 1)
        local next_currency = util.merge_tables(state.currency, { gold = gold - item.price })
        local next_state = state_module.with_inventory(state_module.with_currency(state, next_currency), next_inventory)
        -- 購入した装備を図鑑へ記録する。
        local recorded = state_dex.record_item(next_state, item.id, 1)
        local item_name = menu_logging.resolve_item_name(item, lang)
        set_state(menu_logging.append_localized(
          recorded,
          lang,
          string.format("購入: %s (-%dG)", item_name, tonumber(item.price) or 0),
          string.format("Purchased: %s (-%dG)", item_name, tonumber(item.price) or 0)
        ))
      end, config)
    end, config)
  end
  open_categories()
end

local function open_sell_menu(get_state, set_state, lang, config, on_close)
  local menu_detail = require("idle_dungeon.menu.detail")
  local menu_view = require("idle_dungeon.menu.view")
  local icons = icon_module.config(config)
  local choices = {}
  local state = get_state()
  for _, item in ipairs(content.items) do
    local owned = state.inventory[item.id] or 0
    if owned > 0 and state.equipment[item.slot] ~= item.id then
      table.insert(choices, item)
    end
  end
  -- 売却対象を選ぶための中央メニューを表示する。
  menu_view.select(choices, {
    prompt = i18n.t("prompt_sell", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    -- 連続売却できるように売却後もメニューを閉じない。
    keep_open = true,
    format_item = function(item)
      local state = get_state()
      local icon = icon_module.resolve_slot_icon(item.slot, icons)
      local name = icon ~= "" and string.format("%s %s", icon, item.name) or item.name
      return string.format("✓ %-36s x%d", name, state.inventory[item.id] or 0)
    end,
    detail_provider = function(item)
      return menu_detail.build_item_detail(item, get_state(), lang, config)
    end,
  }, function(item)
    if not item then
      if on_close then
        -- キャンセル時は状態画面へ戻る。
        on_close()
      end
      return
    end
    local state = get_state()
    local next_inventory = inventory.remove_item(state.inventory, item.id, 1)
    local price = math.floor(item.price * 0.5)
    local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold + price })
    local next_state = state_module.with_inventory(state_module.with_currency(state, next_currency), next_inventory)
    local item_name = menu_logging.resolve_item_name(item, lang)
    set_state(menu_logging.append_localized(
      next_state,
      lang,
      string.format("売却: %s (+%dG)", item_name, price),
      string.format("Sold: %s (+%dG)", item_name, price)
    ))
  end, config)
end

M.open_purchase_menu = open_purchase_menu
M.open_sell_menu = open_sell_menu
M.build_purchase_categories = build_purchase_categories
M.filter_items_by_slot = filter_items_by_slot
M.is_item_unlocked = is_item_unlocked

return M
