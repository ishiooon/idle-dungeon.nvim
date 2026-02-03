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

for _, character in ipairs(content.characters or {}) do
  local speed = character.base and character.base.speed or nil
  assert_true(speed and speed >= 1, "勇者の攻撃速度が設定されている: " .. (character.id or "?"))
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
    enemy = { hp = 10, max_hp = 10, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = "hero",
    turn_wait = 0,
    last_turn = nil,
  },
}

local st1 = battle_flow.tick_battle(base_state, config)
assert_equal(st1.combat.last_turn.attacker, "hero", "最初の攻撃は勇者が行う")
assert_equal(st1.actor.hp, 10, "勇者のターンでは勇者のHPは減らない")
assert_true((st1.combat.enemy.hp or 10) < 10, "勇者の攻撃で敵HPが減る")

local st2 = battle_flow.tick_battle(util.merge_tables(st1, { metrics = { time_sec = 1 } }), config)
assert_equal(st2.combat.last_turn.attacker, "hero", "攻撃演出中は勇者の攻撃情報を保持する")

local st3 = battle_flow.tick_battle(util.merge_tables(st2, { metrics = { time_sec = 2 } }), config)
assert_equal(st3.combat.last_turn.attacker, "enemy", "次の攻撃は敵が行う")
assert_true((st3.actor.hp or 10) < (st1.actor.hp or 10), "敵の攻撃で勇者HPが減る")

print("OK")
