-- このテストはステージ1開幕で被ダメージが常に最小値1に張り付かないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle = require("idle_dungeon.game.battle")
local config_module = require("idle_dungeon.config")
local state_module = require("idle_dungeon.core.state")

-- ステージ1の敵IDを重複なく取り出す。
local function collect_stage1_enemy_ids(stage)
  local ids = {}
  local seen = {}
  local pool = (stage or {}).enemy_pool or {}
  for _, enemy_id in ipairs(pool.fixed or {}) do
    if not seen[enemy_id] then
      table.insert(ids, enemy_id)
      seen[enemy_id] = true
    end
  end
  for _, enemy_id in ipairs(pool.mixed or {}) do
    if not seen[enemy_id] then
      table.insert(ids, enemy_id)
      seen[enemy_id] = true
    end
  end
  return ids
end

local config = config_module.build({})
local state = state_module.new_state(config)
local stage1 = (config.stages or {})[1] or {}
local distance = stage1.start or 0
local actor = state.actor or {}
local enemy_ids = collect_stage1_enemy_ids(stage1)

assert_true(#enemy_ids > 0, "ステージ1の敵候補が1件以上ある")

local max_damage = 0
for _, enemy_id in ipairs(enemy_ids) do
  local enemy = battle.build_enemy(distance, config, { id = enemy_id })
  local damage = battle.calc_damage(enemy.atk or 0, actor.def or 0)
  if damage > max_damage then
    max_damage = damage
  end
end

assert_true(max_damage >= 2, "ステージ1開幕で最低2ダメージを与える敵が存在する")

print("OK")
