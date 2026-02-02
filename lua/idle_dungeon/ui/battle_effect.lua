-- このモジュールは戦闘中の進行トラック演出を整形する。
local util = require("idle_dungeon.util")

local M = {}

-- 攻撃結果に応じた演出記号を決定する。
local function resolve_attack_effect(result, effects)
  if not result then
    return nil
  end
  if result.hit and result.blocked then
    return effects[2] or effects[1]
  end
  if result.hit then
    return effects[1]
  end
  return effects[3] or effects[1]
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

-- 戦闘演出を進行トラックの文字列へ重ねて返す。
local function apply(line, track_model, state, config)
  local effects = ((config.ui or {}).battle_effects) or { "*", "+", "x" }
  if #effects == 0 then
    return line
  end
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
  local primary_enemy = (track_model and track_model.enemies or {})[1]
  local last_turn = state.combat and state.combat.last_turn or nil
  local hero_effect = resolve_attack_effect(last_turn and last_turn.hero, effects)
  local enemy_effect = resolve_attack_effect(last_turn and last_turn.enemy, effects)
  local placed = false
  placed = place_effect(cells, occupied, { hero_end + 1, hero_pos - 1 }, hero_effect) or placed
  if primary_enemy then
    local enemy_left = primary_enemy.position - 1
    local enemy_right = primary_enemy.position + primary_enemy.width
    placed = place_effect(cells, occupied, { enemy_left, enemy_right }, enemy_effect) or placed
  end
  if not placed then
    local time_sec = (state.metrics or {}).time_sec or 0
    local effect = effects[(time_sec % #effects) + 1]
    local candidates = { hero_end + 1, hero_pos - 1 }
    if primary_enemy then
      table.insert(candidates, primary_enemy.position - 1)
      table.insert(candidates, primary_enemy.position + primary_enemy.width)
    end
    place_effect(cells, occupied, candidates, effect)
  end
  return table.concat(cells, "")
end

M.apply = apply

return M
