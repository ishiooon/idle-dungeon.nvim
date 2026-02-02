-- このモジュールはキャラクター定義を提供する。

local M = {}

-- 画像スプライトは廃止したため定義しない。
-- 役割に応じて基礎能力値の差が体感できるように調整する。
M.characters = {
  {
    id = "recorder",
    name = "旅する記録者",
    role = "バランス型",
    base = { hp = 14, atk = 3, def = 2 },
    dialogue_ratio = 0.95,
    starter_items = { weapon = "wood_sword", armor = "cloth_armor", accessory = "record_ring", companion = "white_slime" },
    -- 表示アイコンの強調色としてキャラクターごとの色味を割り当てる。
    sprite_palette = "recorder",
  },
  {
    id = "guardian",
    name = "墨筆の守り手",
    role = "耐久型",
    base = { hp = 18, atk = 2, def = 4 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "round_shield", armor = "thick_cloak", accessory = "guard_amulet", companion = "stone_spirit" },
    -- 表示アイコンの強調色としてキャラクターごとの色味を割り当てる。
    sprite_palette = "guardian",
  },
  {
    id = "hunter",
    name = "遠眼の狩人",
    role = "速攻型",
    base = { hp = 12, atk = 4, def = 1 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "short_bow", armor = "leather_armor", accessory = "swift_ring", companion = "wind_bird" },
    -- 表示アイコンの強調色としてキャラクターごとの色味を割り当てる。
    sprite_palette = "hunter",
  },
  {
    id = "alchemist",
    name = "眠たげな錬金師",
    role = "支援型",
    base = { hp = 15, atk = 3, def = 2 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "sand_staff", armor = "light_robe", accessory = "sleep_pendant", companion = "tiny_familiar" },
    -- 表示アイコンの強調色としてキャラクターごとの色味を割り当てる。
    sprite_palette = "alchemist",
  },
}

return M
