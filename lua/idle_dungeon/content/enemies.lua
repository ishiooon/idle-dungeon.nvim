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
    name_en = "Loop Slime",
    name_ja = "ループスライム",
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
      { id = "dust_slime_strike", kind = "active", name = "ループポップスマッシュ", name_en = "Loop Pop Smash", description = "パワーダッシュでまっすぐぶつかる。", description_en = "Charges straight in with power.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "dust_slime_aura", kind = "passive", name = "ループポップドライブ", name_en = "Loop Pop Drive", description = "フォーム安定でアタックが少しアップ。", description_en = "Steadies form and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It rides a steady rhythm, then snaps forward the moment your guard loosens.",
      ja = "一定のリズムで揺れながら、ガードがゆるんだ瞬間に一気に踏み込む。",
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
      { id = "prism_slime_strike", kind = "active", name = "プリズムポップスマッシュ", name_en = "Prism Pop Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "prism_slime_aura", kind = "passive", name = "プリズムポップドライブ", name_en = "Prism Pop Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its prism body scatters light and turns even a short dash into a sharp threat.",
      ja = "プリズムの体で光を散らし、短い踏み込みさえ鋭い脅威に変える。",
    },
  },
  {
    id = "tux_penguin",
    name_en = "Kernel Penguin",
    name_ja = "カーネルペンギン",
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
      { id = "tux_penguin_strike", kind = "active", name = "カーネルスライドスマッシュ", name_en = "Kernel Slide Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "tux_penguin_aura", kind = "passive", name = "カーネルスライドドライブ", name_en = "Kernel Slide Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A calm slider that closes distance cleanly and lands precise follow-ups.",
      ja = "落ち着いたスライドで間合いを詰め、正確な追撃を重ねる。",
    },
  },
  {
    id = "vim_mantis",
    name_en = "Modal Mantis",
    name_ja = "モーダルマンティス",
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
      { id = "vim_mantis_strike", kind = "active", name = "モーダルシックルスマッシュ", name_en = "Modal Sickle Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "vim_mantis_aura", kind = "passive", name = "モーダルシックルドライブ", name_en = "Modal Sickle Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It trims every motion to the minimum, then commits with a fast arc slash.",
      ja = "動きを最小限まで削ぎ落とし、速いアークスラッシュで勝負を決める。",
    },
  },
  {
    id = "c_sentinel",
    name_en = "Syntax Guard",
    name_ja = "シンタックスガード",
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
      { id = "c_sentinel_strike", kind = "active", name = "シンタックスコアスマッシュ", name_en = "Syntax Core Smash", description = "パワーダッシュでまっすぐぶつかる。", description_en = "Charges straight in with power.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "c_sentinel_aura", kind = "passive", name = "シンタックスコアドライブ", name_en = "Syntax Core Drive", description = "フォーム安定でアタックが少しアップ。", description_en = "Steadies form and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Built for direct pressure, it advances in straight lines and breaks hesitation.",
      ja = "直線的なプレッシャーで押し込み、ためらいをそのまま崩してくる。",
    },
  },
  {
    id = "cpp_colossus",
    name_en = "Template Colossus",
    name_ja = "テンプレコロッサス",
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
      { id = "cpp_colossus_strike", kind = "active", name = "テンプレクラッシュスマッシュ", name_en = "Template Crush Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "cpp_colossus_aura", kind = "passive", name = "テンプレクラッシュドライブ", name_en = "Template Crush Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Layered armor and heavy momentum make each approach feel unavoidable.",
      ja = "多層アーマーと重い推進力で、接近そのものが回避しづらい。",
    },
  },
  {
    id = "php_elephant",
    name_en = "Patchwork Elephant",
    name_ja = "パッチワークエレファント",
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
      { id = "php_elephant_strike", kind = "active", name = "パッチワークスタンプスマッシュ", name_en = "Patchwork Stomp Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "php_elephant_aura", kind = "passive", name = "パッチワークスタンプドライブ", name_en = "Patchwork Stomp Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A massive frame that keeps tempo steady and finishes with crushing force.",
      ja = "大きな体格でテンポを保ち、最後は圧のある一撃で押し切る。",
    },
  },
  {
    id = "docker_whale",
    name_en = "Container Whale",
    name_ja = "コンテナホエール",
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
      { id = "docker_whale_strike", kind = "active", name = "コンテナウェイクスマッシュ", name_en = "Container Wake Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "docker_whale_aura", kind = "passive", name = "コンテナウェイクドライブ", name_en = "Container Wake Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It carries the field's flow on its back and shifts lanes to its advantage.",
      ja = "戦場の流れを背で運び、レーン配置を自分に有利な形へ動かす。",
    },
  },
  {
    id = "go_gopher",
    name_en = "Rocket Gopher",
    name_ja = "ロケットゴーファー",
    icon = "",
    -- 序盤プールに入れるため、体力を基準値へ合わせて即落ちを防ぐ。
    stats = { hp = 6, atk = 3, def = 1, accuracy = 90 },
    elements = { "fire", "normal" },
    appear = { min = 2, max = 6 },
    drops = {
      common = { "short_spell_staff", "swift_ring", "light_robe" },
      rare = { "fast_sand" },
      pet = { "tiny_familiar" },
    },
    skills = {
      { id = "go_gopher_strike", kind = "active", name = "ロケットドリルスマッシュ", name_en = "Rocket Drill Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "go_gopher_aura", kind = "passive", name = "ロケットドリルドライブ", name_en = "Rocket Drill Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Light on the surface, but its acceleration turns small openings into big damage.",
      ja = "軽い動きに見えて、加速が小さなスキを大きな被害へ変えてくる。",
    },
  },
  {
    id = "bash_hound",
    name_en = "Shellfang Hound",
    name_ja = "シェルファングハウンド",
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
      { id = "bash_hound_strike", kind = "active", name = "シェルファングラッシュスマッシュ", name_en = "Shellfang Rush Smash", description = "パワーダッシュでまっすぐぶつかる。", description_en = "Charges straight in with power.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bash_hound_aura", kind = "passive", name = "シェルファングラッシュドライブ", name_en = "Shellfang Rush Drive", description = "フォーム安定でアタックが少しアップ。", description_en = "Steadies form and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It probes with quick bites and commits the instant your stance opens.",
      ja = "小刻みな噛みで様子を見て、姿勢が開いた瞬間に本命を通す。",
    },
  },
  {
    id = "mysql_dolphin",
    name_en = "Query Dolphin",
    name_ja = "クエリードルフィン",
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
      { id = "mysql_dolphin_strike", kind = "active", name = "クエリースプラッシュスマッシュ", name_en = "Query Splash Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mysql_dolphin_aura", kind = "passive", name = "クエリースプラッシュドライブ", name_en = "Query Splash Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It threads through tight paths and surfaces exactly where pressure peaks.",
      ja = "狭い経路を抜け、プレッシャーが最大になる地点で姿を見せる。",
    },
  },
  {
    id = "postgres_colossus",
    name_en = "Ledger Colossus",
    name_ja = "レジャーコロッサス",
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
      { id = "postgres_colossus_strike", kind = "active", name = "レジャータイドスマッシュ", name_en = "Ledger Tide Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "postgres_colossus_aura", kind = "passive", name = "レジャータイドドライブ", name_en = "Ledger Tide Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Slow and composed, it stacks constant pressure until retreat stops working.",
      ja = "ゆるがない構えで圧を積み上げ、後退の選択肢をじわじわ削る。",
    },
  },
  {
    id = "dbeaver",
    name_en = "Schema Beaver",
    name_ja = "スキーマビーバー",
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
      { id = "dbeaver_strike", kind = "active", name = "スキーマカーブスマッシュ", name_en = "Schema Carve Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "dbeaver_aura", kind = "passive", name = "スキーマカーブドライブ", name_en = "Schema Carve Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It carves clean channels into the battlefield and controls movement lines.",
      ja = "戦場に整った水路を刻み、移動ラインそのものを支配する。",
    },
  },
  {
    id = "ruby_scarab",
    name_en = "Gem Scarab",
    name_ja = "ジェムスカラベ",
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
      { id = "ruby_scarab_strike", kind = "active", name = "ジェムシェルスマッシュ", name_en = "Gem Shell Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "ruby_scarab_aura", kind = "passive", name = "ジェムシェルドライブ", name_en = "Gem Shell Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its gem shell draws attention, then turns that attention into a clean counter.",
      ja = "ジェムの殻で視線を集め、その視線ごと確実なカウンターへ返す。",
    },
  },
  {
    id = "clojure_oracle",
    name_en = "Paren Oracle",
    name_ja = "パレンオラクル",
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
      { id = "clojure_oracle_strike", kind = "active", name = "パレンエコースマッシュ", name_en = "Paren Echo Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "clojure_oracle_aura", kind = "passive", name = "パレンエコードライブ", name_en = "Paren Echo Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It repeats quiet patterns until your options narrow to the route it expected.",
      ja = "静かなパターンを反復し、選択肢を予測したラインへ絞り込む。",
    },
  },
  {
    id = "node_phantom",
    name_en = "Event Phantom",
    name_ja = "イベントファントム",
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
      { id = "node_phantom_strike", kind = "active", name = "イベントブリンクスマッシュ", name_en = "Event Blink Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "node_phantom_aura", kind = "passive", name = "イベントブリンクドライブ", name_en = "Event Blink Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It blinks between beats and reappears where awareness is thinnest.",
      ja = "拍のあいだで明滅し、警戒が薄い位置に再出現する。",
    },
  },
  {
    id = "python_serpent",
    name_en = "Bytecoil Serpent",
    name_ja = "バイトコイルサーペント",
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
      { id = "python_serpent_strike", kind = "active", name = "バイトコイルファングスマッシュ", name_en = "Bytecoil Fang Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "python_serpent_aura", kind = "passive", name = "バイトコイルファングドライブ", name_en = "Bytecoil Fang Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "A smooth coil that shifts from loose control to sudden constriction.",
      ja = "なめらかなコイルで間合いを取り、急な締め込みで主導権を奪う。",
    },
  },
  {
    id = "java_ifrit",
    name_en = "Boiler Ifrit",
    name_ja = "ボイラーイフリート",
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
      { id = "java_ifrit_strike", kind = "active", name = "ボイラーフレイムスマッシュ", name_en = "Boiler Flame Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "java_ifrit_aura", kind = "passive", name = "ボイラーフレイムドライブ", name_en = "Boiler Flame Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Heat rises in controlled waves, then breaks in a bright final burst.",
      ja = "制御されたヒートの波を重ね、最後に明確なバーストで仕留める。",
    },
  },
  {
    id = "kotlin_fox",
    name_en = "Nullsafe Fox",
    name_ja = "ヌルセーフフォックス",
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
      { id = "kotlin_fox_strike", kind = "active", name = "ヌルセーフアークスマッシュ", name_en = "Nullsafe Arc Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "kotlin_fox_aura", kind = "passive", name = "ヌルセーフアークドライブ", name_en = "Nullsafe Arc Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its feints stay clean and readable, yet the finish arrives before you adjust.",
      ja = "クリーンなフェイントで見せながら、対応前にフィニッシュへ入る。",
    },
  },
  {
    id = "swift_raptor",
    name_en = "Arc Raptor",
    name_ja = "アークラプター",
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
      { id = "swift_raptor_strike", kind = "active", name = "アークフラッシュスマッシュ", name_en = "Arc Flash Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "swift_raptor_aura", kind = "passive", name = "アークフラッシュドライブ", name_en = "Arc Flash Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It converts pure speed into pressure and reaches you before the echo does.",
      ja = "純粋なスピードを圧へ変え、反響より先に間合いへ入ってくる。",
    },
  },
  {
    id = "git_wyrm",
    name_en = "Branch Wyrm",
    name_ja = "ブランチワーム",
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
      { id = "git_wyrm_strike", kind = "active", name = "ブランチバイトスマッシュ", name_en = "Branch Bite Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "git_wyrm_aura", kind = "passive", name = "ブランチバイトドライブ", name_en = "Branch Bite Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "It watches every branch point and punishes delay with immediate force.",
      ja = "分岐点をすべて監視し、判断の遅れを即座に咬み取る。",
    },
  },
  {
    id = "rust_crab",
    name_en = "Oxide Crab",
    name_ja = "オキサイドクラブ",
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
      { id = "rust_crab_strike", kind = "active", name = "オキサイドクロウスマッシュ", name_en = "Oxide Claw Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "rust_crab_aura", kind = "passive", name = "オキサイドクロウドライブ", name_en = "Oxide Claw Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Metal claws spark against stone while its low stance controls the exchange.",
      ja = "メタルの鋏が火花を散らし、低い構えで攻防の主導を握る。",
    },
  },
  {
    id = "gnu_bison",
    name_en = "Freehorn Bison",
    name_ja = "フリーホーンバイソン",
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
      { id = "gnu_bison_strike", kind = "active", name = "フリーホーンダッシュスマッシュ", name_en = "Freehorn Dash Smash", description = "パワーダッシュでまっすぐぶつかる。", description_en = "Charges straight in with power.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gnu_bison_aura", kind = "passive", name = "フリーホーンダッシュドライブ", name_en = "Freehorn Dash Drive", description = "フォーム安定でアタックが少しアップ。", description_en = "Steadies form and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "Its plan is simple and effective: build momentum and run through the line.",
      ja = "戦術は明快。勢いを積み、前線ごと押し抜いてくる。",
    },
  },
  -- 既存のモチーフに属性別の派生種を加え、戦術と雰囲気の幅を広げる。
  -- 派生種の戦利品は属性に合わせた装備が並ぶように調整する。
  {
    id = "penguin_ember",
    name_en = "Ember Penguin",
    name_ja = "エンバーペンギン",
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
      { id = "penguin_ember_strike", kind = "active", name = "エンバースライドスマッシュ", name_en = "Ember Slide Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_ember_aura", kind = "passive", name = "エンバースライドドライブ", name_en = "Ember Slide Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it uses short slides to close space and pick exact hit points.",
      ja = "抑えたヒートの気配をまとい、ショートスライドで距離を詰め、的確なポイントへ一撃を入れる。",
    },
  },
  {
    id = "penguin_tide",
    name_en = "Tide Penguin",
    name_ja = "タイドペンギン",
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
      { id = "penguin_tide_strike", kind = "active", name = "タイドスライドスマッシュ", name_en = "Tide Slide Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_tide_aura", kind = "passive", name = "タイドスライドドライブ", name_en = "Tide Slide Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it uses short slides to close space and pick exact hit points.",
      ja = "冷たいミストの軌跡を引き、ショートスライドで距離を詰め、的確なポイントへ一撃を入れる。",
    },
  },
  {
    id = "penguin_moss",
    name_en = "Moss Penguin",
    name_ja = "モスペンギン",
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
      { id = "penguin_moss_strike", kind = "active", name = "モススライドスマッシュ", name_en = "Moss Slide Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_moss_aura", kind = "passive", name = "モススライドドライブ", name_en = "Moss Slide Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it uses short slides to close space and pick exact hit points.",
      ja = "グリーンの圧を残しながら、ショートスライドで距離を詰め、的確なポイントへ一撃を入れる。",
    },
  },
  {
    id = "penguin_lumen",
    name_en = "Lumen Penguin",
    name_ja = "ルーメンペンギン",
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
      { id = "penguin_lumen_strike", kind = "active", name = "ルーメンスライドスマッシュ", name_en = "Lumen Slide Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_lumen_aura", kind = "passive", name = "ルーメンスライドドライブ", name_en = "Lumen Slide Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it uses short slides to close space and pick exact hit points.",
      ja = "淡いライトの残光を引き、ショートスライドで距離を詰め、的確なポイントへ一撃を入れる。",
    },
  },
  {
    id = "penguin_umbral",
    name_en = "Umbral Penguin",
    name_ja = "アンブラペンギン",
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
      { id = "penguin_umbral_strike", kind = "active", name = "アンブラスライドスマッシュ", name_en = "Umbral Slide Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "penguin_umbral_aura", kind = "passive", name = "アンブラスライドドライブ", name_en = "Umbral Slide Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it uses short slides to close space and pick exact hit points.",
      ja = "静かなシャドウを揺らしながら、ショートスライドで距離を詰め、的確なポイントへ一撃を入れる。",
    },
  },
  {
    id = "mantis_blaze",
    name_en = "Blaze Mantis",
    name_ja = "ブレイズマンティス",
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
      { id = "mantis_blaze_strike", kind = "active", name = "ブレイズシックルスマッシュ", name_en = "Blaze Sickle Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_blaze_aura", kind = "passive", name = "ブレイズシックルドライブ", name_en = "Blaze Sickle Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it measures range once and cuts through with a clean arc.",
      ja = "抑えたヒートの気配をまとい、一度だけ間合いを測り、クリーンなアークで斬り込む。",
    },
  },
  {
    id = "mantis_mist",
    name_en = "Mist Mantis",
    name_ja = "ミストマンティス",
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
      { id = "mantis_mist_strike", kind = "active", name = "ミストシックルスマッシュ", name_en = "Mist Sickle Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_mist_aura", kind = "passive", name = "ミストシックルドライブ", name_en = "Mist Sickle Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it measures range once and cuts through with a clean arc.",
      ja = "冷たいミストの軌跡を引き、一度だけ間合いを測り、クリーンなアークで斬り込む。",
    },
  },
  {
    id = "mantis_verdant",
    name_en = "Verdant Mantis",
    name_ja = "ヴァーダントマンティス",
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
      { id = "mantis_verdant_strike", kind = "active", name = "ヴァーダントシックルスマッシュ", name_en = "Verdant Sickle Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_verdant_aura", kind = "passive", name = "ヴァーダントシックルドライブ", name_en = "Verdant Sickle Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it measures range once and cuts through with a clean arc.",
      ja = "グリーンの圧を残しながら、一度だけ間合いを測り、クリーンなアークで斬り込む。",
    },
  },
  {
    id = "mantis_radiant",
    name_en = "Radiant Mantis",
    name_ja = "レイディアントマンティス",
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
      { id = "mantis_radiant_strike", kind = "active", name = "レイディアントシックルスマッシュ", name_en = "Radiant Sickle Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_radiant_aura", kind = "passive", name = "レイディアントシックルドライブ", name_en = "Radiant Sickle Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it measures range once and cuts through with a clean arc.",
      ja = "淡いライトの残光を引き、一度だけ間合いを測り、クリーンなアークで斬り込む。",
    },
  },
  {
    id = "mantis_gloom",
    name_en = "Gloom Mantis",
    name_ja = "グルームマンティス",
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
      { id = "mantis_gloom_strike", kind = "active", name = "グルームシックルスマッシュ", name_en = "Gloom Sickle Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "mantis_gloom_aura", kind = "passive", name = "グルームシックルドライブ", name_en = "Gloom Sickle Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it measures range once and cuts through with a clean arc.",
      ja = "静かなシャドウを揺らしながら、一度だけ間合いを測り、クリーンなアークで斬り込む。",
    },
  },
  {
    id = "whale_pyre",
    name_en = "Pyre Whale",
    name_ja = "パイアホエール",
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
      { id = "whale_pyre_strike", kind = "active", name = "パイアウェイクスマッシュ", name_en = "Pyre Wake Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_pyre_aura", kind = "passive", name = "パイアウェイクドライブ", name_en = "Pyre Wake Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it bends lanes into waves and steals stable footing.",
      ja = "抑えたヒートの気配をまとい、レーンをウェーブ化して安定した足場を奪う。",
    },
  },
  {
    id = "whale_rill",
    name_en = "Rill Whale",
    name_ja = "リルホエール",
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
      { id = "whale_rill_strike", kind = "active", name = "リルウェイクスマッシュ", name_en = "Rill Wake Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_rill_aura", kind = "passive", name = "リルウェイクドライブ", name_en = "Rill Wake Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it bends lanes into waves and steals stable footing.",
      ja = "冷たいミストの軌跡を引き、レーンをウェーブ化して安定した足場を奪う。",
    },
  },
  {
    id = "whale_sprout",
    name_en = "Sprout Whale",
    name_ja = "スプラウトホエール",
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
      { id = "whale_sprout_strike", kind = "active", name = "スプラウトウェイクスマッシュ", name_en = "Sprout Wake Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_sprout_aura", kind = "passive", name = "スプラウトウェイクドライブ", name_en = "Sprout Wake Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it bends lanes into waves and steals stable footing.",
      ja = "グリーンの圧を残しながら、レーンをウェーブ化して安定した足場を奪う。",
    },
  },
  {
    id = "whale_halo",
    name_en = "Halo Whale",
    name_ja = "ヘイローホエール",
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
      { id = "whale_halo_strike", kind = "active", name = "ヘイローウェイクスマッシュ", name_en = "Halo Wake Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_halo_aura", kind = "passive", name = "ヘイローウェイクドライブ", name_en = "Halo Wake Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it bends lanes into waves and steals stable footing.",
      ja = "淡いライトの残光を引き、レーンをウェーブ化して安定した足場を奪う。",
    },
  },
  {
    id = "whale_shade",
    name_en = "Shade Whale",
    name_ja = "シェイドホエール",
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
      { id = "whale_shade_strike", kind = "active", name = "シェイドウェイクスマッシュ", name_en = "Shade Wake Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "whale_shade_aura", kind = "passive", name = "シェイドウェイクドライブ", name_en = "Shade Wake Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it bends lanes into waves and steals stable footing.",
      ja = "静かなシャドウを揺らしながら、レーンをウェーブ化して安定した足場を奪う。",
    },
  },
  {
    id = "gopher_cinder",
    name_en = "Cinder Gopher",
    name_ja = "シンダーゴーファー",
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
      { id = "gopher_cinder_strike", kind = "active", name = "シンダードリルスマッシュ", name_en = "Cinder Drill Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_cinder_aura", kind = "passive", name = "シンダードリルドライブ", name_en = "Cinder Drill Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it tunnels out of sight and strikes from blind angles.",
      ja = "抑えたヒートの気配をまとい、潜行で視界から消え、死角から急襲する。",
    },
  },
  {
    id = "gopher_surge",
    name_en = "Surge Gopher",
    name_ja = "サージゴーファー",
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
      { id = "gopher_surge_strike", kind = "active", name = "サージドリルスマッシュ", name_en = "Surge Drill Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_surge_aura", kind = "passive", name = "サージドリルドライブ", name_en = "Surge Drill Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it tunnels out of sight and strikes from blind angles.",
      ja = "冷たいミストの軌跡を引き、潜行で視界から消え、死角から急襲する。",
    },
  },
  {
    id = "gopher_bloom",
    name_en = "Bloom Gopher",
    name_ja = "ブルームゴーファー",
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
      { id = "gopher_bloom_strike", kind = "active", name = "ブルームドリルスマッシュ", name_en = "Bloom Drill Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_bloom_aura", kind = "passive", name = "ブルームドリルドライブ", name_en = "Bloom Drill Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it tunnels out of sight and strikes from blind angles.",
      ja = "グリーンの圧を残しながら、潜行で視界から消え、死角から急襲する。",
    },
  },
  {
    id = "gopher_dawn",
    name_en = "Dawn Gopher",
    name_ja = "ドーンゴーファー",
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
      { id = "gopher_dawn_strike", kind = "active", name = "ドーンドリルスマッシュ", name_en = "Dawn Drill Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_dawn_aura", kind = "passive", name = "ドーンドリルドライブ", name_en = "Dawn Drill Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it tunnels out of sight and strikes from blind angles.",
      ja = "淡いライトの残光を引き、潜行で視界から消え、死角から急襲する。",
    },
  },
  {
    id = "gopher_dusk",
    name_en = "Dusk Gopher",
    name_ja = "ダスクゴーファー",
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
      { id = "gopher_dusk_strike", kind = "active", name = "ダスクドリルスマッシュ", name_en = "Dusk Drill Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "gopher_dusk_aura", kind = "passive", name = "ダスクドリルドライブ", name_en = "Dusk Drill Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it tunnels out of sight and strikes from blind angles.",
      ja = "静かなシャドウを揺らしながら、潜行で視界から消え、死角から急襲する。",
    },
  },
  {
    id = "elephant_sear",
    name_en = "Sear Elephant",
    name_ja = "シアエレファント",
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
      { id = "elephant_sear_strike", kind = "active", name = "シアスタンプスマッシュ", name_en = "Sear Stamp Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_sear_aura", kind = "passive", name = "シアスタンプドライブ", name_en = "Sear Stamp Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it advances like a moving wall and keeps pressure constant.",
      ja = "抑えたヒートの気配をまとい、動くウォールのように前進し、圧を切らさない。",
    },
  },
  {
    id = "elephant_abyss",
    name_en = "Abyss Elephant",
    name_ja = "アビスエレファント",
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
      { id = "elephant_abyss_strike", kind = "active", name = "アビススタンプスマッシュ", name_en = "Abyss Stamp Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_abyss_aura", kind = "passive", name = "アビススタンプドライブ", name_en = "Abyss Stamp Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it advances like a moving wall and keeps pressure constant.",
      ja = "冷たいミストの軌跡を引き、動くウォールのように前進し、圧を切らさない。",
    },
  },
  {
    id = "elephant_grove",
    name_en = "Grove Elephant",
    name_ja = "グローブエレファント",
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
      { id = "elephant_grove_strike", kind = "active", name = "グローブスタンプスマッシュ", name_en = "Grove Stamp Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_grove_aura", kind = "passive", name = "グローブスタンプドライブ", name_en = "Grove Stamp Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it advances like a moving wall and keeps pressure constant.",
      ja = "グリーンの圧を残しながら、動くウォールのように前進し、圧を切らさない。",
    },
  },
  {
    id = "elephant_aurora",
    name_en = "Aurora Elephant",
    name_ja = "オーロラエレファント",
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
      { id = "elephant_aurora_strike", kind = "active", name = "オーロラスタンプスマッシュ", name_en = "Aurora Stamp Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_aurora_aura", kind = "passive", name = "オーロラスタンプドライブ", name_en = "Aurora Stamp Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it advances like a moving wall and keeps pressure constant.",
      ja = "淡いライトの残光を引き、動くウォールのように前進し、圧を切らさない。",
    },
  },
  {
    id = "elephant_void",
    name_en = "Void Elephant",
    name_ja = "ヴォイドエレファント",
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
      { id = "elephant_void_strike", kind = "active", name = "ヴォイドスタンプスマッシュ", name_en = "Void Stamp Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "elephant_void_aura", kind = "passive", name = "ヴォイドスタンプドライブ", name_en = "Void Stamp Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it advances like a moving wall and keeps pressure constant.",
      ja = "静かなシャドウを揺らしながら、動くウォールのように前進し、圧を切らさない。",
    },
  },
  {
    id = "scarab_ember",
    name_en = "Ember Scarab",
    name_ja = "エンバースカラベ",
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
      { id = "scarab_ember_strike", kind = "active", name = "エンバーシェルスマッシュ", name_en = "Ember Shell Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_ember_aura", kind = "passive", name = "エンバーシェルドライブ", name_en = "Ember Shell Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it catches impact on shell and answers with tidy counters.",
      ja = "抑えたヒートの気配をまとい、シェルで衝撃を受けて、整ったカウンターを返す。",
    },
  },
  {
    id = "scarab_tide",
    name_en = "Tide Scarab",
    name_ja = "タイドスカラベ",
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
      { id = "scarab_tide_strike", kind = "active", name = "タイドシェルスマッシュ", name_en = "Tide Shell Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_tide_aura", kind = "passive", name = "タイドシェルドライブ", name_en = "Tide Shell Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it catches impact on shell and answers with tidy counters.",
      ja = "冷たいミストの軌跡を引き、シェルで衝撃を受けて、整ったカウンターを返す。",
    },
  },
  {
    id = "scarab_moss",
    name_en = "Moss Scarab",
    name_ja = "モススカラベ",
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
      { id = "scarab_moss_strike", kind = "active", name = "モスシェルスマッシュ", name_en = "Moss Shell Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_moss_aura", kind = "passive", name = "モスシェルドライブ", name_en = "Moss Shell Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it catches impact on shell and answers with tidy counters.",
      ja = "グリーンの圧を残しながら、シェルで衝撃を受けて、整ったカウンターを返す。",
    },
  },
  {
    id = "scarab_lumen",
    name_en = "Lumen Scarab",
    name_ja = "ルーメンスカラベ",
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
      { id = "scarab_lumen_strike", kind = "active", name = "ルーメンシェルスマッシュ", name_en = "Lumen Shell Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_lumen_aura", kind = "passive", name = "ルーメンシェルドライブ", name_en = "Lumen Shell Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it catches impact on shell and answers with tidy counters.",
      ja = "淡いライトの残光を引き、シェルで衝撃を受けて、整ったカウンターを返す。",
    },
  },
  {
    id = "scarab_umbral",
    name_en = "Umbral Scarab",
    name_ja = "アンブラスカラベ",
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
      { id = "scarab_umbral_strike", kind = "active", name = "アンブラシェルスマッシュ", name_en = "Umbral Shell Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "scarab_umbral_aura", kind = "passive", name = "アンブラシェルドライブ", name_en = "Umbral Shell Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it catches impact on shell and answers with tidy counters.",
      ja = "静かなシャドウを揺らしながら、シェルで衝撃を受けて、整ったカウンターを返す。",
    },
  },
  {
    id = "serpent_blaze",
    name_en = "Blaze Serpent",
    name_ja = "ブレイズサーペント",
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
      { id = "serpent_blaze_strike", kind = "active", name = "ブレイズコイルスマッシュ", name_en = "Blaze Coil Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_blaze_aura", kind = "passive", name = "ブレイズコイルドライブ", name_en = "Blaze Coil Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it coils along terrain and tightens when exits narrow.",
      ja = "抑えたヒートの気配をまとい、地形に沿ってコイルし、退路が狭まる瞬間に締める。",
    },
  },
  {
    id = "serpent_mist",
    name_en = "Mist Serpent",
    name_ja = "ミストサーペント",
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
      { id = "serpent_mist_strike", kind = "active", name = "ミストコイルスマッシュ", name_en = "Mist Coil Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_mist_aura", kind = "passive", name = "ミストコイルドライブ", name_en = "Mist Coil Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it coils along terrain and tightens when exits narrow.",
      ja = "冷たいミストの軌跡を引き、地形に沿ってコイルし、退路が狭まる瞬間に締める。",
    },
  },
  {
    id = "serpent_verdant",
    name_en = "Verdant Serpent",
    name_ja = "ヴァーダントサーペント",
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
      { id = "serpent_verdant_strike", kind = "active", name = "ヴァーダントコイルスマッシュ", name_en = "Verdant Coil Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_verdant_aura", kind = "passive", name = "ヴァーダントコイルドライブ", name_en = "Verdant Coil Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it coils along terrain and tightens when exits narrow.",
      ja = "グリーンの圧を残しながら、地形に沿ってコイルし、退路が狭まる瞬間に締める。",
    },
  },
  {
    id = "serpent_radiant",
    name_en = "Radiant Serpent",
    name_ja = "レイディアントサーペント",
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
      { id = "serpent_radiant_strike", kind = "active", name = "レイディアントコイルスマッシュ", name_en = "Radiant Coil Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_radiant_aura", kind = "passive", name = "レイディアントコイルドライブ", name_en = "Radiant Coil Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it coils along terrain and tightens when exits narrow.",
      ja = "淡いライトの残光を引き、地形に沿ってコイルし、退路が狭まる瞬間に締める。",
    },
  },
  {
    id = "serpent_gloom",
    name_en = "Gloom Serpent",
    name_ja = "グルームサーペント",
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
      { id = "serpent_gloom_strike", kind = "active", name = "グルームコイルスマッシュ", name_en = "Gloom Coil Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "serpent_gloom_aura", kind = "passive", name = "グルームコイルドライブ", name_en = "Gloom Coil Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it coils along terrain and tightens when exits narrow.",
      ja = "静かなシャドウを揺らしながら、地形に沿ってコイルし、退路が狭まる瞬間に締める。",
    },
  },
  {
    id = "fox_pyre",
    name_en = "Pyre Fox",
    name_ja = "パイアフォックス",
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
      { id = "fox_pyre_strike", kind = "active", name = "パイアテイルスマッシュ", name_en = "Pyre Tail Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_pyre_aura", kind = "passive", name = "パイアテイルドライブ", name_en = "Pyre Tail Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it layers feints and commits only at high-value timing.",
      ja = "抑えたヒートの気配をまとい、フェイントを重ね、価値の高いタイミングだけを突く。",
    },
  },
  {
    id = "fox_rill",
    name_en = "Rill Fox",
    name_ja = "リルフォックス",
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
      { id = "fox_rill_strike", kind = "active", name = "リルテイルスマッシュ", name_en = "Rill Tail Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_rill_aura", kind = "passive", name = "リルテイルドライブ", name_en = "Rill Tail Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it layers feints and commits only at high-value timing.",
      ja = "冷たいミストの軌跡を引き、フェイントを重ね、価値の高いタイミングだけを突く。",
    },
  },
  {
    id = "fox_sprout",
    name_en = "Sprout Fox",
    name_ja = "スプラウトフォックス",
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
      { id = "fox_sprout_strike", kind = "active", name = "スプラウトテイルスマッシュ", name_en = "Sprout Tail Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_sprout_aura", kind = "passive", name = "スプラウトテイルドライブ", name_en = "Sprout Tail Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it layers feints and commits only at high-value timing.",
      ja = "グリーンの圧を残しながら、フェイントを重ね、価値の高いタイミングだけを突く。",
    },
  },
  {
    id = "fox_halo",
    name_en = "Halo Fox",
    name_ja = "ヘイローフォックス",
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
      { id = "fox_halo_strike", kind = "active", name = "ヘイローテイルスマッシュ", name_en = "Halo Tail Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_halo_aura", kind = "passive", name = "ヘイローテイルドライブ", name_en = "Halo Tail Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it layers feints and commits only at high-value timing.",
      ja = "淡いライトの残光を引き、フェイントを重ね、価値の高いタイミングだけを突く。",
    },
  },
  {
    id = "fox_shade",
    name_en = "Shade Fox",
    name_ja = "シェイドフォックス",
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
      { id = "fox_shade_strike", kind = "active", name = "シェイドテイルスマッシュ", name_en = "Shade Tail Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "fox_shade_aura", kind = "passive", name = "シェイドテイルドライブ", name_en = "Shade Tail Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it layers feints and commits only at high-value timing.",
      ja = "静かなシャドウを揺らしながら、フェイントを重ね、価値の高いタイミングだけを突く。",
    },
  },
  {
    id = "crab_cinder",
    name_en = "Cinder Crab",
    name_ja = "シンダークラブ",
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
      { id = "crab_cinder_strike", kind = "active", name = "シンダークロウスマッシュ", name_en = "Cinder Claw Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_cinder_aura", kind = "passive", name = "シンダークロウドライブ", name_en = "Cinder Claw Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it stays low, absorbs contact, and returns hard counters.",
      ja = "抑えたヒートの気配をまとい、低い姿勢で受け止め、強いカウンターで流れを取り返す。",
    },
  },
  {
    id = "crab_surge",
    name_en = "Surge Crab",
    name_ja = "サージクラブ",
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
      { id = "crab_surge_strike", kind = "active", name = "サージクロウスマッシュ", name_en = "Surge Claw Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_surge_aura", kind = "passive", name = "サージクロウドライブ", name_en = "Surge Claw Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it stays low, absorbs contact, and returns hard counters.",
      ja = "冷たいミストの軌跡を引き、低い姿勢で受け止め、強いカウンターで流れを取り返す。",
    },
  },
  {
    id = "crab_bloom",
    name_en = "Bloom Crab",
    name_ja = "ブルームクラブ",
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
      { id = "crab_bloom_strike", kind = "active", name = "ブルームクロウスマッシュ", name_en = "Bloom Claw Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_bloom_aura", kind = "passive", name = "ブルームクロウドライブ", name_en = "Bloom Claw Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it stays low, absorbs contact, and returns hard counters.",
      ja = "グリーンの圧を残しながら、低い姿勢で受け止め、強いカウンターで流れを取り返す。",
    },
  },
  {
    id = "crab_dawn",
    name_en = "Dawn Crab",
    name_ja = "ドーンクラブ",
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
      { id = "crab_dawn_strike", kind = "active", name = "ドーンクロウスマッシュ", name_en = "Dawn Claw Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_dawn_aura", kind = "passive", name = "ドーンクロウドライブ", name_en = "Dawn Claw Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it stays low, absorbs contact, and returns hard counters.",
      ja = "淡いライトの残光を引き、低い姿勢で受け止め、強いカウンターで流れを取り返す。",
    },
  },
  {
    id = "crab_dusk",
    name_en = "Dusk Crab",
    name_ja = "ダスククラブ",
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
      { id = "crab_dusk_strike", kind = "active", name = "ダスククロウスマッシュ", name_en = "Dusk Claw Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "crab_dusk_aura", kind = "passive", name = "ダスククロウドライブ", name_en = "Dusk Claw Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it stays low, absorbs contact, and returns hard counters.",
      ja = "静かなシャドウを揺らしながら、低い姿勢で受け止め、強いカウンターで流れを取り返す。",
    },
  },
  {
    id = "bison_sear",
    name_en = "Sear Bison",
    name_ja = "シアバイソン",
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
      { id = "bison_sear_strike", kind = "active", name = "シアホーンスマッシュ", name_en = "Sear Horn Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_sear_aura", kind = "passive", name = "シアホーンドライブ", name_en = "Sear Horn Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a restrained heat aura, it builds speed over distance and breaks clustered lines.",
      ja = "抑えたヒートの気配をまとい、助走で速度を作り、密集した陣形をまとめて崩す。",
    },
  },
  {
    id = "bison_abyss",
    name_en = "Abyss Bison",
    name_ja = "アビスバイソン",
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
      { id = "bison_abyss_strike", kind = "active", name = "アビスホーンスマッシュ", name_en = "Abyss Horn Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_abyss_aura", kind = "passive", name = "アビスホーンドライブ", name_en = "Abyss Horn Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With a cool mist wake, it builds speed over distance and breaks clustered lines.",
      ja = "冷たいミストの軌跡を引き、助走で速度を作り、密集した陣形をまとめて崩す。",
    },
  },
  {
    id = "bison_grove",
    name_en = "Grove Bison",
    name_ja = "グローブバイソン",
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
      { id = "bison_grove_strike", kind = "active", name = "グローブホーンスマッシュ", name_en = "Grove Horn Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_grove_aura", kind = "passive", name = "グローブホーンドライブ", name_en = "Grove Horn Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With green pressure in its trail, it builds speed over distance and breaks clustered lines.",
      ja = "グリーンの圧を残しながら、助走で速度を作り、密集した陣形をまとめて崩す。",
    },
  },
  {
    id = "bison_aurora",
    name_en = "Aurora Bison",
    name_ja = "オーロラバイソン",
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
      { id = "bison_aurora_strike", kind = "active", name = "オーロラホーンスマッシュ", name_en = "Aurora Horn Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_aurora_aura", kind = "passive", name = "オーロラホーンドライブ", name_en = "Aurora Horn Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With pale light streaks, it builds speed over distance and breaks clustered lines.",
      ja = "淡いライトの残光を引き、助走で速度を作り、密集した陣形をまとめて崩す。",
    },
  },
  {
    id = "bison_void",
    name_en = "Void Bison",
    name_ja = "ヴォイドバイソン",
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
      { id = "bison_void_strike", kind = "active", name = "ヴォイドホーンスマッシュ", name_en = "Void Horn Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.10, accuracy = 0, rate = 0.30 },
      { id = "bison_void_aura", kind = "passive", name = "ヴォイドホーンドライブ", name_en = "Void Horn Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.05 } },
    },
    flavor = {
      en = "With quiet shadow drift, it builds speed over distance and breaks clustered lines.",
      ja = "静かなシャドウを揺らしながら、助走で速度を作り、密集した陣形をまとめて崩す。",
    },
  },
  {
    id = "boss_ice_regent",
    name_en = "Ice Regent",
    name_ja = "アイスリージェント",
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
      { id = "boss_ice_regent_strike", kind = "active", name = "アイスクラウンスマッシュ", name_en = "Ice Crown Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_ice_regent_aura", kind = "passive", name = "アイスクラウンドライブ", name_en = "Ice Crown Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_ice_regent_overlord", kind = "passive", name = "アイスクラウンオーラ", name_en = "Ice Crown Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A composed ruler of frost that controls pace and spacing with cold authority.",
      ja = "冷たい威圧でテンポと距離を支配する、凍気のリージェント。",
    },
  },
  {
    id = "boss_docker_leviathan",
    name_en = "Harbor Leviathan",
    name_ja = "ハーバーリヴァイアサン",
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
      { id = "boss_docker_leviathan_strike", kind = "active", name = "ハーバーアビススマッシュ", name_en = "Harbor Abyss Smash", description = "ウォーターダッシュでまとめてノックバック。", description_en = "Surges in with a splashy rush.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_docker_leviathan_aura", kind = "passive", name = "ハーバーアビスドライブ", name_en = "Harbor Abyss Drive", description = "リズムを合わせてアタックが少しアップ。", description_en = "Finds the rhythm and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_docker_leviathan_overlord", kind = "passive", name = "ハーバーアビスオーラ", name_en = "Harbor Abyss Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A harbor-scale leviathan that shifts the entire battleline with one sweep.",
      ja = "一振りで戦列全体を動かす、港湾級のリヴァイアサン。",
    },
  },
  {
    id = "boss_ruby_empress",
    name_en = "Ruby Empress",
    name_ja = "ルビーエンプレス",
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
      { id = "boss_ruby_empress_strike", kind = "active", name = "ルビーヴァーディクトスマッシュ", name_en = "Ruby Verdict Smash", description = "フラッシュスラッシュで一気にせめる。", description_en = "Cuts in with a bright flash slash.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_ruby_empress_aura", kind = "passive", name = "ルビーヴァーディクトドライブ", name_en = "Ruby Verdict Drive", description = "ライトチャージでアタックが少しアップ。", description_en = "Charges light and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_ruby_empress_overlord", kind = "passive", name = "ルビーヴァーディクトオーラ", name_en = "Ruby Verdict Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "Radiant and severe, she turns every glint into sustained pressure.",
      ja = "鮮烈な輝きを保ったまま、あらゆる光を継続的な圧へ変える。",
    },
  },
  {
    id = "boss_python_prime",
    name_en = "Prime Constrictor",
    name_ja = "プライムコンストリクター",
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
      { id = "boss_python_prime_strike", kind = "active", name = "プライムコイルスマッシュ", name_en = "Prime Coil Smash", description = "ツタコンボでじわっと追いこむ。", description_en = "Pins targets with a vine combo.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_python_prime_aura", kind = "passive", name = "プライムコイルドライブ", name_en = "Prime Coil Drive", description = "グリーンパワーでアタックが少しアップ。", description_en = "Channels green energy and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_python_prime_overlord", kind = "passive", name = "プライムコイルオーラ", name_en = "Prime Coil Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "The prime coil closes angles one by one until escape becomes theoretical.",
      ja = "原初のコイルが角度を順に封じ、退路を理論上のものにする。",
    },
  },
  {
    id = "boss_git_overlord",
    name_en = "Branch Overlord",
    name_ja = "ブランチオーバーロード",
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
      { id = "boss_git_overlord_strike", kind = "active", name = "ブランチタイラントスマッシュ", name_en = "Branch Tyrant Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_git_overlord_aura", kind = "passive", name = "ブランチタイラントドライブ", name_en = "Branch Tyrant Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_git_overlord_overlord", kind = "passive", name = "ブランチタイラントオーラ", name_en = "Branch Tyrant Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "It selects one route and crushes all alternatives without pause.",
      ja = "一本のルートだけを残し、他の可能性を迷いなく圧し潰す。",
    },
  },
  {
    id = "boss_rust_juggernaut",
    name_en = "Ferrum Juggernaut",
    name_ja = "フェラムジャガーノート",
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
      { id = "boss_rust_juggernaut_strike", kind = "active", name = "フェラムクラッシュスマッシュ", name_en = "Ferrum Crush Smash", description = "アツいダッシュでドカンとぶつかる。", description_en = "Blasts in with a hot dash.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_rust_juggernaut_aura", kind = "passive", name = "フェラムクラッシュドライブ", name_en = "Ferrum Crush Drive", description = "ヒートアップしてアタックが少しアップ。", description_en = "Heats up and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_rust_juggernaut_overlord", kind = "passive", name = "フェラムクラッシュオーラ", name_en = "Ferrum Crush Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "A furnace-heavy juggernaut that treats walls and warriors the same.",
      ja = "炉のような重装で、壁も敵も同じ重さで砕いて進む。",
    },
  },
  {
    id = "boss_gnu_ancestral",
    name_en = "Ancestral Freehorn",
    name_ja = "アンセストラルフリーホーン",
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
      { id = "boss_gnu_ancestral_strike", kind = "active", name = "アンセストラルホーンスマッシュ", name_en = "Ancestral Horn Smash", description = "パワーダッシュでまっすぐぶつかる。", description_en = "Charges straight in with power.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_gnu_ancestral_aura", kind = "passive", name = "アンセストラルホーンドライブ", name_en = "Ancestral Horn Drive", description = "フォーム安定でアタックが少しアップ。", description_en = "Steadies form and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_gnu_ancestral_overlord", kind = "passive", name = "アンセストラルホーンオーラ", name_en = "Ancestral Horn Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "An ancestral force that keeps charging long after normal limits fail.",
      ja = "常識的な限界を越えてなお突進を続ける、祖霊の力そのもの。",
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
      { id = "boss_null_horizon_strike", kind = "active", name = "ヌルエクリプススマッシュ", name_en = "Null Eclipse Smash", description = "シャドウステップでスパッときりこむ。", description_en = "Dives in with a shadow step.", power = 1.25, accuracy = 0, rate = 0.35 },
      { id = "boss_null_horizon_aura", kind = "passive", name = "ヌルエクリプスドライブ", name_en = "Null Eclipse Drive", description = "ダークチャージでアタックが少しアップ。", description_en = "Charges shadow and boosts attack a little.", bonus_mul = { atk = 1.10 } },
      { id = "boss_null_horizon_overlord", kind = "passive", name = "ヌルエクリプスオーラ", name_en = "Null Eclipse Aura", description = "ボスオーラでディフェンスも少しアップ。", description_en = "Boss aura slightly boosts defense too.", bonus_mul = { def = 1.10 } },
    },
    flavor = {
      en = "At null horizon, light and shadow flatten into one sharp silence.",
      ja = "ヌルホライゾンでは、ライトとシャドウが重なり鋭い静寂だけが残る。",
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
