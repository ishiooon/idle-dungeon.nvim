-- このモジュールは画像スプライトの選択を純粋関数として提供する。
-- 画像スプライト関連の参照先はui配下へ統一する。
local animation = require("idle_dungeon.ui.animation")
local sprite = require("idle_dungeon.ui.sprite")
local catalog = require("idle_dungeon.ui.sprite_catalog")

local M = {}

local function image_config(config)
  local ui = (config or {}).ui or {}
  local image = ui.image_sprites or {}
  return {
    frame_seconds = image.frame_seconds or 1,
    boss_frames = image.boss or {},
  }
end

local function resolve_actor_frames(state, mode)
  local character = catalog.find_character(state.actor and state.actor.id)
  if not character or not character.image_sprite then
    return nil
  end
  return sprite.select_frames(character.image_sprite, mode)
end

local function resolve_enemy_frames(state, config, mode)
  local settings = image_config(config)
  local enemy = state.combat and state.combat.enemy or {}
  if enemy.is_boss and settings.boss_frames and #settings.boss_frames > 0 then
    return settings.boss_frames
  end
  local enemy_data = catalog.find_enemy(enemy.id or enemy.name)
  if not enemy_data or not enemy_data.image_sprite then
    return nil
  end
  return sprite.select_frames(enemy_data.image_sprite, mode)
end

local function pick_frame(frames, time_sec, frame_seconds)
  if not frames or #frames == 0 then
    return nil
  end
  return animation.select_frame(frames, time_sec, frame_seconds)
end

local function pick_actor_frame(state, config, mode)
  local frames = resolve_actor_frames(state, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  return pick_frame(frames, time_sec, image_config(config).frame_seconds)
end

local function pick_enemy_frame(state, config, mode)
  local frames = resolve_enemy_frames(state, config, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  return pick_frame(frames, time_sec, image_config(config).frame_seconds)
end

M.resolve_actor_frames = resolve_actor_frames
M.resolve_enemy_frames = resolve_enemy_frames
M.pick_actor_frame = pick_actor_frame
M.pick_enemy_frame = pick_enemy_frame

return M
