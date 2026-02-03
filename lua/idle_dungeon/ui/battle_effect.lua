-- このモジュールは戦闘中の進行トラック演出を整形する。
local icon_module = require("idle_dungeon.ui.icon")
local util = require("idle_dungeon.util")

local M = {}

-- 攻撃結果に応じた演出記号を決定する。
local function resolve_attack_effect(result, icons, attacker)
  if not result then
    return nil
  end
  if result.hit then
    if result.blocked and attacker == "hero" then
      -- 勇者の攻撃が弾かれた場合だけ防御アイコンで表現する。
      return icons.armor or ""
    end
    return icons.weapon or ""
  end
  return "·"
end

-- 既存表示と重ならない位置へ演出記号を置く。
local function place_effect(cells, occupied, positions, symbol)
  if not symbol or symbol == "" then
    return false
  end
  for _, pos in ipairs(positions or {}) do
    if pos >= 1 and pos <= #cells and not occupied[pos] then
      cells[pos] = symbol
      occupied[pos] = true
      return true
    end
  end
  return false
end

-- 表示済みの範囲を占有マップへ反映する。
local function mark_range(occupied, start_pos, width)
  local start = tonumber(start_pos) or 0
  local span = math.max(tonumber(width) or 1, 1)
  for index = start, start + span - 1 do
    occupied[index] = true
  end
end

local function clear_gap(cells, occupied, hero_end, enemy_pos)
  if not hero_end or not enemy_pos then
    return
  end
  for pos = hero_end + 1, enemy_pos - 1 do
    if pos >= 1 and pos <= #cells and not occupied[pos] then
      cells[pos] = " "
    end
  end
end

-- 戦闘対象の敵をモデルから取得する。
local function resolve_primary_enemy(track_model)
  if track_model and track_model.primary_enemy then
    return track_model.primary_enemy
  end
  local enemies = (track_model and track_model.enemies) or {}
  return enemies[1]
end

-- 攻撃演出は該当ティックのみに限定して位置が戻るようにする。
local function is_attack_frame(state)
  local combat = state and state.combat or nil
  local remaining = combat and combat.attack_effect or nil
  if remaining ~= nil then
    -- 残りフレーム数がある間は演出を出す。
    return (tonumber(remaining) or 0) > 0
  end
  local legacy = combat and combat.attack_frame or nil
  if legacy ~= nil then
    return (tonumber(legacy) or 0) > 0
  end
  local last_turn = combat and combat.last_turn or nil
  if not last_turn then
    return false
  end
  local now = state and state.metrics and state.metrics.time_sec
  local target = last_turn.time_sec
  if now == nil or target == nil then
    return true
  end
  return math.abs(now - target) < 0.0001
end

-- 戦闘演出を進行トラックの文字列へ重ねて返す。
local function apply(line, track_model, state, config)
  local icons = icon_module.config(config)
  local cells = util.split_utf8(line or "")
  local occupied = {}
  local hero = track_model and track_model.hero or {}
  local hero_pos = hero.position or 1
  local hero_end = hero_pos + (hero.width or 1) - 1
  if track_model and track_model.hero then
    mark_range(occupied, track_model.hero.position, track_model.hero.width)
  end
  for _, enemy in ipairs((track_model and track_model.enemies) or {}) do
    mark_range(occupied, enemy.position, enemy.width)
  end
  local primary_enemy = resolve_primary_enemy(track_model)
  local last_turn = state.combat and state.combat.last_turn or nil
  if not primary_enemy then
    return line
  end
  -- 勇者と敵の間を空白にして戦闘の間合いを表現する。
  clear_gap(cells, occupied, hero_end, primary_enemy.position)
  if not is_attack_frame(state) then
    return table.concat(cells, "")
  end
  local effect = resolve_attack_effect(last_turn.result, icons, last_turn.attacker)
  if last_turn.attacker == "hero" then
    place_effect(cells, occupied, { hero_end + 1 }, effect)
  else
    local enemy_left = primary_enemy.position - 1
    place_effect(cells, occupied, { enemy_left }, effect)
  end
  return table.concat(cells, "")
end

M.apply = apply
M.is_attack_frame = is_attack_frame

return M
