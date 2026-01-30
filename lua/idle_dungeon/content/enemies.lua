-- このモジュールは敵の図鑑データ定義を提供する。

local M = {}

-- 図鑑表示に使う敵の英語名とフレーバーテキストを定義する。
M.enemies = {
  {
    id = "dust_slime",
    name_en = "Dust Slime",
    name_ja = "ホコリスライム",
    flavor = {
      en = "A jelly of old paper and dust that loves to follow warm footsteps.",
      ja = "古い紙と埃が溶け合った粘体。温かな足音に惹かれて付いてくる。",
    },
    -- ぷにっとした動きを表すスプライトを定義する。
    sprite = { idle = { "(_)", "(.)", "(~)" }, battle = { "(+)", "(*)" }, defeat = { "(_)" } },
    -- 敵ごとの色味を割り当てる。
    sprite_palette = "dust_slime",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "enemy_dust_slime_idle_1.png", "enemy_dust_slime_idle_2.png" },
      walk = { "enemy_dust_slime_idle_1.png", "enemy_dust_slime_idle_2.png" },
      battle = { "enemy_dust_slime_battle.png" },
    },
  },
  {
    id = "cave_bat",
    name_en = "Cave Bat",
    name_ja = "洞窟コウモリ",
    flavor = {
      en = "It hums a quiet rhythm and charges when the echo changes.",
      ja = "静かな羽音で様子を測り、反響が変わると一気に突進する。",
    },
    -- 羽ばたきを表すスプライトを定義する。
    sprite = { idle = { "\\_/", "/_\\", "/V\\" }, battle = { "\\_/", "<_>" }, defeat = { "\\_/" } },
    -- 敵ごとの色味を割り当てる。
    sprite_palette = "cave_bat",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "enemy_cave_bat_idle_1.png", "enemy_cave_bat_idle_2.png" },
      walk = { "enemy_cave_bat_idle_1.png", "enemy_cave_bat_idle_2.png" },
      battle = { "enemy_cave_bat_battle.png" },
    },
  },
  {
    id = "moss_goblin",
    name_en = "Moss Goblin",
    name_ja = "苔ゴブリン",
    flavor = {
      en = "A small scavenger that hoards shiny scraps inside its mossy hood.",
      ja = "苔のフードに光るガラクタを隠す小柄な漁り屋。",
    },
    -- いたずら好きな表情を表すスプライトを定義する。
    sprite = { idle = { "g_g", "g^g", "gog" }, battle = { "g>g", "g*g" }, defeat = { "g_g" } },
    -- 敵ごとの色味を割り当てる。
    sprite_palette = "moss_goblin",
    -- 画像スプライトのパスを定義する。
    image_sprite = {
      idle = { "enemy_moss_goblin_idle_1.png", "enemy_moss_goblin_idle_2.png" },
      walk = { "enemy_moss_goblin_idle_1.png", "enemy_moss_goblin_idle_2.png" },
      battle = { "enemy_moss_goblin_battle.png" },
    },
  },
}

return M
