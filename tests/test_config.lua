-- このテストは無限ステージとボス節目が設定に含まれることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function resolve_stage_name(name)
  if type(name) == "table" then
    return name.en or name.ja or name.jp or ""
  end
  return name or ""
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("idle_dungeon.config")
local content = require("idle_dungeon.content")

local built = config.build({})
local stages = built.stages or {}
assert_true(#stages == 8, "ステージ数は8である")
assert_true(stages[1].id == 1, "ステージ1のIDが1である")
assert_true(stages[8].id == 8, "ステージ8のIDが8である")
assert_true(resolve_stage_name(stages[1].name) ~= "dungeon1", "ステージ1の名称は味気ない既定値ではない")
assert_true(resolve_stage_name(stages[8].name) ~= "last-dungeon", "ステージ8の名称は味気ない既定値ではない")
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
assert_true(type(built.game_tick_seconds) == "number", "ゲーム進行のティック秒が定義される")
assert_true(type(built.battle_tick_seconds) == "number", "戦闘進行のティック秒が定義される")
assert_true(type(built.game_speed_options) == "table", "ゲーム速度の選択肢が定義される")
assert_true(type(built.default_game_speed) == "string", "既定のゲーム速度IDが定義される")
assert_true(built.game_tick_seconds == 0.5, "ゲーム進行ティック秒の既定値は0.5である")
assert_true(built.battle_tick_seconds == 0.5, "戦闘進行ティック秒の既定値は0.5である")
assert_true(built.default_game_speed == "1x", "既定のゲーム速度は1xである")
assert_true(#built.game_speed_options == 4, "ゲーム速度は1x/2x/5x/10xの4種類が定義される")
assert_true(built.game_speed_options[1].id == "1x", "ゲーム速度1つ目のIDは1xである")
assert_true(built.game_speed_options[1].tick_seconds == 0.5, "1xのティック秒は0.5である")
assert_true(built.game_speed_options[2].id == "2x", "ゲーム速度2つ目のIDは2xである")
assert_true(built.game_speed_options[2].tick_seconds == 0.25, "2xのティック秒は0.25である")
assert_true(built.game_speed_options[3].id == "5x", "ゲーム速度3つ目のIDは5xである")
assert_true(built.game_speed_options[3].tick_seconds == 0.1, "5xのティック秒は0.1である")
assert_true(built.game_speed_options[4].id == "10x", "ゲーム速度4つ目のIDは10xである")
assert_true(built.game_speed_options[4].tick_seconds == 0.05, "10xのティック秒は0.05である")
-- 右下の進行表示は少し短めの既定長にして視認性を高める。
assert_true(built.ui.track_length == 32, "進行トラックの既定長は32である")
assert_true(built.ui.max_height == 2, "最大表示行数は2である")
assert_true(built.ui.height == 2, "表示行数の既定値は2である")
assert_true(type(built.floor_length) == "number", "階層の横幅が数値で定義される")
assert_true(type(built.floor_encounters) == "table", "階層遭遇数の設定が定義される")
assert_true(type(built.floor_encounters.min) == "number", "階層遭遇数の最小値が定義される")
assert_true(type(built.floor_encounters.max) == "number", "階層遭遇数の最大値が定義される")
assert_true(type(built.boss_every) == "number", "ボスの出現間隔が定義される")
assert_true(type(built.battle) == "table", "戦闘設定が定義される")
-- 経験値の既定値は調整後の値と一致する。
assert_true(built.battle.reward_exp == 30, "経験値の既定値が引き上げられている")
assert_true(type(built.battle.skill_active_rate) == "number", "スキル発動率が定義される")
-- 会話待機の既定値は0秒で停止時間を発生させない。
assert_true(built.dialogue_seconds == 0, "会話待機の既定値は0秒である")
assert_true(type(built.stage_intro_seconds) == "number", "ステージ導入の表示秒数が定義される")
-- 表示用アイコンと進行トラックの設定が含まれることを確認する。
assert_true(type(built.ui.icons) == "table", "表示用アイコンの設定が定義される")
assert_true(type(built.ui.icons.weapon) == "string", "武器アイコンが定義される")
assert_true(type(built.ui.icons.armor) == "string", "防具アイコンが定義される")
assert_true(type(built.ui.icons.accessory) == "string", "装飾アイコンが定義される")
assert_true(built.ui.icons.defeat == "󰥓", "敗北アイコンは墓標になっている")
assert_true(type(built.ui.track_fill) == "string", "進行トラックの埋め文字が定義される")
assert_true(built.ui.icons_only == true, "表示はアイコン優先が既定である")
assert_true(type(built.ui.sprites) == "table", "スプライト表示の設定が定義される")
assert_true(built.ui.sprites.enabled == true, "スプライト表示は既定で有効である")
assert_true(type(built.ui.sprite_palette) == "table", "スプライトの色設定が定義される")
-- 戦闘時のHP分母表示は既定で非表示であることを確認する。
assert_true(built.ui.battle_hp_show_max == false, "戦闘時のHP分母表示は既定で無効である")
-- 未使用の設定は持たない。
assert_true(built.ui.battle_effects == nil, "未使用のbattle_effectsは設定に含めない")
-- 画像スプライト設定は廃止したため検証しない。
-- メニュー表示の既定値が設定に含まれることを確認する。
-- 比率ベースのメニュー設定が追加されたため検証内容を更新する。
assert_true(type(built.ui.menu) == "table", "メニュー表示の設定が定義される")
assert_true(type(built.ui.menu.width_ratio) == "number", "メニューの幅比率が数値で定義される")
assert_true(type(built.ui.menu.height_ratio) == "number", "メニューの高さ比率が数値で定義される")
assert_true(type(built.ui.menu.min_width) == "number", "メニューの最小幅が定義される")
assert_true(type(built.ui.menu.min_height) == "number", "メニューの最小高さが定義される")
assert_true(type(built.ui.menu.max_width) == "number", "メニューの最大幅が定義される")
assert_true(type(built.ui.menu.max_height) == "number", "メニューの最大高さが定義される")
assert_true(built.ui.menu.width_ratio == 0.52, "メニューの既定幅比率が設定される")
assert_true(built.ui.menu.height_ratio == 0.56, "メニューの既定高さ比率が設定される")
assert_true(built.ui.menu.min_width == 52, "メニューの既定最小幅が設定される")
assert_true(built.ui.menu.min_height == 16, "メニューの既定最小高さが設定される")
assert_true(built.ui.menu.max_width == 68, "メニューの既定最大幅が設定される")
assert_true(built.ui.menu.max_height == 26, "メニューの既定最大高さが設定される")
assert_true(built.ui.menu.padding == 2, "メニューの既定余白が設定される")
assert_true(built.ui.menu.border == "none", "メニューの既定境界線は最小表示である")
assert_true(type(built.ui.menu.theme) == "table", "メニューのテーマ設定が定義される")
assert_true(built.ui.menu.theme.inherit == true, "メニューのテーマ継承が既定で有効である")
assert_true(type(built.ui.menu.tabs) == "table", "タブ表示スタイルが定義される")
assert_true(built.ui.menu.tabs_position == "top", "タブ表示の既定位置が上部である")
assert_true(built.ui.menu.tabs.active_prefix == "󰐊", "タブの既定アクティブ接頭辞が定義される")
assert_true(built.ui.menu.tabs.active_suffix == "", "タブの既定アクティブ接尾辞が定義される")
assert_true(built.ui.menu.tabs.show_index == false, "タブの既定表示は番号を省略する")
assert_true(type(built.ui.menu.tabs.icons) == "table", "タブの既定アイコン設定が定義される")
assert_true(type(built.ui.menu.tabs.icons.status) == "string", "状態タブのアイコンが定義される")
assert_true(built.ui.menu.item_prefix == "󰜴 ", "項目選択の記号はアイコンを使う")
assert_true(type(built.ui.menu.meter) == "table", "メニューの進行バー設定が定義される")
assert_true(type(built.ui.menu.meter.on) == "string" and built.ui.menu.meter.on ~= "", "メニューの進行バーON記号が定義される")
assert_true(type(built.ui.menu.meter.off) == "string" and built.ui.menu.meter.off ~= "", "メニューの進行バーOFF記号が定義される")
-- 既定ジョブIDが初期化に含まれることを確認する。
assert_true(type(built.default_job_id) == "string", "既定ジョブIDが設定される")
-- 敵一覧はコンテンツ定義から生成し、二重管理を避ける。
assert_true(type(built.enemy_names) == "table", "敵一覧が設定に含まれる")
assert_true(#built.enemy_names == #(content.enemies or {}), "敵一覧は敵定義の件数と一致する")

print("OK")
