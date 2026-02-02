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

-- 属性タイプを短い記号へ変換する。
local function resolve_element_tag(element_id)
  local map = {
    normal = "N",
    fire = "F",
    water = "W",
    grass = "G",
    light = "L",
    dark = "D",
  }
  return map[element_id or "normal"] or "N"
end

-- 相性結果を短い記号へ変換する。
local function resolve_effect_tag(result)
  if not result then
    return ""
  end
  if result.effectiveness == "strong" then
    return "+"
  end
  if result.effectiveness == "weak" then
    return "-"
  end
  return ""
end

-- 攻撃結果を短い文字列に整形する。
local function build_attack_text(result, icon)
  local safe_icon = icon or ""
  if not result then
    return safe_icon .. " -"
  end
  local label = resolve_attack_label(result)
  local tag = resolve_element_tag(result.element)
  local effect = resolve_effect_tag(result)
  if result.hit then
    return string.format("%s%s%d[%s%s]", safe_icon, label, result.damage or 0, tag, effect)
  end
  return string.format("%s%s[%s%s]", safe_icon, label, tag, effect)
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
  local guard_icon = icons.armor or ""
  if guard_icon ~= "" then
    return string.format("%s %s %s %s %s", hero_label, hero_hp, guard_icon, enemy_label, enemy_hp)
  end
  return string.format("%s %s %s %s", hero_label, hero_hp, enemy_label, enemy_hp)
end

-- 戦闘ログの表示を1行にまとめる。
local function build_battle_attack_line(last_turn, enemy, icons)
  if not last_turn then
    return ""
  end
  local hero_label = icons.hero or "HERO"
  local enemy_label = resolve_enemy_icon(enemy, icons)
  local weapon_icon = icons.weapon or ""
  local hero_text = build_attack_text(last_turn.hero, weapon_icon)
  local enemy_text = build_attack_text(last_turn.enemy, weapon_icon)
  return string.format("%s:%s | %s:%s", hero_label, hero_text, enemy_label, enemy_text)
end

-- 戦闘中の攻撃ログと体力表示を組み立てる。
local function build_battle_info_line(state, config, lang)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = icon_module.config(config)
  local last_turn = state.combat and state.combat.last_turn or nil
  local hp_line = build_battle_hp_line(state.actor or {}, enemy, icons)
  if not last_turn then
    return hp_line
  end
  local attack_line = build_battle_attack_line(last_turn, enemy, icons)
  -- 攻撃ログは常に併記し、何が起きたか分かるようにする。
  if attack_line ~= "" then
    return string.format("%s | %s", hp_line, attack_line)
  end
  return hp_line
end

M.build_battle_info_line = build_battle_info_line

return M
