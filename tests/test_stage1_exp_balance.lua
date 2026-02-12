-- このテストはステージ1序盤で経験値が過剰に入らず急激なレベル上昇を防ぐことを確認する。

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

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle_flow = require("idle_dungeon.core.transition.battle")
local battle = require("idle_dungeon.game.battle")
local config_module = require("idle_dungeon.config")
local util = require("idle_dungeon.util")
local state_module = require("idle_dungeon.core.state")

local config = config_module.build({
  battle = {
    -- 命中ぶれを排除して経験値計算のみを検証する。
    accuracy = 100,
    skill_active_rate = 0,
    enemy_skill_rate = 0,
  },
})

local stage1_start = (((config.stages or {})[1] or {}).start) or 0
local stage1_enemy = battle.build_enemy(stage1_start, config, { id = "penguin_umbral" })
local state = state_module.new_state(config)
local combat_state = util.merge_tables(state, {
  ui = util.merge_tables(state.ui or {}, { mode = "battle" }),
  progress = util.merge_tables(state.progress or {}, { rng_seed = 1 }),
  combat = {
    enemy = util.merge_tables(stage1_enemy, {
      hp = 1,
      max_hp = math.max(stage1_enemy.max_hp or stage1_enemy.hp or 1, 1),
      def = 0,
      accuracy = 0,
      speed = 1,
      drops = {},
    }),
    turn = nil,
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
    last_turn = nil,
  },
})

local after_battle = battle_flow.tick_battle(combat_state, config)
local pending_exp = (((after_battle.combat or {}).pending_exp) or 0)
assert_true(pending_exp > 0, "撃破時の経験値が計算される")
assert_true(pending_exp <= 3, "ステージ1序盤の1戦経験値は3以下に抑える")

local reward_state = util.merge_tables(after_battle, {
  ui = util.merge_tables(after_battle.ui or {}, { mode = "reward" }),
})
local after_reward = battle_flow.tick_reward(reward_state, config)
assert_equal((after_reward.actor or {}).level, 1, "ステージ1の1戦でレベルが2以上に急上昇しない")

print("OK")
