-- このモジュールは戦闘時の情報行を純粋関数で整形する。
local element = require("idle_dungeon.game.element")
local icon_module = require("idle_dungeon.ui.icon")

local M = {}

-- 攻撃結果の表示用ラベルを返す。
local function resolve_attack_label(result)
  if not result then
    return ""
  end
  if result.hit then
    return result.blocked and "Block" or "Hit"
  end
  if result.attacker == "enemy" then
    return "Evade"
  end
  return "Miss"
end

-- 攻撃結果を短い文字列に整形する。
local function build_attack_text(result, icon, lang)
  if not result then
    return icon .. " -"
  end
  local label = resolve_attack_label(result)
  local element_label = element.label(result.element or "normal", lang)
  local element_text = element_label ~= "" and (" " .. element_label) or ""
  if result.hit then
    return string.format("%s %s%d%s", icon, label, result.damage or 0, element_text)
  end
  return string.format("%s %s%s", icon, label, element_text)
end

-- 戦闘中の体力表示を短くまとめる。
local function build_battle_hp_text(actor, enemy)
  local enemy_max = enemy.max_hp or enemy.hp or 0
  return string.format("H%d/%d E%d/%d", actor.hp or 0, actor.max_hp or 0, enemy.hp or 0, enemy_max)
end

-- 戦闘中の攻撃ログと体力表示を組み立てる。
local function build_battle_info_line(state, config, lang)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = icon_module.config(config)
  local icon = enemy.is_boss and icons.boss or icons.enemy
  local enemy_max = enemy.max_hp or enemy.hp or 0
  local last_turn = state.combat and state.combat.last_turn or nil
  if not last_turn then
    return string.format("%s %d/%d", icon, enemy.hp or 0, enemy_max)
  end
  local hero_text = build_attack_text(last_turn.hero, icons.hero, lang)
  local enemy_text = build_attack_text(last_turn.enemy, icon, lang)
  local hp_text = build_battle_hp_text(state.actor or {}, enemy)
  return string.format("%s | %s | %s", hero_text, enemy_text, hp_text)
end

M.build_battle_info_line = build_battle_info_line

return M
