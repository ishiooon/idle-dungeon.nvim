-- このテストはペットの獲得・保持上限・戦闘参加・離脱の振る舞いを確認する。

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
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 0,
  stage_name = "pet-stage",
  stages = {
    { id = 1, name = "pet-stage", start = 0, length = 12 },
  },
  battle = {
    enemy_hp = 4,
    enemy_atk = 1,
    reward_exp = 1,
    reward_gold = 1,
    accuracy = 100,
    skill_active_rate = 0,
    enemy_skill_rate = 0,
    pet_target_rate = 1,
  },
  event_distances = {},
  ui = { language = "en" },
}

local st0 = state_module.new_state(config)
assert_equal(#(st0.pet_party or {}), 0, "初期状態ではペットを保持しない")

-- 通常ジョブでは保持上限1で、後から得たペットが残る。
local reward1 = util.merge_tables(st0, {
  ui = util.merge_tables(st0.ui, { mode = "reward" }),
  combat = {
    pending_drop = { id = "dust_slime", rarity = "pet" },
    pending_exp = 0,
    pending_gold = 0,
    source = nil,
    -- 撃破時点の敵ステータスをそのまま引き継ぎ、HPのみ全快することを確認する。
    enemy = {
      id = "dust_slime",
      name = "Lua Slime",
      hp = 0,
      max_hp = 23,
      atk = 7,
      def = 4,
      accuracy = 93,
      speed = 2,
      element = "grass",
    },
  },
})
local st1 = battle_flow.tick_reward(reward1, config)
assert_equal(#(st1.pet_party or {}), 1, "ペットドロップで1匹保持する")
assert_equal(st1.pet_party[1].id, "dust_slime", "取得した敵が保持される")
assert_equal(st1.pet_party[1].max_hp, 23, "撃破時点の最大HPを保持する")
assert_equal(st1.pet_party[1].hp, 23, "加入時はHPを全快にする")
assert_equal(st1.pet_party[1].atk, 7, "撃破時点の攻撃力を保持する")
assert_equal(st1.pet_party[1].def, 4, "撃破時点の防御力を保持する")
assert_equal(st1.pet_party[1].accuracy, 93, "撃破時点の命中率を保持する")
assert_equal(st1.pet_party[1].speed, 2, "撃破時点の速度を保持する")

local reward2 = util.merge_tables(st1, {
  ui = util.merge_tables(st1.ui, { mode = "reward" }),
  combat = {
    pending_drop = { id = "tux_penguin", rarity = "pet" },
    pending_exp = 0,
    pending_gold = 0,
    source = nil,
    enemy = {
      id = "tux_penguin",
      name = "Tux Penguin",
      hp = 0,
      max_hp = 31,
      atk = 11,
      def = 5,
      accuracy = 95,
      speed = 3,
      element = "water",
    },
  },
})
local st2 = battle_flow.tick_reward(reward2, config)
assert_equal(#(st2.pet_party or {}), 1, "保持上限を超えた場合でも1匹のみ保持する")
assert_equal(st2.pet_party[1].id, "tux_penguin", "上限超過時は後から得たペットが残る")
assert_equal(st2.pet_party[1].max_hp, 31, "後から得た敵の最大HPが反映される")
assert_equal(st2.pet_party[1].hp, 31, "後から得た敵もHP全快で加入する")
assert_equal(st2.pet_party[1].speed, 3, "後から得た敵の速度が反映される")

-- 猛獣使いは保持上限が増え、複数保持できる。
local st_tamer_seed = util.merge_tables(st0, {
  job_levels = util.merge_tables(st0.job_levels or {}, {
    beast_tamer = { level = 5 },
  }),
})
local st_tamer = state_module.change_job(st_tamer_seed, "beast_tamer")
local reward3 = util.merge_tables(st_tamer, {
  ui = util.merge_tables(st_tamer.ui, { mode = "reward" }),
  combat = { pending_drop = { id = "dust_slime", rarity = "pet" }, pending_exp = 0, pending_gold = 0, source = nil },
})
local st3 = battle_flow.tick_reward(reward3, config)
local reward4 = util.merge_tables(st3, {
  ui = util.merge_tables(st3.ui, { mode = "reward" }),
  combat = { pending_drop = { id = "tux_penguin", rarity = "pet" }, pending_exp = 0, pending_gold = 0, source = nil },
})
local st4 = battle_flow.tick_reward(reward4, config)
assert_true(#(st4.pet_party or {}) >= 2, "猛獣使いはペット保持上限が増える")

-- ペットがいる場合、勇者ターンでペット攻撃が加算される。
local battle_with_pet = util.merge_tables(st1, {
  actor = util.merge_tables(st1.actor, { atk = 0, speed = 3 }),
  progress = { rng_seed = 1 },
  ui = util.merge_tables(st1.ui, { mode = "battle" }),
  combat = {
    enemy = { id = "dust_slime", hp = 8, max_hp = 8, atk = 1, def = 0, accuracy = 100, speed = 1, element = "normal", drops = {} },
    turn = nil,
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
    last_turn = nil,
  },
})
local st5 = battle_flow.tick_battle(battle_with_pet, config)
assert_true((st5.combat.enemy.hp or 8) < 8, "勇者ターンでペットが攻撃に参加する")

-- 敵ターンでペットが0になった場合は手放す。
local battle_pet_defeated = util.merge_tables(st1, {
  actor = util.merge_tables(st1.actor, { def = 0, speed = 1 }),
  progress = { rng_seed = 1 },
  ui = util.merge_tables(st1.ui, { mode = "battle" }),
  combat = {
    enemy = { id = "dust_slime", hp = 8, max_hp = 8, atk = 99, def = 0, accuracy = 100, speed = 3, element = "normal", drops = {} },
    turn = nil,
    turn_wait = 0,
    hero_turn_wait = 0,
    enemy_turn_wait = 0,
    last_turn = nil,
  },
})
local st6 = battle_flow.tick_battle(battle_pet_defeated, config)
assert_equal(#(st6.pet_party or {}), 0, "ペットHPが0になると手放す")

print("OK")
