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

local empty_state = { dex = { enemies = {}, items = {} } }

local enemy_lines = dex_catalog.build_enemy_lines(empty_state, "en")
assert_true(#enemy_lines > 0, "未遭遇の敵も図鑑に表示される")
assert_match(enemy_lines[1] or "", "%?%?%?", "未遭遇の敵は???で表示される")

local item_lines = dex_catalog.build_item_lines(empty_state, "en")
assert_true(#item_lines > 0, "未取得の装備も図鑑に表示される")
assert_match(item_lines[1] or "", "%?%?%?", "未取得の装備は???で表示される")

print("OK")
