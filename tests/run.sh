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
BALANCE_GUIDE_FILE="${DOCS_DIR}/game_balance_tuning.md"

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

if [[ ! -f "${BALANCE_GUIDE_FILE}" ]]; then
  echo "バランス調整ガイドが見つかりません: ${BALANCE_GUIDE_FILE}" >&2
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
grep -q "^# " "${BALANCE_GUIDE_FILE}" || { echo "バランス調整ガイドに見出しがありません。" >&2; exit 1; }
grep -q "## 1. まず編集するファイル" "${BALANCE_GUIDE_FILE}" || { echo "バランス調整ガイドに編集起点の見出しがありません。" >&2; exit 1; }

if ! command -v lua >/dev/null 2>&1; then
  echo "Luaが見つかりません。/usr/bin/lua を用意してください。" >&2
  exit 1
fi

lua tests/test_config.lua
lua tests/test_balance_profile.lua
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
# 詳細画面が静的カード表示で描画されることを確認する。
lua tests/test_menu_static_detail_view.lua
# 横幅超過の文字列が省略されないことを確認する。
lua tests/test_menu_wrap.lua
# メニュー上部表示が折り返し回避のため幅を優先拡張することを確認する。
lua tests/test_menu_live_header_no_wrap.lua
# メニュー上部のライブトラック表示を確認する。
lua tests/test_menu_live_header.lua
# メニュー上部ライブヘッダのパレット色ハイライト適用を確認する。
lua tests/test_menu_live_header_highlight.lua
# クレジット表示が下から上へ流れ、中央寄せされることを確認する。
lua tests/test_menu_credits_crawl.lua
# メニュー選択アニメーションの位相切替を確認する。
lua tests/test_menu_selection_fx.lua
# アクティブタブの背景色を使わない強調表示を確認する。
lua tests/test_menu_tab_active_highlight.lua
# メニュー表示中はカーソルを隠し、終了時に復元することを確認する。
lua tests/test_menu_cursor_hidden.lua
# メニューのカーソルが選択記号の上に重ならないことを確認する。
lua tests/test_menu_cursor_position.lua
# メインメニューで先頭から上入力した際に末尾へ循環することを確認する。
lua tests/test_menu_tabs_wrap_navigation.lua
# タブ項目の整形関数へ行番号情報が渡されることを確認する。
lua tests/test_menu_tabs_format_index.lua
# メインタブが1カラム表示で描画されることを確認する。
lua tests/test_menu_tabs_detail_preview.lua
# 図鑑タブは常に1カラムで表示されることを確認する。
lua tests/test_menu_dex_single_column.lua
# 詳細プレビューがあってもEnterで項目実行を優先することを確認する。
lua tests/test_menu_enter_exec_priority.lua
# サブメニューで先頭から上入力した際に末尾へ循環することを確認する。
lua tests/test_menu_submenu_wrap_navigation.lua
# サブメニューが1カラム表示で描画されることを確認する。
lua tests/test_menu_submenu_style.lua
# サブメニューで2カラム指定した場合だけ詳細右カラムを表示することを確認する。
lua tests/test_menu_submenu_split_layout.lua
# メインメニューの横幅拡張と折り返し無効を確認する。
lua tests/test_menu_tabs_width_expand.lua
# タブ更新時にメニューの表示サイズが縮まないことを確認する。
lua tests/test_menu_tabs_stable_layout.lua
# ジョブ選択メニューが確定後に閉じないことを確認する。
lua tests/test_menu_job_keep_open.lua
# ジョブ選択画面で現在ジョブと変更差分が一覧表示されることを確認する。
lua tests/test_menu_job_compare_view.lua
# ジョブ選択メニューの詳細に選択後の比較情報が表示されることを確認する。
lua tests/test_menu_job_detail_preview.lua
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
# 図鑑タブの展開/折りたたみトグルを確認する。
lua tests/test_menu_dex_toggle.lua
# 設定タブの再読み込み項目がハンドラを呼ぶことを確認する。
lua tests/test_menu_config_reload.lua
# Read-only表示の単体テストを確認する。
lua tests/test_read_only.lua
# 閲覧専用状態から主導権を奪取できることを確認する。
lua tests/test_session_takeover.lua
# 公開APIの主導権奪取委譲を確認する。
lua tests/test_takeover_api.lua
# setupの自動開始抑止オプションを確認する。
lua tests/test_setup_skip_auto_start.lua
# reloadが二重起動せず再読込後の起動を1回だけ行うことを確認する。
lua tests/test_reload_single_start.lua
# 停止処理でメニューをサイレントに閉じることを確認する。
lua tests/test_engine_stop_menu_close.lua
# メニュー表示のデータ生成を確認する。
lua tests/test_menu_tabs_data.lua
# 操作タブと設定タブがカード風の行ラベルで整形されることを確認する。
lua tests/test_menu_action_config_style.lua
# メニューの状態タブに指標と進行バーが表示されることを確認する。
lua tests/test_menu_status_widgets.lua
# 図鑑データの単体テストを確認する。
lua tests/test_dex.lua
# 図鑑の表示モード切り替えを確認する。
lua tests/test_dex_view_mode.lua
# 図鑑の並び替えと検索フィルタを確認する。
lua tests/test_dex_sort_filter.lua
# 図鑑の達成率がドロップ解放率で更新されることを確認する。
lua tests/test_dex_drop_progress.lua
# 図鑑詳細がカード形式で表示されることを確認する。
lua tests/test_dex_detail_card.lua
# 購入メニューの分類と解錠判定を確認する。
lua tests/test_shop_purchase.lua
# スプライト表示の単体テストを確認する。
lua tests/test_sprites.lua
# 右下表示のクリック判定を確認する。
lua tests/test_ui_click.lua
# 右下表示を閉じる際にステージイントロも閉じることを確認する。
lua tests/test_ui_close_stage_intro.lua
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
# ステージ1-2で初期攻撃が一撃になりにくいことを確認する。
lua tests/test_stage1_floor2_balance.lua
# ステージ1序盤の経験値が過剰にならないことを確認する。
lua tests/test_stage1_exp_balance.lua
# 序盤の手応えと6-1以降の伸び過ぎ抑制を確認する。
lua tests/test_stage_balance_curve.lua
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
# ジョブ切替直後にステータスが変化しないことを確認する。
lua tests/test_job_change_no_stat_shift.lua
# スキル引き継ぎの単体テストを確認する。
lua tests/test_skill_unlock.lua
# スキル効果が戦闘計算に反映されることを確認する。
lua tests/test_skill_battle_effect.lua
# スキル選択画面で有効状態と効果内容が一覧表示されることを確認する。
lua tests/test_menu_skills_compare_view.lua
# 前ターンのスキル名が次ターンの攻撃名へ残らないことを確認する。
lua tests/test_battle_skill_label_reset.lua
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
# 装備選択画面で現在装備と変更差分が一覧表示されることを確認する。
lua tests/test_menu_equip_compare_view.lua
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
# ペットアイコンの左右反転表示を確認する。
lua tests/test_pet_icon_mirror.lua
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
