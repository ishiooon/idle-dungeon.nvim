-- このモジュールは購入と売却の処理をまとめる。
-- ショップの参照先はgameとmenuの領域へ整理する。
local content = require("idle_dungeon.content")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local menu_locale = require("idle_dungeon.menu.locale")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local M = {}

-- 購入メニューのカテゴリは装備スロット順で統一する。
local PURCHASE_SLOTS = { "weapon", "armor", "accessory" }

-- 装備の解放条件を参照しやすい形に並べ替える。
local function resolve_unlock_rules(config, item)
  local rules = {}
  local unlock_rules = (config or {}).unlock_rules or {}
  for _, rule in ipairs(unlock_rules) do
    if rule.target == "items" and rule.id == item.id then
      table.insert(rules, rule)
    end
  end
  return rules
end

-- 稼働時間の表示を言語に合わせて短く整形する。
local function format_time_seconds(seconds, lang)
  local total = math.max(0, math.floor(seconds or 0))
  local minutes = math.floor(total / 60)
  local secs = total % 60
  local hours = math.floor(minutes / 60)
  local rem_minutes = minutes % 60
  local is_ja = lang == "ja" or lang == "jp"
  if hours > 0 then
    if is_ja then
      return string.format("%d時間%02d分", hours, rem_minutes)
    end
    return string.format("%dh %02dm", hours, rem_minutes)
  end
  if minutes > 0 then
    if is_ja then
      return string.format("%d分%02d秒", minutes, secs)
    end
    return string.format("%dm %02ds", minutes, secs)
  end
  if is_ja then
    return string.format("%d秒", secs)
  end
  return string.format("%ds", secs)
end

-- 解放条件の進行度を行配列へ整形して返す。
local function build_unlock_lines(item, state, config, lang)
  local rules = resolve_unlock_rules(config, item)
  if #rules == 0 then
    return { i18n.t("unlock_none", lang) }
  end
  local metrics = (state or {}).metrics or {}
  local lines = {}
  for _, rule in ipairs(rules) do
    local required = rule.value or 0
    if rule.kind == "chars" then
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_chars", lang), metrics.chars or 0, required))
    elseif rule.kind == "saves" then
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_saves", lang), metrics.saves or 0, required))
    elseif rule.kind == "time_sec" then
      local current = format_time_seconds(metrics.time_sec or 0, lang)
      local required_text = format_time_seconds(required, lang)
      table.insert(lines, string.format("%s %s/%s", i18n.t("unlock_time", lang), current, required_text))
    elseif rule.kind == "filetype_chars" then
      local filetype = rule.filetype or ""
      local count = ((metrics.filetypes or {})[filetype]) or 0
      local label = string.format(i18n.t("unlock_filetype", lang), filetype)
      table.insert(lines, string.format("%s %d/%d", label, count, required))
    else
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_unknown", lang), 0, required))
    end
  end
  return lines
end

-- 未解放装備の詳細表示は条件を中心に構成する。
local function build_locked_detail(item, state, config, lang)
  local lines = { i18n.t("unlock_title", lang) }
  for _, line in ipairs(build_unlock_lines(item, state, config, lang)) do
    table.insert(lines, line)
  end
  return { title = i18n.t("dex_unknown", lang), lines = lines }
end

local function format_item_label(item, owned, unlocked, gold, lang)
  local name = unlocked and (item.name or "") or i18n.t("dex_unknown", lang)
  local status = unlocked and i18n.t("status_unlocked", lang) or i18n.t("status_locked", lang)
  local count = i18n.t("status_owned", lang) .. (owned or 0)
  local price_value = unlocked and (item.price or 0) or i18n.t("dex_unknown", lang)
  local price = i18n.t("status_price", lang) .. price_value
  local afford = i18n.t("status_unaffordable", lang)
  if unlocked then
    local current_gold = gold or 0
    afford = current_gold >= (item.price or 0) and i18n.t("status_affordable", lang) or i18n.t("status_unaffordable", lang)
  end
  return string.format("%s (%s %s %s %s)", name, status, count, price, afford)
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
  return menu_detail.build_item_detail(item, state, lang)
end

local function open_purchase_menu(get_state, set_state, lang, config, on_close)
  local menu_detail = require("idle_dungeon.menu.detail")
  local menu_view = require("idle_dungeon.menu.view")
  local function open_categories()
    local categories = build_purchase_categories(lang)
    -- 購入カテゴリを選ぶメニューを表示する。
    menu_view.select(categories, {
      prompt_provider = function()
        return build_gold_prompt(i18n.t("prompt_purchase", lang), get_state(), lang)
      end,
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
        -- 連続購入できるように購入後もメニューを閉じない。
        keep_open = true,
        format_item = function(item)
          local state = get_state()
          local owned = state.inventory[item.id] or 0
          local unlocked = is_item_unlocked(state, item)
          local gold = ((state.currency or {}).gold) or 0
          return format_item_label(item, owned, unlocked, gold, lang)
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
        set_state(state_dex.record_item(next_state, item.id, 1))
      end, config)
    end, config)
  end
  open_categories()
end

local function open_sell_menu(get_state, set_state, lang, config)
  local menu_detail = require("idle_dungeon.menu.detail")
  local menu_view = require("idle_dungeon.menu.view")
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
    -- 連続売却できるように売却後もメニューを閉じない。
    keep_open = true,
    format_item = function(item)
      local state = get_state()
      return string.format("%s (%s%d)", item.name, i18n.t("status_owned", lang), state.inventory[item.id] or 0)
    end,
    detail_provider = function(item)
      return menu_detail.build_item_detail(item, get_state(), lang)
    end,
  }, function(item)
    if not item then
      return
    end
    local state = get_state()
    local next_inventory = inventory.remove_item(state.inventory, item.id, 1)
    local price = math.floor(item.price * 0.5)
    local next_currency = util.merge_tables(state.currency, { gold = state.currency.gold + price })
    local next_state = state_module.with_inventory(state_module.with_currency(state, next_currency), next_inventory)
    set_state(next_state)
  end, config)
end

M.open_purchase_menu = open_purchase_menu
M.open_sell_menu = open_sell_menu
M.build_purchase_categories = build_purchase_categories
M.filter_items_by_slot = filter_items_by_slot
M.is_item_unlocked = is_item_unlocked

return M
