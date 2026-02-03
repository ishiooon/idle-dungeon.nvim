-- このテストは入力文字数の差分加算が負の値を無視することを確認する。

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local metrics = require("idle_dungeon.game.metrics")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
  end
end

local base = metrics.new_metrics()
local first = metrics.add_chars_delta(base, 10, 12, "lua")
assert_equal(first.chars, 2, "正の差分は加算される")
assert_equal((first.filetypes or {}).lua, 2, "ファイル種別ごとの差分が加算される")

local second = metrics.add_chars_delta(first, 12, 9, "lua")
assert_equal(second.chars, 2, "負の差分は加算されない")
assert_equal((second.filetypes or {}).lua, 2, "負の差分では内訳も増えない")

print("OK")
