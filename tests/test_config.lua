-- このテストは無限ステージとボス節目が設定に含まれることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("idle_dungeon.config")

local built = config.build({})
local infinite_stage = nil
for _, stage in ipairs(built.stages or {}) do
  if stage.infinite then
    infinite_stage = stage
  end
end

assert_true(infinite_stage ~= nil, "無限ステージが存在する")
assert_true(type(infinite_stage.boss_every) == "number", "ボス出現間隔が数値で定義される")
assert_true(infinite_stage.boss_every > 0, "ボス出現間隔が1以上で定義される")
assert_true(type(built.storage) == "table", "保存設定が定義される")
assert_true(type(built.storage.lock_ttl_seconds) == "number", "ロックの有効時間が定義される")
assert_true(type(built.storage.sync_seconds) == "number", "同期間隔が定義される")
assert_true(type(built.storage.autosave_seconds) == "number", "自動保存間隔が定義される")
assert_true(type(built.ui) == "table", "表示設定が定義される")
assert_true(built.ui.language == "en", "既定言語は英語である")
assert_true(type(built.ui.languages) == "table", "言語一覧が定義される")
assert_true(built.ui.auto_start == true, "自動開始の既定値はtrueである")
assert_true(built.ui.max_height == 2, "最大表示行数は2である")
assert_true(built.ui.height == 1, "表示行数の既定値は1である")
assert_true(type(built.floor_length) == "number", "階層の横幅が数値で定義される")
assert_true(type(built.floor_encounters) == "table", "階層遭遇数の設定が定義される")
assert_true(type(built.floor_encounters.min) == "number", "階層遭遇数の最小値が定義される")
assert_true(type(built.floor_encounters.max) == "number", "階層遭遇数の最大値が定義される")
assert_true(type(built.boss_every) == "number", "ボスの出現間隔が定義される")
-- 会話待機の既定値は0秒で停止時間を発生させない。
assert_true(built.dialogue_seconds == 0, "会話待機の既定値は0秒である")
-- 表示用アイコンと進行トラックの設定が含まれることを確認する。
assert_true(type(built.ui.icons) == "table", "表示用アイコンの設定が定義される")
assert_true(type(built.ui.track_fill) == "string", "進行トラックの埋め文字が定義される")
assert_true(type(built.ui.sprites) == "table", "スプライト表示の設定が定義される")
assert_true(built.ui.sprites.enabled == true, "スプライト表示は既定で有効である")
assert_true(type(built.ui.sprite_palette) == "table", "スプライトの色設定が定義される")
assert_true(type(built.ui.image_sprites) == "table", "画像スプライト設定が定義される")
assert_true(built.ui.image_sprites.enabled == false, "画像スプライトは既定で無効である")
-- メニュー表示の既定値が設定に含まれることを確認する。
assert_true(type(built.ui.menu) == "table", "メニュー表示の設定が定義される")
assert_true(type(built.ui.menu.width) == "number", "メニューの幅設定が数値で定義される")
assert_true(type(built.ui.menu.max_height) == "number", "メニューの高さ上限が数値で定義される")
assert_true(built.ui.menu.width == 72, "メニューの既定幅が拡大されている")
assert_true(built.ui.menu.max_height == 22, "メニューの既定高さ上限が拡大されている")
assert_true(built.ui.menu.tabs_position == "top", "タブ表示の既定位置が上部である")

print("OK")
