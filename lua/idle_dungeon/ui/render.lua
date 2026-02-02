-- このモジュールは表示用の文字列を生成する純粋関数を提供する。
-- 描画関連の参照先はui配下へ統一する。
local render_info = require("idle_dungeon.ui.render_info")
local sprite = require("idle_dungeon.ui.sprite")
local track = require("idle_dungeon.ui.track")

local M = {}

local function join_names(names)
  return table.concat(names or {}, ",")
end

local function build_floor_enemies(state, config)
  local enemies = {}
  for _, enemy in ipairs((state.progress or {}).floor_enemies or {}) do
    if not enemy.defeated then
      table.insert(enemies, {
        position = enemy.position,
        icon = sprite.build_floor_enemy_icon(enemy, config),
        id = enemy.id,
        element = enemy.element,
      })
    end
  end
  return enemies
end

local function build_track_line(state, config)
  local length = (config.ui or {}).track_length or 18
  local ground = (config.ui or {}).track_fill or "."
  local mode = state.ui.mode == "battle" and "battle" or "move"
  local hero_icon = sprite.build_hero_sprite(state, config, mode)
  local enemies = build_floor_enemies(state, config)
  local track_line = track.build_track_line(state.progress.distance or 0, length, hero_icon ~= "" and hero_icon or "@", ground, enemies)
  return track_line
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
  if mode == "battle" then
    local label = state.combat and state.combat.enemy.is_boss and "boss" or "enemy"
    return string.format("[Encountered %s (%s)]", label, join_names(config.enemy_names))
  end
  if mode == "reward" then
    return string.format("[Reward exp+%d gold+%d]", config.battle.reward_exp, config.battle.reward_gold)
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
