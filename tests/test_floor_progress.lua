-- このテストは階層進行の補助関数が正しく計算されることを確認する。
-- 階層モジュールの配置が変更されても読み取れることを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local floor_progress = require("idle_dungeon.game.floor.progress")

local config = { floor_length = 8, ui = { track_length = 12 } }
local floor_length = floor_progress.resolve_floor_length(config)
assert_equal(floor_length, 8, "floor_lengthの既定値を優先する")

assert_equal(floor_progress.floor_index(0, floor_length), 0, "距離0は0階層目")
assert_equal(floor_progress.floor_index(8, floor_length), 1, "距離8は1階層目")
assert_equal(floor_progress.floor_step(9, floor_length), 1, "距離9は階層内1歩")

local stage = { floors = 5 }
assert_equal(floor_progress.stage_total_floors(stage, floor_length), 5, "ステージ階層数を取得できる")

local stage_len = { length = 80 }
assert_equal(floor_progress.stage_total_floors(stage_len, floor_length), 10, "距離長から階層数へ換算できる")

local progress = { distance = 16, stage_start = 0 }
assert_equal(floor_progress.stage_floor_distance(progress, floor_length), 2, "ステージ内の階層距離を算出する")

print("OK")
