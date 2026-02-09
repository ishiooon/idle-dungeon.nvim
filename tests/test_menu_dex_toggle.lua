-- このテストは図鑑タブの展開/折りたたみトグルが切り替わることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local selected_tabs = nil
local updated_tabs = nil

package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(tabs, _, _)
    selected_tabs = tabs
  end,
  update = function(tabs)
    updated_tabs = tabs
  end,
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

menu.open(get_state, set_state, config)

local function find_tab(tabs, tab_id)
  for _, tab in ipairs(tabs or {}) do
    if tab.id == tab_id then
      return tab
    end
  end
  return nil
end

local function find_control(tab, pattern)
  for _, item in ipairs((tab and tab.items) or {}) do
    if item.id == "dex_control" and (item.label or ""):match(pattern) then
      return item
    end
  end
  return nil
end

local dex_tab = find_tab(selected_tabs, "dex")
assert_true(dex_tab ~= nil, "図鑑タブが生成される")
local expand_control = find_control(dex_tab, "Expand")
assert_true(expand_control ~= nil, "初期状態では展開トグルが表示される")
assert_true(type(dex_tab.on_choice) == "function", "図鑑タブに選択ハンドラが存在する")

dex_tab.on_choice(expand_control)
menu.update(get_state, set_state, config)

local updated_dex = find_tab(updated_tabs, "dex")
assert_true(updated_dex ~= nil, "更新後も図鑑タブが存在する")
local collapse_control = find_control(updated_dex, "Collapse")
assert_true(collapse_control ~= nil, "展開後は折りたたみトグルへ切り替わる")

print("OK")
