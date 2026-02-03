-- このテストは入力統計で除外するファイル種別が設定に含まれることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("idle_dungeon.config")

local built = config.build({})
local ignored = ((built.input or {}).ignored_filetypes) or {}
local lookup = {}
for _, name in ipairs(ignored) do
  lookup[name] = true
end

assert_true(lookup.alpha == true, "alpha は除外対象に含まれる")
assert_true(lookup.dashboard == true, "dashboard は除外対象に含まれる")
assert_true(lookup.NvimTree == true, "NvimTree は除外対象に含まれる")
assert_true(lookup["neo-tree"] == true, "neo-tree は除外対象に含まれる")

print("OK")
