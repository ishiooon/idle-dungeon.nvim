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

local config = {
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
local status_items = menu_data.build_status_items(state, config, "en")
assert_true(#status_items > 0, "状態タブの項目が生成される")
assert_match(status_items[1].label or "", "Stage:", "英語の状態表示が含まれる")

local action_items = menu_data.build_action_items()
assert_true(#action_items >= 5, "操作タブの項目が生成される")
assert_match(action_items[1].id or "", "equip", "操作項目に装備変更が含まれる")

local config_items = menu_data.build_config_items()
assert_true(#config_items >= 3, "設定タブの項目が生成される")
assert_match(config_items[1].id or "", "toggle_text", "設定項目にモード切り替えが含まれる")
local found_language = false
for _, item in ipairs(config_items) do
  if item.id == "language" then
    found_language = true
    assert_true(item.keep_open == true, "言語設定はメニューを閉じずに開ける")
  end
end
assert_true(found_language, "言語設定の項目が含まれる")

local credits_items = menu_data.build_credits_items("en")
assert_true(#credits_items > 0, "クレジットタブの項目が生成される")
assert_match(credits_items[1].label or "", "IDEL", "クレジットのアスキーアートが含まれる")

print("OK")
