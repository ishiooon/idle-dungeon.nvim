-- このテストは状態の初期化が期待通りに行われることを確認する。
-- core配下への整理に合わせて参照先を更新する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state = require("idle_dungeon.core.state")

local config = {
  stage_name = "dungeon1-2",
  enemy_names = { "a" },
  battle = { enemy_hp = 3, enemy_atk = 1, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
}

local st0 = state.new_state(config)
local st1 = state.tick(st0, config)
local reset = state.reset_state(config)

assert_equal(st1.progress.distance ~= reset.progress.distance, true, "進行距離が初期化される")
assert_equal(reset.progress.stage_name, "dungeon1-2", "開始ステージが初期状態に戻る")
assert_equal(reset.actor.level, 1, "レベルが初期化される")

print("OK")
