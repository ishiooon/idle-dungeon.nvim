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

local actions_tab = find_tab("actions")
assert_true(actions_tab ~= nil, "操作タブが生成される")
local action_label = actions_tab.format_item(actions_tab.items[1], 1, #actions_tab.items)
assert_not_contains(action_label, "ACT ", "操作タブの行頭に識別タグを表示しない")
assert_not_contains(action_label, "01/", "操作タブの行に連番を表示しない")
assert_contains(action_label, "|", "操作タブに効果説明の区切りが表示される")
assert_not_contains(action_label, "⟫", "意味の不明な記号は表示しない")
assert_true(type(actions_tab.detail_provider) == "function", "操作タブに詳細プレビュー関数が存在する")
local action_detail = actions_tab.detail_provider(actions_tab.items[1])
assert_true(type(action_detail) == "table", "操作タブの詳細プレビューが生成される")
assert_contains(table.concat(action_detail.lines or {}, "\n"), "After Select", "操作タブの詳細に選択後説明が含まれる")

local config_tab = find_tab("config")
assert_true(config_tab ~= nil, "設定タブが生成される")
local config_label = config_tab.format_item(config_tab.items[1], 1, #config_tab.items)
assert_not_contains(config_label, "CFG ", "設定タブの行頭に識別タグを表示しない")
assert_not_contains(config_label, "01/", "設定タブの行に連番を表示しない")
assert_contains(config_label, "->", "設定タブに変更後の値プレビューが表示される")
assert_not_contains(config_label, "⟫", "意味の不明な記号は表示しない")
assert_true(type(config_tab.detail_provider) == "function", "設定タブに詳細プレビュー関数が存在する")
local config_detail = config_tab.detail_provider(config_tab.items[1])
assert_true(type(config_detail) == "table", "設定タブの詳細プレビューが生成される")
assert_contains(table.concat(config_detail.lines or {}, "\n"), "Current", "設定タブの詳細に現在値が含まれる")
assert_contains(table.concat(config_detail.lines or {}, "\n"), "Next", "設定タブの詳細に変更後の値が含まれる")

print("OK")
