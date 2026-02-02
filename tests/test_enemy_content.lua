-- このテストは敵データの件数と必須項目が揃っていることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

local enemies = content.enemies or {}
assert_true(#enemies >= 80, "敵データは80種類以上を用意する")

for _, enemy in ipairs(enemies) do
  assert_true(enemy.id ~= nil and enemy.id ~= "", "敵IDが必須である")
  assert_true(enemy.name_en ~= nil and enemy.name_en ~= "", "英語名が必須である")
  assert_true(enemy.name_ja ~= nil and enemy.name_ja ~= "", "日本語名が必須である")
  assert_true(enemy.icon ~= nil and enemy.icon ~= "", "アイコンが必須である")
  assert_true(type(enemy.stats) == "table", "ステータスが定義される")
  assert_true(type(enemy.stats.hp) == "number", "HPが数値で定義される")
  assert_true(type(enemy.stats.atk) == "number", "攻撃力が数値で定義される")
  assert_true(type(enemy.stats.def) == "number", "防御力が数値で定義される")
  assert_true(type(enemy.stats.accuracy) == "number", "命中率が数値で定義される")
  assert_true(type(enemy.drops) == "table", "ドロップ定義が存在する")
  assert_true(type(enemy.drops.common) == "table", "通常ドロップが定義される")
  assert_true(type(enemy.drops.rare) == "table", "レアドロップが定義される")
  assert_true(type(enemy.drops.pet) == "table", "ペットドロップが定義される")
  assert_true(type(enemy.drops.gold) == "table", "ゴールドドロップが定義される")
  assert_true(type(enemy.drops.gold.min) == "number", "ゴールド最小値が数値で定義される")
  assert_true(type(enemy.drops.gold.max) == "number", "ゴールド最大値が数値で定義される")
  assert_true(type(enemy.flavor) == "table", "フレーバーテキストが定義される")
end

print("OK")
