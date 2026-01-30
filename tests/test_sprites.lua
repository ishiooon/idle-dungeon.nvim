-- このテストは戦闘時にスプライトが表示されることを確認する。
-- ui配下への整理に合わせて参照先を更新する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local render = require("idle_dungeon.ui.render")
local state = require("idle_dungeon.core.state")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 0,
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  enemy_names = { "dust_slime" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = { track_length = 12, width = 36, max_height = 2, height = 1, sprites = { enabled = true } },
}

local base_state = state.new_state(config)
local battle_state = {
  progress = base_state.progress,
  actor = base_state.actor,
  equipment = base_state.equipment,
  inventory = base_state.inventory,
  currency = base_state.currency,
  metrics = base_state.metrics,
  unlocks = base_state.unlocks,
  dex = base_state.dex,
  ui = {
    mode = "battle",
    dialogue_remaining = 0,
    render_mode = "visual",
    auto_start = true,
    language = "en",
    event_id = nil,
  },
  combat = { enemy = { id = "dust_slime", name = "Dust Slime", hp = 3, max_hp = 3, atk = 1, def = 0 } },
}

local lines = render.build_lines(battle_state, config)
assert_match(lines[1], ".+>.+", "戦闘表示に勇者と敵のスプライトが含まれる")

print("OK")
