-- このモジュールは表示用アイコンの解決と優先設定を純粋関数で提供する。

local M = {}

-- 既定のアイコン定義を1か所で管理する。
local function default_icons()
  return {
    hero = "",
    enemy = "",
    boss = "",
    separator = ">",
    -- 右下の情報行で使うアイコンをまとめて定義する。
    -- HPはハートアイコンを既定に戻す。
    hp = "",
    -- ゴールドは別アイコンに置き換えて視認性を上げる。
    gold = "",
    exp = "",
    -- 報酬や敗北の結果表示に使うアイコンをまとめる。
    reward = "",
    -- 敗北表示は墓標のアイコンを既定にする。
    defeat = "󰥓",
    drop = "󰆧",
    -- 装備一覧で使うアイコンをまとめて定義する。
    weapon = "󰓥",
    armor = "",
    accessory = "󰓒",
    companion = "󰠳",
  }
end

-- 既定と上書き設定を統合して返す。
local function merge_icons(override)
  local base = default_icons()
  for key, value in pairs(override or {}) do
    if value ~= nil then
      base[key] = value
    end
  end
  return base
end

local function config(config)
  local icons = ((config or {}).ui or {}).icons or {}
  return merge_icons(icons)
end

-- 装備スロットごとのアイコンを取得する。
local function resolve_slot_icon(slot, icons)
  local safe_icons = icons or {}
  local map = {
    weapon = safe_icons.weapon or "",
    armor = safe_icons.armor or "",
    accessory = safe_icons.accessory or "",
    companion = safe_icons.companion or "",
  }
  return map[slot or ""] or ""
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
M.resolve_slot_icon = resolve_slot_icon
M.default_icons = default_icons

return M
