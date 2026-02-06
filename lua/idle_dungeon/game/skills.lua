-- このモジュールはスキルの解放と状態管理を扱う。

local util = require("idle_dungeon.util")
local rng = require("idle_dungeon.rng")

local M = {}

local function empty()
  return { active = {}, passive = {} }
end

local function normalize(learned)
  local base = learned or {}
  return {
    active = util.merge_tables(base.active or {}, {}),
    passive = util.merge_tables(base.passive or {}, {}),
  }
end

local function normalize_settings(settings)
  local base = settings or {}
  return {
    active = util.merge_tables(base.active or {}, {}),
    passive = util.merge_tables(base.passive or {}, {}),
  }
end

-- ジョブ定義からスキルIDの参照表を作成する。
local function build_catalog(jobs)
  local catalog = {}
  for _, job in ipairs(jobs or {}) do
    for _, skill in ipairs(job.skills or {}) do
      if skill.id then
        catalog[skill.id] = util.merge_tables(skill, { job_id = job.id })
      end
    end
  end
  return catalog
end

-- 指定ジョブのレベルに応じてスキルを解放する。
local function unlock_from_job(learned, job, job_progress)
  local result = normalize(learned)
  local level = (job_progress and job_progress.level) or 1
  for _, skill in ipairs(job.skills or {}) do
    if (skill.level or 1) <= level and skill.id then
      local bucket = skill.kind == "active" and "active" or "passive"
      result[bucket][skill.id] = true
    end
  end
  return result
end

-- 習得済みスキルの一覧を種別ごとに取得する。
local function list_learned(learned, jobs, kind, settings)
  local result = {}
  local normalized = normalize(learned)
  local enabled = settings and normalize_settings(settings) or nil
  local catalog = build_catalog(jobs)
  local source = normalized[kind] or {}
  for id in pairs(source) do
    local skill = catalog[id]
    if skill and (not enabled or enabled[kind][id] ~= false) then
      table.insert(result, skill)
    end
  end
  table.sort(result, function(a, b)
    return (a.level or 1) < (b.level or 1)
  end)
  return result
end

-- 乗数表現の補正値を「1基準の差分」で加算合成する。
local function merge_bonus_value(current, value)
  local numeric = tonumber(value)
  if numeric == nil then
    return current
  end
  return current + (numeric - 1)
end

-- パッシブスキルの補正値を合算して返す。
local function resolve_passive_bonus(learned, settings, jobs)
  local bonus = { atk = 1, def = 1, accuracy = 1 }
  for _, skill in ipairs(list_learned(learned, jobs, "passive", settings)) do
    local mul = skill.bonus_mul or {}
    bonus.atk = merge_bonus_value(bonus.atk, mul.atk)
    bonus.def = merge_bonus_value(bonus.def, mul.def)
    bonus.accuracy = merge_bonus_value(bonus.accuracy, mul.accuracy)
  end
  return bonus
end

-- パッシブスキルによるペット保持上限の増加量を合算する。
local function resolve_passive_pet_slots(learned, settings, jobs)
  local slots = 0
  for _, skill in ipairs(list_learned(learned, jobs, "passive", settings)) do
    slots = slots + math.max(tonumber(skill.pet_slots) or 0, 0)
  end
  return slots
end

-- 敵のパッシブスキル倍率を合算する。
local function resolve_passive_bonus_from_list(skill_list)
  local bonus = { atk = 1, def = 1, accuracy = 1 }
  for _, skill in ipairs(skill_list or {}) do
    if skill.kind == "passive" then
      local mul = skill.bonus_mul or {}
      bonus.atk = merge_bonus_value(bonus.atk, mul.atk)
      bonus.def = merge_bonus_value(bonus.def, mul.def)
      bonus.accuracy = merge_bonus_value(bonus.accuracy, mul.accuracy)
    end
  end
  return bonus
end

-- アクティブスキルの自動発動を抽選して返す。
local function choose_active_skill(learned, settings, jobs, seed, rate)
  local active = list_learned(learned, jobs, "active", settings)
  if #active == 0 then
    return nil, seed
  end
  local chance = math.max(tonumber(rate) or 0, 0)
  if chance <= 0 then
    return nil, seed
  end
  local threshold = math.min(math.floor(chance * 100 + 0.5), 100)
  local roll, next_seed = rng.next_int(seed or 1, 1, 100)
  if roll > threshold then
    return nil, next_seed
  end
  local total_weight = 0
  for _, skill in ipairs(active) do
    total_weight = total_weight + math.max(tonumber(skill.rate) or 0, 0)
  end
  if total_weight <= 0 then
    return nil, next_seed
  end
  local scale = 10000
  local target, seeded = rng.next_int(next_seed, 1, math.max(math.floor(total_weight * scale), 1))
  local cursor = 0
  for _, skill in ipairs(active) do
    cursor = cursor + math.max(tonumber(skill.rate) or 0, 0) * scale
    if target <= cursor then
      return skill, seeded
    end
  end
  return active[#active], seeded
end

-- 敵のアクティブスキルを抽選して返す。
local function choose_active_skill_from_list(skill_list, seed, rate)
  local active = {}
  for _, skill in ipairs(skill_list or {}) do
    if skill.kind == "active" then
      table.insert(active, skill)
    end
  end
  if #active == 0 then
    return nil, seed
  end
  local chance = math.max(tonumber(rate) or 0, 0)
  if chance <= 0 then
    return nil, seed
  end
  local threshold = math.min(math.floor(chance * 100 + 0.5), 100)
  local roll, next_seed = rng.next_int(seed or 1, 1, 100)
  if roll > threshold then
    return nil, next_seed
  end
  local total_weight = 0
  for _, skill in ipairs(active) do
    total_weight = total_weight + math.max(tonumber(skill.rate) or 0, 0)
  end
  if total_weight <= 0 then
    return nil, next_seed
  end
  local scale = 10000
  local target, seeded = rng.next_int(next_seed, 1, math.max(math.floor(total_weight * scale), 1))
  local cursor = 0
  for _, skill in ipairs(active) do
    cursor = cursor + math.max(tonumber(skill.rate) or 0, 0) * scale
    if target <= cursor then
      return skill, seeded
    end
  end
  return active[#active], seeded
end

-- スキルが習得済みかどうかを判定する。
local function is_learned(learned, skill_id)
  local result = normalize(learned)
  return result.active[skill_id] == true or result.passive[skill_id] == true
end

local function is_enabled(settings, skill_id, kind)
  local normalized = normalize_settings(settings)
  local bucket = kind == "active" and normalized.active or normalized.passive
  if bucket[skill_id] == nil then
    return true
  end
  return bucket[skill_id] == true
end

local function ensure_enabled(settings, learned)
  local result = normalize_settings(settings)
  local normalized = normalize(learned)
  for id in pairs(normalized.active) do
    if result.active[id] == nil then
      result.active[id] = true
    end
  end
  for id in pairs(normalized.passive) do
    if result.passive[id] == nil then
      result.passive[id] = true
    end
  end
  return result
end

M.empty = empty
M.normalize = normalize
M.normalize_settings = normalize_settings
M.unlock_from_job = unlock_from_job
M.list_learned = list_learned
M.resolve_passive_bonus = resolve_passive_bonus
M.resolve_passive_pet_slots = resolve_passive_pet_slots
M.resolve_passive_bonus_from_list = resolve_passive_bonus_from_list
M.choose_active_skill = choose_active_skill
M.choose_active_skill_from_list = choose_active_skill_from_list
M.is_learned = is_learned
M.is_enabled = is_enabled
M.ensure_enabled = ensure_enabled

return M
