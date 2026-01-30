-- このモジュールは所持品の増減を純粋関数で扱う。

local util = require("idle_dungeon.util")

local M = {}

local function new_inventory(starter_items)
  local items = {}
  for _, item_id in pairs(starter_items or {}) do
    items[item_id] = (items[item_id] or 0) + 1
  end
  return items
end

local function add_item(inventory, item_id, count)
  local next_inventory = util.shallow_copy(inventory or {})
  next_inventory[item_id] = (next_inventory[item_id] or 0) + (count or 1)
  return next_inventory
end

local function remove_item(inventory, item_id, count)
  local next_inventory = util.shallow_copy(inventory or {})
  local current = next_inventory[item_id] or 0
  local next_count = current - (count or 1)
  if next_count <= 0 then
    next_inventory[item_id] = nil
  else
    next_inventory[item_id] = next_count
  end
  return next_inventory
end

local function has_item(inventory, item_id)
  return (inventory or {})[item_id] ~= nil
end

M.new_inventory = new_inventory
M.add_item = add_item
M.remove_item = remove_item
M.has_item = has_item

return M
