-- このテストは装備データの件数と敵ドロップへの紐付けを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

local items = content.items or {}
local enemies = content.enemies or {}

assert_true(#items >= 60, "装備データは60種類以上を用意する")

local drop_ids = {}
for _, enemy in ipairs(enemies) do
  local drops = enemy.drops or {}
  for _, item_id in ipairs(drops.common or {}) do
    drop_ids[item_id] = true
  end
  for _, item_id in ipairs(drops.rare or {}) do
    drop_ids[item_id] = true
  end
  for _, item_id in ipairs(drops.pet or {}) do
    drop_ids[item_id] = true
  end
end

for _, item in ipairs(items) do
  assert_true(item.id ~= nil and item.id ~= "", "装備IDが必須である")
  assert_true(item.name ~= nil and item.name ~= "", "装備の日本語名が必須である")
  assert_true(item.name_en ~= nil and item.name_en ~= "", "装備の英語名が必須である")
  assert_true(item.slot ~= nil and item.slot ~= "", "装備スロットが必須である")
  assert_true(item.rarity ~= nil and item.rarity ~= "", "装備の希少度が必須である")
  assert_true(type(item.flavor) == "table", "装備のフレーバーテキストが必須である")
  assert_true(drop_ids[item.id] == true, "装備は敵ドロップに紐付く: " .. item.id)
end

print("OK")
