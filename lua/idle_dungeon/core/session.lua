-- このモジュールは共有状態と所有権を管理する。
-- 永続化の参照先はstorage配下に統一する。
local lock = require("idle_dungeon.storage.lock")
local store_state = require("idle_dungeon.storage.state")

local M = {}

local runtime = {
  config = nil,
  state = nil,
  owner = false,
  instance_id = nil,
  last_sync_mtime = nil,
  notified_read_only = false,
}

local function set_config(config)
  runtime.config = config
end

local function ensure_instance_id()
  if not runtime.instance_id then
    runtime.instance_id = lock.build_instance_id()
  end
  return runtime.instance_id
end

local function get_state()
  return runtime.state
end

local function set_state(state)
  runtime.state = state
end

local function is_owner()
  return runtime.owner
end

local function set_owner(owner)
  runtime.owner = owner
end

local function read_only_notified()
  return runtime.notified_read_only
end

local function mark_read_only_notified()
  runtime.notified_read_only = true
end

local function clear_read_only_notified()
  runtime.notified_read_only = false
end

local function load_state()
  -- 保存済みの状態を読み取る。
  local state, mtime = store_state.load_state()
  if state then
    runtime.state = state
    runtime.last_sync_mtime = mtime
  end
  return runtime.state
end

local function sync_state_if_newer()
  -- 共有状態が更新されていれば読み取る。
  local state, mtime = store_state.load_state_if_newer(runtime.last_sync_mtime)
  if state then
    runtime.state = state
    runtime.last_sync_mtime = mtime
  end
  return state
end

local function save_state(state)
  -- 共有状態を保存する。
  if not runtime.owner then
    return state
  end
  local saved, mtime = store_state.save_state(state, runtime.instance_id)
  runtime.state = saved
  runtime.last_sync_mtime = mtime
  return saved
end

local function acquire_owner()
  -- 所有権を取得して更新可能にする。
  local ok = lock.acquire_lock(runtime.instance_id, runtime.config.storage.lock_ttl_seconds)
  runtime.owner = ok
  if ok then
    clear_read_only_notified()
  end
  return ok
end

local function release_owner()
  -- 所有権を解除して更新を停止する。
  if runtime.owner then
    lock.release_lock(runtime.instance_id)
  end
  runtime.owner = false
end

M.set_config = set_config
M.ensure_instance_id = ensure_instance_id
M.get_state = get_state
M.set_state = set_state
M.is_owner = is_owner
M.set_owner = set_owner
M.read_only_notified = read_only_notified
M.mark_read_only_notified = mark_read_only_notified
M.clear_read_only_notified = clear_read_only_notified
M.load_state = load_state
M.sync_state_if_newer = sync_state_if_newer
M.save_state = save_state
M.acquire_owner = acquire_owner
M.release_owner = release_owner

return M
