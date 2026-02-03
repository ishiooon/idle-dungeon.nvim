-- このテストは速度上昇中でも攻撃演出の時刻が一致することを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle_flow = require("idle_dungeon.core.transition.battle")

local config = {
  tick_seconds = 1,
  battle = { accuracy = 100, hero_speed = 1, enemy_speed = 1 },
}

local state = {
  actor = { hp = 5, max_hp = 5, atk = 2, def = 0, speed = 1 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle", speed_boost = { remaining_ticks = 3, tick_seconds = 0.5 } },
  combat = {
    enemy = { hp = 4, max_hp = 4, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = "hero",
    turn_wait = 0,
  },
}

local next_state = battle_flow.tick_battle(state, config)
assert_equal(next_state.combat.last_turn.time_sec, 0.5, "速度上昇中の攻撃時刻は短縮されたティックに一致する")

print("OK")
