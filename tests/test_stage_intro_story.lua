-- このテストはステージ導入文に濃いストーリーが定義されていることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

local function has_text(value)
  return type(value) == "string" and value:match("%S") ~= nil
end

local function count_chars(value, util)
  if type(value) ~= "string" then
    return 0
  end
  return #util.split_utf8(value)
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local util = require("idle_dungeon.util")

local intros = content.stage_intros or {}
assert_true(#intros > 0, "ステージ導入文が定義されている")

for _, intro in ipairs(intros) do
  local story = intro.story or {}
  assert_true(has_text(story.en), "英語のストーリーが定義される: " .. tostring(intro.id))
  assert_true(has_text(story.ja), "日本語のストーリーが定義される: " .. tostring(intro.id))
  -- 濃いストーリーを意識して十分な長さを確保する。
  assert_true(count_chars(story.en, util) >= 900, "英語ストーリーが十分に長い: " .. tostring(intro.id))
  -- 長さの担保は品質を下げない範囲に留め、内容の密度を優先する。
  assert_true(count_chars(story.ja, util) >= 900, "日本語ストーリーが十分に長い: " .. tostring(intro.id))
  -- 物語の目標は「春を取り戻す」に統一する。
  assert_match(story.ja, "春", "春の目標が日本語文に含まれる: " .. tostring(intro.id))
end

local stage1 = nil
for _, intro in ipairs(intros) do
  if intro.stage_id == 1 then
    stage1 = intro
    break
  end
end
assert_true(stage1 ~= nil, "ステージ1の導入文が存在する")
assert_match(stage1.story.en, "[Ii]ce", "氷から始まる理由が英語文に含まれる")
assert_match(stage1.story.ja, "氷", "氷から始まる理由が日本語文に含まれる")
assert_match(stage1.story.ja, "師", "師の登場が日本語文に含まれる")
assert_match(stage1.story.ja, "取り戻", "春を取り戻す動機が日本語文に含まれる")
assert_true(stage1.story.en:match("^Ice is not") == nil, "ステージ1の英語文がメタ的な書き出しでない")
assert_true(stage1.story.ja:match("^初手が氷") == nil, "ステージ1の日本語文がメタ的な書き出しでない")

local stage8 = nil
for _, intro in ipairs(intros) do
  if intro.stage_id == 8 then
    stage8 = intro
    break
  end
end
assert_true(stage8 ~= nil, "ステージ8の導入文が存在する")
assert_match(stage8.story.en, "corridor", "無限回廊への到達が英語文に含まれる")
assert_match(stage8.story.ja, "回廊", "無限回廊への到達が日本語文に含まれる")
-- 師の役割が曖昧にならないよう、直接的な説明が含まれることを確認する。
assert_match(stage8.story.ja, "師", "師の存在が日本語文で示される")
assert_match(stage8.story.ja, "役目", "師の役目が日本語文で示される")
assert_true(stage8.story.ja:match("溶け") == nil, "師が溶け込む表現は避ける")

print("OK")
