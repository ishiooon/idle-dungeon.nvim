-- このテストは翻訳の取得と既定言語の設定を確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("idle_dungeon.config")
local i18n = require("idle_dungeon.i18n")

local built = config.build({})
assert_equal(built.ui.language, "en", "既定の言語は英語")

local title_en = i18n.t("menu_title", "en")
assert_equal(title_en, "Idle Dungeon Menu", "英語の翻訳が取得できる")

local title_ja = i18n.t("menu_title", "ja")
assert_equal(title_ja, "Idle Dungeon メニュー", "日本語の翻訳が取得できる")

print("OK")
