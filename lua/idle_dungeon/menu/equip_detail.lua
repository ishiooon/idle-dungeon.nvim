-- このモジュールは装備変更時のステータス差分表示を生成する。

local content = require("idle_dungeon.content")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")
local player = require("idle_dungeon.game.player")
local util = require("idle_dungeon.util")

local M = {}

-- 装備変更前後の値を差分付きで整形する。
local function format_stat_line(label, current_value, next_value)
  local base = tonumber(current_value) or 0
  local next_v = tonumber(next_value) or 0
  local diff = next_v - base
  return string.format("%s %d -> %d (%+d)", label, base, next_v, diff)
end

-- 現在の装備で適用済みの能力値を計算する。
local function resolve_actor(state, equipment)
  return player.apply_equipment(state.actor, equipment, content.items)
end

-- 装備差分の詳細行を組み立てる。
local function build_detail(item, state, lang)
  if not item or not state then
    return nil
  end
  local current = resolve_actor(state, state.equipment)
  local next_equipment = util.merge_tables(state.equipment, { [item.slot] = item.id })
  local next_actor = resolve_actor(state, next_equipment)
  local lines = {}
  local slot_label = i18n.t("dex_detail_slot", lang)
  local slot_text = menu_locale.slot_label(item.slot, lang)
  table.insert(lines, string.format("%s %s", slot_label, slot_text))
  table.insert(lines, format_stat_line(i18n.t("label_hp", lang), current.max_hp, next_actor.max_hp))
  table.insert(lines, format_stat_line(i18n.t("label_atk", lang), current.atk, next_actor.atk))
  table.insert(lines, format_stat_line(i18n.t("label_def", lang), current.def, next_actor.def))
  return { title = item.name or "", lines = lines }
end

M.build_detail = build_detail

return M
