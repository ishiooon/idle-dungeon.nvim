-- このテストはメニュー開閉の状態遷移が期待通りであることを確認する。
-- メニュー階層整理後の参照先を明確にする。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local toggle = require("idle_dungeon.menu.toggle")

assert_equal(toggle.toggle_open(true), false, "開いている場合は閉じる状態になる")
assert_equal(toggle.toggle_open(false), true, "閉じている場合は開く状態になる")
assert_equal(toggle.toggle_open(nil), true, "未設定の場合は開く状態になる")

print("OK")
