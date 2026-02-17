-- このテストは状態遷移の差分から戦闘・イベント・報酬・ステージ移動のログが生成されることを確認する。

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

-- 戦闘開始の遷移ログを確認する。
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
assert_true(has_log_line(battle_logged, "Battle Start"), "移動から戦闘へ遷移した時に戦闘開始ログが追加される")

-- 報酬受け取りとアイテム取得のログを確認する。
local reward_prev = util.merge_tables(base, {
  ui = util.merge_tables(base.ui or {}, { mode = "reward" }),
  combat = {
    enemy = { id = "dust_slime", element = "normal", hp = 0, max_hp = 12 },
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
  inventory = { typing_blade = 1 },
  currency = { gold = 7 },
})
local reward_logged = transition_log.append_tick_logs(reward_prev, reward_next, config)
assert_true(has_log_line(reward_logged, "Reward"), "報酬受け取り時に報酬ログが追加される")
assert_true(has_log_line(reward_logged, "Item Acquired"), "報酬で装備を得た時に取得ログが追加される")

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
