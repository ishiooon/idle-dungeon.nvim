-- このテストはメニュー表示で長文を省略せず折り返し可能な形で保持することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local frame = require("idle_dungeon.menu.frame")

local long_text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
local built = frame.compose({
  title = "Idle Dungeon",
  top_lines = { long_text },
  tabs_line = "Tabs",
  left_lines = { long_text },
  footer_hints = { "Enter Select" },
  width = 24,
  height = 14,
  show_right = false,
})

assert_true(string.find(built.lines[2] or "", "7890", 1, true) ~= nil, "上部テキストを切り詰めない")
assert_true(string.find(built.lines[2] or "", "...", 1, true) == nil, "省略記号で切り詰めない")
assert_true(string.find(built.lines[built.body_start] or "", "7890", 1, true) ~= nil, "本文テキストを切り詰めない")

local compact = frame.compose({
  title = "Idle",
  top_lines = { "A" },
  tabs_line = "T",
  left_lines = { "B" },
  footer_hints = { "C" },
  width = 24,
  height = 10,
  show_right = false,
})

assert_true(#(compact.lines[1] or "") <= 24, "単一ペイン表示は幅を72へ強制拡張しない")
assert_true(#(compact.lines[compact.footer_hint_line or #compact.lines] or "") <= 24, "単一ペイン表示のフッターは指定幅に収まる")

print("OK")
