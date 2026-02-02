-- このモジュールはメニュー表示に必要なデータを純粋関数として生成する。
-- 図鑑とメニューの参照先は関心ごとに整理する。
local dex_catalog = require("idle_dungeon.game.dex.catalog")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")

local M = {}

local function build_action_items()
  return {
    -- 操作系はメニューを閉じてから各サブメニューを開く。
    { id = "equip", key = "menu_action_equip" },
    { id = "stage", key = "menu_action_stage" },
    { id = "purchase", key = "menu_action_purchase" },
    { id = "sell", key = "menu_action_sell" },
    { id = "character", key = "menu_action_character" },
  }
end

local function build_config_items()
  return {
    { id = "toggle_text", key = "menu_action_toggle_text", keep_open = true, kind = "toggle" },
    { id = "auto_start", key = "menu_action_auto_start", keep_open = true, kind = "toggle" },
    -- 設定系は閉じずに選択できるようkeep_openで維持する。
    { id = "language", key = "menu_action_language", keep_open = true },
    { id = "reset", key = "menu_action_reset", keep_open = true },
  }
end

-- クレジット表示用のアスキーアートを定義する。
local function build_credits_art()
  return {
    "=== IDEL DUNGEON ===",
    " ___ ____  _____ _       ____  _   _ _   _  ____  _   _ ",
    "|_ _|  _ \\| ____| |     |  _ \\| | | | \\ | |/ ___|| | | |",
    " | || | | |  _| | |     | | | | | | |  \\| | |  _ | | | |",
    " | || |_| | |___| |___  | |_| | |_| | |\\  | |_| || |_| |",
    "|___|____/|_____|_____| |____/ \\___/|_| \\_|\\____| \\___/ ",
  }
end

-- 状態タブ用の行をまとめて返す。
local function build_status_items(state, config, lang)
  local items = {}
  for _, line in ipairs(menu_locale.status_lines(state, lang, config)) do
    table.insert(items, { id = "info", label = line })
  end
  return items
end

-- クレジットタブで表示する行をまとめる。
local function build_credits_items(lang)
  local items = {}
  for _, line in ipairs(build_credits_art()) do
    table.insert(items, { id = "art", label = line })
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = i18n.t("credits_title", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_created", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_ui", lang) })
  -- 画像スプライト参照の表示は廃止した。
  table.insert(items, { id = "entry", label = i18n.t("credits_line_thanks", lang) })
  return items
end

-- 見出しと項目をまとめて並べるための補助関数。
local function append_section(items, title, lines, empty_label)
  table.insert(items, { id = "header", label = title })
  if #lines == 0 then
    table.insert(items, { id = "empty", label = empty_label })
    return items
  end
  for _, line in ipairs(lines) do
    table.insert(items, { id = "entry", label = line })
  end
  return items
end

-- 図鑑のタイル表示に使う1行テキストを組み立てる。
local function build_tile_label(entry, kind, lang)
  local name = entry.name or ""
  local icon = entry.icon or ""
  local base = icon ~= "" and (icon .. " " .. name) or name
  local element_label = entry.element_label
  if element_label and element_label ~= "" then
    base = string.format("%s [%s]", base, element_label)
  end
  local count = tonumber(entry.count) or 0
  if kind == "enemy" then
    return string.format("%s x%d", base, count)
  end
  return string.format("%s x%d", base, count)
end

-- レアリティの表示名を整形する。
local function rarity_label(rarity, lang)
  if rarity == "rare" then
    return i18n.t("dex_rarity_rare", lang)
  end
  if rarity == "pet" then
    return i18n.t("dex_rarity_pet", lang)
  end
  return i18n.t("dex_rarity_common", lang)
end

-- 図鑑の詳細表示用に行を組み立てる。
local function build_detail_lines(entry, kind, lang)
  local lines = {}
  local name_label = i18n.t("dex_detail_name", lang)
  local type_label = i18n.t("dex_detail_type", lang)
  local count_label = i18n.t("dex_detail_count", lang)
  local element_label = i18n.t("dex_detail_element", lang)
  local flavor_label = i18n.t("dex_detail_flavor", lang)
  local drops_label = i18n.t("dex_label_drops", lang)
  local type_value = kind == "enemy" and i18n.t("dex_detail_kind_enemy", lang) or i18n.t("dex_detail_kind_item", lang)
  table.insert(lines, string.format("%s %s", type_label, type_value))
  table.insert(lines, string.format("%s %s", name_label, entry.name or ""))
  table.insert(lines, string.format("%s %d", count_label, tonumber(entry.count) or 0))
  if entry.element_label and entry.element_label ~= "" then
    table.insert(lines, string.format("%s %s", element_label, entry.element_label))
  end
  if kind == "item" then
    local slot_label = i18n.t("dex_detail_slot", lang)
    local rarity_text = i18n.t("dex_detail_rarity", lang)
    local slot_text = entry.slot and menu_locale.slot_label(entry.slot, lang) or ""
    local rarity_text_value = rarity_label(entry.rarity, lang)
    if slot_text ~= "" then
      table.insert(lines, string.format("%s %s", slot_label, slot_text))
    end
    table.insert(lines, string.format("%s %s", rarity_text, rarity_text_value))
  end
  if kind == "enemy" then
    local parts = {}
    for _, drop in ipairs(entry.drops or {}) do
      table.insert(parts, drop.name or "")
    end
    if #parts > 0 then
      table.insert(lines, string.format("%s %s", drops_label, table.concat(parts, ", ")))
    end
  end
  if entry.flavor and entry.flavor ~= "" then
    table.insert(lines, string.format("%s %s", flavor_label, entry.flavor))
  end
  return lines
end

-- 図鑑タブで表示する敵と装備の一覧を生成する。
local function build_dex_items(state, config, lang)
  local items = {}
  local enemy_entries = dex_catalog.build_enemy_entries(state, lang)
  local item_entries = dex_catalog.build_item_entries(state, lang)
  table.insert(items, { id = "header", label = i18n.t("dex_title_enemies", lang) })
  if #enemy_entries == 0 then
    table.insert(items, { id = "empty", label = i18n.t("dex_empty_enemies", lang) })
  else
    for _, entry in ipairs(enemy_entries) do
      table.insert(items, {
        id = "dex_entry",
        kind = "enemy",
        label = build_tile_label(entry, "enemy", lang),
        tile_label = build_tile_label(entry, "enemy", lang),
        detail_title = entry.name,
        detail_lines = build_detail_lines(entry, "enemy", lang),
        keep_open = true,
      })
    end
  end
  table.insert(items, { id = "header", label = i18n.t("dex_title_items", lang) })
  if #item_entries == 0 then
    table.insert(items, { id = "empty", label = i18n.t("dex_empty_items", lang) })
  else
    for _, entry in ipairs(item_entries) do
      table.insert(items, {
        id = "dex_entry",
        kind = "item",
        label = build_tile_label(entry, "item", lang),
        tile_label = build_tile_label(entry, "item", lang),
        detail_title = entry.name,
        detail_lines = build_detail_lines(entry, "item", lang),
        keep_open = true,
      })
    end
  end
  return items
end

M.build_action_items = build_action_items
M.build_config_items = build_config_items
M.build_credits_items = build_credits_items
M.build_dex_items = build_dex_items
M.build_status_items = build_status_items

return M
