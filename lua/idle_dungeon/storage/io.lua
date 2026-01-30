-- このモジュールは保存ファイルの入出力を担う。

local uv = vim.loop

local M = {}

local function join_path(...)
  return table.concat({ ... }, "/")
end

local function data_dir()
  return join_path(vim.fn.stdpath("data"), "idle-dungeon")
end

local function state_path()
  return join_path(data_dir(), "state.json")
end

local function lock_path()
  return join_path(data_dir(), "lock.json")
end

local function decode_json(payload)
  if not payload or payload == "" then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, payload)
  if not ok then
    return nil
  end
  return decoded
end

local function encode_json(payload)
  return vim.json.encode(payload)
end

local function read_file(path)
  -- ファイルを読み取り、内容と更新情報を返す。
  local fd = uv.fs_open(path, "r", 420)
  if not fd then
    return nil, nil
  end
  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, nil
  end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data, stat
end

local function write_file_atomic(path, payload)
  -- 一時ファイル経由で書き込み、破損を避ける。
  local tmp_path = path .. ".tmp"
  local fd = uv.fs_open(tmp_path, "w", 420)
  if not fd then
    return false
  end
  uv.fs_write(fd, payload, 0)
  uv.fs_close(fd)
  uv.fs_rename(tmp_path, path)
  return true
end

local function ensure_dir()
  -- 保存用ディレクトリを作成する。
  vim.fn.mkdir(data_dir(), "p")
end

M.data_dir = data_dir
M.state_path = state_path
M.lock_path = lock_path
M.decode_json = decode_json
M.encode_json = encode_json
M.read_file = read_file
M.write_file_atomic = write_file_atomic
M.ensure_dir = ensure_dir

return M
