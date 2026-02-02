-- このモジュールは進行トラック上の位置計算を純粋関数で提供する。

local M = {}
local util = require("idle_dungeon.util")

local function calculate_position(distance, track_length, sprite_length)
  local span = math.max(track_length - sprite_length, 0)
  if span == 0 then
    return 0
  end
  return math.floor(distance or 0) % (span + 1)
end

local function split_text(text)
  -- UTF-8分割は共通関数へ委譲する。
  return util.split_utf8(text)
end

local function build_cells(track_length, fill_char)
  local cells = {}
  for index = 1, track_length do
    cells[index] = fill_char
  end
  return cells
end

local function place_sprite(cells, position, sprite)
  local parts = split_text(sprite)
  if #parts == 0 then
    return 0
  end
  for index, part in ipairs(parts) do
    local target = position + index - 1
    if target >= 1 and target <= #cells then
      cells[target] = part
    end
  end
  return #parts
end

local function build_offsets(cells)
  local offsets = {}
  local cursor = 0
  for index, cell in ipairs(cells) do
    offsets[index] = cursor
    cursor = cursor + #cell
  end
  return offsets
end

local function build_track(distance, length, hero_sprite, filler, enemies)
  local safe_sprite = hero_sprite or ""
  local track_length = math.max(length or 1, 1)
  local fill_char = (filler or "."):sub(1, 1)
  local cells = build_cells(track_length, fill_char)
  local enemy_positions = {}
  for _, enemy in ipairs(enemies or {}) do
    if enemy and enemy.position and not enemy.defeated then
      local width = place_sprite(cells, enemy.position, enemy.icon or "")
      table.insert(enemy_positions, { position = enemy.position, width = width, enemy = enemy })
    end
  end
  local hero_width = math.max(#split_text(safe_sprite), 1)
  local base_position = calculate_position(distance or 0, track_length, hero_width)
  local hero_position = base_position + 1
  place_sprite(cells, hero_position, safe_sprite)
  return {
    line = table.concat(cells, ""),
    offsets = build_offsets(cells),
    hero = { position = hero_position, width = hero_width },
    enemies = enemy_positions,
  }
end

local function build_track_line(distance, length, sprite, filler, enemies)
  return build_track(distance, length, sprite, filler, enemies).line
end

M.calculate_position = calculate_position
M.build_track = build_track
M.build_track_line = build_track_line

return M
