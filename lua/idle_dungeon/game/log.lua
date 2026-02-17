-- このモジュールはゲーム内ログの保持と行数制限を行う純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

local DEFAULT_MAX_LINES = 1000

-- ログ1行を安全な文字列へ正規化する。
local function normalize_line(line)
  local text = tostring(line or "")
  if text == "" then
    return nil
  end
  return text
end

-- ログ配列を最大行数内に切り詰める。
local function trim_lines(lines, max_lines)
  local source = type(lines) == "table" and lines or {}
  local limit = math.max(tonumber(max_lines) or DEFAULT_MAX_LINES, 1)
  local normalized = {}
  for _, line in ipairs(source) do
    local text = normalize_line(line)
    if text then
      table.insert(normalized, text)
    end
  end
  local extra = #normalized - limit
  if extra <= 0 then
    return normalized
  end
  local trimmed = {}
  for index = extra + 1, #normalized do
    table.insert(trimmed, normalized[index])
  end
  return trimmed
end

-- 状態からログ配列を取り出して正規化する。
local function lines(state, max_lines)
  local logs = ((state or {}).logs) or {}
  return trim_lines(logs, max_lines)
end

-- ログ配列を差し替えた状態を返す。
local function with_lines(state, logs, max_lines)
  local safe_state = state or {}
  return util.merge_tables(safe_state, {
    logs = trim_lines(logs, max_lines),
  })
end

-- 1行追記して最大行数を超えた分を先頭から削除する。
local function append(state, line, max_lines)
  local text = normalize_line(line)
  if not text then
    return with_lines(state, lines(state, max_lines), max_lines)
  end
  local next_lines = lines(state, max_lines)
  table.insert(next_lines, text)
  return with_lines(state, next_lines, max_lines)
end

M.DEFAULT_MAX_LINES = DEFAULT_MAX_LINES
M.trim_lines = trim_lines
M.lines = lines
M.with_lines = with_lines
M.append = append

return M
