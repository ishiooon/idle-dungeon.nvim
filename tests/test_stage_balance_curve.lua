-- このテストは序盤の手応えと中盤以降の伸び過ぎ抑制を同時に確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config_module = require("idle_dungeon.config")
local battle = require("idle_dungeon.game.battle")

local config = config_module.build({})
local stages = config.stages or {}

local function build_at_stage(stage_index)
  local stage = stages[stage_index] or {}
  return battle.build_enemy(stage.start or 0, config, { id = "dust_slime" })
end

local stage1_enemy = build_at_stage(1)
local stage3_enemy = build_at_stage(3)
local stage6_enemy = build_at_stage(6)

-- 1〜3は弱すぎない手応えを維持する。
assert_true((stage1_enemy.hp or 0) >= 9, "ステージ1開幕の敵HPは9以上にする")
assert_true((stage1_enemy.atk or 0) >= 3, "ステージ1開幕の敵ATKは3以上にする")

-- 進行に合わせて強くはなるが、6-1で詰まる急上昇は抑える。
assert_true((stage3_enemy.hp or 0) > (stage1_enemy.hp or 0), "ステージ3はステージ1より強い")
assert_true((stage6_enemy.hp or 0) > (stage3_enemy.hp or 0), "ステージ6はステージ3より強い")
assert_true((stage6_enemy.hp or 0) <= 100, "ステージ6開幕の敵HPは100以下に抑える")
assert_true((stage6_enemy.atk or 0) <= 55, "ステージ6開幕の敵ATKは55以下に抑える")

local ratio = (stage6_enemy.hp or 1) / math.max(stage3_enemy.hp or 1, 1)
assert_true(ratio <= 1.7, "ステージ3から6へのHP上昇倍率を1.7倍以下に抑える")

print("OK")
