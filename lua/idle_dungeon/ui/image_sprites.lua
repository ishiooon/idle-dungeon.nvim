-- このモジュールは画像スプライト表示の描画処理を担当する。
-- 画像スプライトとペット表示はui配下の参照に統一する。
local picker = require("idle_dungeon.ui.image_sprite_picker"); local pet = require("idle_dungeon.ui.pet")
local M = {}
local image_state = { images = {}, last = {}, last_buf = nil }

local function image_config(config)
  local ui = (config or {}).ui or {}; local image = ui.image_sprites or {}
  return { enabled = image.enabled == true, backend = image.backend or "kitty", asset_dir = image.asset_dir or "assets/idle_dungeon/sprites", rows = image.rows or 1, cols = image.cols or 4, opacity = image.opacity or 1, row_offset = image.row_offset or 0, col_offset = image.col_offset or 0, show_enemy = image.show_enemy ~= false, show_hero = image.show_hero ~= false }
end

local function resolve_asset_dir(asset_dir)
  if asset_dir:sub(1, 1) == "/" then return asset_dir end
  local path = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(path, ":h:h:h:h") .. "/" .. asset_dir
end

local function join_path(base, name)
  if name:sub(1, 1) == "/" then return name end
  if name:match("^%a:[/\\]") then return name end
  return base .. "/" .. name
end
local function file_exists(path) return vim.loop.fs_stat(path) ~= nil end
local function load_image_module() local ok, image = pcall(require, "hologram.image"); return ok and image or nil end

local function ensure_image(image_module, path, settings)
  if image_state.images[path] then return image_state.images[path] end
  local image = image_module:new(path, { backend = settings.backend, opacity = settings.opacity })
  image_state.images[path] = image
  return image
end
local function display_image(image, buf, row, col, settings) image:display(row, col, buf, { width = settings.cols, height = settings.rows }) end
local function delete_image(image, buf) image:delete(buf) end

local function resolve_mode(state)
  if state.ui.mode == "battle" then return "battle" end
  if state.ui.mode == "defeat" then return "defeat" end
  if state.ui.mode == "reward" then return "reward" end
  return "move"
end

local function resolve_positions(state, config, settings)
  local track_length = (config.ui or {}).track_length or 18; local hero_col = settings.col_offset
  if state.ui.mode == "move" then hero_col = pet.calculate_position(state.progress.distance or 0, track_length, settings.cols) + settings.col_offset end
  return settings.row_offset, hero_col, track_length - settings.cols + settings.col_offset
end

local function clear_if_needed(buf)
  if image_state.last_buf and image_state.last_buf ~= buf then
    for _, image in pairs(image_state.images) do
      -- 以前のバッファに描画した画像を削除する。
      pcall(delete_image, image, image_state.last_buf)
    end
    image_state.last = {}
  end
  image_state.last_buf = buf
end

local function update_slot(buf, key, path, row, col, image_module, settings)
  local last_path = image_state.last[key]
  if last_path and last_path ~= path then
    local last_image = image_state.images[last_path]
    if last_image then -- 旧画像を削除して残像を防ぐ。
      pcall(delete_image, last_image, buf)
    end
  end
  if not path then
    image_state.last[key] = nil
    return
  end
  if not file_exists(path) then
    image_state.last[key] = nil
    return
  end
  local image = ensure_image(image_module, path, settings)
  -- 画像を指定位置へ描画する。
  pcall(display_image, image, buf, row, col, settings)
  image_state.last[key] = path
end

local function render(state, config, buf)
  local settings = image_config(config)
  if not settings.enabled or state.ui.render_mode == "text" then return end
  local image_module = load_image_module()
  if not image_module then return end
  clear_if_needed(buf)
  local asset_dir = resolve_asset_dir(settings.asset_dir)
  local mode = resolve_mode(state)
  local row, hero_col, enemy_col = resolve_positions(state, config, settings)
  if settings.show_hero then
    local hero_name = picker.pick_actor_frame(state, config, mode)
    local hero_path = hero_name and join_path(asset_dir, hero_name) or nil
    update_slot(buf, "hero", hero_path, row, hero_col, image_module, settings)
  end
  if settings.show_enemy and state.ui.mode == "battle" then
    local enemy_name = picker.pick_enemy_frame(state, config, mode)
    local enemy_path = enemy_name and join_path(asset_dir, enemy_name) or nil
    update_slot(buf, "enemy", enemy_path, row, enemy_col, image_module, settings)
  else
    update_slot(buf, "enemy", nil, row, enemy_col, image_module, settings)
  end
end

local function clear(buf)
  if not buf then
    return
  end
  for _, image in pairs(image_state.images) do
    -- バッファに描画した画像を削除する。
    pcall(delete_image, image, buf)
  end
  image_state.last = {}
  if image_state.last_buf == buf then
    image_state.last_buf = nil
  end
end

M.render = render
M.clear = clear

return M
