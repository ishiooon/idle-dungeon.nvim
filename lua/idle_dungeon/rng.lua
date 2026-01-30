-- このモジュールは擬似乱数の更新と範囲取得を純粋関数で提供する。

local M = {}

local MODULUS = 2147483647
local MULTIPLIER = 1103515245
local INCREMENT = 12345

local function normalize_seed(seed)
  local value = tonumber(seed)
  if not value or value <= 0 then
    return 1
  end
  return math.floor(value) % MODULUS
end

local function next_seed(seed)
  local base = normalize_seed(seed)
  return (base * MULTIPLIER + INCREMENT) % MODULUS
end

local function next_int(seed, min_value, max_value)
  local min_val = math.floor(tonumber(min_value) or 0)
  local max_val = math.floor(tonumber(max_value) or min_val)
  if max_val < min_val then
    max_val, min_val = min_val, max_val
  end
  local updated_seed = next_seed(seed)
  local span = (max_val - min_val) + 1
  local value = min_val + (updated_seed % span)
  return value, updated_seed
end

M.next_seed = next_seed
M.next_int = next_int

return M
