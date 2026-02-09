-- このテストはメニュー表示のデータ生成が期待通りであることを確認する。
-- メニュー階層整理に合わせて参照先を更新する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")
local dex = require("idle_dungeon.game.dex")

local config = {
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  metrics = {
    chars = 120,
    saves = 2,
    time_sec = 60,
    filetypes = { lua = 100, python = 20 },
  },
})
local status_items = menu_data.build_status_items(state, config, "en")
assert_true(#status_items > 0, "状態タブの項目が生成される")
local found_stage = false
local found_live_track_label = false
for _, item in ipairs(status_items) do
  if (item.label or ""):match("Stage:") then
    found_stage = true
  end
  if (item.label or ""):match("Live Track") then
    found_live_track_label = true
  end
end
assert_true(found_stage, "英語の状態表示が含まれる")
assert_true(not found_live_track_label, "ライブトラックの見出しはタブ内に重複表示しない")
local found_metrics = false
for _, item in ipairs(status_items) do
  if item.id == "metrics_detail" then
    found_metrics = true
    local joined = table.concat(item.detail_lines or {}, " ")
    assert_match(joined, "lua", "入力統計の詳細にファイル種別が含まれる")
  end
end
assert_true(found_metrics, "入力統計の詳細項目が含まれる")
local normal_entry = nil
for _, item in ipairs(status_items) do
  if item.id == "entry" then
    normal_entry = item
    break
  end
end
assert_true(normal_entry ~= nil, "通常エントリが存在する")
local detail_none = menu_data.build_status_detail(normal_entry, state, config, "en")
assert_true(detail_none == nil, "通常エントリでは詳細を表示しない")
local metrics_entry = nil
for _, item in ipairs(status_items) do
  if item.id == "metrics_detail" then
    metrics_entry = item
    break
  end
end
assert_true(metrics_entry ~= nil, "統計詳細エントリが存在する")
local detail_metrics = menu_data.build_status_detail(metrics_entry, state, config, "en")
assert_true(type(detail_metrics) == "table", "統計詳細エントリでは詳細を表示する")

local action_items = menu_data.build_action_items()
assert_true(#action_items >= 5, "操作タブの項目が生成される")
assert_match(action_items[1].id or "", "equip", "操作項目に装備変更が含まれる")

local config_items = menu_data.build_config_items()
assert_true(#config_items >= 3, "設定タブの項目が生成される")
assert_match(config_items[1].id or "", "toggle_text", "設定項目にモード切り替えが含まれる")
local found_language = false
local found_display_lines = false
local found_battle_hp = false
local found_game_speed = false
local found_reload_plugin = false
for _, item in ipairs(config_items) do
  if item.id == "language" then
    found_language = true
    assert_true(item.keep_open == true, "言語設定はメニューを閉じずに開ける")
  end
  if item.id == "display_lines" then
    found_display_lines = true
    assert_true(item.keep_open == true, "表示行数の設定はメニューを閉じずに開ける")
  end
  if item.id == "game_speed" then
    found_game_speed = true
    assert_true(item.keep_open == true, "ゲーム速度の設定はメニューを閉じずに開ける")
  end
  if item.id == "reload_plugin" then
    found_reload_plugin = true
    assert_true(item.keep_open == true, "再読み込みはメニューを閉じずに実行できる")
  end
  -- 戦闘時のHP分母表示を切り替える項目が含まれることを確認する。
  if item.id == "battle_hp_show_max" then
    found_battle_hp = true
    assert_true(item.keep_open == true, "戦闘HP表示の設定はメニューを閉じずに開ける")
  end
end
assert_true(found_language, "言語設定の項目が含まれる")
assert_true(found_display_lines, "表示行数の項目が含まれる")
assert_true(found_game_speed, "ゲーム速度の項目が含まれる")
assert_true(found_battle_hp, "戦闘HP表示の項目が含まれる")
assert_true(found_reload_plugin, "再読み込みの項目が含まれる")
assert_true((config_items[#config_items] or {}).id == "reload_plugin", "再読み込みの項目は設定メニューの最下段にある")

local credits_items = menu_data.build_credits_items("en")
assert_true(#credits_items > 0, "クレジットタブの項目が生成される")
-- クレジットの表記は IdleDungeon に統一する。
assert_match(credits_items[1].label or "", "IdleDungeon", "クレジットのアスキーアートが含まれる")

-- 図鑑のアイコン色付けはアイコン部分だけに適用するため情報を保持する。
local dex_state = util.merge_tables(state, {
  dex = dex.record_enemy(dex.new_dex(), "dust_slime", "normal", 10),
})
local dex_items = menu_data.build_dex_items(dex_state, config, "en", {
  show_controls = true,
})
local highlighted = nil
local found_dex_summary = false
local found_dex_toggle = false
local found_dex_hint = false
local found_mastery_badge = false
local found_mastery_legend = false
local found_sort_control = false
local found_element_control = false
local found_keyword_control = false
local found_danger_detail = false
local found_drop_band_detail = false
for _, item in ipairs(dex_items) do
  if item.id == "header" and (item.label or ""):match("Enemies") and (item.label or ""):match("Items") and (item.label or ""):match("%[") then
    found_dex_summary = true
  end
  if item.id == "header" and (item.label or ""):match("NEW=") then
    found_mastery_legend = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Expand") then
    found_dex_toggle = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Sort:") then
    found_sort_control = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Element:") then
    found_element_control = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Search:") then
    found_keyword_control = true
  end
  if item.id == "header" and (item.label or ""):match("Enter:") then
    found_dex_hint = true
  end
  if item.id == "dex_entry" and item.highlight_key then
    highlighted = item
    if (item.label or ""):match("NEW") or (item.label or ""):match("★") then
      found_mastery_badge = true
    end
    local detail_joined = table.concat(item.detail_lines or {}, " ")
    if detail_joined:match("Danger:") then
      found_danger_detail = true
    end
    if detail_joined:match("Drop Band:") then
      found_drop_band_detail = true
    end
  end
end
assert_true(found_dex_summary, "図鑑の概要行に進捗メーターが含まれる")
assert_true(found_mastery_legend, "図鑑の達成バッジ説明が含まれる")
assert_true(found_dex_toggle, "図鑑の展開トグルが含まれる")
assert_true(found_sort_control, "図鑑の並び替えトグルが含まれる")
assert_true(found_element_control, "図鑑の属性フィルタが含まれる")
assert_true(found_keyword_control, "図鑑の検索フィルタが含まれる")
assert_true(found_dex_hint, "図鑑の操作ヒント行が含まれる")
assert_true(highlighted ~= nil, "図鑑の敵エントリが見つかる")
assert_true(found_mastery_badge, "図鑑のエントリに達成バッジが表示される")
assert_true(found_danger_detail, "図鑑の敵詳細に危険度が表示される")
assert_true(found_drop_band_detail, "図鑑の敵詳細にドロップ帯が表示される")
assert_match(highlighted.highlight_icon or "", "%S", "図鑑の敵アイコンが保持される")

print("OK")
