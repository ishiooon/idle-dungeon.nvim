-- このテストは上部ライブ表示を折り返さないためにメニュー幅を優先拡張することを確認する。

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

local config = view_util.menu_config({
  ui = {
    menu = {
      width = 60,
      min_width = 52,
      max_width = 68,
    },
  },
})

local wide_line = string.rep("A", 90)
local expanded = view_util.resolve_compact_width(config, { wide_line }, "Tabs")
assert_true(expanded > 68, "上部ライブ表示が長い場合は既定の最大幅より広げる")
assert_equal(expanded, 96, "上部表示の長さに合わせた幅へ拡張する")

local too_wide_line = string.rep("B", 200)
local clamped = view_util.resolve_compact_width(config, { too_wide_line }, "Tabs")
assert_equal(clamped, config.available_width, "画面幅を上限として拡張する")

print("OK")
