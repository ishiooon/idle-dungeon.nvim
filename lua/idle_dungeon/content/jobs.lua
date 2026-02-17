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
      active("limit_arc", 50, "極限連閃", "Limit Arc", "加速した連閃で防御ごと斬り抜く。", "Accelerated arc combo that cuts through guard.", 2.8, 20, 0.28),
      passive("overedge", 100, "剣圧解放", "Overedge", "剣圧が常時展開され、打点と命中が跳ね上がる。", "Persistent blade pressure massively boosts damage and accuracy.", { atk = 1.8, accuracy = 1.4 }),
      active("star_splitter", 200, "星断ち一閃", "Star Splitter", "一点集中の一閃で前線をまとめて割る。", "Focused star-splitting slash that breaks the whole line.", 4.5, 28, 0.24),
      passive("endless_duel", 500, "無双流転", "Endless Duel", "無双の流れで攻防と照準が桁違いに強化される。", "Endless duel flow multiplies offense, defense, and aim.", { atk = 2.8, def = 1.5, accuracy = 1.8 }),
      active("world_cleave", 1000, "終端断界", "World Cleave", "戦場の位相ごと断ち切る終極スラッシュ。", "Terminal slash that severs the battlefield phase itself.", 12.0, 40, 0.45),
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
      active("bastion_crash", 50, "要塞反衝", "Bastion Crash", "要塞級の踏み込みで陣形ごと押し潰す。", "Fortress-grade impact that crushes entire formations.", 2.6, 18, 0.26),
      passive("absolute_wall", 100, "絶対防壁", "Absolute Wall", "絶対防壁が展開し、防御が別次元まで上昇する。", "Absolute wall field sends defense into another tier.", { def = 2.2, atk = 1.35 }),
      active("aegis_breaker", 200, "聖盾圧砕", "Aegis Breaker", "聖盾の圧で相手の受けを強引に崩す。", "Holy-shield pressure forcefully breaks enemy guard.", 4.0, 24, 0.22),
      passive("citadel_core", 500, "城塞覇気", "Citadel Core", "城塞コアが脈動し、攻防の上限を大幅に押し上げる。", "Citadel core pulse drastically raises offense and defense caps.", { atk = 2.0, def = 3.5, accuracy = 1.5 }),
      active("skyvault_crusher", 1000, "天蓋粉砕", "Skyvault Crusher", "天蓋ごと砕く超重量のシールドクラッシュ。", "Ultra-heavy shield crash that shatters the sky vault.", 10.5, 36, 0.42),
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
      active("meteor_volley", 50, "流星射", "Meteor Volley", "流星のような連射で回避余地を消す。", "Meteor-like volley erases room for dodging.", 2.7, 30, 0.3),
      passive("far_sight_domain", 100, "千里眼域", "Far Sight Domain", "視界支配で照準と打撃出力を大幅強化する。", "Sight domain massively boosts aim and shot output.", { atk = 1.6, accuracy = 1.8 }),
      active("comet_piercer", 200, "彗星貫通", "Comet Piercer", "彗星軌道の貫通弾で後衛まで撃ち抜く。", "Comet-line penetrator that pierces through backline.", 4.4, 35, 0.24),
      passive("terminal_scope", 500, "終極照準", "Terminal Scope", "終極スコープで命中と火力を極端に引き上げる。", "Terminal scope hyper-inflates precision and damage.", { atk = 2.5, accuracy = 2.5 }),
      active("void_rain", 1000, "虚空連天", "Void Rain", "空間を覆う超密度の矢雨を降らせる。", "Unleashes ultra-dense void rain over the battlefield.", 11.0, 45, 0.44),
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
      active("implosion_mix", 50, "爆縮合成", "Implosion Mix", "爆縮反応を束ねて一撃へ圧縮する。", "Compresses implosion reactions into one heavy strike.", 2.8, 18, 0.27),
      passive("sage_reactor", 100, "賢者反応炉", "Sage Reactor", "反応炉が常時稼働し、攻防精度を同時増幅する。", "Sage reactor runs continuously to amplify combat output.", { atk = 1.7, def = 1.7, accuracy = 1.3 }),
      active("deep_transmute", 200, "深層錬成", "Deep Transmute", "深層練成で戦場全体の圧を塗り替える。", "Deep transmutation rewrites pressure across the field.", 4.7, 26, 0.23),
      passive("infinite_catalyst", 500, "無限触媒環", "Infinite Catalyst", "無限触媒環で出力上限を破り続ける。", "Infinite catalyst loop keeps breaking output limits.", { atk = 2.6, def = 2.4, accuracy = 1.8 }),
      active("philosophers_core", 1000, "終極賢者石", "Philosopher's Core", "賢者石の核心反応で敵陣を蒸発させる。", "Core philosopher reaction vaporizes enemy formations.", 12.5, 34, 0.43),
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
      active("abyss_ambush", 50, "瞬獄奇襲", "Abyss Ambush", "瞬間潜行からの奇襲で戦線を裂く。", "Instant infiltrate ambush that tears open the line.", 2.9, 24, 0.32),
      passive("dark_assimilation", 100, "暗夜同化", "Dark Assimilation", "闇との同化で火力・命中・回避圧を同時強化。", "Night assimilation boosts damage, precision, and evasion pressure.", { atk = 1.8, accuracy = 1.6, def = 1.3 }),
      active("venom_stitch", 200, "影縫毒牙", "Venom Stitch", "毒牙の連鎖で行動の隙間を縫い潰す。", "Venom stitch chain crushes timing gaps.", 4.9, 30, 0.25),
      passive("predator_awaken", 500, "捕食本能覚醒", "Predator Awaken", "捕食本能が覚醒し、瞬間火力が暴騰する。", "Predator awakening sends burst potential through the roof.", { atk = 3.0, accuracy = 2.0, def = 1.5 }),
      active("silent_terminal", 1000, "無音終断", "Silent Terminal", "音も残さず急所ラインを断ち切る。", "Silently terminates vital lines with no warning.", 13.0, 42, 0.46),
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
      active("sanctum_burst", 50, "浄界衝", "Sanctum Burst", "浄化圏を衝撃波として前方へ解放する。", "Releases sanctified burst wave straight ahead.", 2.6, 22, 0.28),
      passive("holy_domain", 100, "聖域拡張", "Holy Domain", "拡張聖域で攻防精度を広域に底上げする。", "Expanded holy domain uplifts offense, defense, and aim.", { atk = 1.5, def = 1.9, accuracy = 1.4 }),
      active("judgement_lance", 200, "神罰光条", "Judgement Lance", "神罰の光条で重装ごと貫く。", "Judgement beam pierces through heavy armor.", 4.4, 32, 0.24),
      passive("absolute_blessing", 500, "絶対祝福圏", "Absolute Blessing", "絶対祝福圏で戦線全体の耐久と火力を激増させる。", "Absolute blessing zone massively boosts team durability and damage.", { atk = 2.2, def = 3.0, accuracy = 1.8 }),
      active("final_purification", 1000, "終焉浄化", "Final Purification", "終焉級の浄化光で敵陣を一掃する。", "Final purification light sweeps the enemy field.", 11.5, 38, 0.43),
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
      active("pack_stampede", 50, "群狼突撃", "Pack Stampede", "群れの突撃で広範囲を一気に押し潰す。", "Pack stampede overwhelms a wide area at once.", 2.7, 20, 0.3),
      passive("beast_overlink", 100, "獣王共鳴", "Beast Overlink", "獣王共鳴で連携火力と編成上限を拡張する。", "Beast overlink boosts synergy power and pet capacity.", { atk = 1.7, accuracy = 1.5 }, 2),
      active("thousand_fangs", 200, "万牙連鎖", "Thousand Fangs", "連鎖する牙撃で継続圧を極端に高める。", "Thousand fangs chain raises sustained pressure to extremes.", 4.8, 28, 0.24),
      passive("primal_pack", 500, "原始群域", "Primal Pack", "原始群域を展開し、群れ全体の攻防精度を暴騰させる。", "Primal pack field hyper-boosts team offense, defense, and accuracy.", { atk = 2.7, def = 1.8, accuracy = 2.0 }, 3),
      active("beast_apocalypse", 1000, "終極獣宴", "Beast Apocalypse", "獣宴の極致で戦場を多重連携で飲み込む。", "Ultimate beast feast engulfs the field in chained assaults.", 12.8, 36, 0.44),
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
      active("overflurry", 50, "覇拳連破", "Overflurry", "覇拳の連打で相手の行動テンポを破壊する。", "Overflurry breaks enemy action tempo with relentless fists.", 2.9, 22, 0.31),
      passive("core_ki", 100, "闘気爆芯", "Core Ki", "闘気の爆芯で打撃・耐久・照準を同時増幅。", "Explosive core ki amplifies power, durability, and aim.", { atk = 1.8, def = 1.5, accuracy = 1.4 }),
      active("dragon_quake", 200, "龍脈震掌", "Dragon Quake", "龍脈を震わせる掌圧で前線を押し飛ばす。", "Dragon-quake palm pressure blasts through the frontline.", 5.0, 30, 0.24),
      passive("void_form", 500, "無我極意", "Void Form", "無我極意に入り、攻守の桁を一段引き上げる。", "Void form elevates offense and defense by an entire order.", { atk = 2.9, def = 2.2, accuracy = 1.8 }),
      active("thousand_world_fist", 1000, "千界崩拳", "Thousand-World Fist", "千界を砕く超圧縮の終極拳。", "Ultra-compressed ultimate fist that shatters thousand worlds.", 13.2, 42, 0.46),
    },
  },
}

return M
