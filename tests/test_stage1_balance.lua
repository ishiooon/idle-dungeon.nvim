-- このテストはステージ1の敵が極端に弱くならないように基準値を確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local stages = require("idle_dungeon.config.stages")

local function find_enemy(enemies, enemy_id)
  for _, enemy in ipairs(enemies or {}) do
    if enemy.id == enemy_id then
      return enemy
    end
  end
  return nil
end

local function find_item(items, item_id)
  for _, item in ipairs(items or {}) do
    if item.id == item_id then
      return item
    end
  end
  return nil
end

local stage1 = (stages.default_stages() or {})[1] or {}
local pool = stage1.enemy_pool or {}
local ids = {}
for _, entry in ipairs(pool.fixed or {}) do
  ids[entry] = true
end
for _, entry in ipairs(pool.mixed or {}) do
  ids[entry] = true
end

for enemy_id, _ in pairs(ids) do
  local enemy = find_enemy(content.enemies or {}, enemy_id)
  assert_true(enemy ~= nil, "ステージ1の敵が定義されている: " .. enemy_id)
  local hp = (enemy.stats or {}).hp or 0
  assert_true(hp >= 6, "ステージ1の敵HPは6以上である: " .. enemy_id)
end

local bow = find_item(content.items or {}, "short_bow")
assert_true(bow ~= nil, "short_bow が定義されている")
assert_true((bow.atk or 0) <= 2, "short_bow の攻撃力は抑えめである")

print("OK")
