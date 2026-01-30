-- このモジュールはキャラクター定義を提供する。

local M = {}

M.characters = {
  {
    id = "recorder",
    name = "旅する記録者",
    role = "バランス型",
    base = { hp = 10, atk = 2, def = 1 },
    dialogue_ratio = 0.95,
    starter_items = { weapon = "wood_sword", armor = "cloth_armor", accessory = "record_ring", companion = "white_slime" },
    -- 図鑑用のドット表現として最小限のスプライトを定義する。
    sprite = { idle = { "o_o", "o.o" }, walk = { "o_o", "o^o", "o-o" }, battle = { "o>o", "o>o" }, defeat = { "x_x" } },
    -- スプライトの色味をキャラクターごとに割り当てる。
    sprite_palette = "recorder",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "hero_recorder_idle_1.png", "hero_recorder_idle_2.png" },
      walk = { "hero_recorder_idle_1.png", "hero_recorder_idle_2.png" },
      battle = { "hero_recorder_battle.png" },
    },
  },
  {
    id = "guardian",
    name = "墨筆の守り手",
    role = "耐久型",
    base = { hp = 12, atk = 1, def = 2 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "round_shield", armor = "thick_cloak", accessory = "guard_amulet", companion = "stone_spirit" },
    -- 盾役の落ち着いた表情を表すスプライトを定義する。
    sprite = { idle = { "O_O", "O.O" }, walk = { "O_O", "O^O", "O-O" }, battle = { "O>O", "O>O" }, defeat = { "X_X" } },
    -- スプライトの色味をキャラクターごとに割り当てる。
    sprite_palette = "guardian",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "hero_guardian_idle_1.png", "hero_guardian_idle_2.png" },
      walk = { "hero_guardian_idle_1.png", "hero_guardian_idle_2.png" },
      battle = { "hero_guardian_battle.png" },
    },
  },
  {
    id = "hunter",
    name = "遠眼の狩人",
    role = "速攻型",
    base = { hp = 9, atk = 3, def = 1 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "short_bow", armor = "leather_armor", accessory = "swift_ring", companion = "wind_bird" },
    -- 俊敏さを表す軽い表情のスプライトを定義する。
    sprite = { idle = { "^_^", "^~^" }, walk = { "^_^", "^-^", "^~^" }, battle = { "^>^", "^>^" }, defeat = { "x-x" } },
    -- スプライトの色味をキャラクターごとに割り当てる。
    sprite_palette = "hunter",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "hero_hunter_idle_1.png", "hero_hunter_idle_2.png" },
      walk = { "hero_hunter_idle_1.png", "hero_hunter_idle_2.png" },
      battle = { "hero_hunter_battle.png" },
    },
  },
  {
    id = "alchemist",
    name = "眠たげな錬金師",
    role = "支援型",
    base = { hp = 11, atk = 2, def = 1 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "sand_staff", armor = "light_robe", accessory = "sleep_pendant", companion = "tiny_familiar" },
    -- 眠たげな雰囲気を表すスプライトを定義する。
    sprite = { idle = { "-_-", "-.-" }, walk = { "-_-", "-^-", "-.-" }, battle = { "->-", "->-" }, defeat = { "x_x" } },
    -- スプライトの色味をキャラクターごとに割り当てる。
    sprite_palette = "alchemist",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "hero_alchemist_idle_1.png", "hero_alchemist_idle_2.png" },
      walk = { "hero_alchemist_idle_1.png", "hero_alchemist_idle_2.png" },
      battle = { "hero_alchemist_battle.png" },
    },
  },
}

return M
