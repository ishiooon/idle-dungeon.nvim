-- このテストはジョブ選択画面で現在ジョブと成長方針が一覧で分かることを確認する。

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

local captured = nil
package.loaded["idle_dungeon.menu.view"] = {
  select = function(items, opts)
    captured = { items = items, opts = opts }
  end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "job-compare",
  stages = {
    { id = 1, name = "job-compare", start = 0, length = 8 },
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

actions.open_job_menu(get_state, set_state, config)

assert_true(type(captured) == "table", "ジョブ選択メニューの表示情報を取得できる")
assert_true(type(captured.opts.format_item) == "function", "ジョブ一覧に整形関数が設定される")

local lines = {}
for _, item in ipairs(captured.items or {}) do
  table.insert(lines, captured.opts.format_item(item))
end
local joined = table.concat(lines, "\n")

assert_contains(joined, "ACTIVE", "現在ジョブの識別表示が一覧にある")
assert_contains(joined, "LvUp", "レベルアップ時の成長情報が一覧に表示される")
assert_contains(joined, "HP+", "レベルアップ時のHP成長が一覧に表示される")
assert_contains(joined, "ATK+", "レベルアップ時の攻撃成長が一覧に表示される")
assert_contains(joined, "DEF+", "レベルアップ時の防御成長が一覧に表示される")
assert_contains(joined, "SPD+", "レベルアップ時の速度成長が一覧に表示される")
assert_contains(joined, "Skill:Lv", "ジョブごとのスキル獲得レベル情報が一覧に表示される")
assert_contains(joined, "Slash", "ジョブごとのスキル名が一覧に表示される")
assert_not_contains(joined, "Δ HP", "ジョブ切替時の即時ステータス差分は表示しない")

print("OK")
