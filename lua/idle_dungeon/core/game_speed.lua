-- このモジュールはゲーム進行速度の解決と切り替えを純粋関数で提供する。

local M = {}

local DEFAULT_OPTIONS = {
  { id = "1x", label = "1x", tick_seconds = 0.5 },
  { id = "2x", label = "2x", tick_seconds = 0.25 },
  { id = "5x", label = "5x", tick_seconds = 0.1 },
  { id = "10x", label = "10x", tick_seconds = 0.05 },
}

local function copy_options(options)
  local result = {}
  for _, option in ipairs(options or {}) do
    table.insert(result, {
      id = option.id,
      label = option.label,
      tick_seconds = option.tick_seconds,
    })
  end
  return result
end

local function normalize_options(config)
  local source = (config or {}).game_speed_options
  if type(source) ~= "table" or #source == 0 then
    return copy_options(DEFAULT_OPTIONS)
  end
  local result = {}
  for _, option in ipairs(source) do
    local id = tostring(option.id or "")
    local tick_seconds = tonumber(option.tick_seconds)
    if id ~= "" and tick_seconds and tick_seconds > 0 then
      table.insert(result, {
        id = id,
        label = option.label or id,
        tick_seconds = tick_seconds,
      })
    end
  end
  if #result == 0 then
    return copy_options(DEFAULT_OPTIONS)
  end
  return result
end

local function find_option_by_id(options, id)
  for _, option in ipairs(options or {}) do
    if option.id == id then
      return option
    end
  end
  return nil
end

local function resolve_default_id(config, options)
  local default_id = tostring((config or {}).default_game_speed or "")
  local option = find_option_by_id(options, default_id)
  if option then
    return option.id
  end
  return (options[1] and options[1].id) or "1x"
end

local function resolve_game_speed_id(state, config)
  local options = normalize_options(config)
  local current_id = tostring((((state or {}).ui or {}).game_speed) or "")
  local option = find_option_by_id(options, current_id)
  if option then
    return option.id
  end
  return resolve_default_id(config, options)
end

local function resolve_game_tick_seconds(state, config)
  local options = normalize_options(config)
  local speed_id = resolve_game_speed_id(state, config)
  local option = find_option_by_id(options, speed_id)
  if option then
    return option.tick_seconds
  end
  return tonumber((config or {}).game_tick_seconds) or 0.5
end

local function resolve_base_tick_seconds(config)
  local options = normalize_options(config)
  local base_tick = nil
  for _, option in ipairs(options) do
    local tick = tonumber(option.tick_seconds)
    if tick and tick > 0 and (base_tick == nil or tick > base_tick) then
      base_tick = tick
    end
  end
  if base_tick and base_tick > 0 then
    return base_tick
  end
  return DEFAULT_OPTIONS[1].tick_seconds
end

local function resolve_game_speed_multiplier(state, config)
  local base_tick = resolve_base_tick_seconds(config)
  local current_tick = resolve_game_tick_seconds(state, config)
  if not base_tick or base_tick <= 0 then
    return 1
  end
  if not current_tick or current_tick <= 0 then
    return 1
  end
  -- 最も遅い速度を1倍として、選択中速度の倍率を計算する。
  return math.max(base_tick / current_tick, 1)
end

local function resolve_runtime_tick_seconds(state, config)
  local boost = state and state.ui and state.ui.speed_boost or nil
  if boost and boost.remaining_ticks and boost.remaining_ticks > 0 and boost.tick_seconds then
    local boosted = tonumber(boost.tick_seconds)
    if boosted and boosted > 0 then
      return boosted
    end
  end
  return resolve_game_tick_seconds(state, config)
end

local function resolve_battle_tick_seconds(state, config)
  -- 戦闘進行もゲーム速度設定へ追従させて体感速度を一致させる。
  local tick_seconds = resolve_game_tick_seconds(state, config)
  if tick_seconds and tick_seconds > 0 then
    return tick_seconds
  end
  return DEFAULT_OPTIONS[1].tick_seconds
end

local function cycle_game_speed_id(current_id, config)
  local options = normalize_options(config)
  if #options == 0 then
    return "1x"
  end
  for index, option in ipairs(options) do
    if option.id == current_id then
      local next_index = (index % #options) + 1
      return options[next_index].id
    end
  end
  return resolve_default_id(config, options)
end

local function label_from_id(speed_id, config)
  local options = normalize_options(config)
  local option = find_option_by_id(options, speed_id)
  if option then
    return tostring(option.label or option.id)
  end
  return tostring(speed_id or resolve_default_id(config, options))
end

M.resolve_game_speed_id = resolve_game_speed_id
M.resolve_game_tick_seconds = resolve_game_tick_seconds
M.resolve_game_speed_multiplier = resolve_game_speed_multiplier
M.resolve_runtime_tick_seconds = resolve_runtime_tick_seconds
M.resolve_battle_tick_seconds = resolve_battle_tick_seconds
M.cycle_game_speed_id = cycle_game_speed_id
M.label_from_id = label_from_id

return M
