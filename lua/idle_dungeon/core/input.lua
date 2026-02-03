-- このモジュールは入力と保存イベントを監視して実績更新を通知する。
-- 実績集計はgame/metricsへ集約する。
local metrics = require("idle_dungeon.game.metrics")

local M = {}

local runtime = {
  augroup = nil,
  key_ns = nil,
  on_metrics = nil,
  on_choice = nil,
  buf_state = {},
  ignored_filetypes = {},
}
local handle_insert_char
local handle_text_changed
local handle_save
local handle_buf_enter
local handle_buf_wipeout
local handle_choice_key
local seed_buffer_state
local ensure_buffer_state
local set_buffer_state
local count_buffer_chars
local resolve_filetype
local is_trackable_buffer
local is_insert_mode

local function start(on_metrics, on_choice, config)
  runtime.on_metrics = on_metrics
  runtime.on_choice = on_choice
  -- 入力統計から除外するファイル種別を事前に登録する。
  local ignored = ((config or {}).input or {}).ignored_filetypes or {}
  local ignore_set = {}
  for _, name in ipairs(ignored) do
    ignore_set[name] = true
  end
  runtime.ignored_filetypes = ignore_set
  if runtime.augroup then
    return
  end
  -- 既存バッファの文字数を記録して差分集計の基準にする。
  seed_buffer_state()
  -- 入力統計を更新するための自動コマンドを登録する。
  runtime.augroup = vim.api.nvim_create_augroup("IdleDungeon", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile", "BufReadPost" }, {
    group = runtime.augroup,
    callback = handle_buf_enter,
  })
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    group = runtime.augroup,
    callback = handle_buf_wipeout,
  })
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = runtime.augroup,
    callback = handle_insert_char,
  })
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
    group = runtime.augroup,
    callback = handle_text_changed,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = runtime.augroup,
    callback = handle_save,
  })
  runtime.key_ns = vim.api.nvim_create_namespace("IdleDungeonChoice")
  -- 選択イベントの入力を拾うためにキー入力を監視する。
  vim.on_key(handle_choice_key, runtime.key_ns)
end

local function stop()
  if runtime.augroup then
    -- 登録済みの自動コマンドを削除して入力監視を解除する。
    vim.api.nvim_del_augroup_by_id(runtime.augroup)
    runtime.augroup = nil
  end
  if runtime.key_ns then
    -- 選択イベントのキー監視を解除する。
    vim.on_key(nil, runtime.key_ns)
    runtime.key_ns = nil
  end
  -- 入力統計の参照状態を破棄して次回起動時に初期化する。
  runtime.buf_state = {}
  runtime.on_metrics = nil
  runtime.on_choice = nil
  runtime.ignored_filetypes = {}
end

handle_insert_char = function()
  if not runtime.on_metrics then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_trackable_buffer(bufnr) then
    return
  end
  if not is_insert_mode() then
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
  local state = ensure_buffer_state(bufnr)
  state.pending = (state.pending or 0) + count
  local filetype = resolve_filetype(bufnr)
  runtime.on_metrics(function(current)
    return metrics.add_chars(current, count, filetype)
  end)
end

handle_text_changed = function(args)
  if not runtime.on_metrics then
    return
  end
  local bufnr = (args and args.buf) or vim.api.nvim_get_current_buf()
  if not is_trackable_buffer(bufnr) then
    return
  end
  if not is_insert_mode() then
    return
  end
  local state = runtime.buf_state[bufnr]
  if not state then
    set_buffer_state(bufnr)
    return
  end
  local current_total = count_buffer_chars(bufnr)
  local base_total = state.last_total or current_total
  local pending = state.pending or 0
  local extra = current_total - base_total - pending
  state.last_total = current_total
  state.pending = 0
  if extra <= 0 then
    return
  end
  local filetype = resolve_filetype(bufnr)
  runtime.on_metrics(function(current)
    return metrics.add_chars(current, extra, filetype)
  end)
end

handle_save = function()
  if not runtime.on_metrics then
    return
  end
  runtime.on_metrics(function(current)
    return metrics.add_save(current)
  end)
end

handle_choice_key = function(char)
  if not runtime.on_choice then
    return
  end
  if char == "1" then
    runtime.on_choice(1)
    return
  end
  if char == "2" then
    runtime.on_choice(2)
  end
end

handle_buf_enter = function(args)
  local bufnr = args and args.buf
  if not is_trackable_buffer(bufnr) then
    return
  end
  if runtime.buf_state[bufnr] then
    return
  end
  -- 既存内容を基準として差分集計を開始する。
  set_buffer_state(bufnr)
end

handle_buf_wipeout = function(args)
  local bufnr = args and args.buf
  if not bufnr then
    return
  end
  runtime.buf_state[bufnr] = nil
end

seed_buffer_state = function()
  runtime.buf_state = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and is_trackable_buffer(bufnr) then
      set_buffer_state(bufnr)
    end
  end
end

ensure_buffer_state = function(bufnr)
  if not runtime.buf_state[bufnr] then
    set_buffer_state(bufnr)
  end
  return runtime.buf_state[bufnr]
end

set_buffer_state = function(bufnr)
  runtime.buf_state[bufnr] = {
    last_total = count_buffer_chars(bufnr),
    pending = 0,
  }
end

count_buffer_chars = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return 0
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local total = 0
  for _, line in ipairs(lines) do
    total = total + vim.fn.strchars(line)
  end
  -- 改行分を加算して入力統計の体感と合わせる。
  local newline_count = math.max(#lines - 1, 0)
  return total + newline_count
end

resolve_filetype = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  return vim.bo[bufnr].filetype or ""
end

is_trackable_buffer = function(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  -- 編集対象の通常バッファのみを入力統計の対象にする。
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  -- ダッシュボードやツリー系のファイル種別は集計から除外する。
  local filetype = vim.bo[bufnr].filetype or ""
  if runtime.ignored_filetypes[filetype] then
    return false
  end
  if vim.bo[bufnr].modifiable == false then
    return false
  end
  if vim.bo[bufnr].buflisted == false then
    return false
  end
  return true
end

is_insert_mode = function()
  local mode = vim.api.nvim_get_mode().mode or ""
  local head = mode:sub(1, 1)
  return head == "i" or head == "R"
end

M.start = start
M.stop = stop

return M
