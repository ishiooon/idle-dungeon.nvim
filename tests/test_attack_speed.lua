-- このテストは攻撃速度の定義と速度差による行動回数差を確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local battle_flow = require("idle_dungeon.core.transition.battle")
local util = require("idle_dungeon.util")

for _, enemy in ipairs(content.enemies or {}) do
  local speed = enemy.stats and enemy.stats.speed or nil
  assert_true(speed and speed >= 1, "敵の攻撃速度が設定されている: " .. (enemy.id or "?"))
end

-- ジョブの基礎攻撃速度も必須項目として検証する。
for _, job in ipairs(content.jobs or {}) do
  local speed = job.base and job.base.speed or nil
  assert_true(speed and speed >= 1, "勇者の攻撃速度が設定されている: " .. (job.id or "?"))
end

local config = { battle = { accuracy = 100 } }

local function run_ticks(state, config, ticks)
  local current = state
  local hero_attacks = 0
  local enemy_attacks = 0
  local last_time = nil
  local last_attacker = nil
  for _ = 1, ticks do
    current = battle_flow.tick_battle(current, config)
    local last_turn = current.combat and current.combat.last_turn or nil
    local attacker = last_turn and last_turn.attacker or nil
    local turn_time = last_turn and last_turn.time_sec or nil
    -- 攻撃演出中は同じlast_turnが残るため、時刻と攻撃者が変わった時だけ1回として数える。
    if attacker and (turn_time ~= last_time or attacker ~= last_attacker) then
      if attacker == "hero" then
        hero_attacks = hero_attacks + 1
      elseif attacker == "enemy" then
        enemy_attacks = enemy_attacks + 1
      end
      last_time = turn_time
      last_attacker = attacker
    end
  end
  return current, hero_attacks, enemy_attacks
end

-- speed値は大きいほど速く、同じ時間内に行動回数が増える。
local fast_hero_state = {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 3 },
  metrics = { time_sec = 0 },
  progress = { rng_seed = 1 },
  ui = { mode = "battle" },
  combat = {
    enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 1 },
    turn = nil,
    turn_wait = 0,
    last_turn = nil,
  },
}
local st1, hero_count_1, enemy_count_1 = run_ticks(fast_hero_state, config, 6)
assert_true(st1.combat.last_turn ~= nil, "戦闘行動が1回以上発生する")
assert_true(hero_count_1 > enemy_count_1, "勇者が速いと敵より多く攻撃する")

local fast_enemy_state = util.merge_tables(fast_hero_state, {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 1 },
  combat = { enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 3 }, turn = nil, turn_wait = 0, last_turn = nil },
})
local _, hero_count_2, enemy_count_2 = run_ticks(fast_enemy_state, config, 6)
assert_true(enemy_count_2 > hero_count_2, "敵が速いと勇者より多く攻撃する")

-- speedの絶対値が同倍率で増えても、全体テンポは大きく変化しない。
local balanced_base = util.merge_tables(fast_hero_state, {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 2 },
  combat = { enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 2 }, turn = nil, turn_wait = 0, last_turn = nil },
})
local _, hero_count_3, enemy_count_3 = run_ticks(balanced_base, config, 40)
local total_base = hero_count_3 + enemy_count_3
local balanced_scaled = util.merge_tables(fast_hero_state, {
  actor = { hp = 20, max_hp = 20, atk = 1, def = 0, speed = 6 },
  combat = { enemy = { hp = 20, max_hp = 20, atk = 1, def = 0, accuracy = 100, speed = 6 }, turn = nil, turn_wait = 0, last_turn = nil },
})
local _, hero_count_4, enemy_count_4 = run_ticks(balanced_scaled, config, 40)
local total_scaled = hero_count_4 + enemy_count_4
assert_true(math.abs(total_scaled - total_base) <= 1, "双方のspeedが同倍率で増えても全体の行動テンポはほぼ一定")

print("OK")
