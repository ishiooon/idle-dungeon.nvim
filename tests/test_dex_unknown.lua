-- このテストは図鑑の未発見表示とドロップ表示が期待通りであることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local dex_catalog = require("idle_dungeon.game.dex.catalog")
local content = require("idle_dungeon.content")
local i18n = require("idle_dungeon.i18n")

local empty_state = { dex = { enemies = {}, items = {} } }
local unknown_label = i18n.t("dex_unknown", "en")
local drop_label = i18n.t("dex_label_drops", "en")

local enemy_lines = dex_catalog.build_enemy_lines(empty_state, "en")
assert_equal(#enemy_lines, #content.enemies, "未遭遇の敵も図鑑に並ぶ")

local found_unknown_enemy = false
local found_drop_label = false
for _, line in ipairs(enemy_lines) do
  if line:find(unknown_label, 1, true) then
    found_unknown_enemy = true
  end
  if line:find(drop_label, 1, true) then
    found_drop_label = true
  end
end
assert_true(found_unknown_enemy, "未遭遇の敵は???表示になる")
assert_true(found_drop_label, "敵のドロップ一覧が表示される")

local item_lines = dex_catalog.build_item_lines(empty_state, "en")
assert_equal(#item_lines, #content.items, "未取得の装備も図鑑に並ぶ")

local found_unknown_item = false
for _, line in ipairs(item_lines) do
  if line:find(unknown_label, 1, true) then
    found_unknown_item = true
    break
  end
end
assert_true(found_unknown_item, "未取得の装備は???表示になる")

assert_match(enemy_lines[1] or "", ".+", "図鑑の表示行が生成される")

print("OK")
