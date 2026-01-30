-- このテストは画像スプライトのフレーム選択が行えることを確認する。
-- ui配下の整理に合わせて参照先を更新する。

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

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local picker = require("idle_dungeon.ui.image_sprite_picker")
local state_module = require("idle_dungeon.core.state")

local config = {
  ui = {
    image_sprites = {
      frame_seconds = 1,
      boss = { "boss_1.png" },
    },
  },
  enemy_names = { "dust_slime" },
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, floors = 1 },
  },
}

local state = state_module.new_state(config)
local hero_frames = picker.resolve_actor_frames(state, "move")
assert_true(type(hero_frames) == "table", "勇者の画像フレームが取得できる")

local hero_path = picker.pick_actor_frame(state, config, "move")
assert_true(type(hero_path) == "string", "勇者の画像パスが取得できる")
assert_match(hero_path, "%.png$", "勇者の画像パスがPNGである")

local battle_state = {
  actor = state.actor,
  metrics = { time_sec = 0 },
  ui = { mode = "battle" },
  combat = { enemy = { id = "dust_slime" } },
}
local enemy_frames = picker.resolve_enemy_frames(battle_state, config, "battle")
assert_true(type(enemy_frames) == "table", "敵の画像フレームが取得できる")

local boss_state = {
  actor = state.actor,
  metrics = { time_sec = 0 },
  combat = { enemy = { is_boss = true } },
}
local boss_path = picker.pick_enemy_frame(boss_state, config, "battle")
assert_true(type(boss_path) == "string", "ボス画像パスが取得できる")
assert_match(boss_path, "boss_1%.png$", "ボス画像の既定パスが使われる")

print("OK")
