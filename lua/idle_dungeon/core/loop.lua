-- このモジュールはタイマーの開始と停止をまとめる。

local M = {}

local runtime = { tick_timer = nil, save_timer = nil, sync_timer = nil }

local function start_tick(interval_seconds, on_tick)
  if runtime.tick_timer then
    return
  end
  -- ゲーム進行のタイマーを開始する。
  runtime.tick_timer = vim.loop.new_timer()
  runtime.tick_timer:start(0, interval_seconds * 1000, function()
    vim.schedule(on_tick)
  end)
end

local function stop_tick()
  if not runtime.tick_timer then
    return
  end
  runtime.tick_timer:stop()
  runtime.tick_timer:close()
  runtime.tick_timer = nil
end

local function start_save(interval_seconds, on_save)
  if runtime.save_timer then
    return
  end
  -- 保存処理のタイマーを開始する。
  runtime.save_timer = vim.loop.new_timer()
  runtime.save_timer:start(interval_seconds * 1000, interval_seconds * 1000, function()
    vim.schedule(on_save)
  end)
end

local function stop_save()
  if not runtime.save_timer then
    return
  end
  runtime.save_timer:stop()
  runtime.save_timer:close()
  runtime.save_timer = nil
end

local function start_sync(interval_seconds, on_sync)
  if runtime.sync_timer then
    return
  end
  -- 共有状態を同期するためのタイマーを開始する。
  runtime.sync_timer = vim.loop.new_timer()
  runtime.sync_timer:start(interval_seconds * 1000, interval_seconds * 1000, function()
    vim.schedule(on_sync)
  end)
end

local function stop_sync()
  if not runtime.sync_timer then
    return
  end
  runtime.sync_timer:stop()
  runtime.sync_timer:close()
  runtime.sync_timer = nil
end

local function stop_all()
  stop_tick()
  stop_save()
  stop_sync()
end

M.start_tick = start_tick
M.stop_tick = stop_tick
M.start_save = start_save
M.stop_save = stop_save
M.start_sync = start_sync
M.stop_sync = stop_sync
M.stop_all = stop_all

return M
