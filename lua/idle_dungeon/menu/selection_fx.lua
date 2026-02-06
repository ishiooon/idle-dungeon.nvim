-- このモジュールはメニューの選択切替アニメーションを管理する。

local M = {}

local FX_DURATION_MS = 180
local FX_STEP_MS = 45
local FX_GROUP = "IdleDungeonMenuSelected"
local FX_PULSE_GROUP = "IdleDungeonMenuSelectedPulse"

local function default_now_ms()
  if _G.vim and vim.loop and vim.loop.hrtime then
    return math.floor(vim.loop.hrtime() / 1000000)
  end
  return math.floor(os.clock() * 1000)
end

local now_provider = default_now_ms

local function now_ms()
  return now_provider()
end

local function stop(state)
  if type(state) ~= "table" then
    return
  end
  state.selection_fx_start = nil
  state.selection_fx_end = nil
end

local function is_active(state)
  local finish = type(state) == "table" and state.selection_fx_end or nil
  if type(finish) ~= "number" then
    return false
  end
  return now_ms() <= finish
end

local function selected_group(state)
  if not is_active(state) then
    return FX_GROUP
  end
  local start = state.selection_fx_start or now_ms()
  local phase = math.floor((now_ms() - start) / FX_STEP_MS) % 2
  if phase == 0 then
    return FX_PULSE_GROUP
  end
  return FX_GROUP
end

local function schedule_renders(state, render)
  if not (_G.vim and vim.defer_fn and type(render) == "function") then
    return
  end
  local token = state.selection_fx_token
  local delay = FX_STEP_MS
  while delay <= FX_DURATION_MS do
    vim.defer_fn(function()
      if state.selection_fx_token ~= token or not is_active(state) then
        return
      end
      pcall(render)
    end, delay)
    delay = delay + FX_STEP_MS
  end
end

local function start(state, render)
  if type(state) ~= "table" then
    return
  end
  local start_time = now_ms()
  state.selection_fx_start = start_time
  state.selection_fx_end = start_time + FX_DURATION_MS
  state.selection_fx_token = (state.selection_fx_token or 0) + 1
  schedule_renders(state, render)
end

M.start = start
M.stop = stop
M.is_active = is_active
M.selected_group = selected_group
M._set_time_provider = function(provider)
  now_provider = provider or default_now_ms
end

return M
