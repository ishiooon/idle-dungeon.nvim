-- このテストはジョブ選択の詳細プレビューに成長情報と習得情報が含まれることを確認する。

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

local state = state_module.new_state(config)
local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

actions.open_job_menu(get_state, set_state, config)

assert_true(type(captured) == "table", "ジョブ選択メニューの表示情報を取得できる")
assert_true(type(captured.opts) == "table", "ジョブ選択メニューのオプションが取得できる")
assert_true(type(captured.opts.detail_provider) == "function", "ジョブ詳細の供給関数が設定される")
assert_true(captured.opts.detail_layout == "split", "ジョブ詳細画面は2カラム表示を使う")
assert_true(type(captured.items) == "table" and #captured.items > 0, "ジョブ一覧が生成される")

local detail = captured.opts.detail_provider(captured.items[1])
assert_true(type(detail) == "table", "ジョブ詳細が生成される")
local joined = table.concat(detail.lines or {}, "\n")
assert_contains(joined, "Level Up Growth", "レベルアップ時の成長見出しが含まれる")
assert_contains(joined, "No immediate stat change", "ジョブ切替直後はステータスが変わらない説明が含まれる")
assert_contains(joined, "Skill Unlocks", "スキル習得一覧の見出しが含まれる")
assert_contains(joined, "Lv", "スキル習得レベル情報が含まれる")
assert_not_contains(joined, "After Change", "切替直後の差分比較見出しは表示しない")

print("OK")
