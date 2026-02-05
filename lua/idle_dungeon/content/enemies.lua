-- このモジュールは敵の図鑑データ定義を提供する。

local M = {}

-- 敵ごとのゴールド範囲を基礎能力値から推定する。
local function build_gold_range(enemy)
  local stats = (enemy and enemy.stats) or {}
  local base = (stats.hp or 1) + (stats.atk or 1) + (stats.def or 0)
  local min_value = math.max(math.floor(base * 0.6), 1)
  local max_value = math.max(math.floor(base * 1.1), min_value)
  return { min = min_value, max = max_value }
end

-- 敵定義のドロップにゴールド範囲が無い場合は補完する。
local function apply_gold_defaults(enemies)
  for _, enemy in ipairs(enemies or {}) do
    local drops = enemy.drops or {}
    if not drops.gold then
      drops.gold = build_gold_range(enemy)
    end
    enemy.drops = drops
  end
  return enemies
end

-- 攻撃速度が未定義の場合は既定値で補完する。
local function apply_speed_defaults(enemies, default_speed)
  local speed_value = math.max(tonumber(default_speed) or 2, 1)
  for _, enemy in ipairs(enemies or {}) do
    local stats = enemy.stats or {}
    if stats.speed == nil then
      stats.speed = speed_value
    end
    enemy.stats = stats
  end
  return enemies
end

-- 敵の基礎能力から経験値倍率を計算する。
local function build_exp_multiplier(enemy)
  local stats = (enemy and enemy.stats) or {}
  local base = (stats.hp or 1) + (stats.atk or 1) + (stats.def or 0)
  -- 基礎能力に応じた経験値の振れ幅を広めにする。
  local scaled = base / 6
  local clamped = math.max(1, math.min(scaled, 4))
  return math.floor(clamped * 10 + 0.5) / 10
end

-- 経験値倍率が未定義の場合は既定値で補完する。
local function apply_exp_defaults(enemies)
  for _, enemy in ipairs(enemies or {}) do
    if enemy.exp_multiplier == nil then
      if enemy.id and enemy.id:match("^boss_") then
        enemy.exp_multiplier = 15
      else
        enemy.exp_multiplier = build_exp_multiplier(enemy)
      end
    end
  end
  return enemies
end

-- ドロップ配列へ重複なく追加する。
local function append_unique(list, extras)
  local result = {}
  local seen = {}
  for _, value in ipairs(list or {}) do
    if not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end
  for _, value in ipairs(extras or {}) do
    if not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end
  return result
end

-- 敵ごとの追加ドロップをまとめて適用する。
local function apply_drop_overrides(enemies, overrides)
  for _, enemy in ipairs(enemies or {}) do
    local extra = overrides[enemy.id]
    if extra then
      local drops = enemy.drops or {}
      drops.common = append_unique(drops.common or {}, extra.common)
      drops.rare = append_unique(drops.rare or {}, extra.rare)
      drops.pet = append_unique(drops.pet or {}, extra.pet)
      enemy.drops = drops
    end
  end
  return enemies
end

-- 戦利品候補は敵定義に直接持たせ、図鑑とドロップ抽選に一貫して使う。
-- 図鑑表示に限らず、出現判定・戦闘・UI表示で使う敵情報を定義する。
-- ステータスや出現条件もここに集約して管理する。
-- アイコンとキャラクターの一致感を最優先して構成する。
-- 敵ごとのスキルは個別に記載して戦闘や図鑑に反映する。
local enemies = {
  {
    -- ステージ1の序盤戦は手応えを出すため、基礎敵のHPを引き上げている。
    id = "dust_slime",
    name_en = "Lua Slime",
    name_ja = "ルアスライム",
    icon = "",
    stats = { hp = 6, atk = 1, def = 0, accuracy = 88 },
    elements = { "normal", "grass" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "wood_sword", "sand_staff", "record_ring", "iron_lance", "steady_band" },
      rare = { "fast_sand", "guardian_halberd" },
      pet = { "white_slime" },
    },
    -- 敵ごとのスキルを図鑑定義に含めて内容を見通しやすくする。
    skills = {
      { id = "dust_slime_strike", kind = "active", name = "体当たり霞", name_en = "Body Slam Bloom", description = "勢いよく襲いかかる。", description_en = "Strikes with a sudden rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "dust_slime_aura", kind = "passive", name = "闘気霞", name_en = "Fury Bloom", description = "闘気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with fighting spirit.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A code-born slime that bubbles with gentle loops and sudden bursts.",
      ja = "穏やかなループと突発的な跳ねが混ざるコード生まれの粘体。",
    },
  },
  {
    -- レア枠として大量経験値を持つ特別なスライムを追加する。
    id = "prism_slime",
    name_en = "Prism Slime",
    name_ja = "プリズムスライム",
    icon = "󰝨",
    stats = { hp = 7, atk = 2, def = 1, accuracy = 96 },
    elements = { "light", "water" },
    appear = { min = 4, max = 8 },
    -- 出現率を下げるため重みを小さくする。
    weight = 1,
    exp_multiplier = 60,
    drops = {
      common = { "record_ring", "steady_band" },
      rare = { "fast_sand" },
      pet = {},
    },
    skills = {
      { id = "prism_slime_strike", kind = "active", name = "星彩打翔", name_en = "Star Break Gloom", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "prism_slime_aura", kind = "passive", name = "霊光翔", name_en = "Lumina Gloom", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A rare prism slime that shatters into light and leaves a long trail of exp.",
      ja = "光の欠片を散らしながら現れる希少な粘体。倒すと膨大な経験を残す。",
    },
  },
  {
    id = "tux_penguin",
    name_en = "Tux Penguin",
    name_ja = "タックスペンギン",
    icon = "",
    stats = { hp = 6, atk = 2, def = 0, accuracy = 90 },
    elements = { "water", "light" },
    appear = { min = 1, max = 3 },
    drops = {
      common = { "short_bow", "thick_cloak", "guard_amulet" },
      rare = { "edge_shield" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "tux_penguin_strike", kind = "active", name = "泡砲影", name_en = "Bubble Cannon Burst", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "tux_penguin_aura", kind = "passive", name = "泡盾影", name_en = "Bubble Shield Burst", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A calm glider that answers the dungeon with crisp, icy steps.",
      ja = "涼やかな足取りでダンジョンに応える穏やかな滑走者。",
    },
  },
  {
    id = "vim_mantis",
    name_en = "Vim Mantis",
    name_ja = "ヴィムマンティス",
    icon = "",
    stats = { hp = 6, atk = 2, def = 0, accuracy = 91 },
    elements = { "grass", "light" },
    appear = { min = 1, max = 4 },
    drops = {
      common = { "wood_sword", "light_robe", "swift_ring" },
      rare = { "typing_blade" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "vim_mantis_strike", kind = "active", name = "茨刺金", name_en = "Briar Pierce Nova", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "vim_mantis_aura", kind = "passive", name = "芽生え金", name_en = "Sprout Nova", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It trims the corridor with razor focus, never wasting a keystroke.",
      ja = "鋭い集中で通路を刈り取り、無駄な一打を嫌う。",
    },
  },
  {
    id = "c_sentinel",
    name_en = "C Sentinel",
    name_ja = "Cセンチネル",
    icon = "",
    stats = { hp = 6, atk = 2, def = 1, accuracy = 90 },
    elements = { "normal", "fire" },
    appear = { min = 1, max = 4 },
    drops = {
      common = { "round_shield", "cloth_armor", "guard_amulet", "traveler_coat" },
      rare = { "rest_armor", "bulwark_plate" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "c_sentinel_strike", kind = "active", name = "体当たり芽", name_en = "Body Slam Spike", description = "勢いよく襲いかかる。", description_en = "Strikes with a sudden rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "c_sentinel_aura", kind = "passive", name = "闘気芽", name_en = "Fury Spike", description = "闘気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with fighting spirit.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A simple guardian forged in raw steel, stubborn yet reliable.",
      ja = "原鋼で鍛えられた素朴な守り手。頑固だが頼れる。",
    },
  },
  {
    id = "cpp_colossus",
    name_en = "C++ Colossus",
    name_ja = "C++コロッサス",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 88 },
    elements = { "fire", "dark" },
    appear = { min = 2, max = 5 },
    drops = {
      common = { "round_shield", "leather_armor", "sleep_pendant" },
      rare = { "save_hammer" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "cpp_colossus_strike", kind = "active", name = "火炎噛み渦", name_en = "Flame Bite Gale", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "cpp_colossus_aura", kind = "passive", name = "炎纏渦", name_en = "Flame Veil Gale", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its layered armor reflects countless patterns of ancient craft.",
      ja = "幾重もの装甲に、古い技法の痕跡が刻まれている。",
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
    drops = {
      common = { "leather_armor", "thick_cloak", "record_ring" },
      rare = { "repeat_cloak" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "php_elephant_strike", kind = "active", name = "棘穿ち灼", name_en = "Thorn Skewer Storm", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "php_elephant_aura", kind = "passive", name = "蔓甲灼", name_en = "Vine Armor Storm", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A towering guardian that never forgets a path through the jungle.",
      ja = "密林の道を忘れない巨体の守り手。",
    },
  },
  {
    id = "docker_whale",
    name_en = "Docker Whale",
    name_ja = "ドッカーホエール",
    icon = "",
    stats = { hp = 7, atk = 2, def = 2, accuracy = 85 },
    elements = { "water", "normal" },
    appear = { min = 2, max = 6 },
    drops = {
      common = { "short_bow", "thick_cloak", "sleep_pendant" },
      rare = { "edge_shield" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "docker_whale_strike", kind = "active", name = "波刃影", name_en = "Wave Edge Pulse", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "docker_whale_aura", kind = "passive", name = "霧護影", name_en = "Mist Guard Pulse", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It ferries entire ecosystems on its back and never loses buoyancy.",
      ja = "背に小さな世界を乗せ、浮力を失わない巨大な運び屋。",
    },
  },
  {
    id = "go_gopher",
    name_en = "Go Gopher",
    name_ja = "ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 3, def = 1, accuracy = 90 },
    elements = { "fire", "normal" },
    appear = { min = 2, max = 6 },
    drops = {
      common = { "short_spell_staff", "swift_ring", "light_robe" },
      rare = { "fast_sand" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "go_gopher_strike", kind = "active", name = "焔尾撃翠", name_en = "Ember Tail Lance", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "go_gopher_aura", kind = "passive", name = "熾気翠", name_en = "Ember Lance", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A cheerful sprinter that darts through corridors with blazing speed.",
      ja = "燃えるような速度で通路を駆け抜ける陽気な走り屋。",
    },
  },
  {
    id = "bash_hound",
    name_en = "Bash Hound",
    name_ja = "バッシュハウンド",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 90 },
    elements = { "normal", "dark" },
    appear = { min = 2, max = 6 },
    drops = {
      common = { "sand_staff", "cloth_armor", "silent_ear", "traveler_token" },
      rare = { "focus_bracelet", "guardian_halberd" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "bash_hound_strike", kind = "active", name = "連打烈", name_en = "Flurry Pierce", description = "勢いよく襲いかかる。", description_en = "Strikes with a sudden rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bash_hound_aura", kind = "passive", name = "剛気烈", name_en = "Vigor Pierce", description = "闘気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with fighting spirit.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It obeys short commands and howls when paths become tangled.",
      ja = "短い命令に従い、道が絡まると遠吠えで警告する。",
    },
  },
  {
    id = "mysql_dolphin",
    name_en = "MySQL Dolphin",
    name_ja = "マイエスキューエルドルフィン",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 89 },
    elements = { "water", "light" },
    appear = { min = 3, max = 6 },
    drops = {
      common = { "short_bow", "light_robe", "record_ring" },
      rare = { "edge_shield" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "mysql_dolphin_strike", kind = "active", name = "雨撃輪", name_en = "Rain Strike Ember", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mysql_dolphin_aura", kind = "passive", name = "潮気輪", name_en = "Tide Ember", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It leaps through data streams, flicking droplets of polished light.",
      ja = "データの流れを跳ね、磨かれた光の雫を振り撒く。",
    },
  },
  {
    id = "postgres_colossus",
    name_en = "Postgres Colossus",
    name_ja = "ポストグレスコロッサス",
    icon = "",
    stats = { hp = 7, atk = 3, def = 2, accuracy = 87 },
    elements = { "water", "dark" },
    appear = { min = 3, max = 7 },
    drops = {
      common = { "round_shield", "thick_cloak", "guard_amulet" },
      rare = { "rest_armor" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "postgres_colossus_strike", kind = "active", name = "雨撃冷", name_en = "Rain Strike Fang", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "postgres_colossus_aura", kind = "passive", name = "潮気冷", name_en = "Tide Fang", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "An ancient titan that remembers every echo beneath the stone.",
      ja = "石の下の残響を覚えている古き巨像。",
    },
  },
  {
    id = "dbeaver",
    name_en = "DBeaver",
    name_ja = "デービーバー",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 88 },
    elements = { "water", "grass" },
    appear = { min = 3, max = 6 },
    drops = {
      common = { "sand_staff", "leather_armor", "sleep_pendant" },
      rare = { "repeat_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "dbeaver_strike", kind = "active", name = "渦打金", name_en = "Whirl Crash Glint", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "dbeaver_aura", kind = "passive", name = "霧護金", name_en = "Mist Guard Glint", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It chisels through data logs and builds dams of hardened queries.",
      ja = "データの流れを削り、固いクエリの堤を築く。",
    },
  },
  {
    id = "ruby_scarab",
    name_en = "Ruby Scarab",
    name_ja = "ルビースカラベ",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 89 },
    elements = { "light", "normal" },
    appear = { min = 3, max = 7 },
    drops = {
      common = { "wood_sword", "light_robe", "swift_ring" },
      rare = { "typing_blade" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "ruby_scarab_strike", kind = "active", name = "陽撃盾", name_en = "Solar Strike Gale", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "ruby_scarab_aura", kind = "passive", name = "陽守盾", name_en = "Sun Ward Gale", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its crimson shell shimmers like a gem, warding off weaker blades.",
      ja = "宝石のように輝く紅い殻で、弱い刃を弾き返す。",
    },
  },
  {
    id = "clojure_oracle",
    name_en = "Clojure Oracle",
    name_ja = "クロージャオラクル",
    icon = "",
    stats = { hp = 5, atk = 4, def = 0, accuracy = 88 },
    elements = { "light", "dark" },
    appear = { min = 3, max = 7 },
    drops = {
      common = { "record_ring", "silent_ear", "sleep_pendant" },
      rare = { "focus_bracelet" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "clojure_oracle_strike", kind = "active", name = "光輪斬霞", name_en = "Halo Edge Crash", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "clojure_oracle_aura", kind = "passive", name = "陽守霞", name_en = "Sun Ward Crash", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It mutters in circles, reshaping fate with every repeated phrase.",
      ja = "輪を描くように囁き、反復の言葉で運命を塗り替える。",
    },
  },
  {
    id = "node_phantom",
    name_en = "Node Phantom",
    name_ja = "ノードファントム",
    icon = "",
    stats = { hp = 5, atk = 4, def = 0, accuracy = 90 },
    elements = { "dark", "grass" },
    appear = { min = 3, max = 7 },
    drops = {
      common = { "sand_staff", "light_robe", "silent_ear" },
      rare = { "save_hammer" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "node_phantom_strike", kind = "active", name = "黒刃白", name_en = "Black Edge Blitz", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "node_phantom_aura", kind = "passive", name = "黒幕白", name_en = "Black Mantle Blitz", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It appears in pulses, vanishing between ticks of the event loop.",
      ja = "イベントループの隙間で揺らめき、脈動の合間に消える。",
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
    drops = {
      common = { "short_bow", "leather_armor", "swift_ring" },
      rare = { "save_hammer" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "python_serpent_strike", kind = "active", name = "棘穿ち翔", name_en = "Thorn Skewer Claw", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "python_serpent_aura", kind = "passive", name = "樹皮翔", name_en = "Bark Claw", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It coils around lanterns, squeezing until the light flickers.",
      ja = "灯りに絡みつき、光が揺らぐまで締め上げる。",
    },
  },
  {
    id = "java_ifrit",
    name_en = "Java Ifrit",
    name_ja = "ジャヴァイフリート",
    icon = "",
    stats = { hp = 6, atk = 4, def = 1, accuracy = 88 },
    elements = { "fire", "light" },
    appear = { min = 4, max = 8 },
    drops = {
      common = { "short_spell_staff", "cloth_armor", "guard_amulet" },
      rare = { "fast_sand" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "java_ifrit_strike", kind = "active", name = "燃撃朧", name_en = "Scorch Strike Aegis", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "java_ifrit_aura", kind = "passive", name = "燃勢朧", name_en = "Blaze Aegis", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A fiery spirit that brews scorching steam with every roar.",
      ja = "咆哮のたびに灼熱の蒸気を沸き立たせる炎の精霊。",
    },
  },
  {
    id = "kotlin_fox",
    name_en = "Kotlin Fox",
    name_ja = "コトリンフォックス",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 90 },
    elements = { "light", "water" },
    appear = { min = 4, max = 8 },
    drops = {
      common = { "short_bow", "light_robe", "swift_ring" },
      rare = { "typing_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "kotlin_fox_strike", kind = "active", name = "光弾曙", name_en = "Light Bolt Grim", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "kotlin_fox_aura", kind = "passive", name = "霊光曙", name_en = "Lumina Grim", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its twin tails weave elegant paths, never stepping on the same stone twice.",
      ja = "双つの尾が優雅な軌跡を描き、同じ石を二度踏まない。",
    },
  },
  {
    id = "swift_raptor",
    name_en = "Swift Raptor",
    name_ja = "スウィフトラプター",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 90 },
    elements = { "light", "fire" },
    appear = { min = 4, max = 8 },
    drops = {
      common = { "wood_sword", "swift_ring", "cloth_armor" },
      rare = { "typing_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "swift_raptor_strike", kind = "active", name = "光弾雷", name_en = "Light Bolt Rift", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "swift_raptor_aura", kind = "passive", name = "霊光雷", name_en = "Lumina Rift", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A swift hunter that strikes before the echo of its steps arrives.",
      ja = "足音の反響が届く前に斬りかかる迅速な狩人。",
    },
  },
  {
    id = "git_wyrm",
    name_en = "Git Wyrm",
    name_ja = "ギットワーム",
    icon = "",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 86 },
    elements = { "dark", "normal" },
    appear = { min = 4, max = 8 },
    drops = {
      common = { "round_shield", "leather_armor", "record_ring", "iron_lance" },
      rare = { "save_hammer", "guardian_halberd" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "git_wyrm_strike", kind = "active", name = "影爪岬", name_en = "Shadow Claw Frost", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "git_wyrm_aura", kind = "passive", name = "闇衣岬", name_en = "Gloom Frost", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It burrows through history, guarding every branch it touches.",
      ja = "履歴の地層を掘り進み、触れた枝を守り抜く。",
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
    drops = {
      common = { "round_shield", "thick_cloak", "guard_amulet" },
      rare = { "rest_armor" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "rust_crab_strike", kind = "active", name = "熾火突き盾", name_en = "Ash Thrust Rush", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "rust_crab_aura", kind = "passive", name = "火護盾", name_en = "Fire Guard Rush", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its iron claws leave a warm glow and a lingering scent of metal.",
      ja = "鉄の鋏は温かな光を残し、金属の匂いを漂わせる。",
    },
  },
  {
    id = "gnu_bison",
    name_en = "GNU Bison",
    name_ja = "ヌーバイソン",
    icon = "",
    stats = { hp = 7, atk = 3, def = 2, accuracy = 87 },
    elements = { "normal", "dark" },
    appear = { min = 3, max = 7 },
    drops = {
      common = { "wood_sword", "cloth_armor", "sleep_pendant", "stone_maul" },
      rare = { "repeat_cloak", "bulwark_plate" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "gnu_bison_strike", kind = "active", name = "嚙み砕き槍", name_en = "Crunch Spike", description = "勢いよく襲いかかる。", description_en = "Strikes with a sudden rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gnu_bison_aura", kind = "passive", name = "不屈槍", name_en = "Resolve Spike", description = "闘気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with fighting spirit.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A sturdy bison that trudges forward, breaking walls with sheer will.",
      ja = "意志の力だけで壁を砕き、重い歩みで進む頑強なバイソン。",
    },
  },
  -- 既存のモチーフに属性別の派生種を加え、戦術と雰囲気の幅を広げる。
  -- 派生種の戦利品は属性に合わせた装備が並ぶように調整する。
  {
    id = "penguin_ember",
    name_en = "Ember Penguin",
    name_ja = "熾火ペンギン",
    icon = "",
    stats = { hp = 7, atk = 3, def = 1, accuracy = 89 },
    elements = { "fire" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "flame_dagger", "ember_bow", "ash_mail" },
      rare = { "magma_greatsword" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "penguin_ember_strike", kind = "active", name = "炎牙白", name_en = "Flame Fang Spark", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_ember_aura", kind = "passive", name = "熾気白", name_en = "Ember Spark", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit penguin that skates in bursts and pecks at weak seams.",
      ja = "熾火を纏ったペンギン。短い滑走で間合いを詰め、隙を啄む。",
    },
  },
  {
    id = "penguin_tide",
    name_en = "Tide Penguin",
    name_ja = "潮ペンギン",
    icon = "",
    stats = { hp = 7, atk = 2, def = 1, accuracy = 89 },
    elements = { "water" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "tide_spear", "mist_blade", "foam_coat" },
      rare = { "abyss_trident" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "penguin_tide_strike", kind = "active", name = "渦打黒", name_en = "Whirl Crash Howl", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_tide_aura", kind = "passive", name = "霧護黒", name_en = "Mist Guard Howl", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed penguin that skates in bursts and pecks at weak seams.",
      ja = "潮の気配をまとうペンギン。短い滑走で間合いを詰め、隙を啄む。",
    },
  },
  {
    id = "penguin_moss",
    name_en = "Moss Penguin",
    name_ja = "苔ペンギン",
    icon = "",
    stats = { hp = 7, atk = 2, def = 1, accuracy = 90 },
    elements = { "grass" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "moss_axe", "sprout_spear", "vine_wrap" },
      rare = { "grove_reaver" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "penguin_moss_strike", kind = "active", name = "茨刺朱", name_en = "Briar Pierce Wave", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_moss_aura", kind = "passive", name = "再生朱", name_en = "Regrowth Wave", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy penguin that skates in bursts and pecks at weak seams.",
      ja = "苔むしたペンギン。短い滑走で間合いを詰め、隙を啄む。",
    },
  },
  {
    id = "penguin_lumen",
    name_en = "Lumen Penguin",
    name_ja = "輝光ペンギン",
    icon = "",
    stats = { hp = 7, atk = 2, def = 1, accuracy = 92 },
    elements = { "light" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "glimmer_rapier", "halo_sling", "radiant_veil" },
      rare = { "dawn_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "penguin_lumen_strike", kind = "active", name = "星彩打轟", name_en = "Star Break Burst", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_lumen_aura", kind = "passive", name = "霊光轟", name_en = "Lumina Burst", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous penguin that skates in bursts and pecks at weak seams.",
      ja = "光をまとったペンギン。短い滑走で間合いを詰め、隙を啄む。",
    },
  },
  {
    id = "penguin_umbral",
    name_en = "Umbral Penguin",
    name_ja = "影ペンギン",
    icon = "",
    stats = { hp = 7, atk = 3, def = 1, accuracy = 88 },
    elements = { "dark" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "dusk_katana", "shade_stiletto", "umbra_mail" },
      rare = { "night_reaper" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "penguin_umbral_strike", kind = "active", name = "影穿ち弧", name_en = "Shade Pierce Pulse", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_umbral_aura", kind = "passive", name = "暗気弧", name_en = "Dark Pulse Pulse", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed penguin that skates in bursts and pecks at weak seams.",
      ja = "影を帯びたペンギン。短い滑走で間合いを詰め、隙を啄む。",
    },
  },
  {
    id = "mantis_blaze",
    name_en = "Blaze Mantis",
    name_ja = "炎走マンティス",
    icon = "",
    stats = { hp = 7, atk = 4, def = 1, accuracy = 91 },
    elements = { "fire" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "ember_bow", "ash_mail", "cinder_band" },
      rare = { "phoenix_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "mantis_blaze_strike", kind = "active", name = "熾火突き冷", name_en = "Ash Thrust Bloom", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_blaze_aura", kind = "passive", name = "灼護冷", name_en = "Scorch Guard Bloom", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit mantis that lines up its scythes and cuts clean arcs.",
      ja = "熾火を纏ったマンティス。鎌を揃え、鋭い弧を描いて斬り払う。",
    },
  },
  {
    id = "mantis_mist",
    name_en = "Mist Mantis",
    name_ja = "霧マンティス",
    icon = "",
    stats = { hp = 7, atk = 3, def = 1, accuracy = 91 },
    elements = { "water" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "mist_blade", "foam_coat", "ripple_charm" },
      rare = { "leviathan_scale" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "mantis_mist_strike", kind = "active", name = "泡砲護", name_en = "Bubble Cannon Break", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_mist_aura", kind = "passive", name = "霧護護", name_en = "Mist Guard Break", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed mantis that lines up its scythes and cuts clean arcs.",
      ja = "潮の気配をまとうマンティス。鎌を揃え、鋭い弧を描いて斬り払う。",
    },
  },
  {
    id = "mantis_verdant",
    name_en = "Verdant Mantis",
    name_ja = "緑陰マンティス",
    icon = "",
    stats = { hp = 7, atk = 3, def = 1, accuracy = 92 },
    elements = { "grass" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "sprout_spear", "vine_wrap", "leaf_locket" },
      rare = { "ancient_bark" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "mantis_verdant_strike", kind = "active", name = "棘穿ち朱", name_en = "Thorn Skewer Echo", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_verdant_aura", kind = "passive", name = "蔓甲朱", name_en = "Vine Armor Echo", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy mantis that lines up its scythes and cuts clean arcs.",
      ja = "苔むしたマンティス。鎌を揃え、鋭い弧を描いて斬り払う。",
    },
  },
  {
    id = "mantis_radiant",
    name_en = "Radiant Mantis",
    name_ja = "陽光マンティス",
    icon = "",
    stats = { hp = 7, atk = 3, def = 1, accuracy = 94 },
    elements = { "light" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "halo_sling", "radiant_veil", "prism_charm" },
      rare = { "aurora_plate" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "mantis_radiant_strike", kind = "active", name = "閃光刺暁", name_en = "Flash Pierce Guard", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_radiant_aura", kind = "passive", name = "星護暁", name_en = "Star Guard Guard", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous mantis that lines up its scythes and cuts clean arcs.",
      ja = "光をまとったマンティス。鎌を揃え、鋭い弧を描いて斬り払う。",
    },
  },
  {
    id = "mantis_gloom",
    name_en = "Gloom Mantis",
    name_ja = "暗澹マンティス",
    icon = "",
    stats = { hp = 7, atk = 4, def = 1, accuracy = 90 },
    elements = { "dark" },
    appear = { min = 1, max = 2 },
    drops = {
      common = { "shade_stiletto", "umbra_mail", "void_ring" },
      rare = { "eclipse_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "mantis_gloom_strike", kind = "active", name = "闇裂き疾", name_en = "Gloom Rend Crash", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_gloom_aura", kind = "passive", name = "夜帳疾", name_en = "Night Veil Crash", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed mantis that lines up its scythes and cuts clean arcs.",
      ja = "影を帯びたマンティス。鎌を揃え、鋭い弧を描いて斬り払う。",
    },
  },
  {
    id = "whale_pyre",
    name_en = "Pyre Whale",
    name_ja = "焔ホエール",
    icon = "",
    stats = { hp = 8, atk = 3, def = 2, accuracy = 84 },
    elements = { "fire" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "ash_mail", "cinder_band", "ember_charm" },
      rare = { "magma_greatsword" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "whale_pyre_strike", kind = "active", name = "灼熱突進灼", name_en = "Blaze Rush Shard", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_pyre_aura", kind = "passive", name = "熱気灼", name_en = "Heat Shard", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit whale that rolls like a current and rams when the tide flips.",
      ja = "熾火を纏ったホエール。潮が変わる瞬間に体当たりする。",
    },
  },
  {
    id = "whale_rill",
    name_en = "Rill Whale",
    name_ja = "清流ホエール",
    icon = "",
    stats = { hp = 9, atk = 2, def = 3, accuracy = 84 },
    elements = { "water" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "foam_coat", "ripple_charm", "tide_compass" },
      rare = { "abyss_trident" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "whale_rill_strike", kind = "active", name = "泡砲渦", name_en = "Bubble Cannon Edge", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_rill_aura", kind = "passive", name = "泡盾渦", name_en = "Bubble Shield Edge", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed whale that rolls like a current and rams when the tide flips.",
      ja = "潮の気配をまとうホエール。潮が変わる瞬間に体当たりする。",
    },
  },
  {
    id = "whale_sprout",
    name_en = "Sprout Whale",
    name_ja = "芽吹きホエール",
    icon = "",
    stats = { hp = 8, atk = 2, def = 3, accuracy = 85 },
    elements = { "grass" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "vine_wrap", "leaf_locket", "pollen_charm" },
      rare = { "grove_reaver" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "whale_sprout_strike", kind = "active", name = "蔓打渦", name_en = "Vine Lash Gale", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_sprout_aura", kind = "passive", name = "芽生え渦", name_en = "Sprout Gale", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy whale that rolls like a current and rams when the tide flips.",
      ja = "苔むしたホエール。潮が変わる瞬間に体当たりする。",
    },
  },
  {
    id = "whale_halo",
    name_en = "Halo Whale",
    name_ja = "光輪ホエール",
    icon = "",
    stats = { hp = 8, atk = 2, def = 2, accuracy = 87 },
    elements = { "light" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "radiant_veil", "prism_charm", "beacon_ring" },
      rare = { "dawn_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "whale_halo_strike", kind = "active", name = "輝刃旋", name_en = "Radiant Slash Gloom", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_halo_aura", kind = "passive", name = "星護旋", name_en = "Star Guard Gloom", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous whale that rolls like a current and rams when the tide flips.",
      ja = "光をまとったホエール。潮が変わる瞬間に体当たりする。",
    },
  },
  {
    id = "whale_shade",
    name_en = "Shade Whale",
    name_ja = "陰ホエール",
    icon = "",
    stats = { hp = 8, atk = 3, def = 2, accuracy = 83 },
    elements = { "dark" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "umbra_mail", "void_ring", "gloom_pendant" },
      rare = { "night_reaper" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "whale_shade_strike", kind = "active", name = "影爪鋭", name_en = "Shadow Claw Blight", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_shade_aura", kind = "passive", name = "夜帳鋭", name_en = "Night Veil Blight", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed whale that rolls like a current and rams when the tide flips.",
      ja = "影を帯びたホエール。潮が変わる瞬間に体当たりする。",
    },
  },
  {
    id = "gopher_cinder",
    name_en = "Cinder Gopher",
    name_ja = "燻灰ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 89 },
    elements = { "fire" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "cinder_band", "ember_charm", "flame_dagger" },
      rare = { "phoenix_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "gopher_cinder_strike", kind = "active", name = "炎牙荒", name_en = "Flame Fang Bloom", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_cinder_aura", kind = "passive", name = "燃勢荒", name_en = "Blaze Bloom", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit gopher that tunnels quick passages and pops out with a snap.",
      ja = "熾火を纏ったゴーファー。抜け道から飛び出し素早く噛みつく。",
    },
  },
  {
    id = "gopher_surge",
    name_en = "Surge Gopher",
    name_ja = "奔流ゴーファー",
    icon = "",
    stats = { hp = 6, atk = 3, def = 2, accuracy = 89 },
    elements = { "water" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "ripple_charm", "tide_compass", "tide_spear" },
      rare = { "leviathan_scale" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "gopher_surge_strike", kind = "active", name = "泡砲猛", name_en = "Bubble Cannon Lance", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_surge_aura", kind = "passive", name = "泡盾猛", name_en = "Bubble Shield Lance", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed gopher that tunnels quick passages and pops out with a snap.",
      ja = "潮の気配をまとうゴーファー。抜け道から飛び出し素早く噛みつく。",
    },
  },
  {
    id = "gopher_bloom",
    name_en = "Bloom Gopher",
    name_ja = "花芽ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 3, def = 2, accuracy = 90 },
    elements = { "grass" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "leaf_locket", "pollen_charm", "moss_axe" },
      rare = { "ancient_bark" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "gopher_bloom_strike", kind = "active", name = "苔斬紅", name_en = "Moss Slash Grim", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_bloom_aura", kind = "passive", name = "緑護紅", name_en = "Verdant Guard Grim", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy gopher that tunnels quick passages and pops out with a snap.",
      ja = "苔むしたゴーファー。抜け道から飛び出し素早く噛みつく。",
    },
  },
  {
    id = "gopher_dawn",
    name_en = "Dawn Gopher",
    name_ja = "黎明ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 3, def = 1, accuracy = 92 },
    elements = { "light" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "prism_charm", "beacon_ring", "glimmer_rapier" },
      rare = { "aurora_plate" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "gopher_dawn_strike", kind = "active", name = "光輪斬雷", name_en = "Halo Edge Crest", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_dawn_aura", kind = "passive", name = "陽守雷", name_en = "Sun Ward Crest", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous gopher that tunnels quick passages and pops out with a snap.",
      ja = "光をまとったゴーファー。抜け道から飛び出し素早く噛みつく。",
    },
  },
  {
    id = "gopher_dusk",
    name_en = "Dusk Gopher",
    name_ja = "黄昏ゴーファー",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 88 },
    elements = { "dark" },
    appear = { min = 2, max = 3 },
    drops = {
      common = { "void_ring", "gloom_pendant", "dusk_katana" },
      rare = { "eclipse_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "gopher_dusk_strike", kind = "active", name = "宵牙金", name_en = "Dusk Fang Howl", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_dusk_aura", kind = "passive", name = "暗気金", name_en = "Dark Pulse Howl", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed gopher that tunnels quick passages and pops out with a snap.",
      ja = "影を帯びたゴーファー。抜け道から飛び出し素早く噛みつく。",
    },
  },
  {
    id = "elephant_sear",
    name_en = "Sear Elephant",
    name_ja = "灼熱エレファント",
    icon = "",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 85 },
    elements = { "fire" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "ember_charm", "flame_dagger", "ember_bow" },
      rare = { "magma_greatsword" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "elephant_sear_strike", kind = "active", name = "熾火突き砕", name_en = "Ash Thrust Howl", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_sear_aura", kind = "passive", name = "炎纏砕", name_en = "Flame Veil Howl", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit elephant that stomps to set the tempo and shields its herd.",
      ja = "熾火を纏ったエレファント。踏み鳴らして隊列を守る。",
    },
  },
  {
    id = "elephant_abyss",
    name_en = "Abyss Elephant",
    name_ja = "深淵エレファント",
    icon = "",
    stats = { hp = 8, atk = 3, def = 3, accuracy = 85 },
    elements = { "water" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "tide_compass", "tide_spear", "mist_blade" },
      rare = { "abyss_trident" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "elephant_abyss_strike", kind = "active", name = "氷噛み猛", name_en = "Ice Bite Claw", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_abyss_aura", kind = "passive", name = "流水猛", name_en = "Flow Claw", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed elephant that stomps to set the tempo and shields its herd.",
      ja = "潮の気配をまとうエレファント。踏み鳴らして隊列を守る。",
    },
  },
  {
    id = "elephant_grove",
    name_en = "Grove Elephant",
    name_ja = "木立エレファント",
    icon = "",
    stats = { hp = 7, atk = 3, def = 3, accuracy = 86 },
    elements = { "grass" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "pollen_charm", "moss_axe", "sprout_spear" },
      rare = { "grove_reaver" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "elephant_grove_strike", kind = "active", name = "蔓打鋭", name_en = "Vine Lash Edge", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_grove_aura", kind = "passive", name = "再生鋭", name_en = "Regrowth Edge", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy elephant that stomps to set the tempo and shields its herd.",
      ja = "苔むしたエレファント。踏み鳴らして隊列を守る。",
    },
  },
  {
    id = "elephant_aurora",
    name_en = "Aurora Elephant",
    name_ja = "極光エレファント",
    icon = "",
    stats = { hp = 7, atk = 3, def = 2, accuracy = 88 },
    elements = { "light" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "beacon_ring", "glimmer_rapier", "halo_sling" },
      rare = { "dawn_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "elephant_aurora_strike", kind = "active", name = "星彩打旋", name_en = "Star Break Shade", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_aurora_aura", kind = "passive", name = "聖気旋", name_en = "Holy Glow Shade", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous elephant that stomps to set the tempo and shields its herd.",
      ja = "光をまとったエレファント。踏み鳴らして隊列を守る。",
    },
  },
  {
    id = "elephant_void",
    name_en = "Void Elephant",
    name_ja = "虚無エレファント",
    icon = "",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 84 },
    elements = { "dark" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "gloom_pendant", "dusk_katana", "shade_stiletto" },
      rare = { "night_reaper" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "elephant_void_strike", kind = "active", name = "暗刃紫", name_en = "Dark Blade Vortex", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_void_aura", kind = "passive", name = "冥護紫", name_en = "Dread Ward Vortex", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed elephant that stomps to set the tempo and shields its herd.",
      ja = "影を帯びたエレファント。踏み鳴らして隊列を守る。",
    },
  },
  {
    id = "scarab_ember",
    name_en = "Ember Scarab",
    name_ja = "熾火スカラベ",
    icon = "",
    stats = { hp = 6, atk = 4, def = 1, accuracy = 87 },
    elements = { "fire" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "flame_dagger", "ember_bow", "ash_mail" },
      rare = { "phoenix_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "scarab_ember_strike", kind = "active", name = "熾火突き翔", name_en = "Ash Thrust Thrust", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_ember_aura", kind = "passive", name = "火護翔", name_en = "Fire Guard Thrust", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit scarab that polishes its shell and rebounds stray blows.",
      ja = "熾火を纏ったスカラベ。磨かれた殻で攻撃を弾く。",
    },
  },
  {
    id = "scarab_tide",
    name_en = "Tide Scarab",
    name_ja = "潮スカラベ",
    icon = "",
    stats = { hp = 7, atk = 3, def = 2, accuracy = 87 },
    elements = { "water" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "tide_spear", "mist_blade", "foam_coat" },
      rare = { "leviathan_scale" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "scarab_tide_strike", kind = "active", name = "波刃朽", name_en = "Wave Edge Halo", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_tide_aura", kind = "passive", name = "潮気朽", name_en = "Tide Halo", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed scarab that polishes its shell and rebounds stray blows.",
      ja = "潮の気配をまとうスカラベ。磨かれた殻で攻撃を弾く。",
    },
  },
  {
    id = "scarab_moss",
    name_en = "Moss Scarab",
    name_ja = "苔スカラベ",
    icon = "",
    stats = { hp = 6, atk = 3, def = 2, accuracy = 88 },
    elements = { "grass" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "moss_axe", "sprout_spear", "vine_wrap" },
      rare = { "ancient_bark" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "scarab_moss_strike", kind = "active", name = "苔斬盾", name_en = "Moss Slash Gale", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_moss_aura", kind = "passive", name = "森護盾", name_en = "Grove Guard Gale", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy scarab that polishes its shell and rebounds stray blows.",
      ja = "苔むしたスカラベ。磨かれた殻で攻撃を弾く。",
    },
  },
  {
    id = "scarab_lumen",
    name_en = "Lumen Scarab",
    name_ja = "輝光スカラベ",
    icon = "",
    stats = { hp = 6, atk = 3, def = 1, accuracy = 90 },
    elements = { "light" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "glimmer_rapier", "halo_sling", "radiant_veil" },
      rare = { "aurora_plate" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "scarab_lumen_strike", kind = "active", name = "光弾芽", name_en = "Light Bolt Drift", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_lumen_aura", kind = "passive", name = "光護芽", name_en = "Radiance Drift", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous scarab that polishes its shell and rebounds stray blows.",
      ja = "光をまとったスカラベ。磨かれた殻で攻撃を弾く。",
    },
  },
  {
    id = "scarab_umbral",
    name_en = "Umbral Scarab",
    name_ja = "影スカラベ",
    icon = "",
    stats = { hp = 6, atk = 4, def = 1, accuracy = 86 },
    elements = { "dark" },
    appear = { min = 3, max = 4 },
    drops = {
      common = { "dusk_katana", "shade_stiletto", "umbra_mail" },
      rare = { "eclipse_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "scarab_umbral_strike", kind = "active", name = "影爪霧", name_en = "Shadow Claw Crest", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_umbral_aura", kind = "passive", name = "冥護霧", name_en = "Dread Ward Crest", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed scarab that polishes its shell and rebounds stray blows.",
      ja = "影を帯びたスカラベ。磨かれた殻で攻撃を弾く。",
    },
  },
  {
    id = "serpent_blaze",
    name_en = "Blaze Serpent",
    name_ja = "炎走サーペント",
    icon = "",
    stats = { hp = 5, atk = 5, def = 0, accuracy = 86 },
    elements = { "fire" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "ember_bow", "ash_mail", "cinder_band" },
      rare = { "magma_greatsword" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "serpent_blaze_strike", kind = "active", name = "炎牙猛", name_en = "Flame Fang Guard", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_blaze_aura", kind = "passive", name = "燃勢猛", name_en = "Blaze Guard", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit serpent that coils tight and strikes when the rhythm breaks.",
      ja = "熾火を纏ったサーペント。間合いの乱れに合わせて噛みつく。",
    },
  },
  {
    id = "serpent_mist",
    name_en = "Mist Serpent",
    name_ja = "霧サーペント",
    icon = "",
    stats = { hp = 6, atk = 4, def = 1, accuracy = 86 },
    elements = { "water" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "mist_blade", "foam_coat", "ripple_charm" },
      rare = { "abyss_trident" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "serpent_mist_strike", kind = "active", name = "潮撃渦", name_en = "Tide Slam Gale", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_mist_aura", kind = "passive", name = "水護渦", name_en = "Water Guard Gale", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed serpent that coils tight and strikes when the rhythm breaks.",
      ja = "潮の気配をまとうサーペント。間合いの乱れに合わせて噛みつく。",
    },
  },
  {
    id = "serpent_verdant",
    name_en = "Verdant Serpent",
    name_ja = "緑陰サーペント",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 87 },
    elements = { "grass" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "sprout_spear", "vine_wrap", "leaf_locket" },
      rare = { "grove_reaver" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "serpent_verdant_strike", kind = "active", name = "苔斬静", name_en = "Moss Slash Gloom", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_verdant_aura", kind = "passive", name = "樹皮静", name_en = "Bark Gloom", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy serpent that coils tight and strikes when the rhythm breaks.",
      ja = "苔むしたサーペント。間合いの乱れに合わせて噛みつく。",
    },
  },
  {
    id = "serpent_radiant",
    name_en = "Radiant Serpent",
    name_ja = "陽光サーペント",
    icon = "",
    stats = { hp = 5, atk = 4, def = 0, accuracy = 89 },
    elements = { "light" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "halo_sling", "radiant_veil", "prism_charm" },
      rare = { "dawn_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "serpent_radiant_strike", kind = "active", name = "光弾朱", name_en = "Light Bolt Ember", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_radiant_aura", kind = "passive", name = "清光朱", name_en = "Clear Light Ember", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous serpent that coils tight and strikes when the rhythm breaks.",
      ja = "光をまとったサーペント。間合いの乱れに合わせて噛みつく。",
    },
  },
  {
    id = "serpent_gloom",
    name_en = "Gloom Serpent",
    name_ja = "暗澹サーペント",
    icon = "",
    stats = { hp = 5, atk = 5, def = 0, accuracy = 85 },
    elements = { "dark" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "shade_stiletto", "umbra_mail", "void_ring" },
      rare = { "night_reaper" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "serpent_gloom_strike", kind = "active", name = "暗刃影", name_en = "Dark Blade Crest", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_gloom_aura", kind = "passive", name = "幽気影", name_en = "Umbral Crest", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed serpent that coils tight and strikes when the rhythm breaks.",
      ja = "影を帯びたサーペント。間合いの乱れに合わせて噛みつく。",
    },
  },
  {
    id = "fox_pyre",
    name_en = "Pyre Fox",
    name_ja = "焔フォックス",
    icon = "",
    stats = { hp = 5, atk = 5, def = 1, accuracy = 89 },
    elements = { "fire" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "ash_mail", "cinder_band", "ember_charm" },
      rare = { "phoenix_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "fox_pyre_strike", kind = "active", name = "灼熱突進白", name_en = "Blaze Rush Drift", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_pyre_aura", kind = "passive", name = "紅気白", name_en = "Crimson Pulse Drift", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit fox that feints twice before darting for the throat.",
      ja = "熾火を纏ったフォックス。二度のフェイントから喉元へ飛び込む。",
    },
  },
  {
    id = "fox_rill",
    name_en = "Rill Fox",
    name_ja = "清流フォックス",
    icon = "",
    stats = { hp = 6, atk = 4, def = 2, accuracy = 89 },
    elements = { "water" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "foam_coat", "ripple_charm", "tide_compass" },
      rare = { "leviathan_scale" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "fox_rill_strike", kind = "active", name = "泡砲刃", name_en = "Bubble Cannon Aegis", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_rill_aura", kind = "passive", name = "湿気刃", name_en = "Moisture Aegis", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed fox that feints twice before darting for the throat.",
      ja = "潮の気配をまとうフォックス。二度のフェイントから喉元へ飛び込む。",
    },
  },
  {
    id = "fox_sprout",
    name_en = "Sprout Fox",
    name_ja = "芽吹きフォックス",
    icon = "",
    stats = { hp = 5, atk = 4, def = 2, accuracy = 90 },
    elements = { "grass" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "vine_wrap", "leaf_locket", "pollen_charm" },
      rare = { "ancient_bark" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "fox_sprout_strike", kind = "active", name = "蔓打刃", name_en = "Vine Lash Glint", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_sprout_aura", kind = "passive", name = "再生刃", name_en = "Regrowth Glint", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy fox that feints twice before darting for the throat.",
      ja = "苔むしたフォックス。二度のフェイントから喉元へ飛び込む。",
    },
  },
  {
    id = "fox_halo",
    name_en = "Halo Fox",
    name_ja = "光輪フォックス",
    icon = "",
    stats = { hp = 5, atk = 4, def = 1, accuracy = 92 },
    elements = { "light" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "radiant_veil", "prism_charm", "beacon_ring" },
      rare = { "aurora_plate" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "fox_halo_strike", kind = "active", name = "輝刃轟", name_en = "Radiant Slash Spark", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_halo_aura", kind = "passive", name = "清光轟", name_en = "Clear Light Spark", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous fox that feints twice before darting for the throat.",
      ja = "光をまとったフォックス。二度のフェイントから喉元へ飛び込む。",
    },
  },
  {
    id = "fox_shade",
    name_en = "Shade Fox",
    name_ja = "陰フォックス",
    icon = "",
    stats = { hp = 5, atk = 5, def = 1, accuracy = 88 },
    elements = { "dark" },
    appear = { min = 4, max = 5 },
    drops = {
      common = { "umbra_mail", "void_ring", "gloom_pendant" },
      rare = { "eclipse_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "fox_shade_strike", kind = "active", name = "影爪破", name_en = "Shadow Claw Halo", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_shade_aura", kind = "passive", name = "闇衣破", name_en = "Gloom Halo", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed fox that feints twice before darting for the throat.",
      ja = "影を帯びたフォックス。二度のフェイントから喉元へ飛び込む。",
    },
  },
  {
    id = "crab_cinder",
    name_en = "Cinder Crab",
    name_ja = "燻灰クラブ",
    icon = "",
    stats = { hp = 8, atk = 5, def = 2, accuracy = 83 },
    elements = { "fire" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "cinder_band", "ember_charm", "flame_dagger" },
      rare = { "magma_greatsword" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "crab_cinder_strike", kind = "active", name = "燃撃岬", name_en = "Scorch Strike Blitz", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_cinder_aura", kind = "passive", name = "火護岬", name_en = "Fire Guard Blitz", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit crab that braces its shell and drags foes sideways.",
      ja = "熾火を纏ったクラブ。横薙ぎに相手をずらす。",
    },
  },
  {
    id = "crab_surge",
    name_en = "Surge Crab",
    name_ja = "奔流クラブ",
    icon = "",
    stats = { hp = 9, atk = 4, def = 3, accuracy = 83 },
    elements = { "water" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "ripple_charm", "tide_compass", "tide_spear" },
      rare = { "abyss_trident" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "crab_surge_strike", kind = "active", name = "波刃朱", name_en = "Wave Edge Might", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_surge_aura", kind = "passive", name = "潮気朱", name_en = "Tide Might", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed crab that braces its shell and drags foes sideways.",
      ja = "潮の気配をまとうクラブ。横薙ぎに相手をずらす。",
    },
  },
  {
    id = "crab_bloom",
    name_en = "Bloom Crab",
    name_ja = "花芽クラブ",
    icon = "",
    stats = { hp = 8, atk = 4, def = 3, accuracy = 84 },
    elements = { "grass" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "leaf_locket", "pollen_charm", "moss_axe" },
      rare = { "grove_reaver" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "crab_bloom_strike", kind = "active", name = "森槍猛", name_en = "Forest Spear Spark", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_bloom_aura", kind = "passive", name = "森護猛", name_en = "Grove Guard Spark", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy crab that braces its shell and drags foes sideways.",
      ja = "苔むしたクラブ。横薙ぎに相手をずらす。",
    },
  },
  {
    id = "crab_dawn",
    name_en = "Dawn Crab",
    name_ja = "黎明クラブ",
    icon = "",
    stats = { hp = 8, atk = 4, def = 2, accuracy = 86 },
    elements = { "light" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "prism_charm", "beacon_ring", "glimmer_rapier" },
      rare = { "dawn_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "crab_dawn_strike", kind = "active", name = "星彩打金", name_en = "Star Break Nimbus", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_dawn_aura", kind = "passive", name = "輝護金", name_en = "Luster Nimbus", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous crab that braces its shell and drags foes sideways.",
      ja = "光をまとったクラブ。横薙ぎに相手をずらす。",
    },
  },
  {
    id = "crab_dusk",
    name_en = "Dusk Crab",
    name_ja = "黄昏クラブ",
    icon = "",
    stats = { hp = 8, atk = 5, def = 2, accuracy = 82 },
    elements = { "dark" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "void_ring", "gloom_pendant", "dusk_katana" },
      rare = { "night_reaper" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "crab_dusk_strike", kind = "active", name = "冥撃護", name_en = "Void Strike Dawn", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_dusk_aura", kind = "passive", name = "幽気護", name_en = "Umbral Dawn", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed crab that braces its shell and drags foes sideways.",
      ja = "影を帯びたクラブ。横薙ぎに相手をずらす。",
    },
  },
  {
    id = "bison_sear",
    name_en = "Sear Bison",
    name_ja = "灼熱バイソン",
    icon = "",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 86 },
    elements = { "fire" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "ember_charm", "flame_dagger", "ember_bow" },
      rare = { "phoenix_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "bison_sear_strike", kind = "active", name = "炎牙輪", name_en = "Flame Fang Rush", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_sear_aura", kind = "passive", name = "熾気輪", name_en = "Ember Rush", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A ember-lit bison that charges straight and shakes the floor.",
      ja = "熾火を纏ったバイソン。一直線に突進し床を揺らす。",
    },
  },
  {
    id = "bison_abyss",
    name_en = "Abyss Bison",
    name_ja = "深淵バイソン",
    icon = "",
    stats = { hp = 8, atk = 3, def = 3, accuracy = 86 },
    elements = { "water" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "tide_compass", "tide_spear", "mist_blade" },
      rare = { "leviathan_scale" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "bison_abyss_strike", kind = "active", name = "雨撃銀", name_en = "Rain Strike Blitz", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_abyss_aura", kind = "passive", name = "潮気銀", name_en = "Tide Blitz", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A tide-washed bison that charges straight and shakes the floor.",
      ja = "潮の気配をまとうバイソン。一直線に突進し床を揺らす。",
    },
  },
  {
    id = "bison_grove",
    name_en = "Grove Bison",
    name_ja = "木立バイソン",
    icon = "",
    stats = { hp = 7, atk = 3, def = 3, accuracy = 87 },
    elements = { "grass" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "pollen_charm", "moss_axe", "sprout_spear" },
      rare = { "ancient_bark" },
      pet = { "white_slime" },
    },
    skills = {
      { id = "bison_grove_strike", kind = "active", name = "棘穿ち霞", name_en = "Thorn Skewer Grim", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_grove_aura", kind = "passive", name = "樹皮霞", name_en = "Bark Grim", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A mossy bison that charges straight and shakes the floor.",
      ja = "苔むしたバイソン。一直線に突進し床を揺らす。",
    },
  },
  {
    id = "bison_aurora",
    name_en = "Aurora Bison",
    name_ja = "極光バイソン",
    icon = "",
    stats = { hp = 7, atk = 3, def = 2, accuracy = 89 },
    elements = { "light" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "beacon_ring", "glimmer_rapier", "halo_sling" },
      rare = { "aurora_plate" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "bison_aurora_strike", kind = "active", name = "陽撃宵", name_en = "Solar Strike Gloom", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_aurora_aura", kind = "passive", name = "輝護宵", name_en = "Luster Gloom", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A luminous bison that charges straight and shakes the floor.",
      ja = "光をまとったバイソン。一直線に突進し床を揺らす。",
    },
  },
  {
    id = "bison_void",
    name_en = "Void Bison",
    name_ja = "虚無バイソン",
    icon = "",
    stats = { hp = 7, atk = 4, def = 2, accuracy = 85 },
    elements = { "dark" },
    appear = { min = 5, max = 7 },
    drops = {
      common = { "gloom_pendant", "dusk_katana", "shade_stiletto" },
      rare = { "eclipse_cloak" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "bison_void_strike", kind = "active", name = "冥撃尖", name_en = "Void Strike Drift", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_void_aura", kind = "passive", name = "幽気尖", name_en = "Umbral Drift", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A shadowed bison that charges straight and shakes the floor.",
      ja = "影を帯びたバイソン。一直線に突進し床を揺らす。",
    },
  },
  {
    id = "boss_ice_regent",
    name_en = "Ice Regent",
    name_ja = "氷王レジェント",
    icon = "",
    stats = { hp = 12, atk = 5, def = 3, accuracy = 92 },
    elements = { "water", "light" },
    appear = { stages = {} },
    drops = {
      common = { "short_bow", "thick_cloak", "record_ring" },
      rare = { "edge_shield", "typing_blade" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "boss_ice_regent_strike", kind = "active", name = "雨撃金", name_en = "Rain Strike Pierce", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_ice_regent_aura", kind = "passive", name = "潮気金", name_en = "Tide Pierce", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.10 } },
      { id = "boss_ice_regent_overlord", kind = "passive", name = "覇気金", name_en = "Overlord Pierce", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A sovereign draped in frost, ruling the first halls with quiet authority.",
      ja = "霜を纏う主。静かな威厳で最初の回廊を統べる。",
    },
  },
  {
    id = "boss_docker_leviathan",
    name_en = "Docker Leviathan",
    name_ja = "ドッカーリヴァイアサン",
    icon = "",
    stats = { hp = 13, atk = 5, def = 3, accuracy = 90 },
    elements = { "water", "normal" },
    appear = { stages = {} },
    drops = {
      common = { "short_bow", "thick_cloak", "guard_amulet" },
      rare = { "edge_shield", "rest_armor" },
      pet = { "wind_bird" },
    },
    skills = {
      { id = "boss_docker_leviathan_strike", kind = "active", name = "水槍閃", name_en = "Water Spear Glint", description = "水流で押し流す。", description_en = "Sweeps forward with a surge of water.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_docker_leviathan_aura", kind = "passive", name = "冷気閃", name_en = "Chill Glint", description = "水気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with moisture.", bonus_mul = { atk = 1.10 } },
      { id = "boss_docker_leviathan_overlord", kind = "passive", name = "覇気閃", name_en = "Overlord Glint", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A colossal carrier that turns the corridor into a rolling tide.",
      ja = "回廊を奔流に変える、巨大な運び手。",
    },
  },
  {
    id = "boss_ruby_empress",
    name_en = "Ruby Empress",
    name_ja = "紅玉の女帝",
    icon = "",
    stats = { hp = 12, atk = 5, def = 3, accuracy = 91 },
    elements = { "light", "fire" },
    appear = { stages = {} },
    drops = {
      common = { "wood_sword", "light_robe", "swift_ring" },
      rare = { "typing_blade", "fast_sand" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "boss_ruby_empress_strike", kind = "active", name = "星彩打弧", name_en = "Star Break Quake", description = "眩い光で切り込む。", description_en = "Cuts in with dazzling light.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_ruby_empress_aura", kind = "passive", name = "聖気弧", name_en = "Holy Glow Quake", description = "光気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with light.", bonus_mul = { atk = 1.10 } },
      { id = "boss_ruby_empress_overlord", kind = "passive", name = "覇気弧", name_en = "Overlord Quake", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A jewel-bright ruler who commands the mid halls with radiant resolve.",
      ja = "宝石のように輝き、中層を照らして支配する女帝。",
    },
  },
  {
    id = "boss_python_prime",
    name_en = "Python Prime",
    name_ja = "パイソンプライム",
    icon = "",
    stats = { hp = 12, atk = 6, def = 2, accuracy = 91 },
    elements = { "grass", "dark" },
    appear = { stages = {} },
    drops = {
      common = { "leather_armor", "swift_ring", "sleep_pendant" },
      rare = { "save_hammer", "repeat_cloak" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "boss_python_prime_strike", kind = "active", name = "苔斬旋", name_en = "Moss Slash Rift", description = "蔓や棘で追い詰める。", description_en = "Presses in with vines and thorns.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_python_prime_aura", kind = "passive", name = "緑護旋", name_en = "Verdant Guard Rift", description = "芽生えで攻撃力がわずかに上がる。", description_en = "Attack rises slightly with budding growth.", bonus_mul = { atk = 1.10 } },
      { id = "boss_python_prime_overlord", kind = "passive", name = "覇気旋", name_en = "Overlord Rift", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "An ancient coil that tightens every loop until the air cracks.",
      ja = "古の螺旋が輪を締め上げ、空気を裂くほど迫る。",
    },
  },
  {
    id = "boss_git_overlord",
    name_en = "Git Overlord",
    name_ja = "ギットオーバーロード",
    icon = "",
    stats = { hp = 13, atk = 6, def = 3, accuracy = 89 },
    elements = { "dark", "normal" },
    appear = { stages = {} },
    drops = {
      common = { "round_shield", "leather_armor", "record_ring", "traveler_coat" },
      rare = { "save_hammer", "focus_bracelet", "bulwark_plate" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "boss_git_overlord_strike", kind = "active", name = "宵牙銀", name_en = "Dusk Fang Burst", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_git_overlord_aura", kind = "passive", name = "暗気銀", name_en = "Dark Pulse Burst", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.10 } },
      { id = "boss_git_overlord_overlord", kind = "passive", name = "覇気銀", name_en = "Overlord Burst", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A tyrant of branching paths, sealing exits with layered history.",
      ja = "分岐の道を支配し、幾重の履歴で出口を封じる暴君。",
    },
  },
  {
    id = "boss_rust_juggernaut",
    name_en = "Rust Juggernaut",
    name_ja = "ラストジャガーノート",
    icon = "",
    stats = { hp = 14, atk = 6, def = 4, accuracy = 88 },
    elements = { "fire", "dark" },
    appear = { stages = {} },
    drops = {
      common = { "round_shield", "thick_cloak", "guard_amulet" },
      rare = { "rest_armor", "fast_sand" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "boss_rust_juggernaut_strike", kind = "active", name = "燃撃黒", name_en = "Scorch Strike Echo", description = "燃える一撃を放つ。", description_en = "Delivers a burning hit.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_rust_juggernaut_aura", kind = "passive", name = "灼護黒", name_en = "Scorch Guard Echo", description = "熱気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with heat.", bonus_mul = { atk = 1.10 } },
      { id = "boss_rust_juggernaut_overlord", kind = "passive", name = "覇気黒", name_en = "Overlord Echo", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A relentless crusher whose armor heats the very stone around it.",
      ja = "装甲が石を灼くほどの熱を帯びた、止まらぬ破壊者。",
    },
  },
  {
    id = "boss_gnu_ancestral",
    name_en = "GNU Ancestral",
    name_ja = "ヌーの祖霊",
    icon = "",
    stats = { hp = 14, atk = 5, def = 4, accuracy = 90 },
    elements = { "normal", "dark" },
    appear = { stages = {} },
    drops = {
      common = { "wood_sword", "cloth_armor", "sleep_pendant" },
      rare = { "repeat_cloak", "focus_bracelet" },
      pet = { "stone_spirit" },
    },
    skills = {
      { id = "boss_gnu_ancestral_strike", kind = "active", name = "嚙み砕き雷", name_en = "Crunch Ward", description = "勢いよく襲いかかる。", description_en = "Strikes with a sudden rush.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_gnu_ancestral_aura", kind = "passive", name = "守勢雷", name_en = "Guard Ward", description = "闘気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with fighting spirit.", bonus_mul = { atk = 1.10 } },
      { id = "boss_gnu_ancestral_overlord", kind = "passive", name = "覇気雷", name_en = "Overlord Ward", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "An ancient guardian that tramples forward with unshakable creed.",
      ja = "揺るがぬ信条で踏み進む、古き守護者の祖霊。",
    },
  },
  {
    id = "boss_null_horizon",
    name_en = "Null Horizon",
    name_ja = "ヌルホライゾン",
    icon = "",
    stats = { hp = 15, atk = 7, def = 4, accuracy = 92 },
    elements = { "dark", "light" },
    appear = { stages = {} },
    drops = {
      common = { "light_robe", "silent_ear", "record_ring" },
      rare = { "typing_blade", "save_hammer" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "boss_null_horizon_strike", kind = "active", name = "闇裂き煌", name_en = "Gloom Rend Bloom", description = "影をまとい切り裂く。", description_en = "Slashes under the cover of shadows.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_null_horizon_aura", kind = "passive", name = "闇衣煌", name_en = "Gloom Bloom", description = "闇気で攻撃力がわずかに上がる。", description_en = "Attack rises slightly with darkness.", bonus_mul = { atk = 1.10 } },
      { id = "boss_null_horizon_overlord", kind = "passive", name = "覇気煌", name_en = "Overlord Bloom", description = "覇気で防御もわずかに上がる。", description_en = "Defense rises slightly with overwhelming presence.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A final boundary where light and shadow cancel, leaving only silence.",
      ja = "光と影が相殺され、沈黙だけが残る終端の境界。",
    },
  },
}

-- ファイルタイプ解放装備を関連する敵に紐付けて追加する。
local drop_overrides = {
  dust_slime = { rare = { "lua_sigil_blade" } },
  vim_mantis = { rare = { "vim_focus_ring" } },
  c_sentinel = { rare = { "c_forge_spear" } },
  cpp_colossus = { rare = { "cpp_heap_shield" } },
  python_serpent = { rare = { "python_coil_whip" } },
  node_phantom = { rare = { "js_spark_blade", "ts_guard_mail" } },
  go_gopher = { rare = { "go_stride_band" } },
  rust_crab = { rare = { "rust_crust_armor" } },
  java_ifrit = { rare = { "java_forge_staff" } },
  kotlin_fox = { rare = { "kotlin_arc_amulet" } },
  swift_raptor = { rare = { "swift_wind_dagger" } },
  ruby_scarab = { rare = { "ruby_bloom_ring" } },
  php_elephant = { rare = { "php_bastion_cloak" } },
  bash_hound = { rare = { "bash_echo_charm", "shell_tide_ring" } },
  docker_whale = { rare = { "html_canvas_cloak", "css_palette_charm", "yaml_scroll_robe" } },
  mysql_dolphin = { rare = { "sql_depth_spear", "json_mirror_ring" } },
  postgres_colossus = { rare = { "toml_anchor_band" } },
  gnu_bison = { rare = { "markdown_quill_pendant" } },
}

local function finalize_enemies(entries)
  -- 攻撃速度の既定値を付与して交互ターンの間隔を整える。
  apply_speed_defaults(entries, 2)
  -- 経験値倍率を補完して敵ごとの差を明確にする。
  apply_exp_defaults(entries)
  -- 敵スキルは個別定義をそのまま付与して戦闘演出に使う。
  apply_gold_defaults(entries)
  apply_drop_overrides(entries, drop_overrides)
  return entries
end

M.enemies = finalize_enemies(enemies)

return M
