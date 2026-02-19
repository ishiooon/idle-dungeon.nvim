-- このテストは状態遷移の差分から「遭遇後の勇者/ペットHP・経験値差分」と
-- ステージ・イベント系ログが生成されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state_module = require("idle_dungeon.core.state")
local transition_log = require("idle_dungeon.game.log_transition")
local util = require("idle_dungeon.util")

local config = {
  stage_name = "log-transition-test",
  floor_length = 8,
  stages = {
    { id = 1, name = { en = "Stage One", ja = "第一階層" }, start = 0, length = 8 },
    { id = 2, name = { en = "Stage Two", ja = "第二階層" }, start = 8, length = 8 },
  },
  ui = { language = "en" },
}

local base = state_module.new_state(config)

local function has_log_line(state, token)
  for _, line in ipairs((state and state.logs) or {}) do
    if string.find(tostring(line or ""), token, 1, true) then
      return true
    end
  end
  return false
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

-- 戦闘開始時は詳細ログを出さず、遭遇後の差分だけを出す。
local battle_prev = util.merge_tables(base, {
  ui = util.merge_tables(base.ui or {}, { mode = "move" }),
  logs = {},
})
local battle_next = util.merge_tables(battle_prev, {
  ui = util.merge_tables(battle_prev.ui or {}, { mode = "battle" }),
  combat = {
    enemy = { id = "dust_slime", element = "normal", hp = 12, max_hp = 12 },
    source = { id = "dust_slime", element = "normal" },
  },
})
local battle_logged = transition_log.append_tick_logs(battle_prev, battle_next, config)
assert_true(not has_log_line(battle_logged, "Battle Start"), "移動から戦闘へ遷移しても戦闘開始ログは追加しない")

-- 遭遇終了時は勇者/ペットHP・経験値の差分のみを1行で記録する。
local reward_prev = util.merge_tables(base, {
  ui = util.merge_tables(base.ui or {}, { mode = "reward" }),
  actor = util.merge_tables(base.actor or {}, {
    level = 1,
    hp = 15,
    max_hp = 20,
    atk = 5,
    def = 2,
    speed = 3,
    exp = 0,
    next_level = 10,
  }),
  pet_party = {
    { id = "dust_slime", hp = 3, max_hp = 8 },
  },
  combat = {
    enemy = { id = "dust_slime", element = "normal", hp = 0, max_hp = 12 },
    encounter_start = {
      hero = { hp = 20, exp = 0 },
      pet = { hp = 10, exp = 0 },
    },
    pending_exp = 9,
    pending_gold = 7,
    pending_drop = { id = "typing_blade", rarity = "common" },
  },
  inventory = {},
  logs = {},
})
local reward_next = util.merge_tables(reward_prev, {
  ui = util.merge_tables(reward_prev.ui or {}, { mode = "move" }),
  combat = nil,
  actor = util.merge_tables(reward_prev.actor or {}, {
    level = 2,
    hp = 15,
    max_hp = 22,
    atk = 6,
    def = 3,
    speed = 4,
    exp = 9,
  }),
  pet_party = {
    { id = "dust_slime", hp = 3, max_hp = 8 },
  },
  inventory = { typing_blade = 1 },
  currency = { gold = 7 },
})
local reward_logged = transition_log.append_tick_logs(reward_prev, reward_next, config)
assert_true(has_log_line(reward_logged, "[BATTLE]"), "遭遇終了時に戦闘カテゴリの差分ログが追加される")
assert_true(has_log_line(reward_logged, "Loop Slime"), "遭遇差分ログに敵名が含まれる")
assert_true(has_log_line(reward_logged, ""), "遭遇差分ログに敵アイコンが含まれる")
assert_true(has_log_line(reward_logged, "Hero HP 20->15 EXP 0->9"), "勇者HP・経験値の差分が含まれる")
assert_true(has_log_line(reward_logged, "Pet HP 10->3 EXP 0->0"), "ペットHP・経験値の差分が含まれる")
assert_true(has_log_line(reward_logged, "Level Up"), "レベルアップは独立したログ行で追加される")
local level_line = find_log_line(reward_logged, "Level Up")
assert_true(type(level_line) == "string", "レベルアップ行を取得できる")
assert_true(string.find(level_line, "Lv 1->2", 1, true) ~= nil, "レベルアップ差分が含まれる")
assert_true(string.find(level_line, "ATK 5->6", 1, true) ~= nil, "ステータス差分はレベルアップ行へ含める")
assert_true(not has_log_line(reward_logged, "Reward:"), "報酬要約ログは追加しない")
assert_true(not has_log_line(reward_logged, "Item Acquired"), "アイテム取得ログは追加しない")

-- 同一ステージ内のフロア進行ログはステージ-フロア形式で記録する。
local floor_prev = util.merge_tables(base, {
  progress = util.merge_tables(base.progress or {}, {
    stage_id = 1,
    stage_name = "Stage One",
    distance = 0,
  }),
  ui = util.merge_tables(base.ui or {}, { mode = "move" }),
  logs = {},
})
local floor_next = util.merge_tables(floor_prev, {
  progress = util.merge_tables(floor_prev.progress or {}, {
    stage_id = 1,
    stage_name = "Stage One",
    distance = 8,
  }),
})
local floor_logged = transition_log.append_tick_logs(floor_prev, floor_next, config)
assert_true(has_log_line(floor_logged, "Floor Reached: 1-2"), "フロア到達ログはステージ-フロア形式で追加される")

-- ステージ移動とイベント開始のログを確認する。
local stage_prev = util.merge_tables(base, {
  progress = util.merge_tables(base.progress or {}, {
    stage_id = 1,
    stage_name = "Stage One",
    distance = 7,
  }),
  ui = util.merge_tables(base.ui or {}, { mode = "move", event_id = nil }),
  logs = {},
})
local stage_next = util.merge_tables(stage_prev, {
  progress = util.merge_tables(stage_prev.progress or {}, {
    stage_id = 2,
    stage_name = "Stage Two",
    distance = 8,
  }),
  ui = util.merge_tables(stage_prev.ui or {}, {
    mode = "dialogue",
    event_id = "event_2_001",
    event_message = "A quiet market opens.",
    event_message_remaining = 3,
  }),
})
local stage_logged = transition_log.append_tick_logs(stage_prev, stage_next, config)
assert_true(has_log_line(stage_logged, "Stage Move"), "ステージIDが変わった時に移動ログが追加される")
assert_true(has_log_line(stage_logged, "Event Start"), "イベント開始時に開始ログが追加される")
assert_true(has_log_line(stage_logged, "Event:"), "イベントメッセージが設定された時に内容ログが追加される")

print("OK")
