-- このテストはメニュー操作ログに日時とカテゴリが付与されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_logging = require("idle_dungeon.menu.logging")

local state = {
  metrics = { time_sec = 42 },
  logs = {},
}

state = menu_logging.append(state, "Equipment Changed: Weapon -> Wood Sword")
local line = tostring((state.logs or {})[#(state.logs or {})] or "")

assert_true(
  line:match("^%[MENU%] Equipment Changed: Weapon %-%> Wood Sword %[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]$") ~= nil,
  "メニュー操作ログはカテゴリ先頭・日時末尾で保存される"
)

print("OK")
