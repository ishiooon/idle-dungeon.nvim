-- このモジュールはジョブ定義を提供する。

local M = {}

-- アクティブスキルを簡潔に定義するための補助関数。
local function active(id, level, name, name_en, description, description_en, power, accuracy, rate)
  return {
    id = id,
    level = level,
    kind = "active",
    name = name,
    name_en = name_en,
    description = description,
    description_en = description_en,
    power = power,
    accuracy = accuracy,
    rate = rate,
  }
end

-- パッシブスキルを簡潔に定義するための補助関数。
local function passive(id, level, name, name_en, description, description_en, bonus_mul, pet_slots)
  return {
    id = id,
    level = level,
    kind = "passive",
    name = name,
    name_en = name_en,
    description = description,
    description_en = description_en,
    bonus_mul = bonus_mul or {},
    pet_slots = pet_slots,
  }
end

-- 画像スプライトは廃止したため定義しない。
-- ジョブごとの役割差が体感できるように基礎能力値を整える。
M.jobs = {
  -- 敵コンテンツの文体に合わせ、短く手触りが伝わる説明へ再調整する。
  {
    id = "recorder",
    name = "剣士",
    name_en = "Swordsman",
    role = "攻撃型",
    role_en = "Offense",
    -- 攻撃速度は1以上の整数で、相手より高いほど攻撃間隔が短くなる。
    base = { hp = 14, atk = 5, def = 2, speed = 3 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 2, def = 1, speed = 0 },
    dialogue_ratio = 0.95,
    starter_items = { weapon = "wood_sword", armor = "cloth_armor", accessory = "record_ring" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "recorder",
    -- アクティブ/パッシブのスキル効果は戦闘計算で反映する。
    -- 英語表記は言語切り替え時の表示に使う。
    skills = {
      active("slash", 5, "斬撃", "Slash", "テンポよく間合いを詰める基本スラッシュ。", "Core slash that closes space on tempo.", 1.1, 5, 0.35),
      active("double_slash", 8, "連撃", "Double Slash", "リズムを崩さず二連で押し込む。", "A clean two-hit sequence with steady rhythm.", 1.25, 5, 0.25),
      passive("blade_aura", 12, "剣気解放", "Blade Aura", "ブレードオーラで打点を安定強化する。", "Blade aura stabilizes and boosts strike power.", { atk = 1.1 }),
      active("guard_break", 16, "崩し切り", "Guard Break", "重い踏み込みでガードごと割る。", "Breaks through guard with a heavy step-in cut.", 1.35, 0, 0.18),
      passive("duelist_stance", 20, "剣客の構え", "Duelist Stance", "デュエル姿勢で火力と命中を同時に伸ばす。", "Duelist posture raises both damage and accuracy.", { atk = 1.08, accuracy = 1.08 }),
    },
  },
  {
    id = "guardian",
    name = "騎士",
    name_en = "Guardian",
    role = "防御型",
    role_en = "Defense",
    -- 防御寄りのため攻撃速度は少し遅めに設定する。
    base = { hp = 18, atk = 2, def = 4, speed = 5 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 2, atk = 1, def = 2, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "round_shield", armor = "thick_cloak", accessory = "guard_amulet" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "guardian",
    -- ジョブごとに習得する技を定義する。
    skills = {
      passive("guard_stance", 5, "防御陣", "Guard Stance", "ガード姿勢を固めて被弾を抑える。", "Locks in guard stance to reduce incoming damage.", { def = 1.12 }),
      active("shield_bash", 8, "盾打ち", "Shield Bash", "シールドで押し当て、体勢をずらして叩く。", "Body-check with the shield, then bash off-balance.", 1.08, 10, 0.28),
      passive("iron_wall", 12, "鉄壁", "Iron Wall", "アイアンウォールで前線維持力を上げる。", "Iron Wall sharply boosts frontline durability.", { def = 1.2 }),
      active("oath_of_guard", 16, "守護の誓い", "Oath of Guard", "守りの流れから反撃へ切り替える。", "Converts defensive flow into a measured counter hit.", 1.2, 8, 0.2),
      passive("fortress_heart", 20, "城塞の心", "Fortress Heart", "フォートレスの心で攻防を同時に底上げ。", "Fortress heart raises both defense and counter pressure.", { atk = 1.05, def = 1.12 }),
    },
  },
  {
    id = "hunter",
    name = "弓兵",
    name_en = "Hunter",
    role = "速攻型",
    role_en = "Speed",
    -- 速攻型は攻撃間隔を短めにする。
    base = { hp = 12, atk = 4, def = 1, speed = 2 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 2, def = 0, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "short_bow", armor = "leather_armor", accessory = "swift_ring" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "hunter",
    -- ジョブごとに習得する技を定義する。
    skills = {
      active("aim_shot", 5, "精密射撃", "Aimed Shot", "照準を合わせて確実に射抜く。", "Tightens aim for a reliable opening shot.", 1.1, 10, 0.4),
      active("rapid_shot", 8, "速射", "Rapid Shot", "ショート間隔で連続して矢を放つ。", "Fires in short intervals to keep pressure high.", 1.2, 5, 0.3),
      passive("wind_arrow", 12, "風の矢", "Wind Arrow", "風を読む射線で命中精度を伸ばす。", "Reads wind lines to boost shot precision.", { accuracy = 1.1 }),
      active("piercing_bolt", 16, "貫通射", "Piercing Bolt", "一点集中のボルトで防御越しに抜く。", "Concentrated bolt that punches through armor.", 1.32, 8, 0.2),
      passive("hawk_eye", 20, "鷹の眼", "Hawk Eye", "ホークアイで火力と照準を高水準維持。", "Hawk Eye sustains high power and precision.", { atk = 1.06, accuracy = 1.12 }),
    },
  },
  {
    id = "alchemist",
    name = "錬金術師",
    name_en = "Alchemist",
    role = "支援型",
    role_en = "Support",
    -- 支援型は安定した間隔で行動する。
    base = { hp = 15, atk = 3, def = 2, speed = 4 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 1, def = 1, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "sand_staff", armor = "light_robe", accessory = "sleep_pendant" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "alchemist",
    -- ジョブごとに習得する技を定義する。
    skills = {
      active("mix", 5, "調合", "Mix", "クイック調合で攻めの流れを整える。", "Quick mix stabilizes offensive tempo.", 1.05, 5, 0.3),
      passive("catalyst", 8, "触媒強化", "Catalyst Boost", "触媒強化で攻防をバランスよく上げる。", "Catalyst boost lifts both attack and defense.", { atk = 1.05, def = 1.05 }),
      active("transmute", 12, "練成", "Transmute", "練成反応で一時的に出力を引き上げる。", "Transmute reaction spikes battle output.", 1.3, 5, 0.2),
      active("volatile_elixir", 16, "揮発触媒", "Volatile Elixir", "揮発エリクサーで高リスク高打点を狙う。", "Volatile elixir trades stability for heavy impact.", 1.4, 0, 0.15),
      passive("philosopher_skin", 20, "賢者皮膜", "Philosopher Skin", "賢者皮膜で防御と照準を静かに強化。", "Philosopher skin quietly improves defense and aim.", { def = 1.1, accuracy = 1.06 }),
    },
  },
  {
    id = "rogue",
    name = "盗賊",
    name_en = "Rogue",
    role = "俊敏型",
    role_en = "Agile",
    -- 俊敏型は素早い攻撃を重視する。
    base = { hp = 11, atk = 4, def = 1, speed = 2 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 1, def = 0, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "wood_sword", armor = "leather_armor", accessory = "swift_ring" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "hunter",
    -- ジョブごとに習得する技を定義する。
    skills = {
      active("ambush", 5, "奇襲", "Ambush", "視線の外から入り、先手を確保する。", "Enters from blind angle to seize first tempo.", 1.35, 5, 0.4),
      passive("shadow_step", 8, "影踏み", "Shadow Step", "シャドウステップで被弾ラインを外す。", "Shadow step shifts you off incoming lines.", { def = 1.05 }),
      passive("critical_eye", 12, "急所狙い", "Critical Eye", "急所ラインの見極めで命中を伸ばす。", "Critical reading improves vital-point accuracy.", { accuracy = 1.1 }),
      active("poison_blade", 16, "毒刃", "Poison Blade", "深く刺さる毒刃で継続圧をかける。", "Poison blade lands deep and keeps pressure up.", 1.35, 5, 0.2),
      passive("night_predator", 20, "夜の捕食者", "Night Predator", "夜の捕食者として火力と精度を同時強化。", "Night Predator boosts both burst and precision.", { atk = 1.08, accuracy = 1.08 }),
    },
  },
  {
    id = "cleric",
    name = "神官",
    name_en = "Cleric",
    role = "回復型",
    role_en = "Healer",
    -- 回復型は体力と防御を重視する。
    base = { hp = 16, atk = 2, def = 3, speed = 4 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 2, atk = 0, def = 1, speed = 0 },
    dialogue_ratio = 1.05,
    starter_items = { weapon = "sand_staff", armor = "light_robe", accessory = "guard_amulet" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "guardian",
    -- ジョブごとに習得する技を定義する。
    skills = {
      passive("prayer", 5, "祈り", "Prayer", "祈りで前線の安定感を底上げする。", "Prayer reinforces frontline stability.", { def = 1.05 }),
      active("purify", 8, "清め", "Purify", "乱れた流れを整えつつ打ち込む。", "Purify resets bad flow while striking forward.", 1.1, 10, 0.25),
      passive("blessing", 12, "祝福", "Blessing", "祝福の循環で支援出力を伸ばす。", "Blessing cycle raises support output.", { atk = 1.05 }),
      active("holy_strike", 16, "聖撃", "Holy Strike", "聖撃で迷いを断ち、ラインを押し戻す。", "Holy strike cuts doubt and pushes the line back.", 1.28, 10, 0.2),
      passive("sacred_guard", 20, "聖域護持", "Sacred Guard", "聖域維持で守りと命中を同時強化。", "Sacred guard improves both defense and accuracy.", { def = 1.1, accuracy = 1.08 }),
    },
  },
  {
    id = "beast_tamer",
    name = "猛獣使い",
    name_en = "Beast Tamer",
    role = "共闘型",
    role_en = "Tamer",
    -- 共闘型は本人の攻撃力を抑え、ペット運用で火力を補う。
    base = { hp = 13, atk = 3, def = 2, speed = 3 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 1, def = 1, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "wood_sword", armor = "leather_armor", accessory = "steady_band" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "hunter",
    -- パッシブで保持可能なペット数を増やす。
    skills = {
      passive("pack_command", 5, "群れの号令", "Pack Command", "パックコマンドで同行ペット枠を増やす。", "Pack command increases active pet capacity.", {}, 1),
      active("beast_strike", 8, "連携牙撃", "Beast Strike", "相棒との連携で牙撃を重ねる。", "Syncs with companions for chained fang strikes.", 1.2, 5, 0.3),
      passive("alpha_whistle", 12, "統率の笛", "Alpha Whistle", "アルファホイッスルでさらに編成を拡張。", "Alpha whistle further expands pet formation slots.", {}, 1),
      active("fangs_of_bond", 16, "絆牙連打", "Fangs of Bond", "絆のタイミングで連打を一気に通す。", "Bond timing converts into a focused multi-hit rush.", 1.35, 5, 0.2),
      passive("pack_instinct", 20, "群れの本能", "Pack Instinct", "群れの本能で枠と連携精度を同時強化。", "Pack instinct boosts both pet count and team accuracy.", { accuracy = 1.05 }, 1),
    },
  },
  {
    id = "monk",
    name = "武闘家",
    name_en = "Monk",
    role = "近接型",
    role_en = "Melee",
    -- 近接型は攻撃と体力の両方を伸ばす。
    base = { hp = 13, atk = 4, def = 2, speed = 3 },
    -- ジョブ固有の成長値を定義する。
    growth = { hp = 1, atk = 2, def = 1, speed = 0 },
    dialogue_ratio = 1.0,
    starter_items = { weapon = "wood_sword", armor = "cloth_armor", accessory = "steady_band" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "recorder",
    -- ジョブごとに習得する技を定義する。
    skills = {
      active("flurry", 5, "連打", "Flurry", "短い間隔で打点を重ねる近接ラッシュ。", "Melee flurry that stacks hits at short intervals.", 1.2, 5, 0.35),
      passive("spirit", 8, "気合", "Spirit", "スピリット集中で打撃出力を底上げ。", "Spirit focus lifts strike output.", { atk = 1.05 }),
      passive("battle_focus", 12, "闘志解放", "Battle Focus", "バトルフォーカスで守りの安定を作る。", "Battle focus improves defensive stability.", { def = 1.05 }),
      active("dragon_palm", 16, "龍掌", "Dragon Palm", "踏み込みと同時に重い掌打を叩き込む。", "Step in and drive a heavy dragon palm.", 1.35, 5, 0.2),
      passive("calm_breath", 20, "静気循環", "Calm Breath", "呼吸循環を整え、攻守の質を同時に上げる。", "Calm breathing raises both offense and defense quality.", { atk = 1.06, def = 1.06 }),
    },
  },
}

return M
