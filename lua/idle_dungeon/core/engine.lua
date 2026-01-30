-- このモジュールはゲームの進行と同期を統括する。
-- 参照先はcore・game・ui・menu配下へ整理する。
local config_module = require("idle_dungeon.config")
local input = require("idle_dungeon.core.input")
local loop = require("idle_dungeon.core.loop")
local menu = require("idle_dungeon.menu")
local metrics = require("idle_dungeon.game.metrics")
local render_state = require("idle_dungeon.ui.render_state")
local session = require("idle_dungeon.core.session")
local state_module = require("idle_dungeon.core.state")
local ui = require("idle_dungeon.ui")
local unlock = require("idle_dungeon.game.unlock")
local i18n = require("idle_dungeon.i18n")
local M = {}
local current_config = nil
local apply_unlocks, handle_metrics, tick, sync_tick, start_owner_mode, start_follower_mode, set_state_and_render, notify_read_only, open_menu, toggle_menu, render_current
local function configure(user_config)
  current_config = config_module.build(user_config)
  session.set_config(current_config)
  -- 右下の表示をクリックした際にメニューを開閉する。
  ui.set_on_click(toggle_menu)
  return current_config
end
render_current = function(state)
  if not state then return end
  -- Read-only表示を反映した状態で描画する。
  local display_state = render_state.with_read_only(state, session.is_owner())
  ui.render(display_state, current_config)
  -- 開いているメニューがあれば最新状態へ更新する。
  menu.update(session.get_state, set_state_and_render, current_config)
end
local function start()
  if not current_config then configure({}) end
  session.ensure_instance_id()
  if not session.load_state() then session.set_state(state_module.new_state(current_config)) end
  if session.acquire_owner() then
    start_owner_mode()
  else
    start_follower_mode()
  end
  render_current(session.get_state())
end
local function stop()
  -- タイマーや入力監視を停止し、ロックを解放する。
  loop.stop_all()
  input.stop()
  if session.is_owner() then
    session.release_owner()
  end
  ui.close()
end
open_menu = function()
  if not current_config then start() end
  if not session.is_owner() then return notify_read_only() end
  menu.open(session.get_state, set_state_and_render, current_config)
end
toggle_menu = function()
  if not current_config then start() end
  if not session.is_owner() then return notify_read_only() end
  -- クリック操作でメニュー表示を開閉する。
  menu.toggle(session.get_state, set_state_and_render, current_config)
end
local function toggle_text_mode()
  if not current_config then start() end
  if not session.is_owner() then return notify_read_only() end
  -- 表示モードを切り替えて保存する。
  local next_state = state_module.toggle_render_mode(session.get_state())
  set_state_and_render(next_state)
end
tick = function()
  if not session.is_owner() then return end
  local state = session.get_state()
  if not state then return end
  -- 進行を更新し、描画を反映する。
  local next_state = state_module.tick(state, current_config)
  local next_metrics = metrics.add_time(next_state.metrics, current_config.tick_seconds)
  next_state = state_module.with_metrics(next_state, next_metrics)
  next_state = apply_unlocks(next_state)
  session.set_state(next_state)
  render_current(next_state)
end
sync_tick = function()
  if session.is_owner() then return end
  -- 共有状態を同期し、必要なら所有権を取得する。
  local updated = session.sync_state_if_newer()
  if updated then
    render_current(session.get_state())
  end
  if session.acquire_owner() then
    start_owner_mode()
    session.save_state(session.get_state())
    render_current(session.get_state())
  end
end
start_owner_mode = function()
  -- 所有権を持つ場合のタイマーと入力監視を開始する。
  loop.stop_sync()
  input.start(handle_metrics)
  loop.start_tick(current_config.tick_seconds, tick)
  loop.start_save(current_config.storage.autosave_seconds, function()
    local state = session.get_state()
    if state then
      session.save_state(state)
    end
  end)
end
start_follower_mode = function()
  loop.stop_tick()
  loop.stop_save()
  input.stop()
  loop.start_sync(current_config.storage.sync_seconds, sync_tick)
end
apply_unlocks = function(state)
  local next_unlocks = unlock.apply_rules(state.unlocks, state.metrics, current_config.unlock_rules)
  return state_module.with_unlocks(state, next_unlocks)
end
handle_metrics = function(update_fn)
  if not session.is_owner() then return end
  local state = session.get_state()
  if not state then return end
  -- 入力実績に基づき状態を更新する。
  local next_metrics = update_fn(state.metrics)
  local next_state = state_module.with_metrics(state, next_metrics)
  session.set_state(apply_unlocks(next_state))
end
set_state_and_render = function(next_state)
  session.set_state(session.save_state(next_state))
  render_current(session.get_state())
end
notify_read_only = function()
  if session.read_only_notified() then return end
  session.mark_read_only_notified()
  local state = session.get_state()
  local lang = (state and state.ui and state.ui.language) or (current_config.ui or {}).language or "en"
  -- 他のインスタンスが稼働中である旨を通知する。
  vim.notify(i18n.t("notify_read_only", lang), vim.log.levels.INFO)
end
M.configure = configure
M.start = start
M.stop = stop
M.open_menu = open_menu
M.toggle_text_mode = toggle_text_mode
return M
