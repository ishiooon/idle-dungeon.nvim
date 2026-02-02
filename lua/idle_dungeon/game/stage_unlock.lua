-- このモジュールはステージ解放の判定を純粋関数で提供する。
local util = require("idle_dungeon.util")

local M = {}

local function find_stage_index(stages, stage_id)
  for index, stage in ipairs(stages or {}) do
    if stage.id == stage_id then
      return index
    end
  end
  return nil
end

local function initial_unlocks(stages)
  local result = {}
  local first = (stages or {})[1]
  if first and first.id then
    result[first.id] = true
  end
  return result
end

local function is_unlocked(unlocks, stage_id)
  return (unlocks or {})[stage_id] == true
end

local function unlock_next(unlocks, stages, cleared_stage_id)
  local next_unlocks = util.merge_tables(unlocks or {}, {})
  if cleared_stage_id then
    next_unlocks[cleared_stage_id] = true
  end
  local index = find_stage_index(stages or {}, cleared_stage_id)
  if not index then
    return next_unlocks
  end
  local next_stage = (stages or {})[index + 1]
  if next_stage and next_stage.id then
    next_unlocks[next_stage.id] = true
  end
  return next_unlocks
end

M.initial_unlocks = initial_unlocks
M.is_unlocked = is_unlocked
M.unlock_next = unlock_next

return M
