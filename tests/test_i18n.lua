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

local progress_ja = i18n.t("label_progress", "ja")
assert_equal(progress_ja, "ステージ進行:", "進行度の日本語ラベルが取得できる")

local floor_ja = i18n.t("label_floor", "ja")
assert_equal(floor_ja, "現在の階層:", "階層の日本語ラベルが取得できる")

local progress_en = i18n.t("label_progress", "en")
assert_equal(progress_en, "Stage Progress:", "進行度の英語ラベルが取得できる")

local floor_en = i18n.t("label_floor", "en")
assert_equal(floor_en, "Current Floor:", "階層の英語ラベルが取得できる")

print("OK")
