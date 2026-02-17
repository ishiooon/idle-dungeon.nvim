-- このモジュールはゲーム全体の成長式と報酬式を1箇所で管理する。
-- 勇者・敵・報酬の数値ルールを集中定義し、調整時の見通しを上げる。

local M = {}

-- 勇者の成長式はここで一元管理する。
local HERO_PROFILE = {
  default_level = 1,
  default_exp = 0,
  default_next_level = 10,
  next_level_mul = 1.2,
  next_level_add = 1,
  growth = { hp = 1, atk = 1, def = 1, speed = 0 },
}

-- 敵の成長式はここで一元管理する。
local ENEMY_PROFILE = {
  growth_base = 1,
  growth_floor = 2,
  growth_stage = 12,
  growth_boss_multiplier = 1.5,
  growth_hp = 2,
  growth_atk = 1,
  growth_def = 0.5,
  growth_speed = 0.05,
}

-- 報酬の基礎値はここで一元管理する。
local REWARD_PROFILE = {
  base_exp = 8,
  base_gold = 2,
}

-- ステージごとの敵補正と報酬補正を1箇所で管理する。
local STAGE_PROFILES = {
  [1] = {
    -- 序盤の被ダメージが常に最小値へ張り付きにくいよう攻撃力へ固定加算を入れる。
    enemy = { growth_mul = 1.25, hp_mul = 1.15, atk_mul = 1.35, def_mul = 1.15, speed_mul = 1.0, atk_add = 3 },
    reward = { exp_mul = 0.18, exp_cap = 3, gold_mul = 0.7, gold_add = 0 },
  },
  [2] = {
    enemy = { growth_mul = 1.1, hp_mul = 1.1, atk_mul = 1.2, def_mul = 1.1, speed_mul = 1.0 },
    reward = { exp_mul = 0.28, exp_cap = 4, gold_mul = 0.8, gold_add = 0 },
  },
  [3] = {
    enemy = { growth_mul = 1.0, hp_mul = 1.05, atk_mul = 1.08, def_mul = 1.05, speed_mul = 1.0 },
    reward = { exp_mul = 0.45, exp_cap = 6, gold_mul = 0.9, gold_add = 0 },
  },
  [4] = {
    enemy = { growth_mul = 0.94, hp_mul = 0.98, atk_mul = 0.97, def_mul = 0.98, speed_mul = 0.95 },
    reward = { exp_mul = 0.65, exp_cap = 9, gold_mul = 1.0, gold_add = 0 },
  },
  [5] = {
    enemy = { growth_mul = 0.9, hp_mul = 0.94, atk_mul = 0.92, def_mul = 0.94, speed_mul = 0.92 },
    reward = { exp_mul = 0.9, exp_cap = nil, gold_mul = 1.0, gold_add = 0 },
  },
  [6] = {
    enemy = { growth_mul = 0.82, hp_mul = 0.93, atk_mul = 0.9, def_mul = 0.92, speed_mul = 0.9 },
    reward = { exp_mul = 1.0, exp_cap = nil, gold_mul = 1.1, gold_add = 0 },
  },
  [7] = {
    enemy = { growth_mul = 0.8, hp_mul = 0.92, atk_mul = 0.88, def_mul = 0.9, speed_mul = 0.9 },
    reward = { exp_mul = 1.05, exp_cap = nil, gold_mul = 1.15, gold_add = 0 },
  },
  [8] = {
    enemy = { growth_mul = 0.85, hp_mul = 0.95, atk_mul = 0.9, def_mul = 0.92, speed_mul = 0.92 },
    reward = { exp_mul = 1.1, exp_cap = nil, gold_mul = 1.2, gold_add = 0 },
  },
}

local function copy_table(source)
  local result = {}
  for key, value in pairs(source or {}) do
    if type(value) == "table" then
      result[key] = copy_table(value)
    else
      result[key] = value
    end
  end
  return result
end

-- 勇者の成長定義を返す。
local function hero_profile()
  return copy_table(HERO_PROFILE)
end

-- 敵の成長定義を返す。
local function enemy_profile()
  return copy_table(ENEMY_PROFILE)
end

-- 報酬の基礎定義を返す。
local function reward_profile()
  return copy_table(REWARD_PROFILE)
end

-- ステージ補正の定義を返す。
local function stage_profiles()
  return copy_table(STAGE_PROFILES)
end

-- 勇者の初期進行度を返す。
local function default_progress()
  return {
    level = HERO_PROFILE.default_level,
    exp = HERO_PROFILE.default_exp,
    next_level = HERO_PROFILE.default_next_level,
  }
end

-- 次のレベル必要経験値を計算する。
local function next_level_requirement(current_next_level)
  local current = math.max(tonumber(current_next_level) or HERO_PROFILE.default_next_level, 1)
  return math.floor(current * HERO_PROFILE.next_level_mul) + HERO_PROFILE.next_level_add
end

-- ステージ補正を解決し、戦闘で使う形式へ揃える。
local function resolve_stage_tuning(stage)
  local stage_id = tonumber(type(stage) == "table" and stage.id or stage) or 1
  local profile = STAGE_PROFILES[stage_id] or STAGE_PROFILES[8] or {}
  local enemy = profile.enemy or {}
  local reward = profile.reward or {}
  return {
    growth_mul = math.max(tonumber(enemy.growth_mul) or 1, 0.1),
    hp_mul = math.max(tonumber(enemy.hp_mul) or 1, 0.1),
    atk_mul = math.max(tonumber(enemy.atk_mul) or 1, 0.1),
    def_mul = math.max(tonumber(enemy.def_mul) or 1, 0.1),
    speed_mul = math.max(tonumber(enemy.speed_mul) or 1, 0.1),
    hp_add = tonumber(enemy.hp_add) or 0,
    atk_add = tonumber(enemy.atk_add) or 0,
    def_add = tonumber(enemy.def_add) or 0,
    speed_add = tonumber(enemy.speed_add) or 0,
    exp_mul = math.max(tonumber(reward.exp_mul) or 1, 0.05),
    exp_cap = tonumber(reward.exp_cap),
    gold_mul = math.max(tonumber(reward.gold_mul) or 1, 0),
    gold_add = tonumber(reward.gold_add) or 0,
  }
end

-- 設定値と既定値を合わせて敵成長式を解決する。
local function resolve_enemy_growth(config)
  local battle = ((config or {}).battle or {})
  return {
    growth_base = tonumber(battle.growth_base) or ENEMY_PROFILE.growth_base,
    growth_floor = tonumber(battle.growth_floor) or ENEMY_PROFILE.growth_floor,
    growth_stage = tonumber(battle.growth_stage) or ENEMY_PROFILE.growth_stage,
    growth_boss_multiplier = tonumber(battle.growth_boss_multiplier) or ENEMY_PROFILE.growth_boss_multiplier,
    growth_hp = tonumber(battle.growth_hp) or ENEMY_PROFILE.growth_hp,
    growth_atk = tonumber(battle.growth_atk) or ENEMY_PROFILE.growth_atk,
    growth_def = tonumber(battle.growth_def) or ENEMY_PROFILE.growth_def,
    growth_speed = math.max(tonumber(battle.growth_speed) or ENEMY_PROFILE.growth_speed, 0),
  }
end

-- 敵情報から経験値報酬を計算する。
local function resolve_exp_reward(base_exp, enemy)
  local multiplier = tonumber(enemy and enemy.exp_multiplier) or 1
  local scaled = (tonumber(base_exp) or 0) * multiplier
  local reward = math.max(0, math.floor(scaled + 0.5))
  local cap = tonumber(enemy and enemy.exp_cap)
  if cap and cap >= 0 then
    reward = math.min(reward, math.floor(cap + 0.5))
  end
  return reward
end

-- 敵情報からゴールド報酬を計算する。
local function resolve_gold_reward(base_gold, bonus_gold, enemy)
  local base = tonumber(base_gold) or 0
  local bonus = tonumber(bonus_gold) or 0
  local mul = tonumber(enemy and enemy.gold_mul) or 1
  local add = tonumber(enemy and enemy.gold_add) or 0
  local scaled = math.max(0, math.floor(base * math.max(mul, 0) + 0.5) + math.floor(add + 0.5))
  return math.max(scaled + bonus, 0)
end

M.hero_profile = hero_profile
M.enemy_profile = enemy_profile
M.reward_profile = reward_profile
M.stage_profiles = stage_profiles
M.default_progress = default_progress
M.next_level_requirement = next_level_requirement
M.resolve_stage_tuning = resolve_stage_tuning
M.resolve_enemy_growth = resolve_enemy_growth
M.resolve_exp_reward = resolve_exp_reward
M.resolve_gold_reward = resolve_gold_reward

return M
