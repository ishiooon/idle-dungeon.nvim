-- このモジュールは敵データの参照と出現判定を純粋関数で提供する。
local content = require("idle_dungeon.content")
local element = require("idle_dungeon.game.element")
local rng = require("idle_dungeon.rng")

local M = {}

local function find_enemy(enemy_id)
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.id == enemy_id then
      return enemy
    end
  end
  return nil
end

local function appears_in_stage(enemy, stage_id)
  local appear = enemy and enemy.appear or nil
  if not appear then
    return true
  end
  if not stage_id then
    return true
  end
  if appear.stages then
    for _, value in ipairs(appear.stages) do
      if value == stage_id then
        return true
      end
    end
    return false
  end
  if appear.min and stage_id < appear.min then
    return false
  end
  if appear.max and stage_id > appear.max then
    return false
  end
  return true
end

local function available_ids(stage_id)
  local ids = {}
  for _, enemy in ipairs(content.enemies or {}) do
    if appears_in_stage(enemy, stage_id) then
      table.insert(ids, enemy.id)
    end
  end
  return ids
end

local function find_stage(config, stage_id)
  for _, stage in ipairs((config or {}).stages or {}) do
    if stage.id == stage_id then
      return stage
    end
  end
  return nil
end

local function filter_known_ids(ids)
  local result = {}
  local seen = {}
  for _, enemy_id in ipairs(ids or {}) do
    if not seen[enemy_id] and find_enemy(enemy_id) then
      table.insert(result, enemy_id)
      seen[enemy_id] = true
    end
  end
  return result
end

-- 敵の重みを取得し、未設定なら既定値を使う。
local function resolve_weight(enemy_id)
  local enemy = find_enemy(enemy_id)
  local weight = enemy and enemy.weight or 10
  if type(weight) ~= "number" or weight <= 0 then
    return 10
  end
  return weight
end

local function pick_from_list(seed, ids)
  if #ids == 0 then
    return nil, seed
  end
  local total = 0
  for _, enemy_id in ipairs(ids) do
    total = total + resolve_weight(enemy_id)
  end
  local roll, next_seed = rng.next_int(seed or 1, 1, total)
  local cursor = 0
  for _, enemy_id in ipairs(ids) do
    cursor = cursor + resolve_weight(enemy_id)
    if roll <= cursor then
      return enemy_id, next_seed
    end
  end
  return ids[#ids], next_seed
end

local function resolve_pool(progress, config)
  local stage = find_stage(config, progress and progress.stage_id or nil)
  local pool = stage and stage.enemy_pool or nil
  if not pool then
    return nil
  end
  -- ステージ指定のプールは敵定義に存在するIDだけを採用する。
  return {
    fixed = filter_known_ids(pool.fixed),
    mixed = filter_known_ids(pool.mixed),
    fixed_ratio = tonumber(pool.fixed_ratio),
  }
end

local function fallback_ids(progress, config)
  local names = (config or {}).enemy_names or {}
  if #names > 0 then
    return names
  end
  return available_ids(progress and progress.stage_id or nil)
end

local function pick_enemy_id(seed, progress, config)
  local pool = resolve_pool(progress, config)
  local next_seed = seed or 1
  local chosen = {}
  if pool and (pool.fixed_ratio or #pool.fixed > 0 or #pool.mixed > 0) then
    local ratio = pool.fixed_ratio or 0
    local roll
    roll, next_seed = rng.next_int(next_seed, 1, 100)
    local use_fixed = roll <= ratio
    if use_fixed and #pool.fixed > 0 then
      chosen = pool.fixed
    elseif (not use_fixed) and #pool.mixed > 0 then
      chosen = pool.mixed
    elseif #pool.fixed > 0 then
      chosen = pool.fixed
    else
      chosen = pool.mixed
    end
  end
  if #chosen == 0 then
    chosen = fallback_ids(progress, config)
  end
  local enemy_id
  enemy_id, next_seed = pick_from_list(next_seed, chosen)
  return enemy_id or "enemy", next_seed
end

local function pick_element(enemy, seed, config)
  local list = (enemy and enemy.elements) or element.list(config)
  if #list == 0 then
    return "normal", seed
  end
  local index, next_seed = rng.next_int(seed or 1, 1, #list)
  return list[index], next_seed
end

M.find_enemy = find_enemy
M.available_ids = available_ids
M.pick_enemy_id = pick_enemy_id
M.pick_element = pick_element

return M
