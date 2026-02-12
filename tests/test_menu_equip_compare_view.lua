-- このテストは装備選択画面で現在装備と変更差分が一覧で分かることを確認する。

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

local calls = {}
package.loaded["idle_dungeon.menu.view"] = {
  select = function(items, opts, on_choice)
    table.insert(calls, { items = items, opts = opts, on_choice = on_choice })
    -- スロット選択で武器を選び、装備一覧画面まで遷移させる。
    if #calls == 1 and on_choice then
      on_choice("weapon")
    end
  end,
}

local actions = require("idle_dungeon.menu.actions")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  stage_name = "equip-compare",
  stages = {
    { id = 1, name = "equip-compare", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  inventory = util.merge_tables(state.inventory or {}, {
    wood_sword = 1,
    short_bow = 1,
  }),
})

local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

actions.open_equip_menu(get_state, set_state, config)

assert_true(#calls >= 2, "装備スロットと装備一覧の2段階メニューが開かれる")
local equip_call = calls[2]
assert_true(type(equip_call.opts.format_item) == "function", "装備一覧に整形関数が設定される")

local lines = {}
for _, item in ipairs(equip_call.items or {}) do
  table.insert(lines, equip_call.opts.format_item(item))
end
local joined = table.concat(lines, "\n")

assert_contains(joined, "EQUIPPED", "現在装備中の項目が一覧で識別できる")
assert_contains(joined, "CANDIDATE", "候補装備の項目が一覧で識別できる")
assert_contains(joined, "Δ HP", "装備変更時のHP差分が一覧に表示される")
assert_contains(joined, "ATK", "装備変更時の攻撃差分が一覧に表示される")
assert_contains(joined, "DEF", "装備変更時の防御差分が一覧に表示される")
assert_contains(joined, "SPD", "装備変更時の速度差分が一覧に表示される")

print("OK")
