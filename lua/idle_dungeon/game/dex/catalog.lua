-- このモジュールは図鑑表示用の整形を純粋関数として提供する。

local content = require("idle_dungeon.content")
local element = require("idle_dungeon.game.element")
local i18n = require("idle_dungeon.i18n")

local M = {}

-- 多言語の本文を解決する。
local function resolve_text(value, lang)
  if type(value) == "table" then
    return value[lang] or value.en or value.ja or ""
  end
  return value or ""
end

-- 図鑑の表示名を言語に合わせて決定する。
local function resolve_name(entry, lang)
  if lang == "en" and entry.name_en then
    return entry.name_en
  end
  if lang == "ja" and entry.name_ja then
    return entry.name_ja
  end
  return resolve_text(entry.name, lang) ~= "" and resolve_text(entry.name, lang) or (entry.id or "")
end

local function resolve_icon(entry)
  return entry and entry.icon or ""
end

local function resolve_enemy_elements(enemy)
  if not enemy or type(enemy.elements) ~= "table" or #enemy.elements == 0 then
    return { "normal" }
  end
  return enemy.elements
end

local function build_enemy_key(enemy_id, element_id)
  if not enemy_id or enemy_id == "" then
    return nil
  end
  if element_id and element_id ~= "" then
    return enemy_id .. ":" .. element_id
  end
  return enemy_id
end

-- IDで参照できるように一覧をマップ化する。
local function build_map(entries)
  local map = {}
  for _, entry in ipairs(entries or {}) do
    map[entry.id] = entry
  end
  return map
end

-- 図鑑で表示する1行の文を組み立てる。
local function build_entry_line(name, count, flavor, icon_text, element_label, drop_text, unknown_label, known)
  local safe_name = name ~= "" and name or (unknown_label or "???")
  local count_text = known and tostring(count or 0) or (unknown_label or "???")
  local suffix = string.format(" x%s", count_text)
  local icon = icon_text and icon_text ~= "" and (icon_text .. " ") or ""
  local element_text = element_label and element_label ~= "" and ("[" .. element_label .. "] ") or ""
  local base_line
  if flavor ~= "" then
    base_line = string.format("%s%s%s%s - %s", icon, element_text, safe_name, suffix, flavor)
  else
    base_line = string.format("%s%s%s%s", icon, element_text, safe_name, suffix)
  end
  if drop_text and drop_text ~= "" then
    return string.format("%s | %s", base_line, drop_text)
  end
  return base_line
end

-- 敵のドロップ候補を一覧に整形する。
local function build_drop_entries(enemy, dex_items, item_map, lang, unknown_label)
  local drops = enemy and enemy.drops or nil
  if not drops then
    return {}
  end
  local entries = {}
  local seen = {}
  local function push_item(item_id)
    if not item_id or item_id == "" or seen[item_id] then
      return
    end
    local item = item_map[item_id]
    if not item then
      return
    end
    local known = (dex_items or {})[item_id] ~= nil
    local name = known and resolve_name(item, lang) or unknown_label
    table.insert(entries, { id = item_id, name = name, known = known })
    seen[item_id] = true
  end
  for _, item_id in ipairs(drops.common or {}) do
    push_item(item_id)
  end
  for _, item_id in ipairs(drops.rare or {}) do
    push_item(item_id)
  end
  for _, item_id in ipairs(drops.pet or {}) do
    push_item(item_id)
  end
  return entries
end

local function build_drop_text_from_entries(entries, lang)
  if not entries or #entries == 0 then
    return ""
  end
  local drop_label = i18n.t("dex_label_drops", lang)
  local parts = {}
  for _, entry in ipairs(entries) do
    table.insert(parts, entry.name or "")
  end
  if #parts == 0 then
    return ""
  end
  return string.format("%s: %s", drop_label, table.concat(parts, ", "))
end

-- 図鑑に表示する敵のエントリ一覧を構築する。
local function build_enemy_entries(state, lang)
  local dex_entries = (state.dex or {}).enemies or {}
  local dex_items = (state.dex or {}).items or {}
  local unknown_label = i18n.t("dex_unknown", lang)
  local item_map = build_map(content.items or {})
  local recorded = {}
  for entry_id, info in pairs(dex_entries) do
    if entry_id then
      recorded[entry_id] = info
    end
  end
  local entries = {}
  local order_index = 0
  for _, enemy in ipairs(content.enemies or {}) do
    local elements = resolve_enemy_elements(enemy)
    for _, element_id in ipairs(elements) do
      order_index = order_index + 1
      local record_key = build_enemy_key(enemy.id, element_id)
      local record = record_key and recorded[record_key] or nil
      if record then
        local drop_entries = build_drop_entries(enemy, dex_items, item_map, lang, unknown_label)
        local element_label = element_id and element.label(element_id, lang) or nil
        table.insert(entries, {
          id = enemy.id,
          name = resolve_name(enemy, lang),
          icon = resolve_icon(enemy),
          element_id = element_id,
          element_label = element_label,
          count = record.count or 0,
          flavor = resolve_text(enemy.flavor, lang),
          known = true,
          drops = drop_entries,
          first_time = record.first_time or 0,
          order_index = order_index,
        })
      else
        table.insert(entries, {
          id = enemy.id,
          name = unknown_label,
          icon = "",
          element_id = element_id,
          element_label = unknown_label,
          count = 0,
          flavor = "",
          known = false,
          drops = {},
          first_time = nil,
          order_index = order_index,
        })
      end
    end
  end
  table.sort(entries, function(a, b)
    if a.known ~= b.known then
      return a.known
    end
    if a.known and b.known then
      if (a.first_time or 0) == (b.first_time or 0) then
        return (a.order_index or 0) < (b.order_index or 0)
      end
      return (a.first_time or 0) < (b.first_time or 0)
    end
    return (a.order_index or 0) < (b.order_index or 0)
  end)
  return entries
end

-- 図鑑に表示する装備のエントリ一覧を構築する。
local function build_item_entries(state, lang)
  local dex_entries = (state.dex or {}).items or {}
  local unknown_label = i18n.t("dex_unknown", lang)
  local entries = {}
  local order_index = 0
  for _, item in ipairs(content.items or {}) do
    order_index = order_index + 1
    local record = dex_entries[item.id]
    if record then
      local name = resolve_name(item, lang)
      local flavor = resolve_text(item.flavor, lang)
      local element_label = item.element and element.label(item.element, lang) or nil
      table.insert(entries, {
        id = item.id,
        name = name,
        icon = resolve_icon(item),
        element_label = element_label,
        count = record.count or 0,
        flavor = flavor,
        known = true,
        slot = item.slot,
        rarity = item.rarity,
        first_time = record.first_time or 0,
        order_index = order_index,
      })
    else
      table.insert(entries, {
        id = item.id,
        name = unknown_label,
        icon = "",
        element_label = unknown_label,
        count = 0,
        flavor = "",
        known = false,
        slot = item.slot,
        rarity = item.rarity,
        first_time = nil,
        order_index = order_index,
      })
    end
  end
  table.sort(entries, function(a, b)
    if a.known ~= b.known then
      return a.known
    end
    if a.known and b.known then
      if (a.first_time or 0) == (b.first_time or 0) then
        return (a.order_index or 0) < (b.order_index or 0)
      end
      return (a.first_time or 0) < (b.first_time or 0)
    end
    return (a.order_index or 0) < (b.order_index or 0)
  end)
  return entries
end

-- 図鑑に表示する敵一覧を構築する。
local function build_enemy_lines(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local result = {}
  for _, entry in ipairs(build_enemy_entries(state, lang)) do
    local drop_text = build_drop_text_from_entries(entry.drops, lang)
    table.insert(result, build_entry_line(entry.name, entry.count, entry.flavor, entry.icon, entry.element_label, drop_text, unknown_label, entry.known))
  end
  return result
end

-- 図鑑に表示する装備一覧を構築する。
local function build_item_lines(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local result = {}
  for _, entry in ipairs(build_item_entries(state, lang)) do
    table.insert(result, build_entry_line(entry.name, entry.count, entry.flavor, entry.icon, entry.element_label, nil, unknown_label, entry.known))
  end
  return result
end

M.build_enemy_lines = build_enemy_lines
M.build_item_lines = build_item_lines
M.build_enemy_entries = build_enemy_entries
M.build_item_entries = build_item_entries

return M
