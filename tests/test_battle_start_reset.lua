-- このテストは戦闘開始時に前回の戦闘状態が引き継がれないことを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local transition = require("idle_dungeon.core.transition")

local config = {
  move_step = 1,
  encounter_every = 1,
  floor_encounters = { enabled = false },
  dialogue_seconds = 0,
  stage_name = "Test",
  stages = {
    { id = 1, name = "Test", start = 0, length = 5 },
  },
  battle = { enemy_hp = 1, enemy_atk = 1 },
  event_distances = {},
}

local state = {
  ui = { mode = "move" },
  progress = {
    distance = 0,
    stage_start = 0,
    stage_id = 1,
    stage_name = "Test",
    boss_every = 0,
    boss_milestones = {},
    rng_seed = 1,
  },
  actor = { hp = 5, max_hp = 5, atk = 1, def = 0, speed = 1 },
  equipment = {},
  inventory = {},
  currency = { gold = 0 },
  metrics = { time_sec = 0 },
  combat = { outcome = "reward", outcome_wait = 0 },
}

local next_state = transition.tick(state, config)
assert_equal(next_state.ui.mode, "battle", "戦闘開始で戦闘モードに遷移する")
assert_equal(next_state.combat.outcome, nil, "戦闘開始時に前回の戦闘結果は引き継がれない")

print("OK")
