-- このモジュールはメニュー表示に必要な文言を整形する。
-- メニュー表示が参照する進行情報はgame配下へまとめる。
local i18n = require("idle_dungeon.i18n")
-- 階層進行の計算はgame/floor/progressに委譲する。
local content = require("idle_dungeon.content")
local game_speed = require("idle_dungeon.core.game_speed")
local floor_progress = require("idle_dungeon.game.floor.progress")
local time_format = require("idle_dungeon.ui.time_format")
local render_stage = require("idle_dungeon.ui.render_stage")
local stage_progress = require("idle_dungeon.game.stage_progress")
local util = require("idle_dungeon.util")

local M = {}

local function with_hint_icon(icon, text)
  if not icon or icon == "" then
    return text
  end
  return string.format("%s %s", icon, text or "")
end

local function resolve_lang(state, config)
  return (state.ui or {}).language or (config.ui or {}).language or "en"
end

local function slot_label(slot, lang)
  local map = {
    weapon = "slot_weapon",
    armor = "slot_armor",
    accessory = "slot_accessory",
    companion = "slot_companion",
  }
  return i18n.t(map[slot] or slot, lang)
end

local function auto_start_label(auto_start, lang)
  local status_key = auto_start and "status_on" or "status_off"
  local title = i18n.t("menu_action_auto_start", lang)
  local status = i18n.t(status_key, lang)
  return string.format("%s: %s", title, status)
end

-- 表示行数を見やすいラベルに整形する。
local function display_lines_label(lines, lang)
  local count = math.max(math.min(tonumber(lines) or 2, 2), 0)
  local title = i18n.t("menu_action_display_lines", lang)
  local is_ja = lang == "ja" or lang == "jp"
  if count == 0 then
    local suffix = is_ja and "非表示" or "Hidden"
    return string.format("%s: %s", title, suffix)
  end
  local suffix = is_ja and string.format("%d行", count) or string.format("%d line%s", count, count == 1 and "" or "s")
  return string.format("%s: %s", title, suffix)
end

-- ゲーム速度の設定値を見やすいラベルに整形する。
local function game_speed_label(state, config, lang)
  local speed_id = game_speed.resolve_game_speed_id(state, config)
  local speed = game_speed.label_from_id(speed_id, config)
  local title = i18n.t("menu_action_game_speed", lang)
  return string.format("%s: %s", title, speed)
end

-- トグル表示をボタン風の文言へ整形する。
local function toggle_label(title, enabled, lang)
  local status_key = enabled and "status_on" or "status_off"
  local status = i18n.t(status_key, lang)
  return string.format("%s: [ %s ]", title, status)
end

-- 入力統計の表示行を組み立てる。
local function build_metrics_lines(metrics, lang)
  local result = {}
  local safe_metrics = metrics or {}
  table.insert(result, string.format("%s %d", i18n.t("label_chars", lang), safe_metrics.chars or 0))
  table.insert(result, string.format("%s %d", i18n.t("label_saves", lang), safe_metrics.saves or 0))
  table.insert(result, string.format("%s %s", i18n.t("label_time", lang), time_format.format_seconds(safe_metrics.time_sec or 0, lang)))
  local filetypes = util.shallow_copy(safe_metrics.filetypes or {})
  local entries = {}
  for filetype, count in pairs(filetypes) do
    if tonumber(count) and count > 0 then
      table.insert(entries, { filetype = filetype, count = count })
    end
  end
  table.sort(entries, function(a, b)
    if a.count == b.count then
      return (a.filetype or "") < (b.filetype or "")
    end
    return a.count > b.count
  end)
  if #entries > 0 then
    local parts = {}
    for index = 1, math.min(#entries, 5) do
      local entry = entries[index]
      table.insert(parts, string.format("%s:%d", entry.filetype, entry.count))
    end
    table.insert(result, string.format("%s %s", i18n.t("label_filetypes", lang), table.concat(parts, " / ")))
  end
  return result
end

-- 入力統計の詳細表示用に行をまとめる。
local function build_metrics_detail_lines(metrics, lang)
  local safe_metrics = metrics or {}
  local lines = {
    string.format("%s %d", i18n.t("label_chars", lang), safe_metrics.chars or 0),
    string.format("%s %d", i18n.t("label_saves", lang), safe_metrics.saves or 0),
    string.format("%s %s", i18n.t("label_time", lang), time_format.format_seconds(safe_metrics.time_sec or 0, lang)),
  }
  local filetypes = util.shallow_copy(safe_metrics.filetypes or {})
  local entries = {}
  for filetype, count in pairs(filetypes) do
    if tonumber(count) and count > 0 then
      table.insert(entries, { filetype = filetype, count = count })
    end
  end
  table.sort(entries, function(a, b)
    if a.count == b.count then
      return (a.filetype or "") < (b.filetype or "")
    end
    return a.count > b.count
  end)
  if #entries == 0 then
    table.insert(lines, i18n.t("metrics_detail_empty", lang))
    return lines
  end
  table.insert(lines, i18n.t("label_filetypes", lang))
  for _, entry in ipairs(entries) do
    table.insert(lines, string.format("  %s: %d", entry.filetype, entry.count))
  end
  return lines
end

-- メニュー下部の案内文を行配列で返す。
local function menu_footer_hints(lang)
  return {
    with_hint_icon("󰌑", i18n.t("menu_hint_tabs", lang)),
    with_hint_icon("󰁍", i18n.t("menu_hint_toggle", lang)),
    with_hint_icon("󰅖", i18n.t("menu_hint_close", lang)),
  }
end

-- 子画面用の操作案内を返す。
local function submenu_footer_hints(lang)
  return {
    with_hint_icon("󰌑", i18n.t("menu_hint_select", lang)),
    with_hint_icon("󰁍", i18n.t("menu_hint_back", lang)),
    with_hint_icon("󰅖", i18n.t("menu_hint_close", lang)),
  }
end

-- メニュー内の状態表示用の行を組み立てる。
local function status_lines(state, lang, config)
  local progress = state.progress or {}
  local actor = state.actor or {}
  local currency = state.currency or {}
  -- ステージ長を参照して進行度を表示する。
  local _, stage = stage_progress.find_stage_index((config or {}).stages or {}, progress)
  local stage_progress_text = render_stage.build_stage_progress_text(progress, stage, config)
  local stage_name = render_stage.resolve_stage_name(stage, progress, lang)
  -- 階層番号と階層内の進行を表示に反映する。
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local floor_index = floor_progress.floor_index(progress.distance or 0, floor_length)
  local floor_step = floor_progress.floor_step(progress.distance or 0, floor_length)
  local floor_number = floor_index + 1
  local floor_text = tostring(floor_number)
  local step_text = string.format("%d/%d", floor_step, floor_length)
  local auto_start_key = (state.ui and state.ui.auto_start ~= false) and "status_on" or "status_off"
  -- 現在選択中のジョブ名を表示用に取得する。
  local job_name = nil
  for _, job in ipairs(content.jobs or {}) do
    if job.id == actor.id then
      job_name = job.name
      break
    end
  end
  local lines = {
    string.format("%s %s", i18n.t("label_stage", lang), stage_name),
    string.format("%s %s", i18n.t("label_progress", lang), stage_progress_text),
    string.format("%s %s", i18n.t("label_floor", lang), floor_text),
    string.format("%s %s", i18n.t("label_floor_step", lang), step_text),
    string.format("%s %d", i18n.t("label_level", lang), actor.level or 1),
    string.format("%s %d/%d", i18n.t("label_exp", lang), actor.exp or 0, actor.next_level or 0),
    string.format("%s %s", i18n.t("label_job", lang), job_name or ""),
    string.format("%s %d", i18n.t("label_job_level", lang), actor.job_level or 1),
    string.format("%s %d/%d", i18n.t("label_job_exp", lang), actor.job_exp or 0, actor.job_next_level or 0),
    string.format("%s %d/%d", i18n.t("label_hp", lang), actor.hp or 0, actor.max_hp or 0),
    string.format("%s %d", i18n.t("label_atk", lang), actor.atk or 0),
    string.format("%s %d", i18n.t("label_def", lang), actor.def or 0),
    string.format("%s %d", i18n.t("label_gold", lang), currency.gold or 0),
    string.format("%s %s", i18n.t("label_mode", lang), state.ui and state.ui.mode or ""),
    string.format("%s %s", i18n.t("label_render", lang), state.ui and state.ui.render_mode or ""),
    string.format("%s %s", i18n.t("label_auto_start", lang), i18n.t(auto_start_key, lang)),
  }
  for _, line in ipairs(build_metrics_lines(state.metrics or {}, lang)) do
    table.insert(lines, line)
  end
  return lines
end

M.resolve_lang = resolve_lang
M.slot_label = slot_label
M.auto_start_label = auto_start_label
M.display_lines_label = display_lines_label
M.game_speed_label = game_speed_label
-- ジョブごとのレベル表示を一覧で返す。
local function build_job_level_lines(state, lang, jobs)
  local levels = state.job_levels or {}
  local lines = {}
  for _, job in ipairs(jobs or {}) do
    local progress = levels[job.id] or { level = 1 }
    table.insert(lines, string.format("%s Lv%d", job.name or "", progress.level or 1))
  end
  if #lines == 0 then
    table.insert(lines, i18n.t("menu_job_levels_empty", lang))
  end
  return lines
end

M.toggle_label = toggle_label
M.menu_footer_hints = menu_footer_hints
M.submenu_footer_hints = submenu_footer_hints
M.status_lines = status_lines
M.build_metrics_detail_lines = build_metrics_detail_lines
M.build_job_level_lines = build_job_level_lines

return M
