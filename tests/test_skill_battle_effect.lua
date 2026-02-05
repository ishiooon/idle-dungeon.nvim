-- このテストはスキル効果が戦闘計算に反映されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local battle_flow = require("idle_dungeon.core.transition.battle")
local skills = require("idle_dungeon.game.skills")
local util = require("idle_dungeon.util")

local base_state = {
  actor = { hp = 10, max_hp = 10, atk = 4, def = 1, speed = 3, level = 1, exp = 0, next_level = 10 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = { hp = 10, max_hp = 10, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = nil,
    turn_wait = 0,
    last_turn = nil,
  },
}

local passive_state = util.merge_tables(base_state, {
  actor = { hp = 10, max_hp = 10, atk = 9, def = 1, speed = 3, level = 1, exp = 0, next_level = 10 },
  skills = { active = {}, passive = { blade_aura = true } },
})
local passive_config = { battle = { accuracy = 100, skill_active_rate = 0 } }
local passive_result = battle_flow.tick_battle(passive_state, passive_config)
assert_true((passive_result.combat.enemy.hp or 10) == 0, "パッシブスキルの攻撃補正が反映される")

local active_state = util.merge_tables(base_state, {
  actor = { hp = 10, max_hp = 10, atk = 5, def = 1, speed = 3, level = 1, exp = 0, next_level = 10 },
  skills = { active = { ambush = true }, passive = {} },
})
local active_config = { battle = { accuracy = 100, skill_active_rate = 1 } }
local active_result = battle_flow.tick_battle(active_state, active_config)
assert_true((active_result.combat.enemy.hp or 10) == 3, "アクティブスキルの威力補正が反映される")
assert_true(active_result.combat.last_turn and active_result.combat.last_turn.result.skill, "アクティブスキル情報が戦闘結果に残る")

-- 敵側のアクティブスキルが勇者に反映されることを確認する。
local enemy_skill_state = util.merge_tables(base_state, {
  actor = { hp = 10, max_hp = 10, atk = 4, def = 0, speed = 1, level = 1, exp = 0, next_level = 10 },
  combat = {
    enemy = {
      hp = 10,
      max_hp = 10,
      atk = 2,
      def = 0,
      accuracy = 100,
      speed = 5,
      skills = {
        { id = "enemy_test_strike", kind = "active", name = "強打", power = 2, accuracy = 0, rate = 1 },
      },
    },
    turn = nil,
    turn_wait = 0,
    last_turn = nil,
  },
})
local enemy_skill_config = { battle = { accuracy = 100, enemy_accuracy = 100, enemy_skill_rate = 1, skill_active_rate = 0 } }
local enemy_skill_result = battle_flow.tick_battle(enemy_skill_state, enemy_skill_config)
assert_true((enemy_skill_result.actor.hp or 10) == 6, "敵スキルの威力補正が勇者側のダメージに反映される")
assert_true(enemy_skill_result.combat.last_turn and enemy_skill_result.combat.last_turn.result.skill, "敵スキル情報が戦闘結果に残る")

print("OK")
