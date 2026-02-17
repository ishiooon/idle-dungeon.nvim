-- このテストは設定タブの即時反映項目で通知メッセージが表示されることを確認する。

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

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local selected_tabs = nil
local original_vim = _G.vim
local ok, err = pcall(function()
  local notifications = {}

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

  _G.vim = {
    log = { levels = { INFO = 1 } },
    notify = function(message, level, opts)
      table.insert(notifications, {
        message = message,
        level = level,
        opts = opts or {},
      })
    end,
  }

  local menu = require("idle_dungeon.menu")
  local state_module = require("idle_dungeon.core.state")

  local config = {
    stage_name = "toast-test",
    stages = {
      { id = 1, name = "toast-test", start = 0, length = 8 },
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

  local config_tab = nil
  for _, tab in ipairs(selected_tabs or {}) do
    if tab.id == "config" then
      config_tab = tab
      break
    end
  end
  assert_true(type(config_tab) == "table", "設定タブが生成される")

  local auto_start_item = nil
  for _, item in ipairs(config_tab.items or {}) do
    if item.id == "auto_start" then
      auto_start_item = item
      break
    end
  end
  assert_true(type(auto_start_item) == "table", "自動開始の設定項目が存在する")

  config_tab.on_choice(auto_start_item)
  assert_true(#notifications >= 1, "設定反映時に通知メッセージが表示される")
  assert_contains(notifications[#notifications].message or "", "->", "通知メッセージに変更前後の情報が含まれる")
  assert_true((notifications[#notifications].opts or {}).timeout == 1000, "通知メッセージは短時間表示で構成される")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
