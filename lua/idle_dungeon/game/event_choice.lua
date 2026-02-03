-- このモジュールは選択イベントの処理を純粋関数として提供する。

local event_effects = require("idle_dungeon.game.event_effects")
local floor_state = require("idle_dungeon.game.floor.state")
local rng = require("idle_dungeon.rng")
local util = require("idle_dungeon.util")

local M = {}

local function resolve_choice_timeout(event, config)
  local seconds = tonumber(event and event.choice_seconds) or tonumber(config.choice_seconds) or 10
  return math.max(math.floor(seconds), 1)
end

local function is_choice_event(event)
  return event and type(event.choices) == "table" and #event.choices > 0
end

local function pick_option(event, seed, choice_index)
  local options = event and event.choices or {}
  if #options == 0 then
    return nil, seed, nil
  end
  if choice_index and options[choice_index] then
    return options[choice_index], seed, choice_index
  end
  local picked, next_seed = rng.next_int(seed or 1, 1, #options)
  return options[picked], next_seed, picked
end

local function pick_result(option, seed)
  local results = option and option.results or {}
  if #results == 0 then
    return nil, seed
  end
  local total = 0
  for _, result in ipairs(results) do
    total = total + (result.weight or 1)
  end
  if total <= 0 then
    return results[1], seed
  end
  local roll
  roll, seed = rng.next_int(seed or 1, 1, total)
  local cursor = 0
  for _, result in ipairs(results) do
    cursor = cursor + (result.weight or 1)
    if roll <= cursor then
      return result, seed
    end
  end
  return results[#results], seed
end

-- 選択イベントを開始して待機状態へ切り替える。
local function start_choice(state, event, config)
  local remaining = resolve_choice_timeout(event, config)
  local next_ui = util.merge_tables(state.ui or {}, {
    mode = "choice",
    event_id = event and event.id or nil,
    choice_remaining = remaining,
  })
  return util.merge_tables(state, { ui = next_ui })
end

-- 選択肢を確定し、結果の効果とメッセージを適用する。
local function apply_choice_event(state, event, config, choice_index)
  if not is_choice_event(event) then
    return state
  end
  local seed = (state.progress or {}).rng_seed or 1
  local option, next_seed = pick_option(event, seed, choice_index)
  local result
  result, next_seed = pick_result(option, next_seed)
  local next_state, final_seed = event_effects.apply_event(state, result or option or event, config, next_seed)
  local marked_progress = floor_state.mark_event_resolved(next_state.progress or {})
  local next_progress = util.merge_tables(marked_progress, { rng_seed = final_seed })
  local next_ui = util.merge_tables(next_state.ui or {}, {
    mode = "move",
    event_id = nil,
    choice_remaining = 0,
  })
  return util.merge_tables(next_state, { progress = next_progress, ui = next_ui })
end

M.is_choice_event = is_choice_event
M.start_choice = start_choice
M.apply_choice_event = apply_choice_event

return M
