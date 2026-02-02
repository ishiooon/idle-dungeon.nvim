-- このテストはステージ解放のルールが期待通りであることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_false(value, message)
  if value then
    error(message or "assert_false failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local stage_unlock = require("idle_dungeon.game.stage_unlock")

local stages = {
  { id = 1, name = "stage-1" },
  { id = 2, name = "stage-2" },
  { id = 3, name = "stage-3" },
}

local unlocks = stage_unlock.initial_unlocks(stages)
assert_true(stage_unlock.is_unlocked(unlocks, 1), "最初のステージは解放済み")
assert_false(stage_unlock.is_unlocked(unlocks, 2), "次のステージは未解放")

local unlocked_after_clear = stage_unlock.unlock_next(unlocks, stages, 1)
assert_true(stage_unlock.is_unlocked(unlocked_after_clear, 2), "ステージ1クリアでステージ2が解放される")

print("OK")
