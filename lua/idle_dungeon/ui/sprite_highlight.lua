-- このモジュールはスプライト部分のハイライト指定を生成する。
-- スプライト関連はui配下のモジュールを参照する。
local sprite = require("idle_dungeon.ui.sprite")
local track = require("idle_dungeon.ui.track")
local catalog = require("idle_dungeon.ui.sprite_catalog")

local M = {}

local function palette_config(config)
  return ((config or {}).ui or {}).sprite_palette or {}
end

local function palette_key_for_actor(state)
  local character = catalog.find_character(state.actor and state.actor.id)
  return character and character.sprite_palette or "default_hero"
end

local function palette_key_for_enemy_instance(enemy)
  if not enemy then
    return "default_enemy"
  end
  if enemy.is_boss then
    return "boss"
  end
  if enemy.element and enemy.element ~= "" then
    return "element_" .. enemy.element
  end
  local enemy_data = catalog.find_enemy(enemy.id or enemy.name)
  return enemy_data and enemy_data.sprite_palette or "default_enemy"
end

local function group_name(key)
  return "IdleDungeonSprite_" .. key
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
        is_boss = enemy.is_boss,
      })
    end
  end
  return enemies
end

local function build_track_highlights(state, config, line, settings)
  if not line or line == "" then
    return {}
  end
  local mode = state.ui.mode
  if not settings.show_hero_on_track then
    return {}
  end
  local hero = sprite.build_hero_sprite(state, config, mode == "battle" and "battle" or "move")
  if hero == "" then
    return {}
  end
  local length = (config.ui or {}).track_length or 18
  local ground = (config.ui or {}).track_fill or "."
  local enemies = settings.show_enemy_on_track and build_floor_enemies(state, config) or {}
  local track_model = track.build_track(state.progress.distance or 0, length, hero, ground, enemies)
  local offsets = track_model.offsets or {}
  local highlights = {}
  local hero_start = offsets[track_model.hero.position] or 0
  local hero_end = offsets[track_model.hero.position + track_model.hero.width] or #track_model.line
  table.insert(highlights, { line = 0, start_col = hero_start, end_col = hero_end, palette = palette_key_for_actor(state) })
  for _, enemy in ipairs(track_model.enemies or {}) do
    local start_col = offsets[enemy.position] or 0
    local end_col = offsets[enemy.position + enemy.width] or #track_model.line
    table.insert(highlights, {
      line = 0,
      start_col = start_col,
      end_col = end_col,
      palette = palette_key_for_enemy_instance(enemy.enemy),
    })
  end
  return highlights
end

local function build(state, config, lines)
  if state.ui.render_mode == "text" then
    return {}
  end
  local settings = sprite.sprite_config(config)
  if not settings.enabled then
    return {}
  end
  return build_track_highlights(state, config, (lines or {})[1], settings)
end

local function apply(buf, ns, highlights, config)
  local palette = palette_config(config)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, item in ipairs(highlights or {}) do
    local colors = palette[item.palette] or {}
    -- ハイライトグループを定義して色味を反映する。
    vim.api.nvim_set_hl(0, group_name(item.palette), { fg = colors.fg, bg = colors.bg })
    vim.api.nvim_buf_add_highlight(buf, ns, group_name(item.palette), item.line, item.start_col, item.end_col)
  end
end

M.build = build
M.apply = apply

return M
