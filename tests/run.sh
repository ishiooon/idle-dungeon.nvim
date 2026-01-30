#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは要件定義、詳細要件、コンテンツ定義、設計の文書が存在し、最低限の見出しを含むことを確認する。
# さらに、Luaの単体テストを実行して基本ロジックの動作を確認する。
# ファイルの読み取りのみを行い、内容の変更は行わない。

ENV_ARG="${1:-}"
case "${ENV_ARG}" in
  --env=local|--env=localdev) ;;
  "")
    echo "引数に --env=local または --env=localdev を指定してください。" >&2
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
# メニュータブの文字列生成を確認する。
lua tests/test_menu_tabs.lua
# メニュー開閉の状態遷移を確認する。
lua tests/test_menu_toggle.lua
# Read-only表示の単体テストを確認する。
lua tests/test_read_only.lua
# メニュー表示のデータ生成を確認する。
lua tests/test_menu_tabs_data.lua
# 図鑑データの単体テストを確認する。
lua tests/test_dex.lua
# スプライト表示の単体テストを確認する。
lua tests/test_sprites.lua
# 画像スプライト選択の単体テストを確認する。
lua tests/test_image_sprite_picker.lua
# 階層進行の単体テストを確認する。
lua tests/test_floor_progress.lua
# リセット処理の単体テストを確認する。
lua tests/test_reset.lua

echo "OK: ドキュメントとLuaテストを確認しました。"
