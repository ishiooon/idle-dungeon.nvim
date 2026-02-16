-- このテストはジョブレベルが勇者レベルの上昇に同期することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local player = require("idle_dungeon.game.player")

local job = {
  id = "test_job",
  name = "テストジョブ",
  role = "検証用",
  base = { hp = 10, atk = 2, def = 1, speed = 2 },
  growth = { hp = 1, atk = 0, def = 0, speed = 0 },
  skills = {},
  dialogue_ratio = 1.0,
}

local hero_progress = { level = 1, exp = 0, next_level = 5 }
local job_progress = { level = 1 }
local actor = player.new_actor(job, hero_progress, job_progress)

local next_actor, next_job = player.add_exp_with_job(actor, 5, job_progress, job)

assert_true(next_job.level == 2, "勇者レベルの上昇に合わせてジョブレベルが上がる")
assert_true(next_actor.job_level == next_job.level, "勇者側のジョブレベルが反映される")

print("OK")
