-- このテストはメニュー上部のライブトラック表示が常にビジュアル表示であることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

local function assert_not_match(text, pattern, message)
  if text:match(pattern) then
    error((message or "assert_not_match failed") .. ": " .. tostring(text) .. " =~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config_module = require("idle_dungeon.config")
local live_header = require("idle_dungeon.menu.live_header")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = config_module.build({
  ui = { language = "en", render_mode = "text" },
})
local state = state_module.new_state(config)
state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { render_mode = "text" }),
})

local lines = live_header.build_lines(state, config, "en")
assert_true(type(lines) == "table" and #lines >= 2, "ライブトラックの2行表示が返る")
assert_not_match(lines[1] or "", "^%[", "ライブトラックはテキストモード表現を使わない")
assert_match(lines[2] or "", tostring((state.actor or {}).hp or 0), "上部情報に体力値が含まれる")

local battle_state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { mode = "battle" }),
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 6, max_hp = 6, accuracy = 100 },
    last_turn = { attacker = "hero", result = {} },
  },
})
local battle_lines = live_header.build_lines(battle_state, config, "en")
assert_true(type(battle_lines) == "table" and #battle_lines >= 2, "戦闘中もライブトラックの2行表示が返る")
assert_match(battle_lines[2] or "", "Attack", "戦闘中の上部情報に攻撃名が含まれる")
assert_match(battle_lines[2] or "", "〉", "戦闘中の上部情報は戦闘レイアウトで表示される")
assert_match(battle_lines[2] or "", "〈", "戦闘中の上部情報は戦闘レイアウトで表示される")

print("OK")
