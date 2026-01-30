-- このモジュールは入力実績の集計を純粋関数として提供する。

local util = require("idle_dungeon.util")

local M = {}

local function new_metrics()
  return { chars = 0, lines = 0, saves = 0, time_sec = 0, filetypes = {} }
end

local function add_chars(metrics, count, filetype)
  local next_metrics = util.merge_tables(metrics, {})
  next_metrics.chars = (next_metrics.chars or 0) + count
  if filetype and filetype ~= "" then
    local filetypes = util.shallow_copy(next_metrics.filetypes or {})
    filetypes[filetype] = (filetypes[filetype] or 0) + count
    next_metrics.filetypes = filetypes
  end
  return next_metrics
end

local function add_lines(metrics, count)
  local next_metrics = util.merge_tables(metrics, {})
  next_metrics.lines = (next_metrics.lines or 0) + count
  return next_metrics
end

local function add_save(metrics)
  local next_metrics = util.merge_tables(metrics, {})
  next_metrics.saves = (next_metrics.saves or 0) + 1
  return next_metrics
end

local function add_time(metrics, seconds)
  local next_metrics = util.merge_tables(metrics, {})
  next_metrics.time_sec = (next_metrics.time_sec or 0) + seconds
  return next_metrics
end

M.new_metrics = new_metrics
M.add_chars = add_chars
M.add_lines = add_lines
M.add_save = add_save
M.add_time = add_time

return M
