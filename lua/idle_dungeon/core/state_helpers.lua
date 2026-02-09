-- このモジュールは状態生成に必要な小さな関数をまとめる。
local content = require("idle_dungeon.content")
local util = require("idle_dungeon.util")

local M = {}

local function find_job(job_id)
  for _, job in ipairs(content.jobs) do
    if job.id == job_id then
      return job
    end
  end
  -- ジョブ未指定時は先頭を既定として返す。
  return content.jobs[1]
end

local function ensure_equipment(starter_items)
  return {
    weapon = starter_items.weapon,
    armor = starter_items.armor,
    accessory = starter_items.accessory,
  }
end

local function update_section(state, key, updates)
  local result = util.shallow_copy(state)
  result[key] = util.merge_tables(state[key] or {}, updates or {})
  return result
end

M.find_job = find_job
M.ensure_equipment = ensure_equipment
M.update_section = update_section

return M
