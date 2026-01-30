-- このテストはペット表示の文字列生成が期待通りに動くことを確認する。
-- 参照先の整理に合わせて読み込み先を更新する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local pet = require("idle_dungeon.ui.pet")

local sprite = pet.select_frame({ "a", "b" }, 1, 1)
assert_equal(sprite, "b", "フレーム選択は時間に応じて切り替わる")

local track = pet.build_track_line(0, 8, "o_o", ".")
assert_equal(#track, 8, "トラックは指定長になる")
assert_match(track, "o_o", "トラックにペットが描画される")

local state = {
  actor = { id = "recorder" },
  equipment = { companion = nil },
  metrics = { time_sec = 0 },
  progress = { distance = 0 },
  ui = { mode = "move" },
}
local config = {
  ui = {
    track_length = 8,
    pet = { enabled = true, frame_seconds = 1 },
  },
}
local line = pet.build_line(state, config)
assert_match(line, "o_o", "歩行中は歩行フレームが選ばれる")

print("OK")
