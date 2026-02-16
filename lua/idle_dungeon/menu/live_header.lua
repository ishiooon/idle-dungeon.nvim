-- このモジュールはメニュー上部に表示するライブヘッダを生成する。
-- 右下表示と同じ描画関数を使い、表示差分が生まれないようにする。
local render = require("idle_dungeon.ui.render")

local M = {}

-- メニュー内でも描画モードのみvisualへ固定し、右下表示と同じ情報を取得する。
local function build_menu_header_state(state, lang)
  local ui = state.ui or {}
  return {
    actor = state.actor,
    combat = state.combat,
    currency = state.currency,
    metrics = state.metrics,
    pet_party = state.pet_party,
    progress = state.progress,
    ui = {
      language = lang or ui.language,
      mode = ui.mode,
      read_only = ui.read_only,
      render_mode = "visual",
      event_id = ui.event_id,
      event_message = ui.event_message,
      event_message_remaining = ui.event_message_remaining,
      choice_remaining = ui.choice_remaining,
      battle_hp_show_max = ui.battle_hp_show_max,
    },
  }
end

local function build_lines(state, config, lang)
  if not state then
    return {}
  end
  -- 右下表示と同一モジュールの2行をそのまま返して、表示内容を完全同期させる。
  return render.build_lines(build_menu_header_state(state, lang), config or {})
end

M.build_lines = build_lines

return M
