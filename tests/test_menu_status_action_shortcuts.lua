-- このテストは状態タブ内のクイック操作から各サブメニューへ遷移できることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local selected_tabs = nil
local update_called = 0
local called = {
  equip = 0,
  stage = 0,
  purchase = 0,
  sell = 0,
  job = 0,
  skills = 0,
}

package.loaded["idle_dungeon.menu.actions"] = {
  open_equip_menu = function()
    called.equip = called.equip + 1
  end,
  open_stage_menu = function()
    called.stage = called.stage + 1
  end,
  open_job_menu = function()
    called.job = called.job + 1
  end,
  open_skills_menu = function()
    called.skills = called.skills + 1
  end,
}

package.loaded["idle_dungeon.menu.shop"] = {
  open_purchase_menu = function()
    called.purchase = called.purchase + 1
  end,
  open_sell_menu = function()
    called.sell = called.sell + 1
  end,
}

package.loaded["idle_dungeon.menu.tabs_view"] = {
  select = function(tabs)
    selected_tabs = tabs
  end,
  update = function(tabs)
    selected_tabs = tabs or selected_tabs
    update_called = update_called + 1
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
  stage_name = "status-shortcuts",
  stages = {
    { id = 1, name = "status-shortcuts", start = 0, length = 8 },
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

local status_tab = nil
for _, tab in ipairs(selected_tabs or {}) do
  if tab.id == "status" then
    status_tab = tab
    break
  end
end
assert_true(status_tab ~= nil, "状態タブが生成される")
assert_true(type(status_tab.on_choice) == "function", "状態タブに選択ハンドラが設定される")

local equip_item = nil
local stage_item = nil
local purchase_item = nil
local sell_item = nil
local job_item = nil
local skills_item = nil
local advanced_toggle_item = nil
local loadout_toggle_item = nil
for _, item in ipairs(status_tab.items or {}) do
  if item.action_id == "equip" then
    equip_item = item
  end
  if item.action_id == "stage" then
    stage_item = item
  end
  if item.action_id == "purchase" then
    purchase_item = item
  end
  if item.action_id == "sell" then
    sell_item = item
  end
  if item.action_id == "job" then
    job_item = item
  end
  if item.action_id == "skills" then
    skills_item = item
  end
  if item.id == "status_control" and item.action == "toggle_advanced" then
    advanced_toggle_item = item
  end
  if item.id == "status_control" and item.action == "toggle_loadout" then
    loadout_toggle_item = item
  end
end
assert_true(equip_item ~= nil, "状態タブに装備変更のクイック操作が含まれる")
assert_true(stage_item ~= nil, "状態タブに開始ステージ変更の操作が含まれる")
assert_true(purchase_item ~= nil, "状態タブに購入のクイック操作が含まれる")
assert_true(sell_item ~= nil, "状態タブに売却のクイック操作が含まれる")
assert_true(job_item ~= nil, "状態タブにジョブ変更の操作が含まれる")
assert_true(skills_item ~= nil, "状態タブにスキル設定のクイック操作が含まれる")
assert_true(advanced_toggle_item ~= nil, "状態タブに詳細表示の開閉トグルが含まれる")
assert_true(loadout_toggle_item == nil, "要約表示では装備詳細トグルを表示しない")

status_tab.on_choice(advanced_toggle_item)
assert_true(update_called == 1, "状態タブの開閉トグルはタブ表示を更新する")
assert_true(
  called.equip == 0 and called.stage == 0 and called.purchase == 0 and called.sell == 0 and called.job == 0 and called.skills == 0,
  "開閉トグルではサブメニュー遷移しない"
)
for _, tab in ipairs(selected_tabs or {}) do
  if tab.id == "status" then
    status_tab = tab
    break
  end
end
for _, item in ipairs(status_tab.items or {}) do
  if item.id == "status_control" and item.action == "toggle_loadout" then
    loadout_toggle_item = item
    break
  end
end
assert_true(loadout_toggle_item ~= nil, "詳細表示を開くと装備詳細トグルが表示される")

status_tab.on_choice(loadout_toggle_item)
assert_true(update_called == 2, "装備詳細トグルでもタブ表示を更新する")
assert_true(
  called.equip == 0 and called.stage == 0 and called.purchase == 0 and called.sell == 0 and called.job == 0 and called.skills == 0,
  "装備詳細トグルではサブメニュー遷移しない"
)

status_tab.on_choice(equip_item)
status_tab.on_choice(stage_item)
status_tab.on_choice(purchase_item)
status_tab.on_choice(sell_item)
status_tab.on_choice(job_item)
status_tab.on_choice(skills_item)

assert_true(called.equip == 1, "状態タブのクイック操作から装備メニューへ遷移できる")
assert_true(called.stage == 1, "状態タブの進行行からステージ選択メニューへ遷移できる")
assert_true(called.purchase == 1, "状態タブのクイック操作から購入メニューへ遷移できる")
assert_true(called.sell == 1, "状態タブのクイック操作から売却メニューへ遷移できる")
assert_true(called.job == 1, "状態タブのジョブ行からジョブメニューへ遷移できる")
assert_true(called.skills == 1, "状態タブのクイック操作からスキルメニューへ遷移できる")

print("OK")
