-- このテストは戦闘時の進行トラックに演出記号が含まれることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
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
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  battle = { enemy_hp = 3, enemy_atk = 1, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = {
    track_length = 12,
    width = 36,
    max_height = 2,
    height = 2,
    icons = { hero = "H", enemy = "E", boss = "B", hp = "H", gold = "G", exp = "E" },
    battle_effects = { "*", "+", "x" },
  },
}

local base_state = state_module.new_state(config)
local battle_state = util.merge_tables(base_state, {
  ui = util.merge_tables(base_state.ui, { mode = "battle" }),
  progress = util.merge_tables(base_state.progress, {
    floor_enemies = { { id = "dust_slime", position = 8, defeated = false } },
  }),
  combat = {
    enemy = { id = "dust_slime", name = "Dust Slime", is_boss = false },
    last_turn = {
      hero = { hit = true, damage = 2, element = "fire", attacker = "hero" },
      enemy = { hit = false, damage = 0, element = "water", attacker = "enemy" },
    },
  },
})

local lines = render.build_lines(battle_state, config)
-- 攻撃側ごとの演出記号が表示されることを確認する。
assert_match(lines[1] or "", "%*", "勇者の攻撃演出が表示される")
assert_match(lines[1] or "", "x", "敵の攻撃演出が表示される")

print("OK")
