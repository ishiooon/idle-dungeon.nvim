-- このモジュールは戦闘時の情報行を純粋関数で整形する。
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local icon_module = require("idle_dungeon.ui.icon")
local util = require("idle_dungeon.util")

local M = {}

-- 言語設定に応じてスキル名を切り替える。
local function resolve_skill_name(skill, lang)
  if not skill then
    return ""
  end
  if lang == "en" then
    return skill.name_en or skill.name or ""
  end
  return skill.name or ""
end

-- アイコンの後にスペースを入れて数値と重ならないようにする。
local function format_icon_value(icon, text)
  if not icon or icon == "" then
    return text
  end
  return string.format("%s %s", icon, text)
end

-- 戦闘中の体力表示を短くまとめる。
local function build_battle_hp_text(actor, enemy, icons, show_max)
  local enemy_max = enemy.max_hp or enemy.hp or 0
  local hp_icon = icons and icons.hp or ""
  local hero_value = show_max and string.format("%d/%d", actor.hp or 0, actor.max_hp or 0) or string.format("%d", actor.hp or 0)
  local enemy_value = show_max and string.format("%d/%d", enemy.hp or 0, enemy_max) or string.format("%d", enemy.hp or 0)
  local hero_text = format_icon_value(hp_icon, hero_value)
  local enemy_text = format_icon_value(hp_icon, enemy_value)
  return hero_text, enemy_text
end

-- 戦闘中の敵アイコンを定義済み情報から優先的に取得する。
-- 情報行は墓標にせず、元の敵アイコンを維持する。
local function resolve_enemy_icon(enemy, icons)
  local fallback = (enemy and enemy.is_boss) and (icons.boss or icons.enemy) or (icons.enemy or "Enemy")
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

-- 戦闘中のHP表示を左右に寄せ、中央に攻撃名を配置する。
local function build_battle_hp_line(actor, enemy, icons, width, center_text, attacker, show_max)
  local hero_hp, enemy_hp = build_battle_hp_text(actor, enemy, icons, show_max)
  local hero_label = icons.hero or "HERO"
  local enemy_label = resolve_enemy_icon(enemy, icons)
  local center = center_text and center_text ~= "" and center_text or ""
  local left = string.format("%s〉%s〉", hero_label, hero_hp)
  local right = string.format("〈%s〈%s", enemy_hp, enemy_label)
  if center ~= "" then
    -- 攻撃側に合わせて技名の向きを切り替える。
    if attacker == "enemy" then
      right = string.format("〈%s%s", center, right)
    else
      left = string.format("%s%s〉", left, center)
    end
  end
  local total_width = math.max(tonumber(width) or 0, 0)
  if total_width <= 0 then
    return left .. " " .. right
  end
  local left_width = util.display_width(left)
  local right_width = util.display_width(right)
  local padding = total_width - left_width - right_width
  if padding < 1 then
    return left .. " " .. right
  end
  return left .. string.rep(" ", padding) .. right
end

-- 戦闘中は体力表示だけに絞って視認性を高める。
local function build_battle_info_line(state, config, lang)
  local enemy = state.combat and state.combat.enemy or {}
  local ui_state = state.ui or {}
  local icons = icon_module.config(config)
  local width = (config.ui or {}).width or 0
  -- 戦闘中のHP分母表示はUI設定から判定する。
  local show_max = ui_state.battle_hp_show_max
  if show_max == nil then
    show_max = (config.ui or {}).battle_hp_show_max == true
  end
  local last_turn = state.combat and state.combat.last_turn or nil
  -- スキル使用時は名称を中央へ表示する。
  local skill = last_turn and last_turn.result and last_turn.result.skill or nil
  local attacker = last_turn and last_turn.attacker or "hero"
  local skill_name = resolve_skill_name(skill, lang)
  local fallback = lang == "ja" and "攻撃" or "Attack"
  local center = skill_name ~= "" and skill_name or fallback
  return build_battle_hp_line(state.actor or {}, enemy, icons, width, center, attacker, show_max)
end

M.build_battle_info_line = build_battle_info_line

return M
