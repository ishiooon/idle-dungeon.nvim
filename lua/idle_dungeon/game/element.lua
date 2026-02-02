-- このモジュールは属性タイプの一覧と選択を純粋関数で提供する。

local rng = require("idle_dungeon.rng")

local M = {}

local DEFAULT_ELEMENTS = { "normal", "fire", "water", "grass", "light", "dark" }
local DEFAULT_RELATIONS = {
  normal = { strong = {}, weak = {} },
  fire = { strong = { "grass" }, weak = { "water" } },
  water = { strong = { "fire" }, weak = { "grass" } },
  grass = { strong = { "water" }, weak = { "fire" } },
  -- 光と闇は互いに有利とし、攻撃側の相性は対になる属性だけを見る。
  light = { strong = { "dark" }, weak = {} },
  dark = { strong = { "light" }, weak = {} },
}
local DEFAULT_MULTIPLIERS = { strong = 1.25, weak = 0.75, neutral = 1.0 }

local function list(config)
  local custom = (config or {}).elements or (config or {}).element_types
  if type(custom) == "table" and #custom > 0 then
    return custom
  end
  return DEFAULT_ELEMENTS
end

local function pick(seed, config)
  local elements = list(config)
  if #elements == 0 then
    return "normal", seed
  end
  local index, next_seed = rng.next_int(seed or 1, 1, #elements)
  return elements[index], next_seed
end

local function label(element, lang)
  local map = {
    normal = { en = "Normal", jp = "ノーマル" },
    fire = { en = "Fire", jp = "炎" },
    water = { en = "Water", jp = "水" },
    grass = { en = "Grass", jp = "草" },
    light = { en = "Light", jp = "光" },
    dark = { en = "Dark", jp = "闇" },
  }
  local entry = map[element] or map.normal
  if lang == "ja" then
    return entry.jp
  end
  return entry.en
end

-- 相性表を設定から取得し、未指定なら既定表を使う。
local function resolve_relations(config)
  local custom = (config or {}).element_relations or ((config or {}).battle or {}).element_relations
  if type(custom) == "table" then
    return custom
  end
  return DEFAULT_RELATIONS
end

-- ダメージ倍率の設定を取得し、未指定なら既定値を使う。
local function resolve_multipliers(config)
  local custom = (config or {}).element_multipliers or ((config or {}).battle or {}).element_multipliers
  if type(custom) == "table" then
    return {
      strong = tonumber(custom.strong) or DEFAULT_MULTIPLIERS.strong,
      weak = tonumber(custom.weak) or DEFAULT_MULTIPLIERS.weak,
      neutral = tonumber(custom.neutral) or DEFAULT_MULTIPLIERS.neutral,
    }
  end
  return DEFAULT_MULTIPLIERS
end

-- 配列に対象要素が含まれるかを判定する。
local function contains(list, value)
  for _, item in ipairs(list or {}) do
    if item == value then
      return true
    end
  end
  return false
end

-- 攻撃側から見た属性相性の種別を返す。
local function relation(attacker, defender, config)
  local relations = resolve_relations(config)
  local entry = relations[attacker or "normal"] or relations.normal or {}
  if contains(entry.strong, defender) then
    return "strong"
  end
  if contains(entry.weak, defender) then
    return "weak"
  end
  return "neutral"
end

-- ダメージ倍率と相性種別を返す。
local function effectiveness(attacker, defender, config)
  local rel = relation(attacker, defender, config)
  local multipliers = resolve_multipliers(config)
  return multipliers[rel] or multipliers.neutral or 1.0, rel
end

M.list = list
M.pick = pick
M.label = label
M.relation = relation
M.effectiveness = effectiveness

return M
