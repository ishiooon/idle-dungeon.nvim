-- このテストはジョブ定義に不要なスプライト情報が含まれないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

-- ジョブ定義に不要な項目が無いことを確認する。
for _, job in ipairs(content.jobs or {}) do
  assert_true(job.sprite == nil, "ジョブ定義にスプライトが含まれない")
  assert_true(type(job.growth) == "table", "ジョブ成長値が定義されている")
  assert_true(type(job.growth.hp) == "number", "ジョブ成長値のHPが定義されている")
  assert_true(type(job.growth.atk) == "number", "ジョブ成長値の攻撃力が定義されている")
  assert_true(type(job.growth.def) == "number", "ジョブ成長値の防御力が定義されている")
  assert_true(type(job.growth.speed) == "number", "ジョブ成長値の速度が定義されている")
  assert_true(type(job.skills) == "table", "ジョブの技一覧が定義されている")
  assert_true(#(job.skills or {}) >= 4, "ジョブごとに十分な数のスキルが定義されている")
  for _, skill in ipairs(job.skills or {}) do
    assert_true(type(skill.id) == "string", "スキルIDが定義されている")
    assert_true(type(skill.level) == "number", "スキルの習得レベルが定義されている")
    assert_true(skill.level >= 5, "スキルの習得レベル下限が5以上である")
    assert_true(type(skill.name) == "string", "スキルの名称が定義されている")
    -- 英語名は言語切り替え時の表示に使う。
    assert_true(type(skill.name_en) == "string", "スキルの英語名が定義されている")
    assert_true(type(skill.description) == "string", "スキル説明が定義されている")
    -- 説明文も日本語と英語の両方を保持する。
    assert_true(type(skill.description_en) == "string", "スキル説明の英語が定義されている")
    assert_true(skill.kind == "active" or skill.kind == "passive", "スキル種別はactive/passiveである")
    if skill.kind == "active" then
      -- アクティブスキルは個別の発動率を持つ。
      assert_true(type(skill.rate) == "number", "アクティブスキルの発動率が定義されている")
    end
    if skill.kind == "passive" then
      -- パッシブスキルは倍率補正で効果を表現する。
      assert_true(type(skill.bonus_mul) == "table", "パッシブスキルの倍率補正が定義されている")
    end
  end
end

print("OK")
