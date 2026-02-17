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
  default_game_speed = "1x",
  game_speed_options = {
    { id = "1x", label = "1x", tick_seconds = 0.5 },
    { id = "2x", label = "2x", tick_seconds = 0.25 },
    { id = "10x", label = "10x", tick_seconds = 0.05 },
  },
  battle = {
    accuracy = 100,
    hero_speed = 1,
    enemy_speed = 1,
    attack_seconds = 0.6,
    attack_step_seconds = 0.2,
    outcome_wait = 0,
    outcome_seconds = 0.4,
  },
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
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
  },
}

local st1 = battle_flow.tick_battle(state, config)
assert_true(st1.combat.last_turn ~= nil, "ゲーム速度2xでは戦闘ティックも追従して攻撃が実行される")
assert_equal(st1.combat.battle_tick_buffer, 0, "戦闘ティックが一致するため待機バッファは残らない")

local st2 = battle_flow.tick_battle(util.merge_tables(st1, { metrics = { time_sec = 0.25 } }), config)
assert_true(st2.combat.attack_effect ~= nil, "次ティックで攻撃演出が更新される")
assert_equal(st1.combat.last_turn.time_sec, 0.25, "攻撃時刻は2xの戦闘ティックに合わせて記録される")

-- 撃破演出のフレーム数も速度倍率に応じた同一テンポ（同フレーム数）で処理する。
local function build_finish_state(speed_id)
  return {
    actor = { hp = 5, max_hp = 5, atk = 8, def = 0, speed = 1 },
    metrics = { time_sec = 0 },
    progress = { rng_seed = 1 },
    ui = { mode = "battle", game_speed = speed_id },
    combat = {
      enemy = { hp = 1, max_hp = 1, atk = 1, def = 0, accuracy = 100, speed = 1 },
      turn = "hero",
      turn_wait = 0,
      hero_turn_wait = 0,
      enemy_turn_wait = 0,
    },
  }
end

local slow_finish = battle_flow.tick_battle(build_finish_state("1x"), config)
local fast_finish = battle_flow.tick_battle(build_finish_state("10x"), config)
assert_equal(slow_finish.combat.attack_effect, fast_finish.combat.attack_effect, "攻撃演出フレームは速度倍率に依存して同一テンポで解決する")
assert_equal(slow_finish.combat.attack_step, fast_finish.combat.attack_step, "前進演出フレームは速度倍率に依存して同一テンポで解決する")
assert_equal(slow_finish.combat.outcome_wait, fast_finish.combat.outcome_wait, "勝敗待機フレームは速度倍率に依存して同一テンポで解決する")
assert_equal(slow_finish.combat.last_turn.time_sec, 0.5, "1x時の攻撃記録時刻は0.5秒進む")
assert_equal(fast_finish.combat.last_turn.time_sec, 0.05, "10x時の攻撃記録時刻は0.05秒進む")

print("OK")
