-- このテストはキャラクター定義に不要なスプライト情報が含まれないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")

for _, character in ipairs(content.characters or {}) do
  assert_true(character.sprite == nil, "キャラクター定義にスプライトが含まれない")
end

print("OK")
