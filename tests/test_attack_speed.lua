-- このテストは攻撃速度の定義と速度差による行動回数差を確認する。

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

local content = require("idle_dungeon.content")
local battle_flow = require("idle_dungeon.core.transition.battle")
local util = require("idle_dungeon.util")

for _, enemy in ipairs(content.enemies or {}) do
  local speed = enemy.stats and enemy.stats.speed or nil
  assert_true(speed and speed >= 1, "敵の攻撃速度が設定されている: " .. (enemy.id or "?"))
end

-- ジョブの基礎攻撃速度も必須項目として検証する。
for _, job in ipairs(content.jobs or {}) do
  local speed = job.base and job.base.speed or nil
  assert_true(speed and speed >= 1, "勇者の攻撃速度が設定されている: " .. (job.id or "?"))
end

local config = { battle = { accuracy = 100 } }

local function run_ticks(state, config, ticks)
  local current = state
  local hero_attacks = 0
  local enemy_attacks = 0
  for _ = 1, ticks do
    current = battle_flow.tick_battle(current, config)
    local attacker = current.combat and current.combat.last_turn and current.combat.last_turn.attacker or nil
    if attacker == "hero" then
      hero_attacks = hero_attacks + 1
    elseif attacker == "enemy" then
      enemy_attacks = enemy_attacks + 1
    end
  end
  return current, hero_attacks, enemy_attacks
end

-- speed値は小さいほど速く、同じ時間内に行動回数が増える。
local fast_hero_state = {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 1 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 3 },
    turn = nil,
    turn_wait = 0,
    last_turn = nil,
  },
}
local st1, hero_count_1, enemy_count_1 = run_ticks(fast_hero_state, config, 6)
assert_equal(st1.combat.last_turn.attacker, "enemy", "同時行動可能なタイミングでは直前行動者と逆側が選ばれる")
assert_true(hero_count_1 > enemy_count_1, "勇者が速いと敵より多く攻撃する")

local fast_enemy_state = util.merge_tables(fast_hero_state, {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 3 },
  combat = { enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 1 }, turn = nil, turn_wait = 0, last_turn = nil },
})
local _, hero_count_2, enemy_count_2 = run_ticks(fast_enemy_state, config, 6)
assert_true(enemy_count_2 > hero_count_2, "敵が速いと勇者より多く攻撃する")

print("OK")
