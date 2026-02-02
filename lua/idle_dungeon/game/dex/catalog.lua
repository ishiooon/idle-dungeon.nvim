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

local function split_enemy_key(entry_id)
  if not entry_id then
    return nil, nil
  end
  local base, element_id = entry_id:match("^([^:]+):(.+)$")
  if base then
    return base, element_id
  end
  return entry_id, nil
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
local function build_entry_line(name, count, flavor, icon_text, element_label, drop_text, unknown_label)
  local safe_name = name ~= "" and name or (unknown_label or "???")
  local suffix = string.format(" x%d", count or 0)
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
    local base_id, element_id = split_enemy_key(entry_id)
    if base_id then
      recorded[base_id] = recorded[base_id] or {}
      table.insert(recorded[base_id], { element_id = element_id, info = info })
    end
  end
  local entries = {}
  for _, enemy in ipairs(content.enemies or {}) do
    local records = recorded[enemy.id]
    local drop_entries = build_drop_entries(enemy, dex_items, item_map, lang, unknown_label)
    if records then
      for _, record in ipairs(records) do
        local element_label = record.element_id and element.label(record.element_id, lang) or nil
        table.insert(entries, {
          id = enemy.id,
          name = resolve_name(enemy, lang),
          icon = resolve_icon(enemy),
          element_id = record.element_id,
          element_label = element_label,
          count = record.info.count or 0,
          flavor = resolve_text(enemy.flavor, lang),
          known = true,
          drops = drop_entries,
        })
      end
    else
      table.insert(entries, {
        id = enemy.id,
        name = unknown_label,
        icon = "?",
        element_id = nil,
        element_label = nil,
        count = 0,
        flavor = "",
        known = false,
        drops = drop_entries,
      })
    end
  end
  table.sort(entries, function(a, b)
    return (a.name .. (a.element_label or "")) < (b.name .. (b.element_label or ""))
  end)
  return entries
end

-- 図鑑に表示する装備のエントリ一覧を構築する。
local function build_item_entries(state, lang)
  local dex_entries = (state.dex or {}).items or {}
  local unknown_label = i18n.t("dex_unknown", lang)
  local entries = {}
  for _, item in ipairs(content.items or {}) do
    local record = dex_entries[item.id]
    local known = record ~= nil
    local name = known and resolve_name(item, lang) or unknown_label
    local flavor = known and resolve_text(item.flavor, lang) or ""
    local element_label = (known and item.element) and element.label(item.element, lang) or nil
    table.insert(entries, {
      id = item.id,
      name = name,
      icon = resolve_icon(item),
      element_label = element_label,
      count = (record or {}).count or 0,
      flavor = flavor,
      known = known,
      slot = item.slot,
      rarity = item.rarity,
    })
  end
  table.sort(entries, function(a, b)
    return (a.name .. (a.id or "")) < (b.name .. (b.id or ""))
  end)
  return entries
end

-- 図鑑に表示する敵一覧を構築する。
local function build_enemy_lines(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local lines = {}
  for _, entry in ipairs(build_enemy_entries(state, lang)) do
    local drop_text = build_drop_text_from_entries(entry.drops, lang)
    table.insert(lines, {
      sort_key = entry.name .. (entry.element_label or ""),
      line = build_entry_line(entry.name, entry.count, entry.flavor, entry.icon, entry.element_label, drop_text, unknown_label),
    })
  end
  table.sort(lines, function(a, b)
    return a.sort_key < b.sort_key
  end)
  local result = {}
  for _, entry in ipairs(lines) do
    table.insert(result, entry.line)
  end
  return result
end

-- 図鑑に表示する装備一覧を構築する。
local function build_item_lines(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local lines = {}
  for _, entry in ipairs(build_item_entries(state, lang)) do
    table.insert(lines, {
      sort_key = entry.name .. (entry.id or ""),
      line = build_entry_line(entry.name, entry.count, entry.flavor, entry.icon, entry.element_label, nil, unknown_label),
    })
  end
  table.sort(lines, function(a, b)
    return a.sort_key < b.sort_key
  end)
  local result = {}
  for _, entry in ipairs(lines) do
    table.insert(result, entry.line)
  end
  return result
end

M.build_enemy_lines = build_enemy_lines
M.build_item_lines = build_item_lines
M.build_enemy_entries = build_enemy_entries
M.build_item_entries = build_item_entries

return M
