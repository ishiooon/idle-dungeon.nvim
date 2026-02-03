-- このテストは装備詳細に解放条件が表示されることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local detail = require("idle_dungeon.menu.detail")
local state_module = require("idle_dungeon.core.state")

local config = {
  unlock_rules = {
    -- 装備定義の解放条件に合わせて大きめの値を使う。
    { id = "typing_blade", target = "items", kind = "chars", value = 4000 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
local target = nil
for _, item in ipairs(content.items or {}) do
  if item.id == "typing_blade" then
    target = item
    break
  end
end

local result = detail.build_item_detail(target, state, "en", config)
local joined = table.concat(result.lines or {}, " ")
assert_match(joined, "Unlock Requirements", "解放条件の見出しが含まれる")
assert_match(joined, "Typed Characters", "解放条件の項目が含まれる")

print("OK")
