-- このモジュールは表示用の文字列を生成する純粋関数を提供する。
-- 描画関連の参照先はui配下へ統一する。
local pet = require("idle_dungeon.ui.pet")
local render_info = require("idle_dungeon.ui.render_info")
local sprite = require("idle_dungeon.ui.sprite")

local M = {}

local function join_names(names)
  return table.concat(names or {}, ",")
end

local function build_mode_label(state)
  local mode = state.ui.mode
  if mode == "battle" and state.combat then
    local enemy = state.combat.enemy
    -- ボス戦ではラベルを強調する。
    return enemy.is_boss and "BOSS" or "BATTLE"
  end
  if mode == "dialogue" then
    return "STORY"
  end
  if mode == "reward" then
    return "REWARD"
  end
  if mode == "defeat" then
    return "DEFEAT"
  end
  return "MOVE"
end

local function build_track_line(state, config)
  local sprite_line = state.ui.mode == "battle" and sprite.build_battle_line(state, config) or nil
  if sprite_line then
    return sprite_line
  end
  local length = (config.ui or {}).track_length or 18
  local ground = ((config.ui or {}).pet or {}).ground_char
  local hero_line = sprite.build_hero_track(state, config, length, ground)
  if hero_line then
    return hero_line
  end
  local pet_line = pet.build_line(state, config)
  if pet_line then
    return pet_line
  end
  -- ペット表示が無効な場合は従来の位置マーカーで表示する。
  return pet.build_track_line(state.progress.distance or 0, length, "@", ".")
end

local function build_visual_lines(state, config)
  local track = build_track_line(state, config)
  local label = build_mode_label(state)
  -- 1行目に進行位置、2行目に詳細情報を表示する。
  local line1 = render_info.build_header(track, state, config, label)
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
