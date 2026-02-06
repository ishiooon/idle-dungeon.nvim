-- このテストはメニュー共通フレームの行構成を確認する。

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

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local frame = require("idle_dungeon.menu.frame")

local built = frame.compose({
  title = "Idle Dungeon",
  tabs_line = "1 Status | 2 Actions",
  left_lines = { "line1", "line2" },
  right_lines = { "detail1", "detail2" },
  footer_hints = { "Enter: Select", "b: Back", "q: Close" },
  width = 72,
  height = 12,
  padding = 2,
  tabs_position = "top",
})

assert_equal(#built.lines, 12, "固定高さでフレーム行数が埋まる")
assert_true((built.tabs_line_index or 0) > 0, "タブ行の位置が返る")
assert_contains(built.lines[built.tabs_line_index], "Status", "タブ見出しが表示される")
assert_contains(built.lines[built.body_start or 1], "│", "本文で左右ペインの区切りが表示される")
assert_contains(built.lines[built.footer_hint_line or (#built.lines - 1)], "Close", "フッター案内が最下部に表示される")

print("OK")
