-- このテストはジョブ一覧から詳細画面へ遷移した際に、成長情報と習得情報をすべて確認できることを確認する。

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

local state = nil
local calls = {}
local selected_job = nil
package.loaded["idle_dungeon.menu.view"] = {
  select = function(items, opts, on_choice)
    table.insert(calls, { items = items, opts = opts, on_choice = on_choice })
    -- 一覧から現在ジョブ以外を選んで詳細画面まで遷移させる。
    if #calls == 1 and on_choice then
      local selected = items[1]
      for _, job in ipairs(items or {}) do
        if type(job) == "table" and job.id ~= ((state.actor or {}).id) then
          selected = job
          break
        end
      end
      selected_job = selected
      on_choice(selected)
    end
  end,
  close = function() end,
  set_context = function() end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "detail-test",
  stages = {
    { id = 1, name = "detail-test", start = 0, length = 6 },
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

assert_true(#calls >= 2, "ジョブ一覧から詳細画面へ遷移する")
local list_call = calls[1]
local detail_call = calls[2]

assert_true(type(list_call.items) == "table" and #list_call.items > 0, "ジョブ一覧が生成される")
assert_true(type(detail_call.opts) == "table", "ジョブ詳細画面のオプションが取得できる")
assert_true(detail_call.opts.detail_layout ~= "split", "ジョブ詳細画面は1カラム表示を使う")
assert_true(type(detail_call.opts.format_item) == "function", "ジョブ詳細行の整形関数が設定される")
assert_true(type(detail_call.opts.can_execute_on_enter) == "function", "ジョブ詳細で実行可能行の判定関数が設定される")
assert_true(type(detail_call.opts.enter_hint_provider) == "function", "ジョブ詳細でEnter説明の供給関数が設定される")

local executable_count = 0
local readonly_item = nil
for _, item in ipairs(detail_call.items or {}) do
  if detail_call.opts.can_execute_on_enter(item) == true then
    executable_count = executable_count + 1
  else
    readonly_item = readonly_item or item
  end
end
assert_equal(executable_count, 1, "ジョブ詳細でEnter実行可能な行は適用行のみ")

local joined_lines = {}
for _, item in ipairs(detail_call.items or {}) do
  table.insert(joined_lines, detail_call.opts.format_item(item))
end
local joined = table.concat(joined_lines, "\n")
assert_contains(joined, "Level Up Growth", "レベルアップ時の成長見出しが含まれる")
assert_contains(joined, "No immediate stat change", "ジョブ切替直後はステータスが変わらない説明が含まれる")
assert_contains(joined, "Skill Unlocks", "スキル習得一覧の見出しが含まれる")

assert_true(type(selected_job) == "table", "詳細表示対象のジョブを特定できる")
for _, skill in ipairs(selected_job.skills or {}) do
  assert_contains(joined, skill.name_en, "詳細画面に取得スキルがすべて表示される")
end
assert_not_contains(joined, "After Change", "切替直後の差分比較見出しは表示しない")

local apply_hint = detail_call.opts.enter_hint_provider(detail_call.items[1], "en")
assert_contains(table.concat(apply_hint or {}, "\n"), "Apply", "適用行のEnter説明が表示される")
if readonly_item then
  local readonly_hint = detail_call.opts.enter_hint_provider(readonly_item, "en")
  assert_contains(table.concat(readonly_hint or {}, "\n"), "display-only", "表示専用行のEnter説明が表示される")
end

print("OK")
