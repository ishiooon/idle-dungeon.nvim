-- このモジュールは図鑑表示用の整形を純粋関数として提供する。

local content = require("idle_dungeon.content")
local element = require("idle_dungeon.game.element")

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
local function build_entry_line(name, count, flavor, icon_text, element_label)
  local safe_name = name ~= "" and name or "Unknown"
  local suffix = string.format(" x%d", count or 0)
  local icon = icon_text and icon_text ~= "" and (icon_text .. " ") or ""
  local element_text = element_label and element_label ~= "" and ("[" .. element_label .. "] ") or ""
  if flavor ~= "" then
    return string.format("%s%s%s%s - %s", icon, element_text, safe_name, suffix, flavor)
  end
  return string.format("%s%s%s%s", icon, element_text, safe_name, suffix)
end

-- 図鑑に記録済みの対象だけを整形して返す。
local function build_lines(dex_entries, source_entries, lang, kind)
  local map = build_map(source_entries)
  local lines = {}
  for entry_id, info in pairs(dex_entries or {}) do
    local base_id, element_id = split_enemy_key(entry_id)
    local source = map[base_id or entry_id] or { id = base_id or entry_id, name = base_id or entry_id }
    local name = resolve_name(source, lang)
    local flavor = resolve_text(source.flavor, lang)
    local icon_text = resolve_icon(source)
    local element_label = nil
    if kind == "enemy" and element_id then
      element_label = element.label(element_id, lang)
    end
    if kind == "item" and source.element then
      element_label = element.label(source.element, lang)
    end
    table.insert(lines, {
      sort_key = name .. (element_label or ""),
      line = build_entry_line(name, info.count or 0, flavor, icon_text, element_label),
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

local function build_enemy_lines(state, lang)
  return build_lines((state.dex or {}).enemies or {}, content.enemies or {}, lang, "enemy")
end

local function build_item_lines(state, lang)
  return build_lines((state.dex or {}).items or {}, content.items or {}, lang, "item")
end

M.build_enemy_lines = build_enemy_lines
M.build_item_lines = build_item_lines

return M
