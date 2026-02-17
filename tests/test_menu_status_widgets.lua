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
  stage_name = "azure-vault",
  stages = {
    { id = 1, name = "azure-vault", start = 0, length = 10 },
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

local items = menu_data.build_status_items(state, config, "en", { show_details = true })
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
assert_match(text, "azure%-vault", "状態タブ本文のどこかで現在ダンジョン名が分かる")
assert_not_match(text, "Event Boost", "一時加速がない時は加速表示を出さない")
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

-- イベント由来の一時加速がある場合は、状態タブに明示する。
local boosted_state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, {
    game_speed = "10x",
    speed_boost = {
      remaining_ticks = 6,
      tick_seconds = 0.01,
    },
  }),
})
local boosted_config = util.merge_tables(config, {
  default_game_speed = "1x",
  game_speed_options = {
    { id = "1x", label = "1x", tick_seconds = 0.5 },
    { id = "10x", label = "10x", tick_seconds = 0.05 },
  },
})
local boosted_items = menu_data.build_status_items(boosted_state, boosted_config, "en", { show_details = true })
local boosted_joined = {}
for _, item in ipairs(boosted_items) do
  if item and item.label then
    table.insert(boosted_joined, item.label)
  end
end
local boosted_text = table.concat(boosted_joined, " ")
assert_match(boosted_text, "Event Boost", "一時加速の表示が状態タブに出る")
assert_match(boosted_text, "5%.0x", "加速倍率が表示される")
assert_match(boosted_text, "6T left", "残りティックが表示される")

print("OK")
