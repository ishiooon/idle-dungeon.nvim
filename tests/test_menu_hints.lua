-- このテストはメニュー下部の案内文と言語切替用の表記を確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_locale = require("idle_dungeon.menu.locale")

local toggle_label = menu_locale.toggle_label("Text Mode", true, "en")
assert_match(toggle_label, "%[ %a+ %]", "トグル表記がボタン風になる")

local hints = menu_locale.menu_footer_hints("en")
assert_true(type(hints) == "table" and #hints >= 2, "メニュー下部の案内文が生成される")

local sub_hints = menu_locale.submenu_footer_hints("en")
assert_true(type(sub_hints) == "table" and #sub_hints >= 3, "子画面向けの案内文が生成される")
assert_match(table.concat(sub_hints, " "), "[Bb]ack", "子画面に戻る操作が案内される")

print("OK")
