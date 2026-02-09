-- このモジュールは利用者向けの公開関数を提供する。
-- 公開APIの参照先はcoreとstorage配下へ整理する。
local auto_start = require("idle_dungeon.core.auto_start")
local engine = require("idle_dungeon.core.engine")
local store_state = require("idle_dungeon.storage.state")

local M = {}
local last_user_config = {}

local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end
  local copied = {}
  for key, item in pairs(value) do
    copied[key] = deep_copy(item)
  end
  return copied
end

local function clear_idle_dungeon_cache()
  for name, _ in pairs(package.loaded) do
    if name:match("^idle_dungeon") then
      package.loaded[name] = nil
    end
  end
end

local function setup(user_config)
  last_user_config = deep_copy(user_config or {})
  local config = engine.configure(user_config or {})
  -- 保存済みの設定を読み取り、必要なら保存ディレクトリを作成して自動開始の可否を判定する。
  local saved_state = store_state.load_state()
  if auto_start.resolve(user_config, config, saved_state) then
    engine.start()
  end
  return config
end

local function start()
  engine.start()
end

local function stop()
  engine.stop()
end

local function toggle_text_mode()
  engine.toggle_text_mode()
end

local function open_menu()
  engine.open_menu()
end

local function takeover_owner()
  return engine.takeover_owner()
end

local function reload(options)
  local opts = options or {}
  local open_menu_after = opts.open_menu == true
  local config_copy = deep_copy(last_user_config)
  -- 実行中のループを止めたうえで、idle_dungeon配下のモジュールキャッシュを破棄して再読込する。
  stop()
  clear_idle_dungeon_cache()
  local reloaded = require("idle_dungeon")
  reloaded.setup(config_copy)
  reloaded.start()
  if open_menu_after then
    reloaded.open_menu()
  end
end

M.setup = setup
M.start = start
M.stop = stop
M.toggle_text_mode = toggle_text_mode
M.open_menu = open_menu
M.takeover_owner = takeover_owner
M.reload = reload

return M
