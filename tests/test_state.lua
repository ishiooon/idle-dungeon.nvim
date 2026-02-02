-- このテストは状態更新が純粋関数として動作することを確認する。
-- core配下への整理に合わせて参照先を更新する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state = require("idle_dungeon.core.state")

local base_config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 12,
  stage_name = "test-stage",
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  floor_length = 4,
  floor_encounters = { enabled = false },
  stages = {
    { id = 99, name = "test-stage", start = 0, floors = 3 },
  },
}

local st0 = state.new_state(base_config)
assert_equal(st0.ui.mode, "move", "初期状態は移動中")
assert_equal(st0.progress.distance, 0, "初期距離は0")

local st1 = state.tick(st0, base_config)
assert_equal(st1.progress.distance, 1, "移動で距離が増える")
assert_equal(st1.ui.mode, "move", "イベントがない場合は移動継続")

local stage_config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 12,
  stage_name = "stage-a",
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  floor_length = 2,
  floor_encounters = { enabled = false },
  stages = {
    { id = 77, name = "stage-a", start = 0, floors = 1 },
    { id = 78, name = "stage-b", start = 0, floors = 1 },
  },
}

local st_stage = state.new_state(stage_config)
local st_stage2 = state.tick(st_stage, stage_config)
local st_stage3 = state.tick(st_stage2, stage_config)
assert_equal(st_stage3.progress.stage_name, "stage-b", "ステージ終端で次のステージへ進む")

local encounter_config = {
  move_step = 1,
  encounter_every = 1,
  dialogue_seconds = 12,
  stage_name = "test-stage",
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  floor_length = 4,
  floor_encounters = { min = 1, max = 1 },
  stages = {
    { id = 99, name = "test-stage", start = 0, floors = 3 },
  },
}

local st2 = state.tick(state.new_state(encounter_config), encounter_config)
local st2b = state.tick(st2, encounter_config)
assert_equal(st2b.ui.mode, "battle", "階層内の遭遇条件で戦闘に移行する")

local dialogue_config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 12,
  stage_name = "test-stage",
  enemy_names = { "a", "b", "c" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = { 1 },
  floor_length = 4,
  floor_encounters = { enabled = false },
  stages = {
    { id = 99, name = "test-stage", start = 0, floors = 3 },
  },
}

local st3 = state.tick(state.new_state(dialogue_config), dialogue_config)
assert_equal(st3.ui.mode, "dialogue", "会話イベントで会話状態に移行する")
local expected_dialogue = math.floor(dialogue_config.dialogue_seconds * (st3.actor.dialogue_ratio or 1))
assert_equal(st3.ui.dialogue_remaining, expected_dialogue, "会話タイマーが初期化される")

local st4 = state.toggle_render_mode(st0)
assert_equal(st4.ui.render_mode, "text", "テキストモードに切り替わる")
local st5 = state.toggle_render_mode(st4)
assert_equal(st5.ui.render_mode, "visual", "可視モードに戻る")
local st_lines = state.set_display_lines(st0, 1)
assert_equal(st_lines.ui.display_lines, 1, "表示行数が更新される")
local st_lines2 = state.set_display_lines(st_lines, 2)
assert_equal(st_lines2.ui.display_lines, 2, "表示行数が2行に戻る")
local st_lines0 = state.set_display_lines(st_lines2, 0)
assert_equal(st_lines0.ui.display_lines, 0, "表示行数が0行に切り替わる")

local boss_config = {
  move_step = 1,
  encounter_every = 1,
  dialogue_seconds = 12,
  stage_intro_seconds = 0,
  stage_name = "last-dungeon",
  enemy_names = { "a" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  floor_length = 2,
  floor_encounters = { min = 0, max = 0 },
  boss_every = 2,
  stages = {
    { id = 3, name = "last-dungeon", start = 0, infinite = true },
  },
}

local st6 = state.tick(state.new_state(boss_config), boss_config)
local st7 = state.tick(st6, boss_config)
assert_equal(st7.ui.mode, "battle", "ボス階層で戦闘に移行する")
assert_equal(st7.combat.enemy.is_boss, true, "ボス戦フラグが付与される")

print("OK")
