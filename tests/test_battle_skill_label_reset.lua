-- このテストは攻撃名表示で前ターンのスキル名が次ターンへ残らないことを確認する。

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
local util = require("idle_dungeon.util")

local function advance_until_attacker(state, config, attacker, max_ticks)
  local current = state
  local limit = math.max(tonumber(max_ticks) or 40, 1)
  for index = 1, limit do
    current = battle_flow.tick_battle(current, config)
    current = util.merge_tables(current, { metrics = { time_sec = index * 0.5 } })
    local last_turn = current.combat and current.combat.last_turn or nil
    if last_turn and last_turn.attacker == attacker then
      return current
    end
  end
  error("attacker not reached: " .. tostring(attacker))
end

-- 先に敵スキルが発動したあと、勇者の通常攻撃で敵スキル名が残らないことを確認する。
local enemy_skill_config = {
  battle = {
    accuracy = 100,
    enemy_accuracy = 100,
    skill_active_rate = 0,
    enemy_skill_rate = 1,
  },
}
local enemy_first_state = {
  actor = { hp = 20, max_hp = 20, atk = 2, def = 0, speed = 1, level = 1, exp = 0, next_level = 10 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = {
      hp = 20,
      max_hp = 20,
      atk = 2,
      def = 0,
      accuracy = 100,
      speed = 3,
      skills = {
        { id = "enemy_test_strike", kind = "active", name = "強打", name_en = "Enemy Strike", power = 2, accuracy = 0, rate = 1 },
      },
    },
    turn = nil,
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
    last_turn = nil,
  },
}
local after_enemy_skill = advance_until_attacker(enemy_first_state, enemy_skill_config, "enemy", 10)
assert_true(after_enemy_skill.combat.last_turn.result.skill ~= nil, "敵ターンでスキル情報が記録される")
local after_hero_basic = advance_until_attacker(after_enemy_skill, enemy_skill_config, "hero", 10)
assert_equal(after_hero_basic.combat.last_turn.attacker, "hero", "次ターンは勇者攻撃になる")
assert_true(after_hero_basic.combat.last_turn.result.skill == nil, "勇者通常攻撃では敵スキル名を引き継がない")

-- 先に勇者スキルが発動したあと、敵の通常攻撃で勇者スキル名が残らないことを確認する。
local hero_skill_config = {
  battle = {
    accuracy = 100,
    enemy_accuracy = 100,
    skill_active_rate = 1,
    enemy_skill_rate = 0,
  },
}
local hero_first_state = {
  actor = {
    hp = 20,
    max_hp = 20,
    atk = 3,
    def = 0,
    speed = 3,
    level = 1,
    exp = 0,
    next_level = 10,
  },
  skills = {
    active = { ambush = true },
    passive = {},
  },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = {
      hp = 20,
      max_hp = 20,
      atk = 2,
      def = 0,
      accuracy = 100,
      speed = 1,
      skills = {
        { id = "enemy_basic", kind = "active", name = "無効", name_en = "Disabled", power = 2, accuracy = 0, rate = 1 },
      },
    },
    turn = nil,
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
    last_turn = nil,
  },
}
local after_hero_skill = advance_until_attacker(hero_first_state, hero_skill_config, "hero", 10)
assert_true(after_hero_skill.combat.last_turn.result.skill ~= nil, "勇者ターンでスキル情報が記録される")
local after_enemy_basic = advance_until_attacker(after_hero_skill, hero_skill_config, "enemy", 10)
assert_equal(after_enemy_basic.combat.last_turn.attacker, "enemy", "次ターンは敵攻撃になる")
assert_true(after_enemy_basic.combat.last_turn.result.skill == nil, "敵通常攻撃では勇者スキル名を引き継がない")

print("OK")
