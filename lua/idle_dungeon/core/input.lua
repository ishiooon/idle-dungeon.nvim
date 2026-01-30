-- このモジュールは入力と保存イベントを監視して実績更新を通知する。
-- 実績集計はgame/metricsへ集約する。
local metrics = require("idle_dungeon.game.metrics")

local M = {}

local runtime = { key_ns = nil, augroup = nil, on_metrics = nil }

local function handle_key()
  if not runtime.on_metrics then
    return
  end
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) ~= "i" and mode:sub(1, 1) ~= "R" then
    return
  end
  local char = vim.v.char
  if char == "" then
    return
  end
  local count = vim.fn.strchars(char)
  if count <= 0 then
    return
  end
  local filetype = vim.bo.filetype
  runtime.on_metrics(function(current)
    return metrics.add_chars(current, count, filetype)
  end)
end

local function handle_save()
  if not runtime.on_metrics then
    return
  end
  runtime.on_metrics(function(current)
    return metrics.add_save(current)
  end)
end

local function start(on_metrics)
  runtime.on_metrics = on_metrics
  if runtime.key_ns then
    return
  end
  -- 入力文字数を集計するためのキー監視を登録する。
  runtime.key_ns = vim.api.nvim_create_namespace("IdleDungeonKeys")
  vim.on_key(handle_key, runtime.key_ns)
  -- 保存回数を集計するための自動コマンドを登録する。
  runtime.augroup = vim.api.nvim_create_augroup("IdleDungeon", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = runtime.augroup,
    callback = handle_save,
  })
end

local function stop()
  if runtime.key_ns then
    -- 登録済みのキー監視を解除する。
    vim.on_key(nil, runtime.key_ns)
    runtime.key_ns = nil
  end
  if runtime.augroup then
    -- 自動コマンドを削除して副作用を解除する。
    vim.api.nvim_del_augroup_by_id(runtime.augroup)
    runtime.augroup = nil
  end
  runtime.on_metrics = nil
end

M.start = start
M.stop = stop

return M
