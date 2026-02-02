-- このテストは戦闘時にスプライトが表示されることを確認する。
-- ui配下への整理に合わせて参照先を更新する。

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

local render = require("idle_dungeon.ui.render")
local content = require("idle_dungeon.content")
local sprite = require("idle_dungeon.ui.sprite")
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
  ui = {
    track_length = 12,
    width = 36,
    max_height = 2,
    height = 1,
    icons_only = true,
    icons = { hero = "H", enemy = "E", boss = "B", separator = ">" },
    sprites = { enabled = true },
  },
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
-- 図鑑の敵アイコンが戦闘トラックにも出ることを確認する。
-- 図鑑に含まれる敵アイコンのいずれかが表示されることを確認する。
local function has_any_enemy_icon(text)
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.icon and enemy.icon ~= "" and text:match(enemy.icon) then
      return true
    end
  end
  return false
end
assert_match(lines[1], "H", "戦闘表示に勇者アイコンが含まれる")
if not has_any_enemy_icon(lines[1]) then
  error("戦闘表示に敵アイコンが含まれる: " .. tostring(lines[1]))
end
assert_not_match(lines[1], ">", "戦闘表示はトラック継続のため対峙記号を使わない")

print("OK")
