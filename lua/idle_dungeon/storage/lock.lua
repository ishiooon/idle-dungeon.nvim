-- このモジュールはロック取得と更新を扱う。
-- 永続化I/Oはstorage/ioへ集約する。
local uv = vim.loop
local io = require("idle_dungeon.storage.io")

local M = {}

local function build_instance_id()
  return string.format("%d-%d", uv.os_getpid(), uv.hrtime())
end

local function read_lock()
  -- ロック情報を読み取る。
  local data = io.read_file(io.lock_path())
  return io.decode_json(data)
end

local function lock_is_alive(lock, ttl_seconds)
  if not lock then
    return false
  end
  if lock.updated_at and ttl_seconds then
    if os.time() - lock.updated_at > ttl_seconds then
      return false
    end
  end
  if lock.pid then
    local ok = pcall(uv.kill, lock.pid, 0)
    if ok then
      return true
    end
  end
  return false
end

local function write_lock(lock)
  -- ロック情報を更新して競合を抑止する。
  return io.write_file_atomic(io.lock_path(), io.encode_json(lock))
end

local function acquire_lock(instance_id, ttl_seconds)
  -- ロックファイルを作成して所有権を取得する。
  io.ensure_dir()
  local fd = uv.fs_open(io.lock_path(), "wx", 420)
  if fd then
    local now = os.time()
    local lock = { instance_id = instance_id, pid = uv.os_getpid(), created_at = now, updated_at = now }
    uv.fs_write(fd, io.encode_json(lock), 0)
    uv.fs_close(fd)
    return true
  end
  local existing = read_lock()
  if not lock_is_alive(existing, ttl_seconds) then
    local removed = uv.fs_unlink(io.lock_path())
    if removed then
      return acquire_lock(instance_id, ttl_seconds)
    end
  end
  return false
end

local function refresh_lock(instance_id)
  -- ロックの更新時刻を更新して所有権を維持する。
  local lock = read_lock()
  if not lock or lock.instance_id ~= instance_id then
    return false
  end
  lock.updated_at = os.time()
  return write_lock(lock)
end

local function release_lock(instance_id)
  -- ロックを解除して他のインスタンスに譲る。
  local lock = read_lock()
  if not lock or lock.instance_id ~= instance_id then
    return false
  end
  return uv.fs_unlink(io.lock_path())
end

M.build_instance_id = build_instance_id
M.acquire_lock = acquire_lock
M.refresh_lock = refresh_lock
M.release_lock = release_lock

return M
