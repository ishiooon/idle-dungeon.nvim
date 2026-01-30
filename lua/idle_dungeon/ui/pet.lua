-- このモジュールは可視モードのペット表示を生成する純粋関数を提供する。

local M = {}

-- ペットの表情と歩行フレームを定義する。
local BASE_FRAMES = {
  dot = { idle = { "o.o" }, walk = { "o_o", "o^o" }, battle = { "o>o" }, reward = { "oAo" }, defeat = { "x_x" } },
  stone = { idle = { "O.O" }, walk = { "O_O", "O^O" }, battle = { "O>O" }, reward = { "OAO" }, defeat = { "X_X" } },
  bird = { idle = { "^.^" }, walk = { "^_^", "^-^" }, battle = { "^>^" }, reward = { "^A^" }, defeat = { "x-x" } },
  sleep = { idle = { "-.-" }, walk = { "-_-", "-^-" }, battle = { "->-" }, reward = { "-A-" }, defeat = { "x_x" } },
}
local PET_FRAMES = {
  recorder = BASE_FRAMES.dot,
  guardian = BASE_FRAMES.stone,
  hunter = BASE_FRAMES.bird,
  alchemist = BASE_FRAMES.sleep,
  white_slime = BASE_FRAMES.dot,
  stone_spirit = BASE_FRAMES.stone,
  wind_bird = BASE_FRAMES.bird,
  tiny_familiar = BASE_FRAMES.sleep,
  default = BASE_FRAMES.dot,
}

local function resolve_style_id(state, config)
  local pet_config = (config.ui or {}).pet or {}
  local style = pet_config.style or "auto"
  if style ~= "auto" then
    return style
  end
  local companion = state.equipment and state.equipment.companion or nil
  if companion and PET_FRAMES[companion] then
    return companion
  end
  local actor_id = state.actor and state.actor.id or "default"
  if PET_FRAMES[actor_id] then
    return actor_id
  end
  return "default"
end

local function resolve_frames(style_id)
  return PET_FRAMES[style_id] or PET_FRAMES.default
end

local function choose_frames(mode, frames)
  if mode == "move" then
    return frames.walk or frames.idle
  end
  if mode == "battle" then
    return frames.battle or frames.walk or frames.idle
  end
  if mode == "reward" then
    return frames.reward or frames.idle
  end
  if mode == "defeat" then
    return frames.defeat or frames.idle
  end
  if mode == "dialogue" then
    return frames.idle
  end
  return frames.idle
end

local function normalize_seconds(value, fallback)
  local seconds = tonumber(value)
  if not seconds or seconds <= 0 then
    return fallback
  end
  return seconds
end

local function select_frame(frames, time_sec, frame_seconds)
  local count = #frames
  if count == 0 then
    return ""
  end
  local span = normalize_seconds(frame_seconds, 1)
  local clock = math.floor((time_sec or 0) / span)
  local index = (clock % count) + 1
  return frames[index]
end

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

local function build_line(state, config)
  local pet_config = (config.ui or {}).pet or {}
  if pet_config.enabled == false then
    return nil
  end
  local style_id = resolve_style_id(state, config)
  local frames = choose_frames(state.ui.mode, resolve_frames(style_id))
  local time_sec = (state.metrics or {}).time_sec or 0
  local sprite = select_frame(frames, time_sec, pet_config.frame_seconds)
  local length = (config.ui or {}).track_length or 18
  return build_track_line(state.progress.distance or 0, length, sprite, pet_config.ground_char)
end

M.build_line = build_line
M.build_track_line = build_track_line
M.select_frame = select_frame
M.calculate_position = calculate_position

return M
