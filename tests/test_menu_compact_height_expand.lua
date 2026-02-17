-- このテストはメニュー本文が入りきらない場合でも、設定上限内で高さを決めることを確認する。

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

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local view_util = require("idle_dungeon.menu.view_util")

local config = {
  min_height = 18,
  max_height = 26,
  height = 26,
}

local compact_height = view_util.resolve_compact_height(config, 40, 10, { "A", "B", "C" }, true)
assert_equal(compact_height, 18, "本文が収まる場合は必要最小限の高さで表示する")

local expanded_height = view_util.resolve_compact_height(config, 40, 32, { "A", "B", "C" }, true)
assert_equal(expanded_height, 23, "本文が多い場合でも高さは設定レンジ内で決定する")

local footer_expand_height = view_util.resolve_compact_height(config, 40, 8, { "A", "B", "C", "D" }, true, 2)
assert_equal(footer_expand_height, 20, "フッター説明行がある場合はその行数ぶん高さを拡張する")

print("OK")
