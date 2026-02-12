-- このテストはスキル選択画面で有効状態と効果内容が一覧で分かることを確認する。

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

local captured = nil
package.loaded["idle_dungeon.menu.view"] = {
  select = function(items, opts)
    captured = { items = items, opts = opts }
  end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  stage_name = "skill-compare",
  stages = {
    { id = 1, name = "skill-compare", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  skills = {
    active = { slash = true },
    passive = { blade_aura = true },
  },
  skill_settings = {
    active = { slash = true },
    passive = { blade_aura = false },
  },
})

local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

actions.open_skills_menu(get_state, set_state, config)

assert_true(type(captured) == "table", "スキル選択メニューの表示情報を取得できる")
assert_true(type(captured.opts.format_item) == "function", "スキル一覧に整形関数が設定される")

local lines = {}
for _, item in ipairs(captured.items or {}) do
  table.insert(lines, captured.opts.format_item(item))
end
local joined = table.concat(lines, "\n")

assert_contains(joined, "ON", "有効中スキルの状態が一覧で表示される")
assert_contains(joined, "OFF", "無効中スキルの状態が一覧で表示される")
assert_contains(joined, "Rate", "アクティブスキルの発動率が一覧に表示される")
assert_contains(joined, "Pow", "アクティブスキルの威力情報が一覧に表示される")
assert_contains(joined, "ATKx", "パッシブスキルの補正情報が一覧に表示される")

print("OK")
