-- このテストは停止処理でメニューをサイレントに閉じることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local calls = {
  menu_close = 0,
  menu_close_arg = nil,
  ui_close = 0,
  loop_stop_all = 0,
  input_stop = 0,
  release_owner = 0,
}

package.loaded["idle_dungeon.config"] = {
  build = function(user)
    return {
      ui = (user and user.ui) or { language = "en" },
      storage = { autosave_seconds = 10, sync_seconds = 1 },
      unlock_rules = {},
    }
  end,
}
package.loaded["idle_dungeon.core.game_speed"] = {
  resolve_runtime_tick_seconds = function()
    return 0.5
  end,
}
package.loaded["idle_dungeon.core.input"] = {
  stop = function()
    calls.input_stop = calls.input_stop + 1
  end,
  start = function() end,
}
package.loaded["idle_dungeon.core.loop"] = {
  stop_all = function()
    calls.loop_stop_all = calls.loop_stop_all + 1
  end,
  stop_tick = function() end,
  start_tick = function() end,
  stop_sync = function() end,
  start_sync = function() end,
  stop_save = function() end,
  start_save = function() end,
}
package.loaded["idle_dungeon.menu"] = {
  set_on_close = function() end,
  set_context = function() end,
  is_open = function()
    return false
  end,
  open = function() end,
  toggle = function() end,
  update = function() end,
  close = function(opts)
    calls.menu_close = calls.menu_close + 1
    calls.menu_close_arg = opts
  end,
}
package.loaded["idle_dungeon.game.metrics"] = {
  add_time = function(metrics)
    return metrics
  end,
}
package.loaded["idle_dungeon.game.event_catalog"] = {
  find_event = function()
    return nil
  end,
}
package.loaded["idle_dungeon.game.event_choice"] = {
  is_choice_event = function()
    return false
  end,
  apply_choice_event = function(state)
    return state
  end,
}
package.loaded["idle_dungeon.ui.render_state"] = {
  with_read_only = function(state)
    return state
  end,
}
package.loaded["idle_dungeon.core.session"] = {
  set_config = function() end,
  get_state = function()
    return { ui = { language = "en" } }
  end,
  set_state = function() end,
  is_owner = function()
    return true
  end,
  release_owner = function()
    calls.release_owner = calls.release_owner + 1
  end,
}
package.loaded["idle_dungeon.core.state"] = {
  new_state = function()
    return {}
  end,
}
package.loaded["idle_dungeon.ui"] = {
  set_on_click = function() end,
  close = function()
    calls.ui_close = calls.ui_close + 1
  end,
  render = function() end,
}
package.loaded["idle_dungeon.game.unlock"] = {
  apply_rules = function(unlocks)
    return unlocks
  end,
}
package.loaded["idle_dungeon.i18n"] = {
  t = function(key)
    return key
  end,
}

local engine = require("idle_dungeon.core.engine")
engine.configure({ ui = { language = "en" } })
engine.stop()

assert_true(calls.menu_close == 1, "停止時にメニューを閉じる")
assert_true(type(calls.menu_close_arg) == "table", "停止時のメニュークローズはオプション付き")
assert_true(calls.menu_close_arg.silent == true, "停止時のメニュークローズはサイレントで行う")
assert_true(calls.ui_close == 1, "停止時に右下表示を閉じる")
assert_true(calls.loop_stop_all == 1, "停止時にループを停止する")
assert_true(calls.input_stop == 1, "停止時に入力監視を停止する")
assert_true(calls.release_owner == 1, "停止時に所有権を解放する")

print("OK")
