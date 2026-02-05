-- このテストはメニューのサブ画面から状態画面へ戻れることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

-- メニュー表示は実際に開かず、キャンセル時の挙動のみ検証する。
package.loaded["idle_dungeon.menu.view"] = {
  select = function(_, _, on_choice, _)
    on_choice(nil)
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

local job_back = false
actions.open_job_menu(get_state, set_state, config, function()
  job_back = true
end)
assert_true(job_back, "ジョブ選択のキャンセルで戻り処理が呼ばれる")

local stage_back = false
actions.open_stage_menu(get_state, set_state, config, function()
  stage_back = true
end)
assert_true(stage_back, "ステージ選択のキャンセルで戻り処理が呼ばれる")

print("OK")
