-- このテストは戦闘時の進行トラックに演出記号が含まれることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
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
local sprite = require("idle_dungeon.ui.sprite")
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
    icons = { hero = "H", enemy = "E", boss = "B", hp = "H", gold = "G", exp = "E", weapon = "W", armor = "S" },
  },
}

local base_state = state_module.new_state(config)
local battle_state = util.merge_tables(base_state, {
  -- 攻撃演出は該当ティックのみなので時刻を合わせておく。
  metrics = { time_sec = 99 },
  ui = util.merge_tables(base_state.ui, { mode = "battle" }),
  progress = util.merge_tables(base_state.progress, {
    floor_enemies = { { id = "dust_slime", position = 8, defeated = false } },
  }),
  combat = {
    enemy = { id = "dust_slime", name = "Dust Slime", is_boss = false },
    attack_effect = 2,
    attack_step = 1,
    last_turn = {
      attacker = "hero",
      time_sec = 99,
      result = { hit = true, damage = 2, element = "fire", attacker = "hero" },
    },
  },
})

local lines = render.build_lines(battle_state, config)
-- 攻撃演出に剣や盾のアイコンが表示されることを確認する。
assert_match(lines[1] or "", "W", "剣アイコンが表示される")

local encounter_state = util.merge_tables(base_state, {
  ui = util.merge_tables(base_state.ui, { mode = "battle" }),
  progress = util.merge_tables(base_state.progress, {
    floor_enemies = { { id = "dust_slime", position = 2, defeated = false } },
  }),
  combat = {
    enemy = { id = "dust_slime", name = "Dust Slime", is_boss = false },
  },
})
local encounter_lines = render.build_lines(encounter_state, config)
local enemy_icon = sprite.build_floor_enemy_icon({ id = "dust_slime" }, config)
assert_contains(encounter_lines[1] or "", "H  " .. enemy_icon, "遭遇直後は勇者と敵の間に2マス空く")

print("OK")
