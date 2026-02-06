-- このテストはゲーム速度の変更が戦闘進行にも反映されることを確認する。

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

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle_flow = require("idle_dungeon.core.transition.battle")
local util = require("idle_dungeon.util")

local config = {
  game_tick_seconds = 0.5,
  battle_tick_seconds = 0.5,
  battle = { accuracy = 100, hero_speed = 1, enemy_speed = 1 },
}

local state = {
  actor = { hp = 5, max_hp = 5, atk = 2, def = 0, speed = 1 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle", game_speed = "2x" },
  combat = {
    enemy = { hp = 4, max_hp = 4, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = "hero",
    turn_wait = 0,
  },
}

local st1 = battle_flow.tick_battle(state, config)
assert_true(st1.combat.last_turn ~= nil, "ゲーム速度2xでは戦闘ティックも追従して攻撃が実行される")
assert_equal(st1.combat.battle_tick_buffer, 0, "戦闘ティックが一致するため待機バッファは残らない")

local st2 = battle_flow.tick_battle(util.merge_tables(st1, { metrics = { time_sec = 0.25 } }), config)
assert_true(st2.combat.attack_effect ~= nil, "次ティックで攻撃演出が更新される")
assert_equal(st1.combat.last_turn.time_sec, 0.25, "攻撃時刻は2xの戦闘ティックに合わせて記録される")

print("OK")
