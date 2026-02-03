-- このテストは敵のHPが0のときに敗北アイコンが表示されることを確認する。

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

local render_battle = require("idle_dungeon.ui.render_battle_info")
local render = require("idle_dungeon.ui.render")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local util = require("idle_dungeon.util")

local state = {
  actor = { name = "Hero", hp = 5, max_hp = 10 },
  metrics = { time_sec = 0 },
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 0, max_hp = 8, is_boss = false },
    source = { id = "dust_slime", position = 7, element = "normal" },
    last_turn = {
      attacker = "hero",
      time_sec = 0,
      result = { hit = true, damage = 2, element = "fire", attacker = "hero" },
    },
  },
  progress = {
    distance = 0,
    floor_enemies = {
      { id = "dust_slime", element = "normal", position = 4, defeated = false },
      { id = "dust_slime", element = "normal", position = 7, defeated = false },
    },
  },
  ui = { mode = "battle", render_mode = "visual" },
}

local config = {
  ui = { icons = { hero = "H", enemy = "E", boss = "B", hp = "", defeat = "T" }, width = 40, track_length = 12 },
  battle = { encounter_gap = 0 },
}
local line_hp = render_battle.build_battle_info_line(state, config, "en")
assert_match(line_hp, "T", "敵HPが0のとき敗北アイコンが表示される")
assert_not_match(line_hp, "", "敵HPが0のとき元の敵アイコンは表示されない")

local lines = render.build_lines(state, config)
local line_track = lines[1] or ""
local tomb_count = 0
local enemy_count = 0
local enemy_icon = (enemy_catalog.find_enemy("dust_slime") or {}).icon or "E"
for _, char in ipairs(util.split_utf8(line_track)) do
  if char == "T" then
    tomb_count = tomb_count + 1
  elseif char == enemy_icon then
    enemy_count = enemy_count + 1
  end
end
if tomb_count ~= 1 then
  error("敗北アイコンが複数表示されています: " .. line_track)
end
if enemy_count ~= 1 then
  error("他の敵アイコンが保持されていません: " .. line_track)
end

print("OK")
