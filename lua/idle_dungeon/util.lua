-- このモジュールはデータ構造を扱うための小さな関数をまとめる。

local M = {}

-- テーブルを浅く複製して元の参照を保護する。
local function shallow_copy(source)
  local result = {}
  for key, value in pairs(source or {}) do
    result[key] = value
  end
  return result
end

-- ネストしたテーブルを再帰的に結合して新しいテーブルを返す。
local function merge_tables(base, override)
  local result = shallow_copy(base or {})
  for key, value in pairs(override or {}) do
    if type(value) == "table" and type(result[key]) == "table" then
      result[key] = merge_tables(result[key], value)
    else
      result[key] = value
    end
  end
  return result
end

-- 文字列が指定幅を超える場合は末尾を切り詰める。
local function clamp_line(text, width)
  if not width or #text <= width then
    return text
  end
  return text:sub(1, width)
end

M.shallow_copy = shallow_copy
M.merge_tables = merge_tables
M.clamp_line = clamp_line

return M
