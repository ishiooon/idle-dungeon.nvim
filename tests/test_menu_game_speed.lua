-- このテストはメニュー設定のゲーム速度切り替えが循環することを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

-- 設定モジュール読込時にNeovim APIへ依存しないよう表示モジュールを差し替える。
package.loaded["idle_dungeon.menu.view"] = {
  select = function() end,
}

local settings = require("idle_dungeon.menu.settings")
local state_module = require("idle_dungeon.core.state")

local config = {
  ui = { language = "en" },
  default_game_speed = "1x",
  game_speed_options = {
    { id = "1x", tick_seconds = 0.5, label = "1x" },
    { id = "2x", tick_seconds = 0.25, label = "2x" },
    { id = "5x", tick_seconds = 0.1, label = "5x" },
    { id = "10x", tick_seconds = 0.05, label = "10x" },
  },
}

local state = state_module.new_state(config)
local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

settings.cycle_game_speed(get_state, set_state, config)
assert_equal(state.ui.game_speed, "2x", "1回目の切り替えで2xになる")
settings.cycle_game_speed(get_state, set_state, config)
assert_equal(state.ui.game_speed, "5x", "2回目の切り替えで5xになる")
settings.cycle_game_speed(get_state, set_state, config)
assert_equal(state.ui.game_speed, "10x", "3回目の切り替えで10xになる")
settings.cycle_game_speed(get_state, set_state, config)
assert_equal(state.ui.game_speed, "1x", "4回目の切り替えで1xへ戻る")

print("OK")
