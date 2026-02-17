-- このテストは各ジョブに高レベル帯の強力なスキルが定義されていることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

-- 高レベル帯の到達目標レベルを定義する。
local required_levels = { 50, 100, 200, 500, 1000 }

-- 高レベルスキルはインフレ前提のため、通常帯より十分高い閾値を要求する。
local function is_strong_skill(skill)
  if skill.kind == "active" then
    return type(skill.power) == "number" and skill.power >= 2.5
  end
  if skill.kind == "passive" then
    local highest = 0
    for _, value in pairs(skill.bonus_mul or {}) do
      if type(value) == "number" and value > highest then
        highest = value
      end
    end
    return highest >= 1.5
  end
  return false
end

for _, job in ipairs(content.jobs or {}) do
  local skills = job.skills or {}
  for _, level in ipairs(required_levels) do
    local found = nil
    for _, skill in ipairs(skills) do
      if skill.level == level then
        found = skill
        break
      end
    end
    assert_true(found ~= nil, string.format("ジョブ%sにLv%dスキルが存在する", tostring(job.id), level))
    assert_true(type(found.name) == "string" and found.name ~= "", "高レベルスキルに日本語名が定義される")
    assert_true(type(found.name_en) == "string" and found.name_en ~= "", "高レベルスキルに英語名が定義される")
    assert_true(type(found.description) == "string" and found.description ~= "", "高レベルスキルに説明が定義される")
    assert_true(type(found.description_en) == "string" and found.description_en ~= "", "高レベルスキルに英語説明が定義される")
    assert_true(is_strong_skill(found), string.format("ジョブ%sのLv%dスキルは十分に強力である", tostring(job.id), level))
  end
end

print("OK")
