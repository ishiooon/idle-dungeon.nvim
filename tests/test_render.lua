-- このテストは描画文字列がモードに応じて切り替わることを確認する。
-- 描画モジュールの配置変更に合わせて参照先を更新する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state = require("idle_dungeon.core.state")
local render = require("idle_dungeon.ui.render")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 12,
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 240 },
  },
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = { track_length = 12, width = 36, max_height = 2, height = 2, info_cycle_seconds = 4 },
}

local st0 = state.new_state(config)
local lines_visual = render.build_lines(st0, config)
-- 可視モードではペットの歩行フレームが含まれる。
assert_match(lines_visual[1], "o_o", "可視モードでは歩行フレームがある")
assert_match(lines_visual[1], "d1%-1", "可視モードに短縮ステージ名が入る")
assert_match(lines_visual[1], "MOVE", "可視モードにモード表示が入る")
assert_true(#lines_visual == 2, "可視モードは2行表示が既定である")
assert_true(#lines_visual <= 2, "表示行数は最大2行に収まる")
assert_match(lines_visual[2], "HP", "可視モードに体力が表示される")
assert_match(lines_visual[2], "Lv", "可視モードにレベルが表示される")

local st1 = state.set_render_mode(st0, "text")
local lines_text = render.build_lines(st1, config)
assert_match(lines_text[1], "%[Walking", "テキストモードでは歩行表示がある")
assert_match(lines_text[1], "d1%-1", "テキストモードに短縮ステージ名が入る")
assert_true(#lines_text <= 2, "テキストモードでも最大2行に収まる")
if lines_text[2] then
  assert_match(lines_text[2], "HP", "テキストモードに体力が表示される")
end

print("OK")
