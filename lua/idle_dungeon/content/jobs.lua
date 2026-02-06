-- このモジュールはジョブ定義を提供する。

local M = {}

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
    starter_items = { weapon = "wood_sword", armor = "cloth_armor", accessory = "record_ring", companion = "white_slime" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "recorder",
    -- アクティブ/パッシブのスキル効果は戦闘計算で反映する。
    -- 英語表記は言語切り替え時の表示に使う。
    skills = {
      { id = "slash", level = 1, kind = "active", name = "斬撃", name_en = "Slash", description = "基本の近接攻撃。", description_en = "A basic melee strike.", power = 1.1, accuracy = 5, rate = 0.35 },
      { id = "double_slash", level = 5, kind = "active", name = "連撃", name_en = "Double Slash", description = "素早い二連の剣撃。", description_en = "A swift two-hit sword strike.", power = 1.25, accuracy = 5, rate = 0.25 },
      { id = "blade_aura", level = 12, kind = "passive", name = "剣気解放", name_en = "Blade Aura", description = "集中力で攻撃力を底上げする。", description_en = "Focus heightens attack power.", bonus_mul = { atk = 1.1 } },
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
    starter_items = { weapon = "round_shield", armor = "thick_cloak", accessory = "guard_amulet", companion = "stone_spirit" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "guardian",
    -- ジョブごとに習得する技を定義する。
    skills = {
      { id = "guard_stance", level = 1, kind = "passive", name = "防御陣", name_en = "Guard Stance", description = "盾でダメージを軽減する。", description_en = "Brace to reduce damage.", bonus_mul = { def = 1.1 } },
      { id = "iron_wall", level = 6, kind = "passive", name = "鉄壁", name_en = "Iron Wall", description = "防御力を大きく高める。", description_en = "Greatly boosts defense.", bonus_mul = { def = 1.2 } },
      { id = "oath_of_guard", level = 12, kind = "active", name = "守護の誓い", name_en = "Oath of Guard", description = "守りを固める一手を選ぶ。", description_en = "Choose a steadfast defensive move.", power = 1.0, accuracy = 10, rate = 0.2 },
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
    starter_items = { weapon = "short_bow", armor = "leather_armor", accessory = "swift_ring", companion = "wind_bird" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "hunter",
    -- ジョブごとに習得する技を定義する。
    skills = {
      { id = "aim_shot", level = 1, kind = "active", name = "精密射撃", name_en = "Aimed Shot", description = "命中率を高める。", description_en = "Raises accuracy.", power = 1.1, accuracy = 10, rate = 0.4 },
      { id = "rapid_shot", level = 5, kind = "active", name = "速射", name_en = "Rapid Shot", description = "素早く矢を放つ。", description_en = "Fire arrows in quick succession.", power = 1.2, accuracy = 5, rate = 0.3 },
      { id = "wind_arrow", level = 11, kind = "passive", name = "風の矢", name_en = "Wind Arrow", description = "素早さを活かした一撃。", description_en = "A swift shot that sharpens accuracy.", bonus_mul = { accuracy = 1.1 } },
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
    starter_items = { weapon = "sand_staff", armor = "light_robe", accessory = "sleep_pendant", companion = "tiny_familiar" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "alchemist",
    -- ジョブごとに習得する技を定義する。
    skills = {
      { id = "mix", level = 1, kind = "active", name = "調合", name_en = "Mix", description = "支援効果を高める。", description_en = "Enhances support effects.", power = 1.05, accuracy = 5, rate = 0.3 },
      { id = "catalyst", level = 6, kind = "passive", name = "触媒強化", name_en = "Catalyst Boost", description = "攻撃と防御の底上げを狙う。", description_en = "Slightly raises attack and defense.", bonus_mul = { atk = 1.05, def = 1.05 } },
      { id = "transmute", level = 12, kind = "active", name = "練成", name_en = "Transmute", description = "錬金術の力で能力を底上げする。", description_en = "Alchemy lifts overall performance.", power = 1.3, accuracy = 5, rate = 0.2 },
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
      { id = "ambush", level = 1, kind = "active", name = "奇襲", name_en = "Ambush", description = "先制攻撃で主導権を握る。", description_en = "Seize initiative with a surprise attack.", power = 1.35, accuracy = 5, rate = 0.4 },
      { id = "shadow_step", level = 5, kind = "passive", name = "影踏み", name_en = "Shadow Step", description = "回避の要領を掴む。", description_en = "Footwork that improves defense.", bonus_mul = { def = 1.05 } },
      { id = "critical_eye", level = 10, kind = "passive", name = "急所狙い", name_en = "Critical Eye", description = "致命打を狙う。", description_en = "Aim for vital spots to raise accuracy.", bonus_mul = { accuracy = 1.1 } },
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
      { id = "prayer", level = 1, kind = "passive", name = "祈り", name_en = "Prayer", description = "回復を意識した行動を取る。", description_en = "Act with healing in mind.", bonus_mul = { def = 1.05 } },
      { id = "purify", level = 6, kind = "active", name = "清め", name_en = "Purify", description = "守りを整える一手。", description_en = "A move that steadies defense.", power = 1.1, accuracy = 10, rate = 0.25 },
      { id = "blessing", level = 12, kind = "passive", name = "祝福", name_en = "Blessing", description = "支援効果を高める。", description_en = "Boosts support strength.", bonus_mul = { atk = 1.05 } },
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
    starter_items = { weapon = "wood_sword", armor = "leather_armor", accessory = "steady_band", companion = "white_slime" },
    -- 表示アイコンの強調色としてジョブごとの色味を割り当てる。
    sprite_palette = "hunter",
    -- パッシブで保持可能なペット数を増やす。
    skills = {
      { id = "pack_command", level = 1, kind = "passive", name = "群れの号令", name_en = "Pack Command", description = "保持できるペット数が増える。", description_en = "Increase the number of pets you can keep.", bonus_mul = {}, pet_slots = 1 },
      { id = "beast_strike", level = 6, kind = "active", name = "連携牙撃", name_en = "Beast Strike", description = "仲間と連携して鋭く攻める。", description_en = "Strike sharply with your companions.", power = 1.2, accuracy = 5, rate = 0.3 },
      { id = "alpha_whistle", level = 12, kind = "passive", name = "統率の笛", name_en = "Alpha Whistle", description = "さらに保持できるペット数が増える。", description_en = "Further increase pet capacity.", bonus_mul = {}, pet_slots = 1 },
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
      { id = "flurry", level = 1, kind = "active", name = "連打", name_en = "Flurry", description = "素早く連続攻撃を行う。", description_en = "Strike with rapid blows.", power = 1.2, accuracy = 5, rate = 0.35 },
      { id = "spirit", level = 7, kind = "passive", name = "気合", name_en = "Spirit", description = "攻撃力を引き上げる。", description_en = "Increase attack power.", bonus_mul = { atk = 1.05 } },
      { id = "battle_focus", level = 13, kind = "passive", name = "闘志解放", name_en = "Battle Focus", description = "戦いの集中力を高める。", description_en = "Sharpen focus to raise defense.", bonus_mul = { def = 1.05 } },
    },
  },
}

return M
