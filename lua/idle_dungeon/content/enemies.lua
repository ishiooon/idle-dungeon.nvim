-- このモジュールは敵の図鑑データ定義を提供する。

local M = {}

-- 図鑑表示に使う敵の英語名とフレーバーテキストを定義する。
-- ステータスや出現条件もここに集約して管理する。
-- スプライトは任意とし、未定義でもアイコン表示で成立する。
M.enemies = {
  {
    id = "dust_slime",
    name_en = "Lua Slime",
    name_ja = "ルアスライム",
    icon = "",
    stats = { hp = 4, atk = 1, def = 0, accuracy = 88 },
    elements = { "normal", "grass" },
    appear = { min = 1, max = 2 },
    flavor = {
      en = "A code-born slime that bubbles with gentle loops and sudden bursts.",
      ja = "穏やかなループと突発的な跳ねが混ざるコード生まれの粘体。",
    },
  },
  {
    id = "cave_bat",
    name_en = "Cave Bat",
    name_ja = "洞窟コウモリ",
    icon = "󰐥",
    stats = { hp = 3, atk = 2, def = 0, accuracy = 92 },
    elements = { "normal", "dark" },
    appear = { min = 1, max = 3 },
    flavor = {
      en = "It hums a quiet rhythm and charges when the echo changes.",
      ja = "静かな羽音で様子を測り、反響が変わると一気に突進する。",
    },
  },
  {
    id = "moss_goblin",
    name_en = "Moss Goblin",
    name_ja = "苔ゴブリン",
    icon = "󰲍",
    stats = { hp = 5, atk = 2, def = 1, accuracy = 90 },
    elements = { "grass", "normal" },
    appear = { min = 1, max = 4 },
    flavor = {
      en = "A small scavenger that hoards shiny scraps inside its mossy hood.",
      ja = "苔のフードに光るガラクタを隠す小柄な漁り屋。",
    },
  },
  {
    id = "frost_penguin",
    name_en = "Frost Penguin",
    name_ja = "フロストペンギン",
    icon = "",
    stats = { hp = 5, atk = 2, def = 1, accuracy = 90 },
    elements = { "water", "light" },
    appear = { min = 1, max = 3 },
    flavor = {
      en = "It slides in silence, leaving a trail of chilled code behind.",
      ja = "静かに滑り、冷えたコードの軌跡を残して進む。",
    },
  },
  {
    id = "php_elephant",
    name_en = "PHP Elephant",
    name_ja = "PHPエレファント",
    icon = "",
    stats = { hp = 7, atk = 2, def = 2, accuracy = 86 },
    elements = { "grass", "normal" },
    appear = { min = 2, max = 5 },
    flavor = {
      en = "A towering guardian that never forgets a path through the jungle.",
      ja = "密林の道を忘れない巨体の守り手。",
    },
  },
  {
    id = "ember_wisp",
    name_en = "Ember Wisp",
    name_ja = "熾火ウィスプ",
    icon = "󰔶",
    stats = { hp = 4, atk = 3, def = 0, accuracy = 90 },
    elements = { "fire", "light" },
    appear = { min = 2, max = 6 },
    flavor = {
      en = "A faint ember that drifts like a sigh and stings when ignored.",
      ja = "ため息のように漂う微かな火種。油断すると鋭く刺さる。",
    },
  },
  {
    id = "dbeaver",
    name_en = "DBeaver",
    name_ja = "ディービーバー",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 88 },
    elements = { "water", "grass" },
    appear = { min = 3, max = 6 },
    flavor = {
      en = "It chisels through data logs and builds dams of hardened queries.",
      ja = "データの流れを削り、固いクエリの堤を築く。",
    },
  },
  {
    id = "tidal_urchin",
    name_en = "Tidal Urchin",
    name_ja = "潮ウニ",
    icon = "󰇅",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 88 },
    elements = { "water", "dark" },
    appear = { min = 3, max = 7 },
    flavor = {
      en = "It rolls with the tide and needles anyone who blocks its path.",
      ja = "潮に合わせて転がり、進路を塞ぐ者を針で突く。",
    },
  },
  {
    id = "go_gopher",
    name_en = "Go Gopher",
    name_ja = "ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 3, def = 1, accuracy = 90 },
    elements = { "fire", "normal" },
    appear = { min = 3, max = 7 },
    flavor = {
      en = "A cheerful sprinter that darts through corridors with blazing speed.",
      ja = "燃えるような速度で通路を駆け抜ける陽気な走り屋。",
    },
  },
  {
    id = "python_serpent",
    name_en = "Python Serpent",
    name_ja = "パイソンサーペント",
    icon = "",
    stats = { hp = 5, atk = 4, def = 0, accuracy = 87 },
    elements = { "grass", "dark" },
    appear = { min = 4, max = 8 },
    flavor = {
      en = "It coils around lanterns, squeezing until the light flickers.",
      ja = "灯りに絡みつき、光が揺らぐまで締め上げる。",
    },
  },
  {
    id = "shade_wraith",
    name_en = "Shade Wraith",
    name_ja = "影のレイス",
    icon = "󰊠",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 90 },
    elements = { "dark", "light" },
    appear = { min = 4, max = 8 },
    flavor = {
      en = "A silhouette that slips between lanterns and drinks their glow.",
      ja = "灯りの合間をすり抜け、光を啜る影の亡霊。",
    },
  },
  {
    id = "rust_crab",
    name_en = "Rust Crab",
    name_ja = "ラストクラブ",
    icon = "",
    stats = { hp = 8, atk = 4, def = 2, accuracy = 84 },
    elements = { "fire", "dark" },
    appear = { min = 5, max = 8 },
    flavor = {
      en = "Its iron claws leave a warm glow and a lingering scent of metal.",
      ja = "鉄の鋏は温かな光を残し、金属の匂いを漂わせる。",
    },
  },
}

return M
