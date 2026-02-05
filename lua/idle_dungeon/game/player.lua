-- このモジュールはジョブと装備による能力値を算出する。

local util = require("idle_dungeon.util")

local M = {}

-- 勇者の成長値は既定値として固定する。
local HERO_GROWTH = { hp = 1, atk = 1, def = 1, speed = 0 }

local function default_progress()
  return { level = 1, exp = 0, next_level = 10 }
end

local function normalize_progress(progress)
  local base = progress or {}
  return {
    level = math.max(tonumber(base.level) or 1, 1),
    exp = math.max(tonumber(base.exp) or 0, 0),
    next_level = math.max(tonumber(base.next_level) or 10, 1),
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
    -- 攻撃速度は1以上の整数で管理し、数値が大きいほど行動間隔が長い。
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
    next_state.next_level = math.floor(next_state.next_level * 1.2) + 1
  end
  return next_state
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
  local next_actor = new_actor(job, next_hero, next_job, actor.hp)
  return next_actor, next_job
end

M.new_actor = new_actor
M.default_progress = default_progress
M.apply_equipment = apply_equipment
M.add_exp_with_job = add_exp_with_job

return M
