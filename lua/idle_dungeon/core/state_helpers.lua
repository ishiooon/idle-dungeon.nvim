-- このモジュールは状態生成に必要な小さな関数をまとめる。
local content = require("idle_dungeon.content")
local util = require("idle_dungeon.util")

local M = {}

local function find_character(character_id)
  for _, character in ipairs(content.characters) do
    if character.id == character_id then
      return character
    end
  end
  return content.characters[1]
end

local function ensure_equipment(starter_items)
  return {
    weapon = starter_items.weapon,
    armor = starter_items.armor,
    accessory = starter_items.accessory,
    companion = starter_items.companion,
  }
end

local function update_section(state, key, updates)
  local result = util.shallow_copy(state)
  result[key] = util.merge_tables(state[key] or {}, updates or {})
  return result
end

M.find_character = find_character
M.ensure_equipment = ensure_equipment
M.update_section = update_section

return M
