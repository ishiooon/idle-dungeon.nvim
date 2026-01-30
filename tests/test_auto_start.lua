-- このテストは自動開始の判定ロジックを確認する。
-- core配下への整理に合わせて参照先を更新する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local auto_start = require("idle_dungeon.core.auto_start")
local config = require("idle_dungeon.config")

local built = config.build({})
assert_equal(auto_start.resolve(nil, built, nil), true, "既定は自動開始する")

local saved_disabled = { ui = { auto_start = false } }
assert_equal(auto_start.resolve({}, built, saved_disabled), false, "保存済み設定で自動開始が無効になる")

local user_disabled = { ui = { auto_start = false } }
local saved_enabled = { ui = { auto_start = true } }
assert_equal(auto_start.resolve(user_disabled, built, saved_enabled), false, "ユーザー設定が優先される")

local user_enabled = { ui = { auto_start = true } }
local saved_disabled = { ui = { auto_start = false } }
assert_equal(auto_start.resolve(user_enabled, built, saved_disabled), true, "ユーザー設定の有効化が優先される")

print("OK")
