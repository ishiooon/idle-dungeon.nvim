-- このテストは敵の色味が属性ルールに従って選ばれることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local highlight = require("idle_dungeon.ui.sprite_highlight")

local config = {
  ui = {
    track_length = 12,
    track_fill = ".",
    icons = { hero = "H", enemy = "E", boss = "B", separator = ">" },
    sprites = { enabled = true, show_hero_on_track = true, show_enemy_on_track = true },
    sprite_palette = {
      default_hero = { fg = "#FFFFFF" },
      default_enemy = { fg = "#AAAAAA" },
      element_fire = { fg = "#FF0000" },
      tux_penguin = { fg = "#00FFFF" },
    },
  },
}

local state = {
  actor = { id = "hero" },
  metrics = { time_sec = 0 },
  progress = {
    distance = 0,
    floor_enemies = {
      { id = "tux_penguin", element = "normal", position = 4, defeated = false },
      { id = "java_ifrit", element = "fire", position = 8, defeated = false },
    },
  },
  ui = { mode = "move", render_mode = "visual" },
}

local highlights = highlight.build(state, config, { "dummy" })
local has_normal = false
local has_fire = false
for _, item in ipairs(highlights or {}) do
  if item.palette == "tux_penguin" then
    has_normal = true
  end
  if item.palette == "element_fire" then
    has_fire = true
  end
end

assert_true(has_normal, "ノーマル属性は敵IDの色味を使う")
assert_true(has_fire, "非ノーマル属性は属性色を使う")

print("OK")
