-- このテストはステージ1の2階層目で敵が初期状態の一撃で倒れにくいことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config_module = require("idle_dungeon.config")
local battle = require("idle_dungeon.game.battle")
local floor_progress = require("idle_dungeon.game.floor.progress")
local state_module = require("idle_dungeon.core.state")

local config = config_module.build({})
local state = state_module.new_state(config)
local hero = state.actor or {}
local stage1 = (config.stages or {})[1] or {}
local floor_length = floor_progress.resolve_floor_length(config)
local second_floor_distance = (stage1.start or 0) + floor_length

local ids = {}
for _, enemy_id in ipairs(((stage1.enemy_pool or {}).fixed) or {}) do
  ids[enemy_id] = true
end
for _, enemy_id in ipairs(((stage1.enemy_pool or {}).mixed) or {}) do
  ids[enemy_id] = true
end

for enemy_id, _ in pairs(ids) do
  local enemy = battle.build_enemy(second_floor_distance, config, { id = enemy_id })
  local hero_damage = math.max((hero.atk or 0) - (enemy.def or 0), 1)
  assert_true(
    hero_damage < (enemy.hp or 0),
    "ステージ1-2の敵は初期攻撃で一撃撃破になりにくくする: " .. tostring(enemy_id)
  )
end

print("OK")
