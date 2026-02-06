-- このテストは保持中のペットが勇者の後ろに表示されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local render = require("idle_dungeon.ui.render")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 0,
  stage_name = "pet-track",
  stages = {
    { id = 1, name = "pet-track", start = 0, length = 20 },
  },
  battle = { enemy_hp = 3, enemy_atk = 1, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = {
    track_length = 14,
    width = 40,
    max_height = 2,
    height = 2,
    icons = { hero = "H", enemy = "E", boss = "B", companion = "P", hp = "H", gold = "G", exp = "X", weapon = "W", armor = "S" },
  },
}

local st0 = state_module.new_state(config)
local st1 = util.merge_tables(st0, {
  pet_party = {
    { id = "white_slime", name = "White Slime", icon = "P", hp = 2, max_hp = 2, atk = 1, def = 0 },
  },
})

local lines = render.build_lines(st1, config)
assert_true(type(lines[1]) == "string", "1行目のトラックが生成される")
assert_contains(lines[1], "P", "ペットのアイコンがトラックに表示される")
assert_contains(lines[1], "H", "勇者アイコンがトラックに表示される")

print("OK")
