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

-- UTF-8文字列を安全に分割して配列で返す。
local function split_utf8(text)
  local chars = {}
  if not text or text == "" then
    return chars
  end
  for chunk in tostring(text):gmatch("[\1-\127\194-\244][\128-\191]*") do
    table.insert(chars, chunk)
  end
  if #chars == 0 then
    table.insert(chars, text)
  end
  return chars
end

-- 表示幅の取得はNeovimが無い環境ではUTF-8文字数で代用する。
local function display_width(text)
  local safe_text = text or ""
  if _G.vim and vim.fn and vim.fn.strdisplaywidth then
    return vim.fn.strdisplaywidth(safe_text)
  end
  return #split_utf8(safe_text)
end

-- 文字列が指定幅を超える場合は末尾を切り詰める。
local function clamp_line(text, width)
  if not width then
    return text
  end
  local safe_text = text or ""
  local limit = math.max(width, 0)
  local chars = split_utf8(safe_text)
  if limit == 0 then
    return ""
  end
  if not (_G.vim and vim.fn and vim.fn.strdisplaywidth) then
    if #chars <= limit then
      return safe_text
    end
    local sliced = {}
    for index = 1, limit do
      sliced[index] = chars[index]
    end
    return table.concat(sliced, "")
  end
  local sliced = {}
  local current_width = 0
  for _, ch in ipairs(chars) do
    local ch_width = display_width(ch)
    if current_width + ch_width > limit then
      break
    end
    current_width = current_width + ch_width
    table.insert(sliced, ch)
  end
  return table.concat(sliced, "")
end

M.shallow_copy = shallow_copy
M.merge_tables = merge_tables
M.clamp_line = clamp_line
M.split_utf8 = split_utf8
M.display_width = display_width

return M
