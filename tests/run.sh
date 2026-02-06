#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは要件定義、詳細要件、コンテンツ定義、設計の文書が存在し、最低限の見出しを含むことを確認する。
# さらに、Luaの単体テストを実行して基本ロジックの動作を確認する。
# ファイルの読み取りのみを行い、内容の変更は行わない。

ENV_ARG="${1:-}"
case "${ENV_ARG}" in
  --env=localdev) ;;
  "")
    echo "引数に --env=localdev を指定してください。" >&2
    exit 1
    ;;
  *)
    echo "未対応の環境指定です: ${ENV_ARG}" >&2
    exit 1
    ;;
esac

DOCS_DIR="docs"
REQ_FILE="${DOCS_DIR}/requirements.md"
REQ_DETAIL_FILE="${DOCS_DIR}/requirements_detail.md"
CONTENT_FILE="${DOCS_DIR}/content.md"
DESIGN_FILE="${DOCS_DIR}/design.md"

if [[ ! -f "${REQ_FILE}" ]]; then
  echo "要件定義が見つかりません: ${REQ_FILE}" >&2
  exit 1
fi

if [[ ! -f "${REQ_DETAIL_FILE}" ]]; then
  echo "詳細要件定義が見つかりません: ${REQ_DETAIL_FILE}" >&2
  exit 1
fi

if [[ ! -f "${CONTENT_FILE}" ]]; then
  echo "コンテンツ定義が見つかりません: ${CONTENT_FILE}" >&2
  exit 1
fi

if [[ ! -f "${DESIGN_FILE}" ]]; then
  echo "設計書が見つかりません: ${DESIGN_FILE}" >&2
  exit 1
fi

grep -q "^# " "${REQ_FILE}" || { echo "要件定義に見出しがありません。" >&2; exit 1; }
grep -q "## 主要要件" "${REQ_FILE}" || { echo "要件定義に主要要件の見出しがありません。" >&2; exit 1; }
grep -q "^# " "${REQ_DETAIL_FILE}" || { echo "詳細要件定義に見出しがありません。" >&2; exit 1; }
grep -q "## 機能要件" "${REQ_DETAIL_FILE}" || { echo "詳細要件定義に機能要件の見出しがありません。" >&2; exit 1; }
grep -q "## 非機能要件" "${REQ_DETAIL_FILE}" || { echo "詳細要件定義に非機能要件の見出しがありません。" >&2; exit 1; }
grep -q "## 受け入れ基準" "${REQ_DETAIL_FILE}" || { echo "詳細要件定義に受け入れ基準の見出しがありません。" >&2; exit 1; }
grep -q "^# " "${CONTENT_FILE}" || { echo "コンテンツ定義に見出しがありません。" >&2; exit 1; }
grep -q "## キャラクター設計" "${CONTENT_FILE}" || { echo "コンテンツ定義にキャラクター設計の見出しがありません。" >&2; exit 1; }
grep -q "## 装備一覧" "${CONTENT_FILE}" || { echo "コンテンツ定義に装備一覧の見出しがありません。" >&2; exit 1; }
grep -q "## イベント一覧" "${CONTENT_FILE}" || { echo "コンテンツ定義にイベント一覧の見出しがありません。" >&2; exit 1; }
grep -q "## 全体構成" "${DESIGN_FILE}" || { echo "設計書に全体構成の見出しがありません。" >&2; exit 1; }
grep -q "## Git連携" "${DESIGN_FILE}" || { echo "設計書にGit連携の見出しがありません。" >&2; exit 1; }

if ! command -v lua >/dev/null 2>&1; then
  echo "Luaが見つかりません。/usr/bin/lua を用意してください。" >&2
  exit 1
fi

lua tests/test_config.lua
lua tests/test_i18n.lua
lua tests/test_auto_start.lua
lua tests/test_state.lua
lua tests/test_render.lua
# ペット表示は削除したため、該当テストは実行しない。
# メニュー表示のレイアウト生成を確認する。
lua tests/test_menu_layout.lua
# メニュー共通フレームの生成を確認する。
lua tests/test_menu_frame.lua
# サブメニューでは上部進捗を表示しないことを確認する。
lua tests/test_menu_submenu_header.lua
# 横幅超過の文字列が省略されないことを確認する。
lua tests/test_menu_wrap.lua
# メニュー上部のライブトラック表示を確認する。
lua tests/test_menu_live_header.lua
# ジョブ選択メニューが確定後に閉じないことを確認する。
lua tests/test_menu_job_keep_open.lua
# ステージ選択メニューが確定後に閉じないことを確認する。
lua tests/test_menu_stage_keep_open.lua
# メニュータブの文字列生成を確認する。
lua tests/test_menu_tabs.lua
# メニュー開閉の状態遷移を確認する。
lua tests/test_menu_toggle.lua
# メニューの開閉状態とクローズコールバックを確認する。
lua tests/test_menu_open_state.lua
# メニューのサブ画面から戻れることを確認する。
lua tests/test_menu_action_back.lua
# Read-only表示の単体テストを確認する。
lua tests/test_read_only.lua
# 閲覧専用状態から主導権を奪取できることを確認する。
lua tests/test_session_takeover.lua
# 公開APIの主導権奪取委譲を確認する。
lua tests/test_takeover_api.lua
# メニュー表示のデータ生成を確認する。
lua tests/test_menu_tabs_data.lua
# メニューの状態タブに指標と進行バーが表示されることを確認する。
lua tests/test_menu_status_widgets.lua
# 図鑑データの単体テストを確認する。
lua tests/test_dex.lua
# 購入メニューの分類と解錠判定を確認する。
lua tests/test_shop_purchase.lua
# スプライト表示の単体テストを確認する。
lua tests/test_sprites.lua
# 右下表示のクリック判定を確認する。
lua tests/test_ui_click.lua
# 進行トラックの単体テストを確認する。
lua tests/test_track.lua
# メニューの入力統計表示を確認する。
lua tests/test_menu_metrics.lua
# 入力差分の加算処理を確認する。
lua tests/test_metrics_delta.lua
# ステージの敵プール選択を確認する。
lua tests/test_enemy_pool.lua
# ステージ1の敵と初期装備のバランス基準を確認する。
lua tests/test_stage1_balance.lua
# 敵データの件数と必須項目を確認する。
lua tests/test_enemy_content.lua
# 敵ごとの経験値倍率を確認する。
lua tests/test_enemy_exp_reward.lua
# 敵ごとの固有スキルを確認する。
lua tests/test_enemy_skill_templates.lua
# 攻撃速度と行動回数差の単体テストを確認する。
lua tests/test_attack_speed.lua
# 攻撃演出の時刻が速度上昇に追従することを確認する。
lua tests/test_attack_frame_timing.lua
# ジョブ定義の不要情報が含まれないことを確認する。
# キャラクター定義のテストはジョブ定義へ置き換える。
lua tests/test_job_content.lua
# ジョブ経験値とレベル進行の単体テストを確認する。
lua tests/test_job_progress.lua
# スキル引き継ぎの単体テストを確認する。
lua tests/test_skill_unlock.lua
# スキル効果が戦闘計算に反映されることを確認する。
lua tests/test_skill_battle_effect.lua
# パッシブ補正が掛け算で合成されることを確認する。
lua tests/test_skill_passive_multiplier.lua
# ジョブごとのレベル一覧が生成されることを確認する。
lua tests/test_job_level_lines.lua
# 装備データの件数とドロップ紐付けを確認する。
lua tests/test_item_content.lua
# 装備解放条件が定義から生成されることを確認する。
lua tests/test_item_unlock_rules.lua
# 入力統計の除外設定を確認する。
lua tests/test_input_ignore.lua
# 階層内の敵配置の単体テストを確認する。
lua tests/test_floor_enemies.lua
# 階層進行の単体テストを確認する。
lua tests/test_floor_progress.lua
# リセット処理の単体テストを確認する。
lua tests/test_reset.lua
# 画像スプライトの単体テストは廃止したため実行しない。
# ステージ解放の単体テストを確認する。
lua tests/test_stage_unlock.lua
# ステージ導入文のストーリー定義を確認する。
lua tests/test_stage_intro_story.lua
# スプライトの色割当ルールを確認する。
lua tests/test_sprite_highlight.lua
# 装備変更の詳細表示を確認する。
lua tests/test_equip_detail.lua
# 装備詳細の解放条件表示を確認する。
lua tests/test_menu_detail_unlock.lua
# ステージのボス設定が有効であることを確認する。
lua tests/test_boss_config.lua
# メニューのヒント文言とトグル表記を確認する。
lua tests/test_menu_hints.lua
# メニューのゲーム速度切り替えを確認する。
lua tests/test_menu_game_speed.lua
# 戦利品ドロップの単体テストを確認する。
lua tests/test_loot.lua
# 戦闘中の情報表示を確認する。
lua tests/test_battle_info.lua
# 戦闘中の進行トラック演出を確認する。
lua tests/test_battle_track_effect.lua
# 戦闘結果の表示待機を確認する。
lua tests/test_battle_outcome_wait.lua
# 敗北時のアイコン表示を確認する。
lua tests/test_defeat_icon.lua
# 敵敗北時のアイコン表示を確認する。
lua tests/test_enemy_defeat_icon.lua
# ペットの獲得・保持・戦闘参加の振る舞いを確認する。
lua tests/test_pet_party.lua
# ペット追従のトラック表示を確認する。
lua tests/test_pet_track.lua
# 図鑑の未発見表示を確認する。
lua tests/test_dex_unknown.lua
# 属性相性の単体テストを確認する。
lua tests/test_element_chart.lua
# イベント効果の単体テストを確認する。
lua tests/test_event_effects.lua
# 選択イベントの単体テストを確認する。
lua tests/test_choice_event.lua
# 文字列切り詰めのUTF-8対応を確認する。
lua tests/test_util_clamp.lua

echo "OK: ドキュメントとLuaテストを確認しました。"
