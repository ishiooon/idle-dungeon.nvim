-- このテストはRead-only表示の有無が描画結果に反映されることを確認する。
-- 描画モジュールの参照先整理に合わせて読み込みを更新する。

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
local render_state = require("idle_dungeon.ui.render_state")
local state = require("idle_dungeon.core.state")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 0,
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 240 },
  },
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = { track_length = 12, width = 36, max_height = 2, height = 1 },
}

local base_state = state.new_state(config)
local readonly_state = render_state.with_read_only(base_state, false)
local readonly_lines = render.build_lines(readonly_state, config)
assert_match(readonly_lines[1], "RO", "Read-only時は表示にROが含まれる")

local owner_state = render_state.with_read_only(base_state, true)
local owner_lines = render.build_lines(owner_state, config)
assert_not_match(owner_lines[1], "RO", "所有者時はRO表示が無い")

print("OK")
