-- このテストはジョブ切替直後に現在ステータスが変化しないことを確認する。

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

local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "job-shift",
  stages = {
    { id = 1, name = "job-shift", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
local before = state.actor or {}
local changed = state_module.change_job(state, "guardian")
local after = changed.actor or {}

assert_equal(after.id, "guardian", "ジョブIDは選択したジョブへ切り替わる")
assert_equal(after.max_hp, before.max_hp, "ジョブ切替直後に最大HPは変化しない")
assert_equal(after.atk, before.atk, "ジョブ切替直後に攻撃力は変化しない")
assert_equal(after.def, before.def, "ジョブ切替直後に防御力は変化しない")
assert_equal(after.speed, before.speed, "ジョブ切替直後に速度は変化しない")
assert_true((after.job_level or 0) >= 1, "ジョブ進行情報は有効な値で保持される")

print("OK")
