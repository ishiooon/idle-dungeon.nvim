-- このテストはメニュー上部ライブヘッダの敵表示が右下表示と同じ撃破挙動になることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_not_match(text, pattern, message)
  if text:match(pattern) then
    error((message or "assert_not_match failed") .. ": " .. tostring(text) .. " =~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local live_header = require("idle_dungeon.menu.live_header")
local util = require("idle_dungeon.util")

local config = {
  ui = {
    width = 40,
    track_length = 12,
    icons = { hero = "H", enemy = "E", boss = "B", hp = "H", defeat = "T" },
  },
  battle = { encounter_gap = 0 },
}

local battle_state = {
  actor = { id = "recorder", hp = 10, max_hp = 10, exp = 0, next_level = 10 },
  metrics = { time_sec = 0 },
  ui = { mode = "battle", render_mode = "visual", language = "en" },
  combat = {
    enemy = { id = "ghost_test_enemy", hp = 0, max_hp = 8, is_boss = false },
    source = { id = "ghost_test_enemy", element = "normal", position = 7 },
    last_turn = { attacker = "hero", result = {} },
  },
  progress = {
    distance = 0,
    floor_enemies = {
      { id = "ghost_test_enemy", element = "normal", position = 4, defeated = false },
      { id = "ghost_test_enemy", element = "normal", position = 7, defeated = false },
    },
  },
}

local battle_lines = live_header.build_lines(battle_state, config, "en")
local battle_track = battle_lines[1] or ""
local tomb_count = 0
local enemy_count = 0
for _, char in ipairs(util.split_utf8(battle_track)) do
  if char == "T" then
    tomb_count = tomb_count + 1
  elseif char == "E" then
    enemy_count = enemy_count + 1
  end
end
assert_true(tomb_count == 1, "撃破対象だけ墓標アイコンで表示する")
assert_true(enemy_count == 1, "未撃破の同種敵は通常アイコンで表示する")

local reward_state = {
  actor = battle_state.actor,
  metrics = battle_state.metrics,
  ui = util.merge_tables(battle_state.ui, { mode = "reward" }),
  combat = battle_state.combat,
  progress = {
    distance = 0,
    floor_enemies = {},
  },
}
local reward_lines = live_header.build_lines(reward_state, config, "en")
local reward_track = reward_lines[1] or ""
assert_not_match(reward_track, "T", "報酬表示中に戦闘対象の墓標を追加しない")
assert_not_match(reward_track, "E", "報酬表示中に戦闘対象の敵アイコンを追加しない")

print("OK")
