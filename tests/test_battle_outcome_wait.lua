-- このテストは撃破や敗北時でもHPが0になる瞬間まで戦闘表示が続くことを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle_flow = require("idle_dungeon.core.transition.battle")
local util = require("idle_dungeon.util")

local config = {
  game_tick_seconds = 1,
  battle_tick_seconds = 1,
  default_game_speed = "1x",
  game_speed_options = {
    { id = "1x", label = "1x", tick_seconds = 1 },
  },
  battle = { accuracy = 100, hero_speed = 1, enemy_speed = 1, outcome_wait = 0 },
}

local base_state = {
  actor = { hp = 2, max_hp = 2, atk = 2, def = 0, speed = 1 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = { hp = 1, max_hp = 1, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = "hero",
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
  },
}

local st1 = battle_flow.tick_battle(base_state, config)
assert_equal(st1.ui.mode, "battle", "撃破直後も戦闘表示が維持される")
assert_equal(st1.combat.enemy.hp, 0, "撃破直後は敵HPが0になる")

local st2 = battle_flow.tick_battle(util.merge_tables(st1, { metrics = { time_sec = 1 } }), config)
-- 演出のために最低1ティック分は戦闘表示を維持する。
assert_equal(st2.ui.mode, "battle", "撃破後は最低1ティック分戦闘表示を維持する")
local st3 = battle_flow.tick_battle(util.merge_tables(st2, { metrics = { time_sec = 2 } }), config)
assert_equal(st3.ui.mode, "battle", "演出後も次の遷移までは戦闘表示を維持する")
local st4 = battle_flow.tick_battle(util.merge_tables(st3, { metrics = { time_sec = 3 } }), config)
assert_equal(st4.ui.mode, "reward", "待機後に報酬表示へ移行する")

print("OK")
