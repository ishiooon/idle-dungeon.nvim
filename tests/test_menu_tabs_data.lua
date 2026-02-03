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
assert_match(status_items[1].label or "", "Stage:", "英語の状態表示が含まれる")
local found_metrics = false
for _, item in ipairs(status_items) do
  if item.id == "metrics_detail" then
    found_metrics = true
    local joined = table.concat(item.detail_lines or {}, " ")
    assert_match(joined, "lua", "入力統計の詳細にファイル種別が含まれる")
  end
end
assert_true(found_metrics, "入力統計の詳細項目が含まれる")

local action_items = menu_data.build_action_items()
assert_true(#action_items >= 5, "操作タブの項目が生成される")
assert_match(action_items[1].id or "", "equip", "操作項目に装備変更が含まれる")

local config_items = menu_data.build_config_items()
assert_true(#config_items >= 3, "設定タブの項目が生成される")
assert_match(config_items[1].id or "", "toggle_text", "設定項目にモード切り替えが含まれる")
local found_language = false
local found_display_lines = false
for _, item in ipairs(config_items) do
  if item.id == "language" then
    found_language = true
    assert_true(item.keep_open == true, "言語設定はメニューを閉じずに開ける")
  end
  if item.id == "display_lines" then
    found_display_lines = true
    assert_true(item.keep_open == true, "表示行数の設定はメニューを閉じずに開ける")
  end
end
assert_true(found_language, "言語設定の項目が含まれる")
assert_true(found_display_lines, "表示行数の項目が含まれる")

local credits_items = menu_data.build_credits_items("en")
assert_true(#credits_items > 0, "クレジットタブの項目が生成される")
-- クレジットの表記は IdleDungeon に統一する。
assert_match(credits_items[1].label or "", "IdleDungeon", "クレジットのアスキーアートが含まれる")

-- 図鑑のアイコン色付けはアイコン部分だけに適用するため情報を保持する。
local dex_state = util.merge_tables(state, {
  dex = dex.record_enemy(dex.new_dex(), "dust_slime", "normal", 10),
})
local dex_items = menu_data.build_dex_items(dex_state, config, "en")
local highlighted = nil
for _, item in ipairs(dex_items) do
  if item.id == "dex_entry" and item.highlight_key then
    highlighted = item
    break
  end
end
assert_true(highlighted ~= nil, "図鑑の敵エントリが見つかる")
assert_match(highlighted.highlight_icon or "", "%S", "図鑑の敵アイコンが保持される")

print("OK")
