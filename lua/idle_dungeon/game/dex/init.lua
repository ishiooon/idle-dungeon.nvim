-- このモジュールは図鑑の記録データを扱う純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

-- 図鑑の初期状態を返す。
local function new_dex()
  return { enemies = {}, items = {} }
end

-- 図鑑の記録にカウントと時刻を追加する。
local function record_entry(dex, section, entry_id, count, time_sec)
  if not entry_id or entry_id == "" then
    return dex
  end
  local safe_dex = util.merge_tables(new_dex(), dex or {})
  local entries = util.merge_tables(safe_dex[section] or {}, {})
  local current = entries[entry_id] or { count = 0, first_time = time_sec or 0, last_time = time_sec or 0 }
  local next_count = (current.count or 0) + (count or 1)
  entries[entry_id] = {
    count = next_count,
    first_time = current.first_time or (time_sec or 0),
    last_time = time_sec or current.last_time or 0,
  }
  safe_dex[section] = entries
  return safe_dex
end

local function record_item(dex, item_id, count, time_sec)
  return record_entry(dex, "items", item_id, count, time_sec)
end

local function record_enemy(dex, enemy_id, element, time_sec)
  local key = enemy_id
  if element and element ~= "" then
    key = enemy_id .. ":" .. element
  end
  return record_entry(dex, "enemies", key, 1, time_sec)
end

M.new_dex = new_dex
M.record_item = record_item
M.record_enemy = record_enemy

return M
