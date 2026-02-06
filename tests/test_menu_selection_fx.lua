-- このテストはメニュー選択アニメーションの位相切替と終了判定を確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local fx = require("idle_dungeon.menu.selection_fx")

local now_ms = 1000
fx._set_time_provider(function()
  return now_ms
end)

local state = {}
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelected", "初期状態は通常ハイライト")

fx.start(state)
assert_true(fx.is_active(state), "開始直後はアニメーションが有効")
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelectedPulse", "開始直後はパルス位相")

now_ms = 1050
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelected", "次位相で通常ハイライトへ戻る")

now_ms = 1120
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelectedPulse", "再度パルス位相になる")

now_ms = 1300
assert_true(not fx.is_active(state), "継続時間経過後はアニメーションが終了する")
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelected", "終了後は通常ハイライトへ戻る")

fx.stop(state)
assert_equal(fx.selected_group(state), "IdleDungeonMenuSelected", "明示停止後は通常ハイライト")

fx._set_time_provider(nil)

print("OK")
