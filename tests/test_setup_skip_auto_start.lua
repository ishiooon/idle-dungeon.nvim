-- このテストはsetupの自動開始抑止オプションを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local calls = {
  configure = 0,
  start = 0,
}

package.loaded["idle_dungeon.core.engine"] = {
  configure = function(config)
    calls.configure = calls.configure + 1
    return config or {}
  end,
  start = function()
    calls.start = calls.start + 1
  end,
  stop = function() end,
  toggle_text_mode = function() end,
  open_menu = function() end,
  takeover_owner = function()
    return true
  end,
}

package.loaded["idle_dungeon.core.auto_start"] = {
  resolve = function()
    return true
  end,
}

package.loaded["idle_dungeon.storage.state"] = {
  load_state = function()
    return nil
  end,
}

local idle = require("idle_dungeon")
idle.setup({}, { skip_auto_start = true })
assert_true(calls.configure == 1, "setupはconfigureを呼ぶ")
assert_true(calls.start == 0, "自動開始抑止時はstartを呼ばない")

idle.setup({})
assert_true(calls.configure == 2, "2回目のsetupでもconfigureを呼ぶ")
assert_true(calls.start == 1, "通常setupではstartを呼ぶ")

print("OK")
