-- このテストは公開APIが主導権奪取の処理を提供することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local called = false
package.loaded["idle_dungeon.core.engine"] = {
  configure = function(config)
    return config or {}
  end,
  start = function() end,
  stop = function() end,
  toggle_text_mode = function() end,
  open_menu = function() end,
  takeover_owner = function()
    called = true
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
local ok = idle.takeover_owner()
assert_true(ok == true, "主導権奪取APIはエンジンの結果を返す")
assert_true(called == true, "主導権奪取APIはエンジンへ委譲する")

print("OK")
