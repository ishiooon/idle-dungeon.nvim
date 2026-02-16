-- このテストはジョブ一覧から詳細画面を開き、適用行のEnterでジョブ変更できることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state = nil
local calls = {}
local selected_job = nil
package.loaded["idle_dungeon.menu.view"] = {
  select = function(items, opts, on_choice)
    table.insert(calls, { items = items, opts = opts, on_choice = on_choice })
    -- 一覧で現在ジョブ以外を選び、詳細画面で適用行を選択する。
    if #calls == 1 and on_choice then
      for _, job in ipairs(items or {}) do
        if type(job) == "table" and job.id ~= ((state.actor or {}).id) then
          selected_job = job
          break
        end
      end
      selected_job = selected_job or items[1]
      on_choice(selected_job)
      return
    end
    if #calls == 2 and on_choice then
      local apply_item = nil
      for _, item in ipairs(items or {}) do
        if type(opts.can_execute_on_enter) == "function" and opts.can_execute_on_enter(item) == true then
          apply_item = item
          break
        end
      end
      assert_true(apply_item ~= nil, "ジョブ詳細に適用行が存在する")
      on_choice(apply_item)
    end
  end,
  close = function() end,
  set_context = function() end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "job-detail-apply",
  stages = {
    { id = 1, name = "job-detail-apply", start = 0, length = 6 },
  },
  ui = { language = "en" },
}

state = state_module.new_state(config)
local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

actions.open_job_menu(get_state, set_state, config)

assert_true(#calls >= 3, "ジョブ一覧→詳細→ジョブ一覧の順で画面遷移する")
assert_true(type(selected_job) == "table", "適用対象のジョブを選択できる")
assert_equal((state.actor or {}).id, selected_job.id, "詳細画面の適用行でジョブ変更が反映される")

print("OK")
