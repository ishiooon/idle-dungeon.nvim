-- このモジュールはスプライト部分のハイライト指定を生成する。
-- スプライト関連はui配下のモジュールを参照する。
local pet = require("idle_dungeon.ui.pet")
local sprite = require("idle_dungeon.ui.sprite")
local catalog = require("idle_dungeon.ui.sprite_catalog")

local M = {}

local function palette_config(config)
  return ((config or {}).ui or {}).sprite_palette or {}
end

local function palette_key_for_actor(state)
  local character = catalog.find_character(state.actor and state.actor.id)
  return character and character.sprite_palette or "default_hero"
end

local function palette_key_for_enemy(state)
  local enemy = state.combat and state.combat.enemy or {}
  if enemy.is_boss then
    return "boss"
  end
  local enemy_data = catalog.find_enemy(enemy.id or enemy.name)
  return enemy_data and enemy_data.sprite_palette or "default_enemy"
end

local function group_name(key)
  return "IdleDungeonSprite_" .. key
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
  local highlights = {}
  if mode == "battle" then
    local hero_start = 1
    local enemy = settings.show_enemy_on_track and sprite.build_enemy_sprite(state, config, "battle") or ""
    if enemy ~= "" then
      local enemy_start = hero_start + #hero + 1
      table.insert(highlights, { line = 0, start_col = hero_start, end_col = hero_start + #hero, palette = palette_key_for_actor(state) })
      table.insert(highlights, { line = 0, start_col = enemy_start, end_col = enemy_start + #enemy, palette = palette_key_for_enemy(state) })
      return highlights
    end
  end
  local length = (config.ui or {}).track_length or 18
  local position = pet.calculate_position(state.progress.distance or 0, length, #hero)
  table.insert(highlights, { line = 0, start_col = position, end_col = position + #hero, palette = palette_key_for_actor(state) })
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
