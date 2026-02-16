-- このテストは状態タブに進行バーと指標が表示されることを確認する。

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

local function assert_not_match(text, pattern, message)
  if text:match(pattern) then
    error((message or "assert_not_match failed") .. ": " .. tostring(text) .. " =~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  stage_name = "test-stage",
  stages = {
    { id = 1, name = "test-stage", start = 0, length = 10 },
  },
  ui = {
    language = "en",
    menu = {
      meter = { on = "▬", off = "▭" },
    },
  },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  actor = util.merge_tables(state.actor or {}, {
    hp = 18,
    max_hp = 40,
    exp = 120,
    next_level = 220,
  }),
  progress = util.merge_tables(state.progress or {}, {
    stage_step = 3,
    stage_total = 10,
  }),
})

local items = menu_data.build_status_items(state, config, "en")
local joined = {}
for _, item in ipairs(items) do
  if item and item.label then
    table.insert(joined, item.label)
  end
end
local text = table.concat(joined, " ")

local function prefix_width(line, marker)
  local start_pos = string.find(line or "", marker, 1, true)
  if not start_pos or start_pos <= 1 then
    return 0
  end
  return util.display_width(string.sub(line, 1, start_pos - 1))
end

local function count_literal(text_source, needle)
  local total = 0
  local cursor = 1
  while true do
    local start_pos, end_pos = string.find(text_source or "", needle or "", cursor, true)
    if not start_pos then
      return total
    end
    total = total + 1
    cursor = end_pos + 1
  end
end

assert_match(text, "HP", "HPの指標が表示される")
assert_match(text, "%[", "進行バーの開始記号が表示される")
assert_match(text, "%]", "進行バーの終了記号が表示される")
assert_match(text, "▬", "バー表示は設定された塗りつぶしインジケータを使う")
assert_not_match(text, "#", "バー表示に#を使わない")
assert_not_match(text, "%d+ step%(s%) to enemy", "状態タブに敵まで残り歩数を表示しない")
assert_not_match(text, "Move %d+ step%(s%)", "次行動文言に残り歩数を表示しない")
assert_not_match(text, "Approaching", "状態タブに接敵状況の文言を表示しない")
assert_true(count_literal(text, "Exp:") == 1, "状態タブの経験値表示は勇者分のみを表示する")
assert_match(text, "Next Reward", "状態タブに次の報酬行が表示される")
assert_true(#items >= 8, "状態タブの項目数が不足しない")

local hp_line = nil
local exp_line = nil
for _, item in ipairs(items) do
  local label = (item and item.label) or ""
  if not hp_line and string.find(label, "HP", 1, true) then
    hp_line = label
  end
  if not exp_line and (string.find(label, "Exp:", 1, true) or string.find(label, "経験値:", 1, true)) then
    exp_line = label
  end
end
assert_true(hp_line ~= nil, "HP行が存在する")
assert_true(exp_line ~= nil, "EXP行が存在する")
assert_true(prefix_width(hp_line, "[") == prefix_width(exp_line, "["), "HPとEXPのバー開始位置が揃う")

print("OK")
