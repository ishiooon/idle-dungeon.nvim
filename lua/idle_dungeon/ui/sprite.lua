-- このモジュールは勇者と敵のスプライト表示を生成する純粋関数を提供し、ペット表示は廃止する。
local animation = require("idle_dungeon.ui.animation")
local catalog = require("idle_dungeon.ui.sprite_catalog"); local track = require("idle_dungeon.ui.track")
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
local function icon_config(config)
  local icons = ((config or {}).ui or {}).icons or {}
  return {
    hero = icons.hero or "",
    enemy = icons.enemy or "",
    boss = icons.boss or icons.enemy or "",
    separator = icons.separator or ">",
  }
end
local function build_icon_frames(icon)
  if not icon or icon == "" then
    return nil
  end
  return { idle = { icon }, walk = { icon }, battle = { icon }, defeat = { icon } }
end
local function prefix_icon(frame, icon)
  if not icon or icon == "" then
    return frame
  end
  if frame == "" then
    return icon
  end
  if frame:sub(1, #icon) == icon then
    return frame
  end
  return icon .. frame
end
local function find_character_sprite(actor_id, icons)
  local character = catalog.find_character(actor_id)
  if character and character.sprite then
    return character.sprite
  end
  return build_icon_frames(icons.hero) or DEFAULT_HERO
end
local function find_enemy_sprite(enemy_id, icons)
  local enemy = catalog.find_enemy(enemy_id)
  if enemy and enemy.sprite then
    return enemy.sprite
  end
  return build_icon_frames(icons.enemy) or DEFAULT_ENEMY
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
  local icons = icon_config(config)
  local hero_sprite = find_character_sprite(state.actor and state.actor.id, icons)
  local frames = select_frames(hero_sprite, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  local settings = sprite_config(config)
  return prefix_icon(animation.select_frame(frames, time_sec, settings.frame_seconds), icons.hero)
end
local function build_enemy_sprite(state, config, mode)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = icon_config(config)
  local icon = enemy.is_boss and icons.boss or icons.enemy
  local base_sprite = enemy.is_boss and (build_icon_frames(icons.boss) or BOSS_FRAMES)
    or find_enemy_sprite(enemy.id or enemy.name, icons)
  local frames = select_frames(base_sprite, mode)
  local time_sec = (state.metrics or {}).time_sec or 0
  local settings = sprite_config(config)
  return prefix_icon(animation.select_frame(frames, time_sec, settings.frame_seconds), icon)
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
  local separator = icon_config(config).separator
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
  local separator = icon_config(config).separator
  return string.format("%s%s%s", hero, separator, enemy)
end
M.sprite_config = sprite_config
M.icon_config = icon_config
M.select_frames = select_frames
M.build_hero_sprite = build_hero_sprite
M.build_enemy_sprite = build_enemy_sprite
M.build_battle_line = build_battle_line
M.build_hero_track = build_hero_track
M.build_battle_icons = build_battle_icons
return M
