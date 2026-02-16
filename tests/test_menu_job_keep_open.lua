-- このテストはジョブ選択メニューがEnterで詳細画面へ遷移する前提の設定で開くことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local captured_opts = nil
package.loaded["idle_dungeon.menu.view"] = {
  select = function(_, opts, _, _)
    captured_opts = opts
  end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "test-stage",
  stages = {
    { id = 1, name = "test-stage", start = 0, length = 5 },
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

actions.open_job_menu(get_state, set_state, config, function() end)

assert_true(type(captured_opts) == "table", "ジョブ選択の表示オプションが渡される")
assert_true(captured_opts.keep_open ~= true, "ジョブ一覧は確定時に詳細画面へ遷移するためkeep_openを使わない")
assert_true(type(captured_opts.enter_hint_provider) == "function", "ジョブ一覧でEnter操作説明を表示する")

print("OK")
