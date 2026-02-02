-- このモジュールはメニュー表示に必要なデータを純粋関数として生成する。
-- 図鑑とメニューの参照先は関心ごとに整理する。
local dex_catalog = require("idle_dungeon.game.dex.catalog")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")

local M = {}

local function build_action_items()
  return {
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
    { id = "language", key = "menu_action_language" },
    { id = "reset", key = "menu_action_reset" },
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

-- 図鑑タブで表示する敵と装備の一覧を生成する。
local function build_dex_items(state, config, lang)
  local items = {}
  local enemy_lines = dex_catalog.build_enemy_lines(state, lang)
  local item_lines = dex_catalog.build_item_lines(state, lang)
  append_section(items, i18n.t("dex_title_enemies", lang), enemy_lines, i18n.t("dex_empty_enemies", lang))
  append_section(items, i18n.t("dex_title_items", lang), item_lines, i18n.t("dex_empty_items", lang))
  return items
end

M.build_action_items = build_action_items
M.build_config_items = build_config_items
M.build_credits_items = build_credits_items
M.build_dex_items = build_dex_items
M.build_status_items = build_status_items

return M
