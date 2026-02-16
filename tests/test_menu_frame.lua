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
  top_lines = { "TRACK-L1", "TRACK-L2" },
  tabs_line = "1 Stats  2 Actions  3 Config",
  left_lines = { "line1", "line2" },
  right_lines = { "detail1", "detail2" },
  footer_notes = { "Enter: Open selection", "Current -> Next" },
  footer_hints = { "Enter Select", "Tab Switch", "b Back", "q Close" },
  width = 96,
  height = 20,
  padding = 2,
  tabs_position = "top",
})

assert_equal(#built.lines, 20, "固定高さでフレーム行数が埋まる")
assert_true((built.tabs_line_index or 0) > 0, "タブ行の位置が返る")
assert_contains(built.lines[built.tabs_line_index], "Stats", "タブ見出しが表示される")
assert_contains(built.lines[2], "TRACK-L1", "ライブトラック1行目がタブより上に表示される")
assert_contains(built.lines[3], "TRACK-L2", "ライブトラック2行目がタブより上に表示される")
assert_contains(built.lines[(built.tabs_line_index or 1) + 1], "·", "タブ行の直下に区切り線が表示される")
assert_contains(built.lines[built.body_start or 1], "│", "本文で左右ペインの区切りが表示される")
assert_contains(built.lines[(built.footer_hint_line or #built.lines) - 3], "─", "フッター説明の手前に区切り線が表示される")
assert_contains(built.lines[(built.footer_hint_line or #built.lines) - 2], "Enter: Open selection", "フッターの上段にEnter説明が表示される")
assert_contains(built.lines[(built.footer_hint_line or #built.lines) - 1], "Current -> Next", "フッター直上に変更内容の説明が表示される")
assert_contains(built.lines[built.footer_hint_line or (#built.lines - 1)], "Close", "フッター案内が最下部に表示される")
assert_contains(built.lines[1], "Idle Dungeon", "先頭行にタイトルが表示される")
assert_true((built.left_width or 0) >= 20, "左ペイン幅が狭すぎない")
assert_true((built.right_width or 0) >= 20, "右ペイン幅が狭すぎない")
assert_true((built.left_width or 0) >= 40, "標準幅では左ペインが狭すぎず項目ラベルの見切れを抑える")

-- 左カラムが長文でも2カラムの区切り位置が崩れず、右カラム内容を維持することを確認する。
local long_left = string.rep("L", 120)
local long_split = frame.compose({
  title = "Idle Dungeon",
  left_lines = { long_left },
  right_lines = { "RIGHT-SUMMARY" },
  footer_hints = { "q Close" },
  width = 72,
  height = 16,
})
local first_body = long_split.lines[long_split.body_start or 1] or ""
local separator = string.find(first_body, "│", 1, true)
assert_equal(separator, (long_split.left_width or 0) + 2, "左カラム長文でも区切り線の位置が固定される")
assert_contains(first_body, "RIGHT-SUMMARY", "左カラム長文でも右カラムの説明が表示される")
assert_true((long_split.right_width or 0) > (long_split.left_width or 0), "2カラムでは右側の詳細ペインを広めに確保する")

print("OK")
