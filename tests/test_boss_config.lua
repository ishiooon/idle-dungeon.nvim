-- このテストはステージごとのボスIDが有効であることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local stage_defaults = require("idle_dungeon.config.stages")

local enemies = {}
for _, enemy in ipairs(content.enemies or {}) do
  enemies[enemy.id] = enemy
end

for _, stage in ipairs(stage_defaults.default_stages()) do
  assert_true(stage.boss_id ~= nil and stage.boss_id ~= "", "ステージにボスIDが設定される")
  assert_true(enemies[stage.boss_id] ~= nil, "ボスIDが敵定義に存在する")
  local boss = enemies[stage.boss_id]
  assert_true(type(boss.elements) == "table" and #boss.elements > 0, "ボスに属性リストが定義される")
end

print("OK")
