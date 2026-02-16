-- このテストはメニューの状態表示に入力統計が含まれることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_locale = require("idle_dungeon.menu.locale")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = { ui = { language = "ja" } }
local state = state_module.new_state(config)
local metrics = {
  chars = 120,
  saves = 3,
  time_sec = 65,
  filetypes = { lua = 100, python = 20 },
}
state = util.merge_tables(state, { metrics = metrics })

local lines = menu_locale.status_lines(state, "ja", config)
local joined = table.concat(lines or {}, " ")

assert_match(joined, "入力文字数", "入力文字数の表示が含まれる")
assert_match(joined, "保存回数", "保存回数の表示が含まれる")
assert_match(joined, "稼働時間", "稼働時間の表示が含まれる")
assert_match(joined, "lua", "ファイル種別ごとの内訳が表示される")

local lines_en = menu_locale.status_lines(state, "en", config)
local joined_en = table.concat(lines_en or {}, " ")
assert_contains(joined_en, "Job: Swordsman", "英語設定では状態表示のジョブ名を英語で表示する")

print("OK")
