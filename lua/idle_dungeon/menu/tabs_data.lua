-- このモジュールはメニュー表示に必要なデータを純粋関数として生成する。
-- 図鑑とメニューの参照先は関心ごとに整理する。
local dex_catalog = require("idle_dungeon.game.dex.catalog")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")
local floor_progress = require("idle_dungeon.game.floor.progress")
local render_stage = require("idle_dungeon.ui.render_stage")
local stage_progress = require("idle_dungeon.game.stage_progress")
local util = require("idle_dungeon.util")

local M = {}

local function clamp_ratio(current, total)
  local safe_total = math.max(tonumber(total) or 0, 0)
  if safe_total <= 0 then
    return 0
  end
  local safe_current = math.max(tonumber(current) or 0, 0)
  return math.max(math.min(safe_current / safe_total, 1), 0)
end

local function resolve_meter_style(config)
  local menu = ((config or {}).ui or {}).menu or {}
  local style = menu.meter or {}
  return {
    on = style.on or "▰",
    off = style.off or "▱",
  }
end

local function align_label(label, label_width)
  local text = label or ""
  local width = math.max(tonumber(label_width) or 0, 0)
  if width <= 0 then
    return text
  end
  local gap = width - util.display_width(text)
  if gap <= 0 then
    return text
  end
  return text .. string.rep(" ", gap)
end

local function build_meter(label, current, total, width, suffix, meter_style, label_width)
  local bar_width = math.max(tonumber(width) or 14, 6)
  local ratio = clamp_ratio(current, total)
  local filled = math.floor(ratio * bar_width + 0.5)
  local empty = math.max(bar_width - filled, 0)
  local style = meter_style or { on = "▰", off = "▱" }
  local bar = string.format("[%s%s]", string.rep(style.on, filled), string.rep(style.off, empty))
  local tail = suffix or string.format("%d/%d", math.floor(current or 0), math.floor(total or 0))
  return string.format("%s %s %s", align_label(label, label_width), bar, tail)
end

local function with_icon(icon, text)
  local safe_icon = icon or ""
  local safe_text = text or ""
  if safe_icon == "" then
    return safe_text
  end
  return string.format("%s %s", safe_icon, safe_text)
end

local function resolve_stage_info(state, config, lang)
  local progress = state.progress or {}
  local _, stage = stage_progress.find_stage_index((config or {}).stages or {}, progress)
  local stage_name = render_stage.resolve_stage_name(stage, progress, lang)
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local stage_floor = floor_progress.stage_floor_distance(progress, floor_length)
  local current_floor = math.max(stage_floor + 1, 1)
  local total_floors = floor_progress.stage_total_floors(stage, floor_length)
  local stage_ratio = clamp_ratio(current_floor, total_floors or 0)
  local stage_text = render_stage.build_stage_progress_text(progress, stage, config)
  local floor_step = floor_progress.floor_step(progress.distance or 0, floor_length)
  return {
    name = stage_name,
    text = stage_text,
    ratio = stage_ratio,
    current_floor = current_floor,
    total_floors = total_floors or 0,
    floor_step = floor_step,
    floor_length = floor_length,
  }
end

local function build_status_detail(item, state, config, lang)
  if item.id == "metrics_detail" then
    return {
      title = i18n.t("metrics_detail_title", lang),
      lines = menu_locale.build_metrics_detail_lines(state.metrics or {}, lang),
    }
  end
  return nil
end

local function build_action_items()
  return {
    -- 操作系はメニューを閉じてから各サブメニューを開く。
    { id = "equip", key = "menu_action_equip", icon = "󰓥" },
    { id = "stage", key = "menu_action_stage", icon = "󰝰" },
    { id = "purchase", key = "menu_action_purchase", icon = "󰏓" },
    { id = "sell", key = "menu_action_sell", icon = "󰆏" },
    -- ジョブ変更は専用メニューで扱う。
    { id = "job", key = "menu_action_job", icon = "󰘧" },
    -- 習得済みスキルの切り替え用メニューを追加する。
    { id = "skills", key = "menu_action_skills", icon = "󰌵" },
    { id = "job_levels", key = "menu_action_job_levels", icon = "󰁨" },
  }
end

local function build_config_items()
  return {
    { id = "toggle_text", key = "menu_action_toggle_text", keep_open = true, kind = "toggle", icon = "󰘎" },
    { id = "auto_start", key = "menu_action_auto_start", keep_open = true, kind = "toggle", icon = "󰐊" },
    { id = "game_speed", key = "menu_action_game_speed", keep_open = true, kind = "cycle", icon = "󰓅" },
    { id = "display_lines", key = "menu_action_display_lines", keep_open = true, kind = "toggle", icon = "󰍹" },
    -- 戦闘中のHP分母表示を切り替える設定を追加する。
    { id = "battle_hp_show_max", key = "menu_action_battle_hp_show_max", keep_open = true, kind = "toggle", icon = "󰓣" },
    -- 設定系は閉じずに選択できるようkeep_openで維持する。
    { id = "language", key = "menu_action_language", keep_open = true, icon = "󰗊" },
    { id = "reset", key = "menu_action_reset", keep_open = true, icon = "󰑐" },
    { id = "reload_plugin", key = "menu_action_reload_plugin", keep_open = true, icon = "󰓭" },
  }
end

-- クレジット表示用のアスキーアートを定義する。
local function build_credits_art()
  return {
    -- 作品名の表記は IdleDungeon に統一する。
    "=== IdleDungeon ===",
    " ___ ____  _____ _       ____  _   _ _   _  ____  _   _ ",
    "|_ _|  _ \\| ____| |     |  _ \\| | | | \\ | |/ ___|| | | |",
    " | || | | |  _| | |     | | | | | | |  \\| | |  _ | | | |",
    " | || |_| | |___| |___  | |_| | |_| | |\\  | |_| || |_| |",
    "|___|____/|_____|_____| |____/ \\___/|_| \\_|\\____| \\___/ ",
  }
end

-- 状態タブ用の行をまとめて返す。
local function build_status_items(state, config, lang)
  local items = {}
  local stage_info = resolve_stage_info(state, config, lang)
  local actor = state.actor or {}
  local meter_style = resolve_meter_style(config)
  local hp_label = with_icon("󰓣", i18n.t("label_hp", lang))
  local exp_label = with_icon("", i18n.t("label_exp", lang))
  local meter_label_width = math.max(util.display_width(hp_label), util.display_width(exp_label))
  table.insert(items, { id = "header", label = with_icon("󰀘", lang == "ja" and "ヒーロー" or "Hero") })
  table.insert(items, {
    id = "entry",
    label = with_icon("󰁨", string.format("%s %d  %s %d", i18n.t("label_level", lang), actor.level or 1, i18n.t("label_job_level", lang), actor.job_level or 1)),
  })
  table.insert(items, {
    id = "entry",
    label = build_meter(hp_label, actor.hp or 0, actor.max_hp or 0, 14, nil, meter_style, meter_label_width),
  })
  table.insert(items, {
    id = "entry",
    label = build_meter(exp_label, actor.exp or 0, actor.next_level or 0, 14, nil, meter_style, meter_label_width),
  })
  table.insert(items, {
    id = "entry",
    label = with_icon("󰓥", string.format("%s %d  %s %d", i18n.t("label_atk", lang), actor.atk or 0, i18n.t("label_def", lang), actor.def or 0)),
  })
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = with_icon("󰑓", lang == "ja" and "進行" or "Progress") })
  table.insert(items, {
    id = "entry",
    label = with_icon("󰝰", string.format("%s %s", i18n.t("label_stage", lang), stage_info.name)),
  })
  table.insert(items, {
    id = "entry",
    label = build_meter(with_icon("󰢚", i18n.t("label_progress", lang)), stage_info.current_floor, stage_info.total_floors, 14, stage_info.text, meter_style),
  })
  table.insert(items, {
    id = "entry",
    label = with_icon("󰳞", string.format("%s %d/%d", i18n.t("label_floor_step", lang), stage_info.floor_step, stage_info.floor_length)),
  })
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = with_icon("󱂬", lang == "ja" and "入力統計" or "Input Metrics") })
  local metrics_lines = menu_locale.build_metrics_detail_lines(state.metrics or {}, lang)
  for index, line in ipairs(metrics_lines) do
    if index > 3 then
      break
    end
    table.insert(items, { id = "entry", label = line })
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, {
    id = "metrics_detail",
    label = with_icon("󰈞", i18n.t("menu_status_metrics", lang)),
    detail_title = i18n.t("metrics_detail_title", lang),
    detail_lines = metrics_lines,
    keep_open = true,
  })
  return items
end

-- クレジットタブで表示する行をまとめる。
local function build_credits_items(lang)
  local items = {}
  for _, line in ipairs(build_credits_art()) do
    table.insert(items, { id = "art", label = line })
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = i18n.t("credits_title", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_created", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_ui", lang) })
  -- 画像スプライト参照の表示は廃止した。
  table.insert(items, { id = "entry", label = i18n.t("credits_line_thanks", lang) })
  return items
end

local function count_known(entries)
  local known = 0
  local total = #entries
  for _, entry in ipairs(entries or {}) do
    if entry and entry.known then
      known = known + 1
    end
  end
  return known, total
end

local function pad_right(text, width)
  local safe_text = text or ""
  local safe_width = math.max(tonumber(width) or 0, 0)
  local gap = safe_width - util.display_width(safe_text)
  if gap <= 0 then
    return safe_text
  end
  return safe_text .. string.rep(" ", gap)
end

local function build_inline_meter(current, total, width, meter_style)
  local ratio = clamp_ratio(current, total)
  local bar_width = math.max(tonumber(width) or 10, 6)
  local filled = math.floor(ratio * bar_width + 0.5)
  local empty = math.max(bar_width - filled, 0)
  local style = meter_style or { on = "▰", off = "▱" }
  return string.rep(style.on, filled) .. string.rep(style.off, empty)
end

local function rarity_icon(rarity)
  if rarity == "rare" then
    return "󰎵"
  end
  if rarity == "pet" then
    return "󰚩"
  end
  return "󰄴"
end

local function slot_icon(slot)
  if slot == "weapon" then
    return "󰓥"
  end
  if slot == "armor" then
    return ""
  end
  if slot == "accessory" then
    return "󰓒"
  end
  if slot == "companion" then
    return "󰠳"
  end
  return "󰏫"
end

local function build_enemy_tile_label(entry, index, unknown_label)
  local known = entry and entry.known ~= false
  local icon = known and ((entry and entry.icon) or "") or ""
  if icon == "" then
    icon = known and "󰆈" or "󰇘"
  end
  local name = known and (entry.name or unknown_label) or unknown_label
  local element_text = known and (entry.element_label or unknown_label) or unknown_label
  local count_text = known and tostring(tonumber(entry and entry.count) or 0) or "?"
  local index_text = string.format("%03d", tonumber(index) or 0)
  local name_col = pad_right(util.clamp_line(name, 16), 16)
  local element_col = pad_right(util.clamp_line(element_text, 8), 8)
  return string.format("№%s  %s %s [%s] ×%s", index_text, icon, name_col, element_col, count_text)
end

local function build_item_tile_label(entry, index, unknown_label)
  local known = entry and entry.known ~= false
  local icon = known and ((entry and entry.icon) or "") or ""
  if icon == "" then
    icon = known and "󰏫" or "󰇘"
  end
  local name = known and (entry.name or unknown_label) or unknown_label
  local count_text = known and tostring(tonumber(entry and entry.count) or 0) or "?"
  local index_text = string.format("%03d", tonumber(index) or 0)
  local slot_mark = slot_icon(entry and entry.slot)
  local rarity_mark = rarity_icon(entry and entry.rarity)
  local name_col = pad_right(util.clamp_line(name, 16), 16)
  return string.format("№%s  %s %s %s%s ×%s", index_text, icon, name_col, slot_mark, rarity_mark, count_text)
end

local function build_dex_summary_line(icon, title, known, total, meter_style)
  local meter = build_inline_meter(known, total, 10, meter_style)
  local title_col = pad_right(util.clamp_line(title, 8), 8)
  local count_col = string.format("%3d/%-3d", tonumber(known) or 0, tonumber(total) or 0)
  return string.format("%s %s %s [%s]", icon, title_col, count_col, pad_right(meter, 10))
end

local function build_dex_summary_pair(lang, known_enemy, total_enemy, known_item, total_item, meter_style)
  local enemy = build_dex_summary_line("󰆧", i18n.t("dex_title_enemies", lang), known_enemy, total_enemy, meter_style)
  local item = build_dex_summary_line("󰓥", i18n.t("dex_title_items", lang), known_item, total_item, meter_style)
  return enemy .. "   " .. item
end

local function pick_dex_entries(entries, known_limit, unknown_limit)
  local visible = {}
  local known_count = 0
  local unknown_count = 0
  local hidden = 0
  for index, entry in ipairs(entries or {}) do
    local known = entry and entry.known == true
    if known then
      if known_count < known_limit then
        table.insert(visible, { entry = entry, index = index })
      else
        hidden = hidden + 1
      end
      known_count = known_count + 1
    else
      if unknown_count < unknown_limit then
        table.insert(visible, { entry = entry, index = index })
      else
        hidden = hidden + 1
      end
      unknown_count = unknown_count + 1
    end
  end
  return visible, hidden
end

local function build_more_label(hidden_count, lang)
  local safe_hidden = math.max(tonumber(hidden_count) or 0, 0)
  if safe_hidden <= 0 then
    return ""
  end
  if lang == "ja" then
    return string.format("󰇘 さらに %d 件は省略表示中", safe_hidden)
  end
  return string.format("󰇘 %d more entries are collapsed", safe_hidden)
end

local function build_dex_toggle_label(lang, kind, expand, hidden_count)
  local safe_hidden = math.max(tonumber(hidden_count) or 0, 0)
  local target = kind == "enemy" and i18n.t("dex_title_enemies", lang) or i18n.t("dex_title_items", lang)
  if lang == "ja" then
    if expand then
      return string.format("▶ %sを展開表示 (%d件)", target, safe_hidden)
    end
    return string.format("▼ %sを折りたたむ", target)
  end
  if expand then
    return string.format("▶ Expand %s (%d hidden)", target, safe_hidden)
  end
  return string.format("▼ Collapse %s", target)
end

-- レアリティの表示名を整形する。
local function rarity_label(rarity, lang)
  if rarity == "rare" then
    return i18n.t("dex_rarity_rare", lang)
  end
  if rarity == "pet" then
    return i18n.t("dex_rarity_pet", lang)
  end
  return i18n.t("dex_rarity_common", lang)
end

-- 図鑑の詳細表示用に行を組み立てる。
local function build_detail_lines(entry, kind, lang, unknown_label)
  local lines = {}
  local name_label = i18n.t("dex_detail_name", lang)
  local type_label = i18n.t("dex_detail_type", lang)
  local count_label = i18n.t("dex_detail_count", lang)
  local element_label = i18n.t("dex_detail_element", lang)
  local flavor_label = i18n.t("dex_detail_flavor", lang)
  local drops_label = i18n.t("dex_label_drops", lang)
  local type_value = kind == "enemy" and i18n.t("dex_detail_kind_enemy", lang) or i18n.t("dex_detail_kind_item", lang)
  local is_known = entry and entry.known ~= false
  table.insert(lines, string.format("%s %s", type_label, type_value))
  if not is_known then
    table.insert(lines, string.format("%s %s", name_label, unknown_label))
    table.insert(lines, string.format("%s %s", count_label, unknown_label))
    if kind == "item" then
      table.insert(lines, string.format("%s %s", i18n.t("dex_detail_slot", lang), unknown_label))
      table.insert(lines, string.format("%s %s", i18n.t("dex_detail_rarity", lang), unknown_label))
    else
      table.insert(lines, string.format("%s %s", drops_label, unknown_label))
    end
    return lines
  end
  table.insert(lines, string.format("%s %s", name_label, entry.name or ""))
  table.insert(lines, string.format("%s %d", count_label, tonumber(entry.count) or 0))
  if entry.element_label and entry.element_label ~= "" then
    table.insert(lines, string.format("%s %s", element_label, entry.element_label))
  end
  if kind == "item" then
    local slot_label = i18n.t("dex_detail_slot", lang)
    local rarity_text = i18n.t("dex_detail_rarity", lang)
    local slot_text = entry.slot and menu_locale.slot_label(entry.slot, lang) or ""
    local rarity_text_value = rarity_label(entry.rarity, lang)
    if slot_text ~= "" then
      table.insert(lines, string.format("%s %s", slot_label, slot_text))
    end
    table.insert(lines, string.format("%s %s", rarity_text, rarity_text_value))
  end
  if kind == "enemy" then
    local parts = {}
    for _, drop in ipairs(entry.drops or {}) do
      table.insert(parts, drop.name or "")
    end
    if #parts > 0 then
      table.insert(lines, string.format("%s %s", drops_label, table.concat(parts, ", ")))
    end
  end
  if entry.flavor and entry.flavor ~= "" then
    table.insert(lines, string.format("%s %s", flavor_label, entry.flavor))
  end
  return lines
end

-- 図鑑タブで表示する敵と装備の一覧を生成する。
local function build_dex_items(state, config, lang, view_state)
  local items = {}
  local enemy_entries = dex_catalog.build_enemy_entries(state, lang)
  local item_entries = dex_catalog.build_item_entries(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local meter_style = resolve_meter_style(config)
  local dex_view = view_state or {}
  local show_all_enemies = dex_view.show_all_enemies == true
  local show_all_items = dex_view.show_all_items == true
  local menu_config = ((config or {}).ui or {}).menu or {}
  local dex_known_limit = math.max(tonumber(menu_config.dex_known_limit) or 10, 4)
  local dex_unknown_limit = math.max(tonumber(menu_config.dex_unknown_limit) or 2, 0)
  local known_enemy, total_enemy = count_known(enemy_entries)
  local known_item, total_item = count_known(item_entries)
  table.insert(items, {
    id = "header",
    label = build_dex_summary_pair(lang, known_enemy, total_enemy, known_item, total_item, meter_style),
  })
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = string.format("— %s —", i18n.t("dex_title_enemies", lang)) })
  if #enemy_entries == 0 then
    table.insert(items, { id = "empty", label = i18n.t("dex_empty_enemies", lang) })
  else
    local enemy_visible, enemy_hidden = pick_dex_entries(
      enemy_entries,
      show_all_enemies and #enemy_entries or dex_known_limit,
      show_all_enemies and #enemy_entries or dex_unknown_limit
    )
    for _, picked in ipairs(enemy_visible) do
      local entry = picked.entry
      local index = picked.index
      local element_key = entry.known and ("element_" .. (entry.element_id or "normal")) or nil
      table.insert(items, {
        id = "dex_entry",
        kind = "enemy",
        label = build_enemy_tile_label(entry, index, unknown_label),
        tile_label = build_enemy_tile_label(entry, index, unknown_label),
        detail_title = entry.known and entry.name or unknown_label,
        detail_lines = build_detail_lines(entry, "enemy", lang, unknown_label),
        highlight_key = element_key,
        highlight_icon = entry.icon or "",
        keep_open = true,
      })
    end
    if enemy_hidden > 0 or show_all_enemies then
      table.insert(items, {
        id = "dex_control",
        kind = "enemy",
        action = show_all_enemies and "collapse_enemy" or "expand_enemy",
        label = build_dex_toggle_label(lang, "enemy", not show_all_enemies, enemy_hidden),
        keep_open = true,
      })
      if enemy_hidden > 0 and not show_all_enemies then
        table.insert(items, { id = "header", label = build_more_label(enemy_hidden, lang) })
      end
    end
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = string.format("— %s —", i18n.t("dex_title_items", lang)) })
  if #item_entries == 0 then
    table.insert(items, { id = "empty", label = i18n.t("dex_empty_items", lang) })
  else
    local item_visible, item_hidden = pick_dex_entries(
      item_entries,
      show_all_items and #item_entries or dex_known_limit,
      show_all_items and #item_entries or dex_unknown_limit
    )
    for _, picked in ipairs(item_visible) do
      local entry = picked.entry
      local index = picked.index
      table.insert(items, {
        id = "dex_entry",
        kind = "item",
        label = build_item_tile_label(entry, index, unknown_label),
        tile_label = build_item_tile_label(entry, index, unknown_label),
        detail_title = entry.known and entry.name or unknown_label,
        detail_lines = build_detail_lines(entry, "item", lang, unknown_label),
        keep_open = true,
      })
    end
    if item_hidden > 0 or show_all_items then
      table.insert(items, {
        id = "dex_control",
        kind = "item",
        action = show_all_items and "collapse_item" or "expand_item",
        label = build_dex_toggle_label(lang, "item", not show_all_items, item_hidden),
        keep_open = true,
      })
      if item_hidden > 0 and not show_all_items then
        table.insert(items, { id = "header", label = build_more_label(item_hidden, lang) })
      end
    end
  end
  return items
end

M.build_action_items = build_action_items
M.build_config_items = build_config_items
M.build_credits_items = build_credits_items
M.build_dex_items = build_dex_items
M.build_status_detail = build_status_detail
M.build_status_items = build_status_items

return M
