-- このモジュールは経過時間の表示文字列を整形する。

local M = {}

local function format_seconds(seconds, lang)
  local total = math.max(0, math.floor(tonumber(seconds) or 0))
  local minutes = math.floor(total / 60)
  local secs = total % 60
  local hours = math.floor(minutes / 60)
  local rem_minutes = minutes % 60
  local is_ja = lang == "ja" or lang == "jp"
  if hours > 0 then
    if is_ja then
      return string.format("%d時間%02d分", hours, rem_minutes)
    end
    return string.format("%dh %02dm", hours, rem_minutes)
  end
  if minutes > 0 then
    if is_ja then
      return string.format("%d分%02d秒", minutes, secs)
    end
    return string.format("%dm %02ds", minutes, secs)
  end
  if is_ja then
    return string.format("%d秒", secs)
  end
  return string.format("%ds", secs)
end

M.format_seconds = format_seconds

return M
