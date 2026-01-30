-- このモジュールは状態の読み書きを扱う。
-- 保存処理の参照先はstorage配下に統一する。
local io = require("idle_dungeon.storage.io")
local lock = require("idle_dungeon.storage.lock")

local M = {}

local function load_state()
  -- 保存済みの状態を読み取る。
  io.ensure_dir()
  local data, stat = io.read_file(io.state_path())
  if not data then
    return nil, nil
  end
  local state = io.decode_json(data)
  if not state then
    return nil, nil
  end
  return state, stat and stat.mtime and stat.mtime.sec or 0
end

local function load_state_if_newer(last_mtime)
  -- 更新時刻が変わった場合のみ状態を読み取る。
  local data, stat = io.read_file(io.state_path())
  if not stat then
    return nil, last_mtime
  end
  local mtime = stat.mtime and stat.mtime.sec or 0
  if last_mtime and mtime <= last_mtime then
    return nil, last_mtime
  end
  local state = io.decode_json(data)
  return state, mtime
end

local function save_state(state, instance_id)
  -- 状態を保存し、ロックの更新時刻も更新する。
  io.ensure_dir()
  local next_state = vim.deepcopy(state)
  next_state.meta = next_state.meta or {}
  next_state.meta.updated_at = os.time()
  next_state.meta.instance_id = instance_id
  local ok = io.write_file_atomic(io.state_path(), io.encode_json(next_state))
  if ok then
    lock.refresh_lock(instance_id)
  end
  local _, stat = io.read_file(io.state_path())
  local mtime = stat and stat.mtime and stat.mtime.sec or 0
  return next_state, mtime
end

M.load_state = load_state
M.load_state_if_newer = load_state_if_newer
M.save_state = save_state

return M
