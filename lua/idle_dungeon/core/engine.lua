-- このモジュールはゲームの進行と同期を統括する。
-- 参照先はcore・game・ui・menu配下へ整理する。
local config_module = require("idle_dungeon.config")
local game_speed = require("idle_dungeon.core.game_speed")
local input = require("idle_dungeon.core.input")
local loop = require("idle_dungeon.core.loop")
local menu = require("idle_dungeon.menu")
local metrics = require("idle_dungeon.game.metrics")
local event_catalog = require("idle_dungeon.game.event_catalog")
local event_choice = require("idle_dungeon.game.event_choice")
local render_state = require("idle_dungeon.ui.render_state")
local session = require("idle_dungeon.core.session")
local state_module = require("idle_dungeon.core.state")
local ui = require("idle_dungeon.ui")
local unlock = require("idle_dungeon.game.unlock")
local i18n = require("idle_dungeon.i18n")
local M = {}
local current_config = nil
local current_tick_seconds = nil
local menu_handlers = nil
local apply_unlocks, handle_metrics, handle_choice, tick, sync_tick, start_owner_mode, start_follower_mode, set_state_and_render, notify_read_only, open_menu, toggle_menu, render_current, takeover_owner, reload_plugin

local function resolve_lang()
  local state = session.get_state()
  local ui_config = (current_config and current_config.ui) or {}
  return (state and state.ui and state.ui.language) or ui_config.language or "en"
end

-- 速度上昇などによる実効ティック秒を解決する。
local function resolve_tick_seconds(state, config)
  return game_speed.resolve_runtime_tick_seconds(state, config)
end

-- ティック間隔が変わった場合はタイマーを更新する。                                           
local function update_tick_timer(state)
  local desired = resolve_tick_seconds(state, current_config)
  if current_tick_seconds == nil then
    current_tick_seconds = desired
    return
  end
  if desired == current_tick_seconds then
    return
  end
  loop.stop_tick()
  loop.start_tick(desired, tick)
  current_tick_seconds = desired
end
local function configure(user_config)
  current_config = config_module.build(user_config)
  session.set_config(current_config)
  menu_handlers = {
    on_reload = function()
      return reload_plugin()
    end,
  }
  -- メニューを閉じた直後に右下表示を即時で復帰する。
  menu.set_on_close(function()
    render_current(session.get_state())
  end)
  -- 右下の表示をクリックした際にメニューを開閉する。
  ui.set_on_click(toggle_menu)
  return current_config
end
render_current = function(state)
  if not state then return end
  -- Read-only表示を反映した状態で描画する。
  local display_state = render_state.with_read_only(state, session.is_owner())
  if menu.is_open and menu.is_open() then
    -- メニュー中は右下表示を消して重なりを避ける。
    ui.close()
  else
    ui.render(display_state, current_config)
  end
  -- 開いているメニューがあれば最新状態へ更新する。
  menu.update(session.get_state, set_state_and_render, current_config, menu_handlers)
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
  current_tick_seconds = nil
  if type(menu.close) == "function" then
    -- 再読み込み時の残像を避けるため、コールバックを抑止してメニューを閉じる。
    menu.close({ silent = true })
  end
  if session.is_owner() then
    session.release_owner()
  end
  ui.close()
end
open_menu = function()
  if not current_config then start() end
  if not session.is_owner() then return notify_read_only() end
  menu.open(session.get_state, set_state_and_render, current_config, menu_handlers)
  -- メニュー表示中は右下表示を閉じる。
  ui.close()
end
toggle_menu = function()
  if not current_config then start() end
  if not session.is_owner() then return notify_read_only() end
  local was_open = menu.is_open and menu.is_open() or false
  -- クリック操作でメニュー表示を開閉する。
  menu.toggle(session.get_state, set_state_and_render, current_config, menu_handlers)
  if menu.is_open and menu.is_open() then
    ui.close()
    return
  end
  if was_open then
    render_current(session.get_state())
  end
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
  local elapsed = current_tick_seconds or game_speed.resolve_runtime_tick_seconds(state, current_config)
  local next_metrics = metrics.add_time(next_state.metrics, elapsed)
  next_state = state_module.with_metrics(next_state, next_metrics)
  next_state = apply_unlocks(next_state)
  session.set_state(next_state)
  update_tick_timer(next_state)
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
  input.start(handle_metrics, handle_choice, current_config)
  local state = session.get_state()
  local desired = resolve_tick_seconds(state, current_config)
  loop.start_tick(desired, tick)
  current_tick_seconds = desired
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
  current_tick_seconds = nil
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
handle_choice = function(choice_index)
  if not session.is_owner() then
    return
  end
  local state = session.get_state()
  if not state or not state.ui or state.ui.mode ~= "choice" then
    return
  end
  local event = event_catalog.find_event(state.ui.event_id)
  if not event_choice.is_choice_event(event) then
    local next_state = state_module.set_ui_mode(state, "move", { event_id = nil, choice_remaining = 0 })
    return set_state_and_render(next_state)
  end
  -- 選択結果を反映し、保存と描画を更新する。
  local next_state = event_choice.apply_choice_event(state, event, current_config, choice_index)
  set_state_and_render(next_state)
end
set_state_and_render = function(next_state)
  local saved = session.save_state(next_state)
  session.set_state(saved)
  update_tick_timer(saved)
  render_current(saved)
end
notify_read_only = function()
  if session.read_only_notified() then return end
  session.mark_read_only_notified()
  local lang = resolve_lang()
  -- 他のインスタンスが稼働中である旨を通知する。
  vim.notify(i18n.t("notify_read_only", lang), vim.log.levels.INFO)
end
takeover_owner = function()
  if not current_config then start() end
  if session.is_owner() then
    vim.notify(i18n.t("notify_takeover_already_owner", resolve_lang()), vim.log.levels.INFO)
    return true
  end
  if session.acquire_owner(true) then
    start_owner_mode()
    local state = session.get_state()
    if state then
      session.save_state(state)
    end
    render_current(session.get_state())
    vim.notify(i18n.t("notify_takeover_success", resolve_lang()), vim.log.levels.INFO)
    return true
  end
  vim.notify(i18n.t("notify_takeover_failed", resolve_lang()), vim.log.levels.WARN)
  return false
end
reload_plugin = function()
  local was_open = menu.is_open and menu.is_open() or false
  local idle = require("idle_dungeon")
  if type(idle.reload) == "function" then
    return idle.reload({ open_menu = was_open })
  end
  stop()
  start()
end
M.configure = configure
M.start = start
M.stop = stop
M.open_menu = open_menu
M.toggle_text_mode = toggle_text_mode
M.takeover_owner = takeover_owner
return M
