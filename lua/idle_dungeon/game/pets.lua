-- このモジュールはペットの保持上限と戦闘用データを純粋関数で扱う。

local skills = require("idle_dungeon.game.skills")
local util = require("idle_dungeon.util")

local M = {}

local BASE_CAPACITY = 1
local DEFAULT_PET_ICON = "󰠳"

-- pet_partyは配列として扱うため、再帰マージではなく明示代入で置き換える。
local function replace_pet_party(state, party)
  local next_state = util.shallow_copy(state or {})
  next_state.pet_party = party or {}
  return next_state
end

-- 敵定義からID一致の項目を取得する。
local function find_enemy_def(enemy_defs, enemy_id)
  for _, enemy_def in ipairs(enemy_defs or {}) do
    if enemy_def.id == enemy_id then
      return enemy_def
    end
  end
  return nil
end

-- 敵定義を戦闘用の保持データへ変換する。
local function build_pet_from_enemy(enemy_def, fallback_icon)
  if not enemy_def then
    return nil
  end
  local stats = enemy_def.stats or {}
  local max_hp = math.max(tonumber(enemy_def.hp) or tonumber(stats.hp) or 1, 1)
  local atk = math.max(tonumber(enemy_def.atk) or tonumber(stats.atk) or 1, 1)
  local def = math.max(tonumber(enemy_def.def) or tonumber(stats.def) or 0, 0)
  local accuracy = math.max(tonumber(enemy_def.accuracy) or tonumber(stats.accuracy) or 90, 0)
  local element = enemy_def.element
  if (not element or element == "") and type(enemy_def.elements) == "table" and #enemy_def.elements > 0 then
    element = enemy_def.elements[1]
  end
  return {
    id = enemy_def.id,
    name = enemy_def.name_ja or enemy_def.name or enemy_def.id,
    name_en = enemy_def.name_en or enemy_def.name or enemy_def.id,
    icon = enemy_def.icon or fallback_icon or DEFAULT_PET_ICON,
    hp = max_hp,
    max_hp = max_hp,
    atk = atk,
    def = def,
    accuracy = accuracy,
    element = element or "normal",
  }
end

-- 保存済みデータを安全な形式へ正規化する。
local function normalize_pet(entry, enemy_defs, fallback_icon)
  if not entry then
    return nil
  end
  local enemy_def = find_enemy_def(enemy_defs, entry.id)
  if enemy_def then
    local built = build_pet_from_enemy(enemy_def, fallback_icon)
    built.max_hp = math.max(tonumber(entry.max_hp) or built.max_hp, 1)
    built.hp = math.max(math.min(tonumber(entry.hp) or built.hp, built.max_hp), 0)
    built.atk = math.max(tonumber(entry.atk) or built.atk, 1)
    built.def = math.max(tonumber(entry.def) or built.def, 0)
    built.accuracy = math.max(tonumber(entry.accuracy) or built.accuracy, 0)
    if type(entry.icon) == "string" and entry.icon ~= "" then
      built.icon = entry.icon
    end
    return built
  end
  -- 定義が見つからない旧データでも、最低限の表示情報は維持する。
  return {
    id = entry.id or "pet",
    name = entry.name or entry.id or "pet",
    name_en = entry.name_en or entry.name or entry.id or "pet",
    icon = entry.icon or fallback_icon or DEFAULT_PET_ICON,
    hp = math.max(tonumber(entry.hp) or 1, 0),
    max_hp = math.max(tonumber(entry.max_hp) or 1, 1),
    atk = math.max(tonumber(entry.atk) or 1, 1),
    def = math.max(tonumber(entry.def) or 0, 0),
    accuracy = math.max(tonumber(entry.accuracy) or 90, 0),
    element = entry.element or "normal",
  }
end

-- 配列全体を正規化し、HP0の個体を除外する。
local function normalize_party(party, enemy_defs, fallback_icon)
  local normalized = {}
  for _, entry in ipairs(party or {}) do
    local pet = normalize_pet(entry, enemy_defs, fallback_icon)
    if pet and pet.hp > 0 then
      table.insert(normalized, pet)
    end
  end
  return normalized
end

-- 取得済みパッシブからペット保持上限の増加量を計算する。
local function resolve_capacity(state, jobs)
  local bonus = skills.resolve_passive_pet_slots(state.skills, state.skill_settings, jobs)
  return math.max(BASE_CAPACITY + bonus, 1)
end

-- 末尾優先で保持上限に収まるように切り詰める。
local function trim_to_capacity(party, capacity)
  local limit = math.max(tonumber(capacity) or BASE_CAPACITY, 1)
  if #party <= limit then
    return party
  end
  local result = {}
  for index = #party - limit + 1, #party do
    table.insert(result, party[index])
  end
  return result
end

-- 現在状態の保持上限を強制適用する。
local function enforce_capacity(state, jobs, enemy_defs, fallback_icon)
  local party = normalize_party(state.pet_party, enemy_defs, fallback_icon)
  local capacity = resolve_capacity(state, jobs)
  local next_party = trim_to_capacity(party, capacity)
  if util.is_close(#next_party, #(state.pet_party or {}), 0) then
    local same = true
    for index, pet in ipairs(next_party) do
      local before = (state.pet_party or {})[index]
      if not before or before.id ~= pet.id or before.hp ~= pet.hp then
        same = false
        break
      end
    end
    if same then
      return state
    end
  end
  return replace_pet_party(state, next_party)
end

-- 新しいペットを追加し、保持上限を超えた分は古い順に外す。
local function add_pet(state, pet_id, enemy_defs, jobs, fallback_icon)
  local enemy_def = find_enemy_def(enemy_defs, pet_id)
  local pet = build_pet_from_enemy(enemy_def, fallback_icon)
  if not pet then
    return state
  end
  local party = normalize_party(state.pet_party, enemy_defs, fallback_icon)
  table.insert(party, pet)
  return replace_pet_party(state, trim_to_capacity(party, resolve_capacity(state, jobs)))
end

-- 指定したペットにダメージを与え、HP0なら保持一覧から外す。
local function damage_pet(state, damage, target_index, enemy_defs, fallback_icon)
  local amount = math.max(tonumber(damage) or 0, 0)
  local party = normalize_party(state.pet_party, enemy_defs, fallback_icon)
  if #party == 0 or amount <= 0 then
    return state, nil
  end
  local index = math.max(math.min(tonumber(target_index) or 1, #party), 1)
  local target = util.merge_tables(party[index], {})
  target.hp = math.max((target.hp or 0) - amount, 0)
  local defeated = nil
  if target.hp <= 0 then
    defeated = target
    table.remove(party, index)
  else
    party[index] = target
  end
  return replace_pet_party(state, party), defeated
end

M.normalize_party = normalize_party
M.resolve_capacity = resolve_capacity
M.trim_to_capacity = trim_to_capacity
M.enforce_capacity = enforce_capacity
M.add_pet = add_pet
M.damage_pet = damage_pet

return M
