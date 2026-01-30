-- このモジュールはアニメーション用のフレーム選択を純粋関数で提供する。

local M = {}

local function normalize_seconds(value, fallback)
  local seconds = tonumber(value)
  if not seconds or seconds <= 0 then
    return fallback
  end
  return seconds
end

local function select_frame(frames, time_sec, frame_seconds)
  if not frames or #frames == 0 then
    return ""
  end
  local span = normalize_seconds(frame_seconds, 1)
  local clock = math.floor((time_sec or 0) / span)
  local index = (clock % #frames) + 1
  return frames[index]
end

M.select_frame = select_frame

return M
