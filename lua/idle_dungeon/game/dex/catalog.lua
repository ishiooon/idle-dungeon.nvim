-- このモジュールは図鑑表示用の整形を純粋関数として提供する。

local content = require("idle_dungeon.content")

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

-- IDで参照できるように一覧をマップ化する。
local function build_map(entries)
  local map = {}
  for _, entry in ipairs(entries or {}) do
    map[entry.id] = entry
  end
  return map
end

-- 図鑑で表示する1行の文を組み立てる。
local function build_entry_line(name, count, flavor)
  local safe_name = name ~= "" and name or "Unknown"
  local suffix = string.format(" x%d", count or 0)
  if flavor ~= "" then
    return string.format("%s%s - %s", safe_name, suffix, flavor)
  end
  return string.format("%s%s", safe_name, suffix)
end

-- 図鑑に記録済みの対象だけを整形して返す。
local function build_lines(dex_entries, source_entries, lang)
  local map = build_map(source_entries)
  local lines = {}
  for entry_id, info in pairs(dex_entries or {}) do
    local source = map[entry_id] or { id = entry_id, name = entry_id }
    local name = resolve_name(source, lang)
    local flavor = resolve_text(source.flavor, lang)
    table.insert(lines, { sort_key = name, line = build_entry_line(name, info.count or 0, flavor) })
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
  return build_lines((state.dex or {}).enemies or {}, content.enemies or {}, lang)
end

local function build_item_lines(state, lang)
  return build_lines((state.dex or {}).items or {}, content.items or {}, lang)
end

M.build_enemy_lines = build_enemy_lines
M.build_item_lines = build_item_lines

return M
