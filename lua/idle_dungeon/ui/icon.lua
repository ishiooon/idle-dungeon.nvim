-- このモジュールは表示用アイコンの解決と優先設定を純粋関数で提供する。

local M = {}

local function config(config)
  local icons = ((config or {}).ui or {}).icons or {}
  return {
    hero = icons.hero or "",
    enemy = icons.enemy or "",
    boss = icons.boss or icons.enemy or "",
    separator = icons.separator or ">",
    -- 右下の情報行で使うアイコンをまとめて定義する。
    hp = icons.hp or "",
    gold = icons.gold or "",
    exp = icons.exp or "",
  }
end

local function icons_only(config)
  local ui = (config or {}).ui or {}
  if ui.icons_only ~= nil then
    return ui.icons_only
  end
  local sprites = ui.sprites or {}
  if sprites.icons_only ~= nil then
    return sprites.icons_only
  end
  return true
end

local function build_frames(icon)
  if not icon or icon == "" then
    return nil
  end
  return { idle = { icon }, walk = { icon }, battle = { icon }, defeat = { icon } }
end

local function prefix(frame, icon)
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

M.config = config
M.icons_only = icons_only
M.build_frames = build_frames
M.prefix = prefix

return M
