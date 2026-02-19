-- このテストは遭遇後ログが日時・カテゴリ付きで、
-- 勇者/ペットHP・経験値の差分のみを出力することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function find_log_line(state, token)
  for _, line in ipairs((state and state.logs) or {}) do
    local text = tostring(line or "")
    if string.find(text, token, 1, true) then
      return text
    end
  end
  return nil
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local transition_log = require("idle_dungeon.game.log_transition")
local util = require("idle_dungeon.util")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "log-rich-stats-test",
  stages = {
    { id = 1, name = { en = "Stage One", ja = "第一階層" }, start = 0, length = 8 },
  },
  ui = { language = "en" },
}

do
  local base = state_module.new_state(config)
  local previous_state = util.merge_tables(base, {
    ui = util.merge_tables(base.ui or {}, { mode = "move" }),
    metrics = { time_sec = 77 },
    actor = util.merge_tables(base.actor or {}, {
      hp = 20,
      max_hp = 20,
      atk = 5,
      def = 2,
      speed = 3,
      level = 3,
    }),
    logs = {},
  })
  local next_state = util.merge_tables(previous_state, {
    actor = util.merge_tables(previous_state.actor or {}, {
      hp = 22,
      max_hp = 22,
      atk = 7,
      def = 3,
      speed = 4,
      level = 4,
    }),
  })
  local logged = transition_log.append_tick_logs(previous_state, next_state, config)
  local status_line = find_log_line(logged, "[STATUS]")
  assert_true(status_line == nil, "通常ステータス変動ログは出力しない")
end

do
  local base = state_module.new_state(config)
  local previous_state = util.merge_tables(base, {
    ui = util.merge_tables(base.ui or {}, { mode = "reward" }),
    metrics = { time_sec = 120 },
    actor = {
      id = "recorder",
      hp = 14,
      max_hp = 24,
      atk = 8,
      def = 4,
      speed = 5,
      level = 6,
      exp = 2,
      next_level = 10,
    },
    pet_party = {
      { id = "dust_slime", hp = 2, max_hp = 8 },
    },
    combat = {
      enemy = { id = "dust_slime", element = "normal", hp = 0, max_hp = 12 },
      encounter_start = {
        hero = { hp = 24, exp = 0 },
        pet = { hp = 8, exp = 0 },
      },
      pending_exp = 4,
      pending_gold = 3,
    },
    logs = {},
  })
  local next_state = util.merge_tables(previous_state, {
    ui = util.merge_tables(previous_state.ui or {}, { mode = "move" }),
    combat = nil,
    actor = util.merge_tables(previous_state.actor or {}, {
      level = 7,
      hp = 14,
      max_hp = 26,
      atk = 9,
      def = 5,
      speed = 6,
      exp = 6,
    }),
    pet_party = {
      { id = "dust_slime", hp = 2, max_hp = 8 },
    },
  })
  local logged = transition_log.append_tick_logs(previous_state, next_state, config)
  local battle_line = find_log_line(logged, "Hero HP 24->14 EXP 0->6")
  assert_true(type(battle_line) == "string", "遭遇後差分ログが追加される")
  assert_true(
    battle_line:match("^%[BATTLE%].*%[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]$") ~= nil,
    "遭遇後差分ログはカテゴリ先頭・日時末尾の形式で出力される"
  )
  assert_true(string.find(battle_line, " Loop Slime", 1, true) ~= nil, "遭遇後差分ログに敵アイコンと敵名が含まれる")
  assert_true(string.find(battle_line, "Hero HP 24->14 EXP 0->6", 1, true) ~= nil, "勇者HP・経験値差分がログへ含まれる")
  assert_true(string.find(battle_line, "Pet HP 8->2 EXP 0->0", 1, true) ~= nil, "ペットHP・経験値差分がログへ含まれる")
  assert_true(string.find(battle_line, "ATK 8->9", 1, true) == nil, "遭遇差分ログにステータス差分は含めない")
  assert_true(string.find(battle_line, "MaxHP 24->26", 1, true) == nil, "遭遇差分ログに成長差分は含めない")
  assert_true(string.find(battle_line, "Lv 6->7", 1, true) == nil, "遭遇差分ログにレベルアップ文言は含めない")
  local level_line = find_log_line(logged, "Level Up:")
  assert_true(type(level_line) == "string", "レベルアップは独立したログ行で追加される")
  assert_true(string.find(level_line, "Lv 6->7", 1, true) ~= nil, "レベルアップ行にレベル差分が含まれる")
  assert_true(string.find(level_line, "ATK 8->9", 1, true) ~= nil, "レベルアップ行にステータス差分が含まれる")
end

do
  local base = state_module.new_state(config)
  local previous_state = util.merge_tables(base, {
    ui = util.merge_tables(base.ui or {}, { mode = "reward" }),
    metrics = { time_sec = 130 },
    actor = util.merge_tables(base.actor or {}, {
      hp = 18,
      max_hp = 24,
      exp = 1,
      next_level = 10,
    }),
    pet_party = {},
    combat = {
      enemy = { id = "dust_slime", element = "normal", hp = 0, max_hp = 12 },
      encounter_start = {
        hero = { hp = 24, exp = 0 },
        pet = { hp = 0, exp = 0 },
      },
      pending_exp = 2,
      pending_gold = 1,
    },
    logs = {},
  })
  local next_state = util.merge_tables(previous_state, {
    ui = util.merge_tables(previous_state.ui or {}, { mode = "move" }),
    combat = nil,
    actor = util.merge_tables(previous_state.actor or {}, {
      hp = 18,
      exp = 3,
    }),
    pet_party = {},
  })
  local logged = transition_log.append_tick_logs(previous_state, next_state, config)
  local battle_line = find_log_line(logged, "[BATTLE]")
  assert_true(type(battle_line) == "string", "ペット不在時も遭遇後差分ログは追加される")
  assert_true(string.find(battle_line, " Loop Slime", 1, true) ~= nil, "ペット不在時も敵アイコンと敵名は表示する")
  assert_true(string.find(battle_line, "Hero HP 24->18 EXP 0->3", 1, true) ~= nil, "勇者HP・経験値差分がログへ含まれる")
  assert_true(string.find(battle_line, "Pet HP", 1, true) == nil, "ペット不在時はペット差分を表示しない")
end

print("OK")
