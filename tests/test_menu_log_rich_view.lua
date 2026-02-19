-- このテストはログタブで時刻・カテゴリ・本文を分離した詳細表示が生成されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_contains(text, token, message)
  if not string.find(tostring(text or ""), tostring(token or ""), 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(token))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local tabs_data = require("idle_dungeon.menu.tabs_data")

local state = {
  logs = {
    "[MENU] Equipment Changed: Weapon -> Wood Sword [2026-02-18 09:10:10]",
    "[BATTLE]  Loop Slime | Hero HP 20->15 EXP 0->9 | Pet HP 10->3 EXP 0->0 [2026-02-18 09:10:11]",
    "Event: A quiet market opens.",
  },
}

local items = tabs_data.build_log_items(state, "en")
local battle_entry = nil
for _, item in ipairs(items or {}) do
  if item.id == "log_entry" and string.find(tostring(item.label or ""), "Loop Slime", 1, true) then
    battle_entry = item
    break
  end
end

assert_true(type(battle_entry) == "table", "遭遇差分ログの表示行が生成される")
assert_true(type(battle_entry.detail_lines) == "table", "詳細表示用の行配列が生成される")
assert_true(#(battle_entry.detail_lines or {}) >= 3, "詳細表示に複数行の情報が含まれる")

local detail_text = table.concat(battle_entry.detail_lines or {}, "\n")
assert_contains(detail_text, "Datetime: 2026-02-18 09:10:11", "日時が詳細表示に含まれる")
assert_contains(detail_text, "Category: BATTLE", "カテゴリが詳細表示に含まれる")
assert_contains(
  detail_text,
  "Message:  Loop Slime | Hero HP 20->15 EXP 0->9 | Pet HP 10->3 EXP 0->0",
  "本文が詳細表示に含まれる"
)

print("OK")
