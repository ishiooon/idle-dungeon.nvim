-- このモジュールは進行トラック上の位置計算を純粋関数で提供する。

local M = {}

local function calculate_position(distance, track_length, sprite_length)
  local span = math.max(track_length - sprite_length, 0)
  if span == 0 then
    return 0
  end
  return math.floor(distance or 0) % (span + 1)
end

local function build_track_line(distance, length, sprite, filler)
  local safe_sprite = sprite or ""
  local track_length = math.max(length or #safe_sprite, #safe_sprite, 1)
  local fill_char = (filler or "."):sub(1, 1)
  local position = calculate_position(distance or 0, track_length, #safe_sprite)
  local chars = {}
  for index = 1, track_length do
    chars[index] = fill_char
  end
  for index = 1, #safe_sprite do
    local target = position + index
    if target >= 1 and target <= track_length then
      chars[target] = safe_sprite:sub(index, index)
    end
  end
  return table.concat(chars, "")
end

M.calculate_position = calculate_position
M.build_track_line = build_track_line

return M
