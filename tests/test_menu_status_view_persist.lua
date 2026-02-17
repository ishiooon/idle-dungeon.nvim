-- このテストは状態タブが折りたたみトグルなしの固定構成で再オープン後も維持されることを確認する。

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

local function has_label(tab, token)
  for _, item in ipairs((tab and tab.items) or {}) do
    if string.find(tostring(item.label or ""), token, 1, true) then
      return true
    end
  end
  return false
end

local function has_status_control(tab)
  for _, item in ipairs((tab and tab.items) or {}) do
    if item.id == "status_control" then
      return true
    end
  end
  return false
end

menu.open(get_state, set_state, config)
local status_tab = find_tab(selected_tabs, "status")
assert_true(status_tab ~= nil, "状態タブが生成される")
assert_true(not has_status_control(status_tab), "状態タブに折りたたみトグルを表示しない")
assert_true(has_label(status_tab, "Loadout & Skills"), "状態タブに装備と技能セクションが表示される")
assert_true(has_label(status_tab, "Input Metrics"), "状態タブに入力統計セクションが表示される")

menu.toggle(get_state, set_state, config)
assert_true(not menu.is_open(), "メニューを閉じるとopen状態が解除される")

menu.open(get_state, set_state, config)
status_tab = find_tab(selected_tabs, "status")
assert_true(status_tab ~= nil, "再オープン後も状態タブが生成される")
assert_true(not has_status_control(status_tab), "再オープン後も折りたたみトグルを表示しない")
assert_true(has_label(status_tab, "Loadout & Skills"), "再オープン後も装備と技能セクションが表示される")
assert_true(has_label(status_tab, "Input Metrics"), "再オープン後も入力統計セクションが表示される")

print("OK")
