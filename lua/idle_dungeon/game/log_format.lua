-- このモジュールはログ行の共通書式を生成する純粋関数を提供する。

local M = {}

-- 秒値をログ表示用に正規化する。
local function normalize_elapsed_sec(value)
  return math.max(math.floor(tonumber(value) or 0), 0)
end

-- ログ出力時の日時を文字列で返す。
local function resolve_datetime(now_sec)
  local source = tonumber(now_sec) or os.time()
  return os.date("%Y-%m-%d %H:%M:%S", source)
end

-- 先頭プレフィックスをカテゴリ付きで組み立てる。
local function build_prefix(category)
  local kind = tostring(category or "SYSTEM")
  return string.format("[%s]", kind)
end

-- 末尾サフィックスを日時付きで組み立てる。
local function build_suffix(now_sec)
  local datetime = resolve_datetime(now_sec)
  return string.format("[%s]", datetime)
end

-- 本文付きのログ1行を組み立てる。
local function build_line(text, arg2, arg3, arg4)
  local message = tostring(text or "")
  if message == "" then
    return ""
  end
  local category = nil
  local now_sec = nil
  if arg3 == nil then
    category = arg2
    now_sec = arg4
  else
    -- 後方互換: 旧引数 (text, elapsed_sec, category, now_sec) を受け取っても表示は日時とカテゴリのみとする。
    category = arg3
    now_sec = arg4
  end
  return string.format("%s %s %s", build_prefix(category), message, build_suffix(now_sec))
end

M.normalize_elapsed_sec = normalize_elapsed_sec
M.resolve_datetime = resolve_datetime
M.build_prefix = build_prefix
M.build_suffix = build_suffix
M.build_line = build_line

return M
