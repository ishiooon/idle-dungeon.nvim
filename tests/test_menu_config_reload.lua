-- このテストは設定タブの再読み込み項目がハンドラを呼ぶことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local captured_tabs = nil

package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(tabs, _, _)
    captured_tabs = tabs
  end,
  update = function() end,
  close = function() end,
  set_context = function() end,
}

package.loaded["idle_dungeon.menu.view"] = {
  select = function() end,
  close = function() end,
  set_context = function() end,
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

local reloaded = false
menu.open(get_state, set_state, config, {
  on_reload = function()
    reloaded = true
  end,
})

assert_true(type(captured_tabs) == "table" and #captured_tabs > 0, "メニュータブが生成される")
local config_tab = nil
for _, tab in ipairs(captured_tabs) do
  if tab.id == "config" then
    config_tab = tab
    break
  end
end
assert_true(config_tab ~= nil, "設定タブが存在する")
assert_true(type(config_tab.on_choice) == "function", "設定タブの選択ハンドラが存在する")

config_tab.on_choice({ id = "reload_plugin" })
assert_true(reloaded == true, "再読み込み項目でハンドラが呼ばれる")

print("OK")
