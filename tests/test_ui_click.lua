-- このテストは右下表示のクリック判定が期待通りであることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_false(value, message)
  if value then
    error(message or "assert_false failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local click = require("idle_dungeon.ui.click")

assert_true(click.is_click_on_ui({ winid = 10 }, 10), "同じウィンドウIDのクリックは有効")
assert_false(click.is_click_on_ui({ winid = 9 }, 10), "異なるウィンドウIDのクリックは無効")
assert_false(click.is_click_on_ui(nil, 10), "クリック情報が無い場合は無効")
assert_false(click.is_click_on_ui({ winid = 0 }, 10), "ウィンドウIDが無効な場合は無効")
assert_false(click.is_click_on_ui({ winid = 10 }, nil), "表示ウィンドウが無い場合は無効")

print("OK")
