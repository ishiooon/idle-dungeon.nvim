-- このテストは装備変更時のステータス差分表示が生成できることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local detail = require("idle_dungeon.menu.equip_detail")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  ui = { language = "ja" },
  default_character_id = "recorder",
}

local state = state_module.new_state(config)
local item = { id = "wood_sword", name = "木の剣", slot = "weapon", atk = 2 }
local next_state = util.merge_tables(state, { actor = state.actor, equipment = state.equipment })

local result = detail.build_detail(item, next_state, "ja")

assert_match(result.title or "", "木の剣", "詳細表示のタイトルに装備名が含まれる")
local joined = table.concat(result.lines or {}, " ")
assert_match(joined, "体力", "体力の表示が含まれる")
assert_match(joined, "攻撃力", "攻撃力の表示が含まれる")
assert_match(joined, "防御力", "防御力の表示が含まれる")
assert_match(joined, "->", "変更前後の矢印が含まれる")

print("OK")
