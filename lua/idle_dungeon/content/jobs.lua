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
  {
    id = "recorder",
    name = "剣士",
    role = "攻撃型",
    -- 攻撃速度は1以上の整数で、数値が大きいほど攻撃間隔が長くなる。
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
      active("slash", 5, "斬撃", "Slash", "基本の近接攻撃。", "A basic melee strike.", 1.1, 5, 0.35),
      active("double_slash", 8, "連撃", "Double Slash", "素早い二連の剣撃。", "A swift two-hit sword strike.", 1.25, 5, 0.25),
      passive("blade_aura", 12, "剣気解放", "Blade Aura", "集中力で攻撃力を底上げする。", "Focus heightens attack power.", { atk = 1.1 }),
      active("guard_break", 16, "崩し切り", "Guard Break", "守りを崩す重い一太刀。", "A heavy slash that cracks defenses.", 1.35, 0, 0.18),
      passive("duelist_stance", 20, "剣客の構え", "Duelist Stance", "間合いを見切り攻撃と命中を高める。", "Refine spacing to boost power and accuracy.", { atk = 1.08, accuracy = 1.08 }),
    },
  },
  {
    id = "guardian",
    name = "騎士",
    role = "防御型",
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
      passive("guard_stance", 5, "防御陣", "Guard Stance", "盾でダメージを軽減する。", "Brace to reduce damage.", { def = 1.12 }),
      active("shield_bash", 8, "盾打ち", "Shield Bash", "盾で体勢を崩しながら打ち込む。", "Crash in with a stunning shield blow.", 1.08, 10, 0.28),
      passive("iron_wall", 12, "鉄壁", "Iron Wall", "防御力を大きく高める。", "Greatly boosts defense.", { def = 1.2 }),
      active("oath_of_guard", 16, "守護の誓い", "Oath of Guard", "守りから反撃へ移る一撃。", "A countering strike born from steadfast guard.", 1.2, 8, 0.2),
      passive("fortress_heart", 20, "城塞の心", "Fortress Heart", "堅牢さと反撃力を同時に伸ばす。", "Fortify body and sharpen counter power.", { atk = 1.05, def = 1.12 }),
    },
  },
  {
    id = "hunter",
    name = "弓兵",
    role = "速攻型",
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
      active("aim_shot", 5, "精密射撃", "Aimed Shot", "命中率を高める。", "Raises accuracy.", 1.1, 10, 0.4),
      active("rapid_shot", 8, "速射", "Rapid Shot", "素早く矢を放つ。", "Fire arrows in quick succession.", 1.2, 5, 0.3),
      passive("wind_arrow", 12, "風の矢", "Wind Arrow", "狙いの精度を高める。", "Wind-guided shots sharpen accuracy.", { accuracy = 1.1 }),
      active("piercing_bolt", 16, "貫通射", "Piercing Bolt", "装甲ごと貫く集中射撃。", "A focused shot that punches through armor.", 1.32, 8, 0.2),
      passive("hawk_eye", 20, "鷹の眼", "Hawk Eye", "攻撃と命中を高い水準で維持する。", "Maintain strong power and precision.", { atk = 1.06, accuracy = 1.12 }),
    },
  },
  {
    id = "alchemist",
    name = "錬金術師",
    role = "支援型",
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
      active("mix", 5, "調合", "Mix", "短時間で攻めを整える。", "A quick formula that steadies offense.", 1.05, 5, 0.3),
      passive("catalyst", 8, "触媒強化", "Catalyst Boost", "攻撃と防御の底上げを狙う。", "Slightly raises attack and defense.", { atk = 1.05, def = 1.05 }),
      active("transmute", 12, "練成", "Transmute", "錬金術の力で能力を底上げする。", "Alchemy lifts overall performance.", 1.3, 5, 0.2),
      active("volatile_elixir", 16, "揮発触媒", "Volatile Elixir", "不安定な薬液で大きな一撃を狙う。", "Use unstable elixir for a heavy hit.", 1.4, 0, 0.15),
      passive("philosopher_skin", 20, "賢者皮膜", "Philosopher Skin", "理論を纏い防御と命中を底上げする。", "Wrap yourself in theory to raise defense and aim.", { def = 1.1, accuracy = 1.06 }),
    },
  },
  {
    id = "rogue",
    name = "盗賊",
    role = "俊敏型",
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
      active("ambush", 5, "奇襲", "Ambush", "先制攻撃で主導権を握る。", "Seize initiative with a surprise attack.", 1.35, 5, 0.4),
      passive("shadow_step", 8, "影踏み", "Shadow Step", "回避の要領を掴む。", "Footwork that improves defense.", { def = 1.05 }),
      passive("critical_eye", 12, "急所狙い", "Critical Eye", "致命打を狙う。", "Aim for vital spots to raise accuracy.", { accuracy = 1.1 }),
      active("poison_blade", 16, "毒刃", "Poison Blade", "深く抉るような鋭い一閃。", "A sharp cut that bites deep.", 1.35, 5, 0.2),
      passive("night_predator", 20, "夜の捕食者", "Night Predator", "攻撃と命中を高め一気に畳みかける。", "Boost power and precision for lethal bursts.", { atk = 1.08, accuracy = 1.08 }),
    },
  },
  {
    id = "cleric",
    name = "神官",
    role = "回復型",
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
      passive("prayer", 5, "祈り", "Prayer", "堅実な守りで戦線を支える。", "Support the line through steady protection.", { def = 1.05 }),
      active("purify", 8, "清め", "Purify", "乱れた流れを整える一手。", "A cleansing strike that restores order.", 1.1, 10, 0.25),
      passive("blessing", 12, "祝福", "Blessing", "支援効果を高める。", "Boosts support strength.", { atk = 1.05 }),
      active("holy_strike", 16, "聖撃", "Holy Strike", "清浄な力で迷いを断つ。", "Cut through doubt with sacred force.", 1.28, 10, 0.2),
      passive("sacred_guard", 20, "聖域護持", "Sacred Guard", "守りと照準の精度を底上げする。", "Improve both defense and precision.", { def = 1.1, accuracy = 1.08 }),
    },
  },
  {
    id = "beast_tamer",
    name = "猛獣使い",
    role = "共闘型",
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
      passive("pack_command", 5, "群れの号令", "Pack Command", "保持できるペット数が増える。", "Increase the number of pets you can keep.", {}, 1),
      active("beast_strike", 8, "連携牙撃", "Beast Strike", "仲間と連携して鋭く攻める。", "Strike sharply with your companions.", 1.2, 5, 0.3),
      passive("alpha_whistle", 12, "統率の笛", "Alpha Whistle", "さらに保持できるペット数が増える。", "Further increase pet capacity.", {}, 1),
      active("fangs_of_bond", 16, "絆牙連打", "Fangs of Bond", "連携を噛み合わせて強襲する。", "Chain assaults with bonded companions.", 1.35, 5, 0.2),
      passive("pack_instinct", 20, "群れの本能", "Pack Instinct", "保持可能数を増やしつつ連携精度も上げる。", "Increase pet capacity and teamwork accuracy.", { accuracy = 1.05 }, 1),
    },
  },
  {
    id = "monk",
    name = "武闘家",
    role = "近接型",
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
      active("flurry", 5, "連打", "Flurry", "素早く連続攻撃を行う。", "Strike with rapid blows.", 1.2, 5, 0.35),
      passive("spirit", 8, "気合", "Spirit", "攻撃力を引き上げる。", "Increase attack power.", { atk = 1.05 }),
      passive("battle_focus", 12, "闘志解放", "Battle Focus", "戦いの集中力を高める。", "Sharpen focus to raise defense.", { def = 1.05 }),
      active("dragon_palm", 16, "龍掌", "Dragon Palm", "踏み込みと同時に重い掌打を放つ。", "Step in and unleash a crushing palm strike.", 1.35, 5, 0.2),
      passive("calm_breath", 20, "静気循環", "Calm Breath", "呼吸を整え攻守を同時に高める。", "Steady breathing raises both offense and defense.", { atk = 1.06, def = 1.06 }),
    },
  },
}

return M
