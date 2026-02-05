-- このモジュールは表示用の文字列を生成する純粋関数を提供する。
-- 描画関連の参照先はui配下へ統一する。
local battle_effect = require("idle_dungeon.ui.battle_effect")
local render_info = require("idle_dungeon.ui.render_info")
local icon_module = require("idle_dungeon.ui.icon")
local sprite = require("idle_dungeon.ui.sprite")
local track = require("idle_dungeon.ui.track")
local util = require("idle_dungeon.util")

local M = {}

-- 戦闘対象の敵かどうかを判定する。
local function is_combat_target(enemy, combat_enemy, combat_source)
  if not combat_enemy or not enemy then
    return false
  end
  if combat_source and combat_source.position then
    -- 階層内の位置が分かる場合は位置と属性で厳密に一致させる。
    if enemy.position ~= combat_source.position then
      return false
    end
    if combat_source.id and enemy.id ~= combat_source.id then
      return false
    end
    if combat_source.element and (enemy.element or "normal") ~= (combat_source.element or "normal") then
      return false
    end
    return true
  end
  if combat_enemy.id and enemy.id ~= combat_enemy.id then
    return false
  end
  if combat_enemy.element and (enemy.element or "normal") ~= (combat_enemy.element or "normal") then
    return false
  end
  return true
end

local function build_floor_enemies(state, config)
  local enemies = {}
  local icons = icon_module.config(config)
  local combat = state.combat or {}
  local combat_enemy = combat.enemy or nil
  local combat_source = combat.source or nil
  for _, enemy in ipairs((state.progress or {}).floor_enemies or {}) do
    if not enemy.defeated then
      local icon = sprite.build_floor_enemy_icon(enemy, config)
      if is_combat_target(enemy, combat_enemy, combat_source) and (combat_enemy.hp or 1) <= 0 then
        -- 敵撃破直後は墓標アイコンで状態を分かりやすくする。
        icon = icons.defeat or icon
      end
      table.insert(enemies, {
        position = enemy.position,
        icon = icon,
        id = enemy.id,
        element = enemy.element,
      })
    end
  end
  return enemies
end

-- 戦闘対象の敵をリストから推定してインデックスを返す。
local function resolve_primary_enemy_index(enemies, combat_enemy, combat_source, hero_position)
  if not combat_enemy then
    return nil
  end
  if combat_source and combat_source.position then
    for index, enemy in ipairs(enemies or {}) do
      if enemy
        and enemy.position == combat_source.position
        and (not combat_source.id or enemy.id == combat_source.id)
        and (not combat_source.element or (enemy.element or "normal") == (combat_source.element or "normal")) then
        return index
      end
    end
  end
  local best = nil
  local best_distance = nil
  for index, enemy in ipairs(enemies or {}) do
    if enemy and enemy.id == combat_enemy.id then
      local distance = math.abs((enemy.position or 1) - (hero_position or 1))
      if not best_distance or distance < best_distance then
        best = index
        best_distance = distance
      end
    end
  end
  return best
end

-- 勇者と敵の間に演出用の隙間を確保し、過剰な距離も詰める。
local function ensure_battle_gap(hero_pos, hero_width, enemy_pos, length, gap)
  local gap_size = math.max(tonumber(gap) or 2, 0)
  local safe_length = math.max(tonumber(length) or 1, 1)
  local safe_enemy = math.min(math.max(tonumber(enemy_pos) or 1, 1), safe_length)
  local desired_hero = safe_enemy - hero_width - gap_size
  if desired_hero >= 1 then
    return desired_hero, safe_enemy
  end
  local safe_hero = math.max(tonumber(hero_pos) or 1, 1)
  local desired_enemy = safe_hero + hero_width + gap_size
  if desired_enemy <= safe_length then
    return safe_hero, desired_enemy
  end
  return safe_hero, safe_enemy
end

local function build_track_line(state, config)
  local length = (config.ui or {}).track_length or 18
  local ground = (config.ui or {}).track_fill or "."
  local mode = state.ui.mode == "battle" and "battle" or "move"
  local hero_icon = sprite.build_hero_sprite(state, config, mode)
  local enemies = build_floor_enemies(state, config)
  local hero_sprite = hero_icon ~= "" and hero_icon or "@"
  if state.ui.mode ~= "battle" then
    return track.build_track_line(state.progress.distance or 0, length, hero_sprite, ground, enemies)
  end
  -- 戦闘中は敵との間に余白を作り、演出が見えるようにする。
  -- 表示幅を基準に勇者の占有幅を計算する。
  local hero_width = math.max(util.display_width(hero_sprite), 1)
  local base_position = track.calculate_position(state.progress.distance or 0, length, hero_width) + 1
  local combat = state.combat or {}
  local combat_enemy = combat.enemy or nil
  local combat_source = combat.source or nil
  local primary_index = resolve_primary_enemy_index(enemies, combat_enemy, combat_source, base_position)
  local adjusted_enemies = util.shallow_copy(enemies)
  local hero_pos = base_position
  local primary_enemy = primary_index and adjusted_enemies[primary_index] or nil
  if not primary_enemy and combat_enemy then
    local icons = icon_module.config(config)
    local icon = sprite.build_floor_enemy_icon({ id = combat_enemy.id, is_boss = combat_enemy.is_boss }, config)
    if (combat_enemy.hp or 1) <= 0 then
      -- 1撃撃破など敵HPが0のときは墓標アイコンを優先する。
      icon = icons.defeat or icon
    end
    local gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
    local fallback_pos = math.min(base_position + hero_width + gap + 1, length)
    local position = fallback_pos
    if combat_source and combat_source.position then
      -- 戦闘対象の位置が分かる場合はその位置を優先する。
      position = math.min(math.max(combat_source.position, 1), length)
    end
    table.insert(adjusted_enemies, {
      position = position,
      icon = icon,
      id = combat_enemy.id,
      element = combat_enemy.element,
      is_boss = combat_enemy.is_boss,
    })
    primary_index = #adjusted_enemies
    primary_enemy = adjusted_enemies[primary_index]
  end
  if primary_enemy then
    local enemy_pos = primary_enemy.position or (base_position + 2)
    local battle_gap = math.max(((config.battle or {}).encounter_gap) or 2, 0)
    local combat = state.combat or {}
    local last_turn = combat.last_turn or nil
    -- 攻撃演出は該当ティックのみ有効にして元の位置へ戻す。
    local attack_effect = battle_effect.is_attack_frame(state)
    local attack_step = combat.attack_step
    local attack_frame = combat.attack_frame
    local step_frame = false
    if attack_step ~= nil then
      -- 進み演出はstepの残り回数がある間だけ有効にする。
      step_frame = (tonumber(attack_step) or 0) > 0
    elseif attack_frame ~= nil then
      -- 旧形式では残りフレームが2以上のときだけ一歩前に出る。
      step_frame = (tonumber(attack_frame) or 0) > 1
    else
      -- 旧形式の状態では演出フレーム判定で代用する。
      step_frame = attack_effect
    end
    hero_pos, enemy_pos = ensure_battle_gap(hero_pos, hero_width, enemy_pos, length, battle_gap)
    -- 攻撃ターンだけ一歩前に出して攻撃感を演出する。
    if last_turn and last_turn.attacker and step_frame then
      if last_turn.attacker == "hero" then
        local max_hero = enemy_pos - hero_width - 1
        hero_pos = math.min(hero_pos + 1, math.max(max_hero, hero_pos))
      else
        local min_enemy = hero_pos + hero_width + 1
        enemy_pos = math.max(enemy_pos - 1, min_enemy)
      end
      if enemy_pos > length then
        enemy_pos = length
      end
      if hero_pos < 1 then
        hero_pos = 1
      end
    end
    adjusted_enemies[primary_index] = util.merge_tables(primary_enemy, { position = enemy_pos })
    primary_enemy = adjusted_enemies[primary_index]
  end
  local distance_override = math.max(hero_pos - 1, 0)
  local track_model = track.build_track(distance_override, length, hero_sprite, ground, adjusted_enemies)
  -- 描画済みの敵情報から戦闘対象の参照を取得する。
  if primary_index and track_model.enemies and track_model.enemies[primary_index] then
    track_model.primary_enemy = track_model.enemies[primary_index]
  else
    track_model.primary_enemy = nil
  end
  return battle_effect.apply(track_model.line, track_model, state, config)
end

local function build_visual_lines(state, config)
  local track = build_track_line(state, config)
  -- 1行目に進行位置、2行目に最小限の情報を表示する。
  local line1 = render_info.build_header(track, state, config)
  local line2 = render_info.build_info_line(state, config)
  return { line1, line2 }
end

local function build_text_status(state, config)
  local mode = state.ui.mode
  if mode == "stage_intro" then
    return "[Stage Intro]"
  end
  if mode == "battle" then
    local enemy = state.combat and state.combat.enemy or {}
    local label = enemy.is_boss and "boss" or "enemy"
    local name = enemy.name or enemy.id or "enemy"
    -- テキストモードでは現在の敵名を優先して表示する。
    return string.format("[Encountered %s: %s]", label, name)
  end
  if mode == "reward" then
    local reward = config.battle or {}
    local bonus_gold = (state.combat and state.combat.pending_gold) or 0
    local reward_gold = (reward.reward_gold or 0) + bonus_gold
    local reward_exp = (state.combat and state.combat.pending_exp) or (reward.reward_exp or 0)
    return string.format("[Reward exp+%d gold+%d]", reward_exp, reward_gold)
  end
  if mode == "defeat" then
    return "[Defeated]"
  end
  return render_info.build_text_status(state, config)
end

local function build_text_lines(state, config)
  local status = build_text_status(state, config)
  -- テキスト表示は2行までの情報を返す。
  local info = render_info.build_info_line(state, config)
  return { status, info }
end

local function build_lines(state, config)
  if state.ui.render_mode == "text" then
    return build_text_lines(state, config)
  end
  return build_visual_lines(state, config)
end

M.build_lines = build_lines

return M
