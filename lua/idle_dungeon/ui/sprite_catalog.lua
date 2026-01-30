-- このモジュールはキャラクターと敵の定義参照を提供する。

local content = require("idle_dungeon.content")

local M = {}

local function find_character(actor_id)
  for _, character in ipairs(content.characters or {}) do
    if character.id == actor_id then
      return character
    end
  end
  return nil
end

local function find_enemy(enemy_id)
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.id == enemy_id then
      return enemy
    end
  end
  return nil
end

M.find_character = find_character
M.find_enemy = find_enemy

return M
