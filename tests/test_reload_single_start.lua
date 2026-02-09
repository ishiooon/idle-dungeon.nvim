-- このテストはreloadで二重起動せず、再読込先のstartを1回だけ呼ぶことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local calls = {
  stop = 0,
  reloaded_setup = 0,
  reloaded_start = 0,
  reloaded_open_menu = 0,
}

package.loaded["idle_dungeon.core.engine"] = {
  configure = function(config)
    return config or {}
  end,
  start = function() end,
  stop = function()
    calls.stop = calls.stop + 1
  end,
  toggle_text_mode = function() end,
  open_menu = function() end,
  takeover_owner = function()
    return true
  end,
}

package.loaded["idle_dungeon.core.auto_start"] = {
  resolve = function()
    return false
  end,
}

package.loaded["idle_dungeon.storage.state"] = {
  load_state = function()
    return nil
  end,
}

local idle = require("idle_dungeon")
idle.setup({ ui = { auto_start = false } })

package.preload["idle_dungeon"] = function()
  return {
    setup = function(_, options)
      calls.reloaded_setup = calls.reloaded_setup + 1
      assert_true(type(options) == "table" and options.skip_auto_start == true, "reload時は自動開始を抑止する")
      return {}
    end,
    start = function()
      calls.reloaded_start = calls.reloaded_start + 1
    end,
    open_menu = function()
      calls.reloaded_open_menu = calls.reloaded_open_menu + 1
    end,
  }
end

idle.reload({ open_menu = true })

assert_true(calls.stop == 1, "reload時に旧インスタンスのstopを1回呼ぶ")
assert_true(calls.reloaded_setup == 1, "再読込後のsetupは1回だけ呼ぶ")
assert_true(calls.reloaded_start == 1, "再読込後のstartは1回だけ呼ぶ")
assert_true(calls.reloaded_open_menu == 1, "open_menu指定時は再読込後にメニューを開く")

package.preload["idle_dungeon"] = nil

print("OK")
