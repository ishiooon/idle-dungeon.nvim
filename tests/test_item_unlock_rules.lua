-- このテストは装備の解放条件がアイテム定義から生成されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("idle_dungeon.config")
local content = require("idle_dungeon.content")

local function count_unlocks(items)
  local total = 0
  for _, item in ipairs(items or {}) do
    local unlock = item.unlock
    if type(unlock) == "table" and unlock.kind then
      total = total + 1
    elseif type(unlock) == "table" then
      for _, entry in ipairs(unlock) do
        if type(entry) == "table" and entry.kind then
          total = total + 1
        end
      end
    end
  end
  return total
end

local function find_rule(rules, id, kind, filetype)
  for _, rule in ipairs(rules or {}) do
    if rule.id == id and rule.kind == kind then
      if not filetype or rule.filetype == filetype then
        return rule
      end
    end
  end
  return nil
end

local built = config.build({})
local rules = built.unlock_rules or {}
local expected = count_unlocks(content.items or {})

assert_true(#rules >= expected, "装備定義の解放条件が設定に反映される")

local typing = find_rule(rules, "typing_blade", "chars")
assert_true(typing ~= nil, "入力文字数で解放される装備が登録される")
assert_equal(typing.value, 200, "入力文字数の解放条件が一致する")

local lua_rule = find_rule(rules, "lua_sigil_blade", "filetype_chars", "lua")
assert_true(lua_rule ~= nil, "ファイル種別の解放条件が登録される")
assert_equal(lua_rule.value, 400, "ファイル種別の解放条件が一致する")

print("OK")
