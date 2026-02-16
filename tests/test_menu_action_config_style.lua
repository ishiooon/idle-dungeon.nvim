-- このテストは操作タブと設定タブの表示がカード風に整形されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

local function assert_not_contains(text, needle, message)
  if string.find(text or "", needle or "", 1, true) then
    error((message or "assert_not_contains failed") .. ": " .. tostring(text) .. " =~ " .. tostring(needle))
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
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "style-test",
  stages = {
    { id = 1, name = "style-test", start = 0, length = 8 },
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

local function find_tab(tab_id)
  for _, tab in ipairs(selected_tabs or {}) do
    if tab.id == tab_id then
      return tab
    end
  end
  return nil
end

local status_tab = find_tab("status")
assert_true(status_tab ~= nil, "状態タブが生成される")
assert_true(type(status_tab.on_choice) == "function", "状態タブに選択ハンドラが存在する")
assert_true(type(status_tab.enter_hint_provider) == "function", "状態タブにEnter説明関数が存在する")
assert_true(type(status_tab.can_execute_on_enter) == "function", "状態タブにEnter実行判定関数が存在する")
local action_item = nil
local toggle_item = nil
local read_only_item = nil
for _, item in ipairs(status_tab.items or {}) do
  if item.action_id == "equip" then
    action_item = item
  end
  if item.id == "status_control" and item.action == "toggle_advanced" then
    toggle_item = item
  end
  if read_only_item == nil and item.id == "entry" and item.action_id == nil and item.open_detail_on_enter ~= true then
    read_only_item = item
  end
end
assert_true(action_item ~= nil, "状態タブにクイック操作の項目が含まれる")
assert_true(toggle_item ~= nil, "状態タブに要約表示の開閉トグルが含まれる")
assert_true(read_only_item ~= nil, "状態タブに実行対象ではない表示行が含まれる")
local action_label = status_tab.format_item(action_item, 1, #status_tab.items)
local has_action_label = string.find(action_label, "Equip", 1, true)
  or string.find(action_label, "Recommended", 1, true)
assert_true(has_action_label ~= nil, "状態タブの操作行が表示される")
assert_not_contains(action_label, "⟫", "意味の不明な記号は表示しない")
assert_true(type(status_tab.detail_provider) == "function", "状態タブに詳細プレビュー関数が存在する")
local action_detail = status_tab.detail_provider(action_item)
assert_true(type(action_detail) == "table", "状態タブのクイック操作で詳細プレビューが生成される")
assert_contains(table.concat(action_detail.lines or {}, "\n"), "Compare", "装備変更の詳細に比較方針が表示される")
local status_enter_hint = status_tab.enter_hint_provider(action_item)
assert_true(type(status_enter_hint) == "table" and #status_enter_hint >= 1, "状態タブの選択項目にEnter説明が出る")
assert_contains(table.concat(status_enter_hint, "\n"), "Enter", "状態タブのEnter説明に操作キーが含まれる")
assert_true(status_tab.can_execute_on_enter(action_item) == true, "状態タブの実行項目はEnter実行可能と判定される")
local toggle_enter_hint = status_tab.enter_hint_provider(toggle_item)
assert_contains(table.concat(toggle_enter_hint, "\n"), "Enter", "状態タブの開閉トグルにEnter説明が表示される")
assert_true(status_tab.can_execute_on_enter(toggle_item) == true, "状態タブの開閉トグルはEnter実行可能と判定される")
local read_only_hint = status_tab.enter_hint_provider(read_only_item)
assert_contains(table.concat(read_only_hint, "\n"), "display-only", "状態タブの非実行行は表示専用の説明になる")
assert_true(status_tab.can_execute_on_enter(read_only_item) == false, "状態タブの非実行行はEnter実行対象にならない")

local config_tab = find_tab("config")
assert_true(config_tab ~= nil, "設定タブが生成される")
local config_label = config_tab.format_item(config_tab.items[1], 1, #config_tab.items)
assert_not_contains(config_label, "CFG ", "設定タブの行頭に識別タグを表示しない")
assert_not_contains(config_label, "01/", "設定タブの行に連番を表示しない")
assert_not_contains(config_label, "->", "設定タブ行内の変更後プレビューは下部説明へ移動する")
assert_not_contains(config_label, "⟫", "意味の不明な記号は表示しない")
assert_true(type(config_tab.detail_provider) == "function", "設定タブに詳細プレビュー関数が存在する")
assert_true(type(config_tab.enter_hint_provider) == "function", "設定タブにEnter説明関数が存在する")
assert_true(type(config_tab.can_execute_on_enter) == "function", "設定タブにEnter実行判定関数が存在する")
local config_detail = config_tab.detail_provider(config_tab.items[1])
assert_true(type(config_detail) == "table", "設定タブの詳細プレビューが生成される")
assert_contains(table.concat(config_detail.lines or {}, "\n"), "Current", "設定タブの詳細に現在値が含まれる")
assert_contains(table.concat(config_detail.lines or {}, "\n"), "Next", "設定タブの詳細に変更後の値が含まれる")
local config_enter_hint = config_tab.enter_hint_provider(config_tab.items[1])
assert_true(type(config_enter_hint) == "table" and #config_enter_hint >= 1, "設定タブの選択項目にEnter説明が出る")
assert_contains(table.concat(config_enter_hint, "\n"), "Enter", "設定タブのEnter説明に操作キーが含まれる")
assert_contains(table.concat(config_enter_hint, "\n"), "->", "設定タブのEnter説明に変更前後が表示される")
assert_true(config_tab.can_execute_on_enter(config_tab.items[1]) == true, "設定タブの項目はEnter実行可能と判定される")

print("OK")
