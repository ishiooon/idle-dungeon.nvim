-- このテストはログ行の上限を1000行に保ち、メニューにlogタブが表示されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local selected_tabs = nil

package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(tabs)
    selected_tabs = tabs
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
local game_log = require("idle_dungeon.game.log")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "log-tab-test",
  stages = {
    { id = 1, name = "log-tab-test", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
for index = 1, 1005 do
  state = game_log.append(state, string.format("LOG_%04d", index))
end

assert_true(type(state.logs) == "table", "状態にログ配列が保持される")
assert_true(#state.logs == 1000, "ログは最大1000行に制限される")
assert_true(state.logs[1] == "LOG_0006", "ログが上限を超えると古い行から破棄される")
assert_true(state.logs[#state.logs] == "LOG_1005", "最新行が末尾に追加される")

local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

menu.open(get_state, set_state, config)

local log_tab = nil
for _, tab in ipairs(selected_tabs or {}) do
  if tab.id == "log" then
    log_tab = tab
    break
  end
end
assert_true(type(log_tab) == "table", "メニューにlogタブが生成される")

local entry_count = 0
local latest_found = false
local oldest_trimmed = true
for _, item in ipairs((log_tab and log_tab.items) or {}) do
  if item.id == "log_entry" then
    entry_count = entry_count + 1
    local label = tostring(item.label or "")
    if label:match("LOG_1005") then
      latest_found = true
    end
    if label:match("LOG_0001") then
      oldest_trimmed = false
    end
  end
end
assert_true(entry_count == 1000, "logタブには最大1000件のログを表示する")
assert_true(latest_found, "logタブに最新ログが表示される")
assert_true(oldest_trimmed, "logタブに破棄済みの古いログは表示しない")

print("OK")
