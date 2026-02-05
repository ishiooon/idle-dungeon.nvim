-- このテストは攻撃速度の定義と交互ターンの戦闘進行を確認する。

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

local config = {
  battle = { accuracy = 100 },
}

local base_state = {
  actor = { hp = 10, max_hp = 10, atk = 1, def = 0, speed = 1 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = { hp = 10, max_hp = 10, atk = 1, def = 0, accuracy = 100, speed = 3 },
    turn = nil,
    turn_wait = 0,
    last_turn = nil,
  },
}

local st1 = battle_flow.tick_battle(base_state, config)
assert_equal(st1.combat.last_turn.attacker, "enemy", "速度が高い敵が先に攻撃する")
assert_true((st1.actor.hp or 10) < 10, "敵の攻撃で勇者HPが減る")
assert_equal(st1.combat.enemy.hp, 10, "敵のターンでは敵のHPは減らない")

local fast_hero_state = util.merge_tables(base_state, {
  actor = { hp = 10, max_hp = 10, atk = 1, def = 0, speed = 3 },
  combat = { enemy = { hp = 10, max_hp = 10, atk = 1, def = 0, accuracy = 100, speed = 1 }, turn = nil, turn_wait = 0, last_turn = nil },
})
local st2 = battle_flow.tick_battle(fast_hero_state, config)
assert_equal(st2.combat.last_turn.attacker, "hero", "速度が高い勇者が先に攻撃する")
assert_true((st2.combat.enemy.hp or 10) < 10, "勇者の攻撃で敵HPが減る")

print("OK")
