-- このテストはメニュー上部ライブヘッダが右下表示と同じ描画結果を返すことを確認する。

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

local function assert_not_match(text, pattern, message)
  if text:match(pattern) then
    error((message or "assert_not_match failed") .. ": " .. tostring(text) .. " =~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config_module = require("idle_dungeon.config")
local live_header = require("idle_dungeon.menu.live_header")
local state_module = require("idle_dungeon.core.state")
local render = require("idle_dungeon.ui.render")
local util = require("idle_dungeon.util")

local config = config_module.build({
  ui = { language = "en", render_mode = "text" },
})
local state = state_module.new_state(config)
state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { render_mode = "text" }),
})

local lines = live_header.build_lines(state, config, "en")
local expected_state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { render_mode = "visual" }),
})
local expected_lines = render.build_lines(expected_state, config)
assert_true(type(lines) == "table" and #lines >= 2, "ライブヘッダの表示行が返る")
assert_equal(lines[1], expected_lines[1], "1行目は右下表示の1行目と一致する")
assert_equal(lines[2], expected_lines[2], "2行目は右下表示の2行目と一致する")
assert_not_match(lines[1] or "", "^%[", "ライブトラックはテキストモード表現を使わない")

local battle_state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { mode = "battle" }),
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 6, max_hp = 6, accuracy = 100 },
    last_turn = { attacker = "hero", result = {} },
  },
})
local battle_lines = live_header.build_lines(battle_state, config, "en")
local expected_battle_state = util.merge_tables(battle_state, {
  ui = util.merge_tables(battle_state.ui or {}, { render_mode = "visual" }),
})
local expected_battle_lines = render.build_lines(expected_battle_state, config)
assert_true(type(battle_lines) == "table" and #battle_lines >= 2, "戦闘中もライブヘッダが返る")
assert_equal(battle_lines[1], expected_battle_lines[1], "戦闘中1行目は右下表示と一致する")
assert_equal(battle_lines[2], expected_battle_lines[2], "戦闘中2行目は右下表示と一致する")

print("OK")
