-- このモジュールはジョブと装備による能力値を算出する。

local util = require("idle_dungeon.util")
local balance = require("idle_dungeon.game.balance")

local M = {}

-- 勇者の成長値は既定値として固定する。
local HERO_GROWTH = (balance.hero_profile() or {}).growth or { hp = 1, atk = 1, def = 1, speed = 0 }

local function default_progress()
  return balance.default_progress()
end

local function normalize_progress(progress)
  local base = progress or {}
  return {
    level = math.max(tonumber(base.level) or 1, 1),
    exp = math.max(tonumber(base.exp) or 0, 0),
    next_level = math.max(tonumber(base.next_level) or (balance.default_progress().next_level or 10), 1),
  }
end

local function build_base_stats(job, hero_level, job_level)
  local base = job.base or {}
  local growth = job.growth or {}
  local hero_gain = math.max(tonumber(hero_level) or 1, 1) - 1
  local job_gain = math.max(tonumber(job_level) or 1, 1) - 1
  local function calc(value, hero_step, job_step)
    return (tonumber(value) or 0) + hero_gain * (tonumber(hero_step) or 0) + job_gain * (tonumber(job_step) or 0)
  end
  return {
    hp = calc(base.hp, HERO_GROWTH.hp, growth.hp),
    atk = calc(base.atk, HERO_GROWTH.atk, growth.atk),
    def = calc(base.def, HERO_GROWTH.def, growth.def),
    speed = math.max(calc(base.speed or 2, HERO_GROWTH.speed, growth.speed), 1),
  }
end

local function new_actor(job, hero_progress, job_progress, current_hp)
  local hero = normalize_progress(hero_progress)
  local job_state = normalize_progress(job_progress)
  local base = build_base_stats(job, hero.level, job_state.level)
  local next_hp = current_hp and math.min(current_hp, base.hp) or base.hp
  return {
    id = job.id,
    name = job.name,
    role = job.role,
    -- 勇者レベルは全ジョブ共通で上昇する。
    level = hero.level,
    exp = hero.exp,
    next_level = hero.next_level,
    -- ジョブごとの成長は別のレベルで管理する。
    job_level = job_state.level,
    job_exp = job_state.exp,
    job_next_level = job_state.next_level,
    base_hp = base.hp,
    base_atk = base.atk,
    base_def = base.def,
    -- 攻撃速度は1以上の整数で管理し、相手より高いほど行動間隔が短い。
    base_speed = base.speed,
    max_hp = base.hp,
    hp = next_hp,
    atk = base.atk,
    def = base.def,
    speed = base.speed,
    -- 会話頻度の補正はジョブごとに持たせる。
    dialogue_ratio = job.dialogue_ratio or 1.0,
  }
end

local function apply_equipment(actor, equipment, items)
  local bonus_hp, bonus_atk, bonus_def, bonus_speed = 0, 0, 0, 0
  for _, item in pairs(items or {}) do
    if equipment[item.slot] == item.id then
      bonus_hp = bonus_hp + (item.hp or 0)
      bonus_atk = bonus_atk + (item.atk or 0)
      bonus_def = bonus_def + (item.def or 0)
      bonus_speed = bonus_speed + (item.speed or 0)
    end
  end
  local next_actor = util.merge_tables(actor, {})
  next_actor.max_hp = next_actor.base_hp + bonus_hp
  next_actor.atk = next_actor.base_atk + bonus_atk
  next_actor.def = next_actor.base_def + bonus_def
  -- 装備で速度補正がある場合も1以上を保つ。
  next_actor.speed = math.max((next_actor.base_speed or 1) + bonus_speed, 1)
  if next_actor.hp > next_actor.max_hp then
    next_actor.hp = next_actor.max_hp
  end
  return next_actor
end

local function apply_progress(exp_state, amount)
  local next_state = util.merge_tables(exp_state, {})
  next_state.exp = next_state.exp + amount
  while next_state.exp >= next_state.next_level do
    next_state.exp = next_state.exp - next_state.next_level
    next_state.level = next_state.level + 1
    next_state.next_level = balance.next_level_requirement(next_state.next_level)
  end
  return next_state
end

-- レベル上昇分だけ、勇者共通成長とジョブ成長を現在能力値へ加算する。
local function apply_level_growth(actor, level_gain, job)
  local gain = math.max(tonumber(level_gain) or 0, 0)
  if gain <= 0 then
    return util.merge_tables(actor, {})
  end
  local growth = (job or {}).growth or {}
  local hp_gain = gain * ((HERO_GROWTH.hp or 0) + (tonumber(growth.hp) or 0))
  local atk_gain = gain * ((HERO_GROWTH.atk or 0) + (tonumber(growth.atk) or 0))
  local def_gain = gain * ((HERO_GROWTH.def or 0) + (tonumber(growth.def) or 0))
  local speed_gain = gain * ((HERO_GROWTH.speed or 0) + (tonumber(growth.speed) or 0))
  local base_hp = tonumber(actor.base_hp) or tonumber(actor.max_hp) or tonumber(actor.hp) or 1
  local base_atk = tonumber(actor.base_atk) or tonumber(actor.atk) or 0
  local base_def = tonumber(actor.base_def) or tonumber(actor.def) or 0
  local base_speed = tonumber(actor.base_speed) or tonumber(actor.speed) or 1
  local next_base_hp = math.max(base_hp + hp_gain, 1)
  local next_base_atk = base_atk + atk_gain
  local next_base_def = base_def + def_gain
  local next_base_speed = math.max(base_speed + speed_gain, 1)
  local hp_now = tonumber(actor.hp) or next_base_hp
  local next_hp = math.min(hp_now, next_base_hp)
  return util.merge_tables(actor, {
    base_hp = next_base_hp,
    base_atk = next_base_atk,
    base_def = next_base_def,
    base_speed = next_base_speed,
    max_hp = next_base_hp,
    hp = next_hp,
    atk = next_base_atk,
    def = next_base_def,
    speed = next_base_speed,
  })
end

local function add_exp_with_job(actor, amount, job_progress, job)
  local hero_progress = normalize_progress({ level = actor.level, exp = actor.exp, next_level = actor.next_level })
  local job_state = normalize_progress(job_progress)
  local next_hero = apply_progress(hero_progress, amount)
  -- ジョブレベルは勇者レベルの上昇に同期して上げる。
  local level_gain = math.max(next_hero.level - hero_progress.level, 0)
  local next_job = util.merge_tables(job_state, {
    level = math.max(job_state.level + level_gain, 1),
    -- ジョブ経験値は勇者の進行状況を表示するために合わせて更新する。
    exp = next_hero.exp,
    next_level = next_hero.next_level,
  })
  -- ジョブ切替直後のステータス変化を避けるため、現在値を基準に必要な項目だけ更新する。
  local next_actor = util.merge_tables(actor, {
    id = job.id,
    name = job.name,
    role = job.role,
    level = next_hero.level,
    exp = next_hero.exp,
    next_level = next_hero.next_level,
    job_level = next_job.level,
    job_exp = next_job.exp,
    job_next_level = next_job.next_level,
    dialogue_ratio = job.dialogue_ratio or 1.0,
  })
  next_actor = apply_level_growth(next_actor, level_gain, job)
  return next_actor, next_job
end

M.new_actor = new_actor
M.default_progress = default_progress
M.apply_equipment = apply_equipment
M.add_exp_with_job = add_exp_with_job

return M
