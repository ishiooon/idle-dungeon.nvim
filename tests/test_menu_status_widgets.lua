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
  ui = { language = "en" },
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

assert_match(text, "HP", "HPの指標が表示される")
assert_match(text, "%[", "進行バーの開始記号が表示される")
assert_match(text, "%]", "進行バーの終了記号が表示される")
assert_match(text, "┃", "バー表示は縦棒インジケータを使う")
assert_not_match(text, "#", "バー表示に#を使わない")
assert_true(#items > 8, "状態タブの項目数が不足しない")

print("OK")
