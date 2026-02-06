-- このモジュールは利用者向けの公開関数を提供する。
-- 公開APIの参照先はcoreとstorage配下へ整理する。
local auto_start = require("idle_dungeon.core.auto_start")
local engine = require("idle_dungeon.core.engine")
local store_state = require("idle_dungeon.storage.state")

local M = {}

local function setup(user_config)
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

M.setup = setup
M.start = start
M.stop = stop
M.toggle_text_mode = toggle_text_mode
M.open_menu = open_menu
M.takeover_owner = takeover_owner

return M
