-- このテストはメニューの開閉状態とクローズ時コールバックを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local captured_opts = nil
package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(_, opts, _)
    captured_opts = opts
  end,
  update = function(_) end,
  close = function()
    if captured_opts and captured_opts.on_close then
      captured_opts.on_close()
    end
  end,
  set_context = function(_, _) end,
}
package.loaded["idle_dungeon.menu.view"] = {
  select = function() end,
  close = function() end,
  set_context = function(_, _) end,
}

local menu = require("idle_dungeon.menu")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "test-stage",
  stages = {
    { id = 1, name = "test-stage", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

local closed = false
menu.set_on_close(function()
  closed = true
end)

menu.open(get_state, set_state, config)
assert_true(menu.is_open(), "open後はメニューが開いている")

menu.toggle(get_state, set_state, config)
assert_true(not menu.is_open(), "toggleで閉じた後は開いていない")
assert_true(closed, "メニューを閉じた際にコールバックが呼ばれる")

print("OK")
