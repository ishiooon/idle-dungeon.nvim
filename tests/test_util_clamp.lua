-- このテストはUTF-8文字列の切り詰めが壊れないことを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local util = require("idle_dungeon.util")

local text = "日本語ABC"
local clamped = util.clamp_line(text, 4)
local chunks = util.split_utf8(clamped)

assert_equal(#chunks, 4, "UTF-8の途中で切り詰められていない")

print("OK")
