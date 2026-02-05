-- このテストは敵ごとの固有スキルが割り当てられることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

for _, enemy in ipairs(content.enemies or {}) do
  local has_own = false
  for _, skill in ipairs(enemy.skills or {}) do
    if type(skill.id) == "string" and skill.id:match("^" .. enemy.id .. "_") then
      has_own = true
      break
    end
  end
  assert_true(has_own, "敵ごとの固有スキルIDが割り当てられる")
  for _, skill in ipairs(enemy.skills or {}) do
    local name = tostring(skill.name or "")
    local description = tostring(skill.description or "")
    local name_en = tostring(skill.name_en or "")
    local description_en = tostring(skill.description_en or "")
    -- 個体名を含めず、汎用的な技名と説明にする。
    if enemy.name_ja and enemy.name_ja ~= "" then
      assert_true(not name:match(enemy.name_ja), "スキル名に個体名を含めない")
      assert_true(not description:match(enemy.name_ja), "スキル説明に個体名を含めない")
    end
    if enemy.name_en and enemy.name_en ~= "" then
      assert_true(not name:match(enemy.name_en), "スキル名に英語の個体名を含めない")
      assert_true(not description:match(enemy.name_en), "スキル説明に英語の個体名を含めない")
    end
    if enemy.name_ja and enemy.name_ja ~= "" then
      assert_true(not name_en:match(enemy.name_ja), "英語スキル名に個体名を含めない")
      assert_true(not description_en:match(enemy.name_ja), "英語スキル説明に個体名を含めない")
    end
    if enemy.name_en and enemy.name_en ~= "" then
      assert_true(not name_en:match(enemy.name_en), "英語スキル名に英語の個体名を含めない")
      assert_true(not description_en:match(enemy.name_en), "英語スキル説明に英語の個体名を含めない")
    end
  end
end

-- 敵アクティブスキル名が重複しないことを確認する。
local seen_active = {}
local seen_active_en = {}
for _, enemy in ipairs(content.enemies or {}) do
  for _, skill in ipairs(enemy.skills or {}) do
    if skill.kind == "active" then
      assert_true(not seen_active[skill.name], "アクティブスキル名が重複しない")
      seen_active[skill.name] = true
      assert_true(not seen_active_en[skill.name_en], "英語アクティブスキル名が重複しない")
      seen_active_en[skill.name_en] = true
    end
  end
end

print("OK")
