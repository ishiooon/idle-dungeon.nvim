-- このテストは敵の成長がステージとフロアで加速することを確認する。

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

local battle = require("idle_dungeon.game.battle")
local config_module = require("idle_dungeon.config")

local base_config = {
  floor_length = 5,
  enemy_names = { "dust_slime" },
  elements = { "normal" },
  stages = {
    { id = 1, name = "StageOne", floors = 2 },
    { id = 2, name = "StageTwo", floors = 2 },
  },
  battle = {
    enemy_hp = 4,
    enemy_atk = 1,
    growth_base = 1,
    growth_floor = 2,
    growth_stage = 8,
    growth_hp = 2,
    growth_atk = 1,
    growth_def = 0.5,
    growth_speed = 1,
    growth_boss_multiplier = 1.5,
  },
}

local config = config_module.build(base_config)
local floor_length = config.floor_length
local stage1_start = (config.stages[1] or {}).start or 0
local stage2_start = (config.stages[2] or {}).start or 0

local enemy_start = battle.build_enemy(stage1_start, config, nil)
local enemy_floor2 = battle.build_enemy(stage1_start + floor_length, config, nil)
local enemy_stage2 = battle.build_enemy(stage2_start, config, nil)

assert_true(enemy_start.hp < enemy_floor2.hp, "同一ステージ内でHPが増加する")
assert_true(enemy_floor2.hp < enemy_stage2.hp, "次ステージでHPが増加する")
assert_true(enemy_start.atk <= enemy_floor2.atk, "同一ステージ内で攻撃力が増加する")
assert_true(enemy_floor2.atk <= enemy_stage2.atk, "次ステージで攻撃力が増加する")
assert_true(enemy_start.speed >= enemy_floor2.speed, "同一ステージ内で攻撃速度が速くなる")
assert_true(enemy_floor2.speed >= enemy_stage2.speed, "次ステージで攻撃速度が速くなる")
assert_equal(type(enemy_stage2.level), "number", "敵の成長レベルが数値で保持される")

print("OK")
