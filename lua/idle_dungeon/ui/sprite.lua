-- このモジュールは勇者と敵のスプライト表示を生成する純粋関数を提供し、ペット表示は廃止する。
local animation = require("idle_dungeon.ui.animation")
local catalog = require("idle_dungeon.ui.sprite_catalog")
local icon_module = require("idle_dungeon.ui.icon")
local track = require("idle_dungeon.ui.track")
local M = {}
local DEFAULT_HERO = {
  idle = { "o_o" },
  walk = { "o_o", "o^o" },
  battle = { "o>o" },
  defeat = { "x_x" },
}
local DEFAULT_ENEMY = {
  idle = { "(_)" },
  battle = { "(_)" },
  defeat = { "(_)" },
}
local BOSS_FRAMES = {
  idle = { "B_B" },
  battle = { "B^B" },
  defeat = { "b_b" },
}
local function sprite_config(config)
  local ui = (config or {}).ui or {}
  local sprites = ui.sprites or {}
  return {
    enabled = sprites.enabled ~= false,
    frame_seconds = sprites.frame_seconds or 1,
    show_hero_on_track = sprites.show_hero_on_track ~= false,
    show_enemy_on_track = sprites.show_enemy_on_track ~= false,
  }
end
local function find_job_sprite(actor_id, icons)
  local job = catalog.find_job(actor_id)
  if job and job.sprite then
    return job.sprite
  end
  return icon_module.build_frames(icons.hero) or DEFAULT_HERO
end
local function find_enemy_sprite(enemy_id, icons)
  local enemy = catalog.find_enemy(enemy_id)
  if enemy and enemy.sprite then
    return enemy.sprite
  end
  -- スプライト未定義の敵はアイコン表示にフォールバックする。
  return icon_module.build_frames(icons.enemy) or DEFAULT_ENEMY
end
local function select_frames(sprite, mode)
  if mode == "battle" then
    return sprite.battle or sprite.idle or sprite.walk or {}
  end
  if mode == "defeat" then
    return sprite.defeat or sprite.idle or {}
  end
  if mode == "move" then
    return sprite.walk or sprite.idle or {}
  end
  return sprite.idle or sprite.walk or {}
end
local function build_hero_sprite(state, config, mode)
  local icons = icon_module.config(config)
  local hero_sprite = icon_module.icons_only(config)
    and (icon_module.build_frames(icons.hero) or DEFAULT_HERO)
    -- ジョブ側にスプライト定義が無い場合はアイコンに戻す。
    or find_job_sprite(state.actor and state.actor.id, icons)
  local frames = select_frames(hero_sprite, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  local settings = sprite_config(config)
  return icon_module.prefix(animation.select_frame(frames, time_sec, settings.frame_seconds), icons.hero)
end
local function build_enemy_sprite(state, config, mode)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = icon_module.config(config)
  local icon_value = enemy.is_boss and icons.boss or icons.enemy
  local base_sprite = nil
  if icon_module.icons_only(config) then
    base_sprite = icon_module.build_frames(icon_value) or (enemy.is_boss and BOSS_FRAMES or DEFAULT_ENEMY)
  else
    base_sprite = enemy.is_boss and (icon_module.build_frames(icons.boss) or BOSS_FRAMES)
      or find_enemy_sprite(enemy.id or enemy.name, icons)
  end
  local frames = select_frames(base_sprite, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  local settings = sprite_config(config)
  return icon_module.prefix(animation.select_frame(frames, time_sec, settings.frame_seconds), icon_value)
end
local function build_battle_line(state, config)
  local settings = sprite_config(config)
  if not settings.enabled then
    return nil
  end
  local hero = build_hero_sprite(state, config, "battle")
  local enemy = build_enemy_sprite(state, config, "battle")
  if hero == "" or enemy == "" then
    return nil
  end
  local separator = icon_module.config(config).separator
  local head = settings.show_hero_on_track and hero or ""
  local tail = settings.show_enemy_on_track and enemy or ""
  return head .. separator .. tail
end
local function build_hero_track(state, config, track_length, ground_char)
  local settings = sprite_config(config)
  if not settings.enabled or not settings.show_hero_on_track then
    return nil
  end
  local hero = build_hero_sprite(state, config, "move")
  if hero == "" then
    return nil
  end
  return track.build_track_line(state.progress.distance or 0, track_length, hero, ground_char)
end
local function build_battle_icons(state, config)
  local settings = sprite_config(config)
  if not settings.enabled then
    return ""
  end
  local hero = build_hero_sprite(state, config, "battle")
  local enemy = build_enemy_sprite(state, config, "battle")
  if hero == "" or enemy == "" then
    return ""
  end
  local separator = icon_module.config(config).separator
  return string.format("%s%s%s", hero, separator, enemy)
end
local function build_floor_enemy_icon(enemy, config)
  local icons = icon_module.config(config)
  local source = catalog.find_enemy(enemy and enemy.id)
  local base_icon = source and source.icon or icons.enemy
  if enemy and enemy.is_boss then
    return icons.boss or base_icon
  end
  return base_icon
end
M.sprite_config = sprite_config
M.select_frames = select_frames
M.build_hero_sprite = build_hero_sprite
M.build_enemy_sprite = build_enemy_sprite
M.build_battle_line = build_battle_line
M.build_hero_track = build_hero_track
M.build_battle_icons = build_battle_icons
M.build_floor_enemy_icon = build_floor_enemy_icon
return M
