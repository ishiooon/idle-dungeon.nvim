-- このテストは階層内の敵配置と遭遇判定が期待通りであることを確認する。

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

local floor_state = require("idle_dungeon.game.floor.state")
local floor_progress = require("idle_dungeon.game.floor.progress")

local config = {
  floor_length = 10,
  floor_encounters = { min = 1, max = 1 },
  enemy_names = { "dust_slime" },
  elements = { "normal" },
}

local progress = {
  distance = 0,
  stage_start = 0,
  stage_id = 1,
  boss_every = 10,
  rng_seed = 7,
}

local refreshed = floor_state.refresh(progress, config)
assert_true(type(refreshed.floor_enemies) == "table", "階層内の敵配置が生成される")
assert_equal(#refreshed.floor_enemies, 1, "敵の数が設定範囲内で生成される")

local enemy = refreshed.floor_enemies[1]
assert_true(enemy.position >= 2 and enemy.position <= 9, "敵の位置が階層の範囲内に収まる")

local floor_length = floor_progress.resolve_floor_length(config)
-- 敵位置から実際の距離を復元し、移動量が大きくても遭遇できるかを確認する。
local floor_start = floor_progress.floor_start_distance(refreshed.floor_index, floor_length)
local enemy_distance = floor_start + math.max(enemy.position - 1, 0)
local distance_before = math.max(enemy_distance - 2, 0)
local distance_after = enemy_distance + 1
local progress_before = floor_state.refresh({
  distance = distance_before,
  stage_start = 0,
  boss_every = 10,
  rng_seed = refreshed.rng_seed,
  floor_enemies = refreshed.floor_enemies,
  floor_index = refreshed.floor_index,
  floor_encounters_total = refreshed.floor_encounters_total,
  floor_encounters_remaining = refreshed.floor_encounters_remaining,
  floor_boss_pending = refreshed.floor_boss_pending,
}, config)
local ahead, ahead_distance = floor_state.find_enemy_in_path(progress_before, floor_length, distance_before, distance_after)
assert_true(ahead ~= nil, "移動量が大きくても敵の遭遇が検出できる")
assert_equal(ahead_distance, enemy_distance, "遭遇距離が敵位置と一致する")

local defeated = floor_state.mark_enemy_defeated(refreshed, enemy)
assert_equal(defeated.floor_enemies[1].defeated, true, "敵の撃破状態が記録される")

print("OK")
