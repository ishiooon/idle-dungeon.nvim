-- このモジュールは戦利品ドロップの抽選を純粋関数で提供する。

local rng = require("idle_dungeon.rng")

local M = {}

local function resolve_rates(config, enemy)
  local drop = ((config or {}).battle or {}).drop_rates or {}
  local common = tonumber(drop.common) or 12
  local rare = tonumber(drop.rare) or 3
  local pet = tonumber(drop.pet) or 2
  if enemy and enemy.is_boss then
    local bonus = tonumber(drop.boss_bonus) or 0
    common = common + bonus
    rare = rare + math.max(math.floor(bonus / 2), 0)
    pet = pet + math.max(bonus - math.floor(bonus / 2), 0)
  end
  return {
    common = math.max(common, 0),
    rare = math.max(rare, 0),
    pet = math.max(pet, 0),
  }
end

local function resolve_rarity(item)
  if item and item.rarity then
    return item.rarity
  end
  return "common"
end

local function should_drop(item)
  if not item then
    return false
  end
  if item.drop == false then
    return false
  end
  return true
end

-- アイテムをIDで参照できるようにマップ化する。
local function build_item_map(items)
  local map = {}
  for _, item in ipairs(items or {}) do
    map[item.id] = item
  end
  return map
end

local function build_pools(items)
  local pools = { common = {}, rare = {}, pet = {} }
  for _, item in ipairs(items or {}) do
    if should_drop(item) then
      local rarity = resolve_rarity(item)
      if rarity == "common" or rarity == "rare" then
        table.insert(pools[rarity], item.id)
      end
    end
  end
  return pools
end

-- 敵のドロップ指定に含まれるアイテムIDだけを抽出する。
local function filter_drop_ids(ids, item_map)
  local result = {}
  local seen = {}
  for _, item_id in ipairs(ids or {}) do
    local item = item_map[item_id]
    if item and should_drop(item) and not seen[item_id] then
      table.insert(result, item_id)
      seen[item_id] = true
    end
  end
  return result
end

-- 敵固有のドロッププールがあれば優先し、無い場合は全体プールに戻す。
local function build_enemy_pools(items, enemy)
  local drops = enemy and enemy.drops or nil
  if not drops then
    return build_pools(items)
  end
  local item_map = build_item_map(items)
  local pools = {
    common = filter_drop_ids(drops.common, item_map),
    rare = filter_drop_ids(drops.rare, item_map),
    -- ペットは「戦った敵そのもの」が候補になる。
    pet = {},
  }
  if (#pools.common + #pools.rare + #pools.pet) == 0 then
    return build_pools(items)
  end
  return pools
end

local function pick_from_pool(seed, pool)
  if #pool == 0 then
    return nil, seed
  end
  local index, next_seed = rng.next_int(seed or 1, 1, #pool)
  return pool[index], next_seed
end

-- 敵のゴールドドロップ範囲を安全に解決する。
local function resolve_gold_range(enemy)
  local gold = enemy and enemy.drops and enemy.drops.gold or nil
  if not gold then
    return nil, nil
  end
  if type(gold) == "number" then
    return gold, gold
  end
  local min_value = tonumber(gold.min or gold[1])
  local max_value = tonumber(gold.max or gold[2] or min_value)
  if not min_value then
    return nil, nil
  end
  if max_value < min_value then
    max_value = min_value
  end
  return math.max(min_value, 0), math.max(max_value, 0)
end

-- ドロップ抽選を行い、当選した場合はIDとレアリティを返す。
local function roll_drop(seed, config, items, enemy)
  local rates = resolve_rates(config, enemy)
  local total = rates.common + rates.rare + rates.pet
  if total <= 0 then
    return nil, seed
  end
  local roll, next_seed = rng.next_int(seed or 1, 1, 100)
  local pools = build_enemy_pools(items, enemy)
  if roll <= rates.pet then
    if enemy and enemy.id and enemy.id ~= "" then
      return { id = enemy.id, rarity = "pet" }, next_seed
    end
  end
  if roll <= (rates.pet + rates.rare) then
    local id
    id, next_seed = pick_from_pool(next_seed, pools.rare)
    if id then
      return { id = id, rarity = "rare" }, next_seed
    end
  end
  if roll <= (rates.pet + rates.rare + rates.common) then
    local id
    id, next_seed = pick_from_pool(next_seed, pools.common)
    if id then
      return { id = id, rarity = "common" }, next_seed
    end
  end
  return nil, next_seed
end

-- 敵固有のゴールドドロップ額を抽選する。
local function roll_gold(seed, enemy)
  local min_value, max_value = resolve_gold_range(enemy)
  if not min_value then
    return 0, seed
  end
  local amount, next_seed = rng.next_int(seed or 1, min_value, max_value)
  return amount, next_seed
end

M.roll_drop = roll_drop
M.roll_gold = roll_gold

return M
