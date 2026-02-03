-- このモジュールはイベントデータの参照と出現判定を純粋関数で提供する。

local content = require("idle_dungeon.content")
local rng = require("idle_dungeon.rng")

local M = {}

local function find_event(event_id)
  for _, event in ipairs(content.hidden_events or {}) do
    if event.id == event_id then
      return event
    end
  end
  return nil
end

local function appears_in_stage(event, stage_id)
  local appear = event and event.appear or nil
  if not appear then
    return true
  end
  if not stage_id then
    return true
  end
  if appear.stages then
    for _, value in ipairs(appear.stages) do
      if value == stage_id then
        return true
      end
    end
    return false
  end
  if appear.min and stage_id < appear.min then
    return false
  end
  if appear.max and stage_id > appear.max then
    return false
  end
  return true
end

local function available_events(progress)
  local events = {}
  for _, event in ipairs(content.hidden_events or {}) do
    if appears_in_stage(event, progress and progress.stage_id or nil) then
      table.insert(events, event)
    end
  end
  return events
end

local function pick_event(seed, progress)
  local events = available_events(progress)
  if #events == 0 then
    return nil, seed
  end
  local total = 0
  for _, event in ipairs(events) do
    total = total + (event.weight or 1)
  end
  if total <= 0 then
    return events[1], seed
  end
  local roll, next_seed = rng.next_int(seed or 1, 1, total)
  local cursor = 0
  for _, event in ipairs(events) do
    cursor = cursor + (event.weight or 1)
    if roll <= cursor then
      return event, next_seed
    end
  end
  return events[#events], next_seed
end

M.find_event = find_event
M.pick_event = pick_event

return M
