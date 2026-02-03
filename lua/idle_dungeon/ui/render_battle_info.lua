-- このモジュールは戦闘時の情報行を純粋関数で整形する。
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local icon_module = require("idle_dungeon.ui.icon")

local M = {}

-- アイコンの後にスペースを入れて数値と重ならないようにする。
local function format_icon_value(icon, text)
  if not icon or icon == "" then
    return text
  end
  return string.format("%s %s", icon, text)
end

-- 戦闘中の体力表示を短くまとめる。
local function build_battle_hp_text(actor, enemy, icons)
  local enemy_max = enemy.max_hp or enemy.hp or 0
  local hp_icon = icons and icons.hp or ""
  local hero_text = format_icon_value(hp_icon, string.format("%d/%d", actor.hp or 0, actor.max_hp or 0))
  local enemy_text = format_icon_value(hp_icon, string.format("%d/%d", enemy.hp or 0, enemy_max))
  return hero_text, enemy_text
end

-- 戦闘中の敵アイコンを定義済み情報から優先的に取得する。
local function resolve_enemy_icon(enemy, icons)
  local fallback = (enemy and enemy.is_boss) and (icons.boss or icons.enemy) or (icons.enemy or "Enemy")
  if enemy and (enemy.hp or 1) <= 0 then
    -- 敵撃破時は墓標アイコンを優先して表示する。
    return icons.defeat or fallback
  end
  if enemy and enemy.icon and enemy.icon ~= "" then
    return enemy.icon
  end
  if enemy and enemy.id then
    local entry = enemy_catalog.find_enemy(enemy.id)
    if entry and entry.icon and entry.icon ~= "" then
      return entry.icon
    end
  end
  return fallback
end

-- 戦闘中のHP表示を1行にまとめる。
local function build_battle_hp_line(actor, enemy, icons)
  local hero_hp, enemy_hp = build_battle_hp_text(actor, enemy, icons)
  local hero_label = icons.hero or "HERO"
  local enemy_label = resolve_enemy_icon(enemy, icons)
  return string.format("%s %s %s %s", hero_label, hero_hp, enemy_label, enemy_hp)
end

-- 戦闘中は体力表示だけに絞って視認性を高める。
local function build_battle_info_line(state, config, lang)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = icon_module.config(config)
  local hp_line = build_battle_hp_line(state.actor or {}, enemy, icons)
  return hp_line
end

M.build_battle_info_line = build_battle_info_line

return M
