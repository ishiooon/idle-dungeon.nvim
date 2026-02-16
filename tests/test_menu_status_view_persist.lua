-- このテストは状態タブの詳細表示トグルが再オープン後も保持されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local selected_tabs = nil
local captured_opts = nil

package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(tabs, opts)
    selected_tabs = tabs
    captured_opts = opts
  end,
  update = function(tabs)
    selected_tabs = tabs or selected_tabs
  end,
  close = function()
    if captured_opts and type(captured_opts.on_close) == "function" then
      captured_opts.on_close()
    end
  end,
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
  stage_name = "status-persist",
  stages = {
    { id = 1, name = "status-persist", start = 0, length = 8 },
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

local function find_tab(tabs, tab_id)
  for _, tab in ipairs(tabs or {}) do
    if tab.id == tab_id then
      return tab
    end
  end
  return nil
end

local function find_status_control(tab, action)
  for _, item in ipairs((tab and tab.items) or {}) do
    if item.id == "status_control" and item.action == action then
      return item
    end
  end
  return nil
end

menu.open(get_state, set_state, config)
local status_tab = find_tab(selected_tabs, "status")
assert_true(status_tab ~= nil, "状態タブが生成される")
local toggle_advanced = find_status_control(status_tab, "toggle_advanced")
assert_true(toggle_advanced ~= nil, "状態タブに詳細表示トグルが存在する")

status_tab.on_choice(toggle_advanced)
status_tab = find_tab(selected_tabs, "status")
assert_true(status_tab ~= nil, "トグル後も状態タブが存在する")
assert_true(
  find_status_control(status_tab, "toggle_loadout") ~= nil,
  "詳細表示を開いた直後に装備詳細トグルが表示される"
)

menu.toggle(get_state, set_state, config)
assert_true(not menu.is_open(), "メニューを閉じるとopen状態が解除される")

menu.open(get_state, set_state, config)
status_tab = find_tab(selected_tabs, "status")
assert_true(status_tab ~= nil, "再オープン後も状態タブが生成される")
assert_true(
  find_status_control(status_tab, "toggle_loadout") ~= nil,
  "再オープン後も詳細表示トグルの状態が保持される"
)

print("OK")
