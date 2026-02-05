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
  assert_true(type(enemy.skills) == "table", "敵スキルが定義される")
  for _, skill in ipairs(enemy.skills or {}) do
    assert_true(type(skill.id) == "string", "敵スキルIDが定義される")
    assert_true(type(skill.name) == "string", "敵スキル名が定義される")
    -- 英語表記は言語切り替え表示のため必須とする。
    assert_true(type(skill.name_en) == "string", "敵スキルの英語名が定義される")
    assert_true(skill.kind == "active" or skill.kind == "passive", "敵スキル種別が定義される")
    if skill.kind == "active" then
      assert_true(type(skill.rate) == "number", "敵アクティブの発動率が定義される")
    end
    if skill.kind == "passive" then
      assert_true(type(skill.bonus_mul) == "table", "敵パッシブの倍率補正が定義される")
    end
    -- 説明文は日本語と英語の両方を持たせる。
    assert_true(type(skill.description) == "string", "敵スキル説明が定義される")
    assert_true(type(skill.description_en) == "string", "敵スキル説明の英語が定義される")
  end
end

print("OK")
