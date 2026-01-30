-- このテストはタブ表示の文字列生成と切り替え計算を確認する。
-- メニュー階層整理に合わせて参照先を更新する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local tabs = require("idle_dungeon.menu.tabs")

local items = {
  { label = "Status" },
  { label = "Actions" },
  { label = "Config" },
}

local line1 = tabs.build_tabs_line(items, 1)
assert_equal(line1, "[Status] | Actions | Config", "先頭タブが強調表示される")

local line2 = tabs.build_tabs_line(items, 2)
assert_equal(line2, "Status | [Actions] | Config", "中間タブが強調表示される")

local line3 = tabs.build_tabs_line(items, 3)
assert_equal(line3, "Status | Actions | [Config]", "末尾タブが強調表示される")

assert_equal(tabs.shift_index(1, 1, 3), 2, "右方向の移動が反映される")
assert_equal(tabs.shift_index(3, 1, 3), 1, "末尾から先頭へ循環する")
assert_equal(tabs.shift_index(1, -1, 3), 3, "先頭から末尾へ循環する")

print("OK")
