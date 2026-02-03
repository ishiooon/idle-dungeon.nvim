-- このモジュールは装備定義を提供する。

local util = require("idle_dungeon.util")

local M = {}

-- 解放条件は装備定義側で一元管理し、設定側と重複しないようにする。
local unlock_rules = {
  typing_blade = { kind = "chars", value = 200 },
  save_hammer = { kind = "saves", value = 10 },
  repeat_cloak = { kind = "time_sec", value = 1800 },
  edge_shield = { kind = "filetype_chars", filetype = "lua", value = 200 },
  focus_bracelet = { kind = "chars", value = 600 },
  wind_bird = { kind = "time_sec", value = 900 },
  lua_sigil_blade = { kind = "filetype_chars", filetype = "lua", value = 400 },
  vim_focus_ring = { kind = "filetype_chars", filetype = "vim", value = 300 },
  c_forge_spear = { kind = "filetype_chars", filetype = "c", value = 350 },
  cpp_heap_shield = { kind = "filetype_chars", filetype = "cpp", value = 450 },
  python_coil_whip = { kind = "filetype_chars", filetype = "python", value = 400 },
  js_spark_blade = { kind = "filetype_chars", filetype = "javascript", value = 450 },
  ts_guard_mail = { kind = "filetype_chars", filetype = "typescript", value = 450 },
  go_stride_band = { kind = "filetype_chars", filetype = "go", value = 350 },
  rust_crust_armor = { kind = "filetype_chars", filetype = "rust", value = 450 },
  java_forge_staff = { kind = "filetype_chars", filetype = "java", value = 450 },
  kotlin_arc_amulet = { kind = "filetype_chars", filetype = "kotlin", value = 400 },
  swift_wind_dagger = { kind = "filetype_chars", filetype = "swift", value = 400 },
  ruby_bloom_ring = { kind = "filetype_chars", filetype = "ruby", value = 400 },
  php_bastion_cloak = { kind = "filetype_chars", filetype = "php", value = 400 },
  bash_echo_charm = { kind = "filetype_chars", filetype = "sh", value = 300 },
  shell_tide_ring = { kind = "filetype_chars", filetype = "bash", value = 300 },
  html_canvas_cloak = { kind = "filetype_chars", filetype = "html", value = 300 },
  css_palette_charm = { kind = "filetype_chars", filetype = "css", value = 300 },
  json_mirror_ring = { kind = "filetype_chars", filetype = "json", value = 350 },
  yaml_scroll_robe = { kind = "filetype_chars", filetype = "yaml", value = 350 },
  toml_anchor_band = { kind = "filetype_chars", filetype = "toml", value = 350 },
  sql_depth_spear = { kind = "filetype_chars", filetype = "sql", value = 400 },
  markdown_quill_pendant = { kind = "filetype_chars", filetype = "markdown", value = 300 },
}

-- 解放条件の定義を装備データへ反映して返す。
local function apply_unlock_rules(items, unlocks)
  local result = {}
  for _, item in ipairs(items or {}) do
    local unlock = unlocks[item.id]
    if unlock then
      table.insert(result, util.merge_tables(item, { unlock = unlock }))
    else
      table.insert(result, item)
    end
  end
  return result
end

-- 図鑑表示に使う英語名とフレーバーテキストも定義する。
-- 武器の属性タイプはelementで定義する。
-- rarityは戦利品の希少度を示し、common/rare/petを使う。
local base_items = {
  { id = "wood_sword", name = "木の剣", name_en = "Wooden Sword", slot = "weapon", atk = 2, element = "grass", price = 5, rarity = "common", flavor = { en = "A starter blade that smells faintly of forest rain.", ja = "森の雨の匂いが残る初心者向けの木剣。" } },
  { id = "round_shield", name = "丸盾", name_en = "Round Shield", slot = "weapon", def = 2, element = "normal", price = 6, rarity = "common", flavor = { en = "A sturdy circle that never looks away from danger.", ja = "危険から目を逸らさない堅実な円盾。" } },
  -- 上位装備は価格と性能を引き上げ、明確な成長幅を作る。
  { id = "typing_blade", name = "タイピングブレード", name_en = "Typing Blade", slot = "weapon", atk = 7, element = "light", price = 70, rarity = "rare", flavor = { en = "Each keystroke sharpens its edge just a little more.", ja = "キーを叩くたびに刃が僅かに研ぎ澄まされる。" } },
  { id = "save_hammer", name = "連続保存の槌", name_en = "Save Hammer", slot = "weapon", atk = 9, element = "dark", price = 90, rarity = "rare", flavor = { en = "A heavy hammer that leaves save marks on the ground.", ja = "地面に保存の刻印を残す重たい槌。" } },
  { id = "short_spell_staff", name = "短い詠唱の杖", name_en = "Short Spell Staff", slot = "weapon", atk = 3, element = "fire", price = 25, rarity = "common", flavor = { en = "Built for quick chants and even quicker escapes.", ja = "短い詠唱と素早い撤退のための杖。" } },
  { id = "short_bow", name = "近距離弓", name_en = "Short Bow", slot = "weapon", atk = 3, element = "water", price = 12, rarity = "common", flavor = { en = "A compact bow that thrives in narrow corridors.", ja = "狭い通路で真価を発揮する小型の弓。" } },
  { id = "sand_staff", name = "砂の杖", name_en = "Sand Staff", slot = "weapon", atk = 2, def = 1, element = "normal", price = 14, rarity = "common", flavor = { en = "A faint grit follows its swings, blinding foes briefly.", ja = "振るうたびに微かな砂が舞い、敵の視界を曇らせる。" } },
  { id = "cloth_armor", name = "布の上着", name_en = "Cloth Armor", slot = "armor", def = 2, price = 5, rarity = "common", flavor = { en = "Light and flexible, it favors speed over pride.", ja = "軽くしなやかで、誇りよりも速度を選ぶ。" } },
  { id = "leather_armor", name = "革の上着", name_en = "Leather Armor", slot = "armor", def = 3, price = 10, rarity = "common", flavor = { en = "Softened by long travel, it moves with the wearer.", ja = "長旅で柔らかくなり、身体の動きに寄り添う。" } },
  { id = "thick_cloak", name = "厚手の外套", name_en = "Thick Cloak", slot = "armor", def = 3, hp = 1, price = 12, rarity = "common", flavor = { en = "A cloak that feels like a small campfire on cold floors.", ja = "冷たい床でも小さな焚き火のように温かい外套。" } },
  { id = "light_robe", name = "薄手のローブ", name_en = "Light Robe", slot = "armor", def = 2, hp = 1, price = 8, rarity = "common", flavor = { en = "A robe that whispers with every step.", ja = "歩くたびにかすかなささやきが聞こえるローブ。" } },
  { id = "repeat_cloak", name = "反復作業の外套", name_en = "Repeat Cloak", slot = "armor", def = 5, price = 60, rarity = "rare", flavor = { en = "Its threads memorize patterns and avoid the same scratch.", ja = "糸が動きを覚え、同じ傷を避けるように揺れる。" } },
  { id = "rest_armor", name = "小休止の鎧", name_en = "Rest Armor", slot = "armor", def = 6, hp = 2, price = 70, rarity = "rare", flavor = { en = "Built with quiet gaps that let the wearer breathe.", ja = "静かな隙間があり、着る者に小さな休息を与える。" } },
  { id = "edge_shield", name = "画面端の盾", name_en = "Edge Shield", slot = "armor", def = 4, hp = 2, price = 55, rarity = "rare", flavor = { en = "A shield that always knows where the border lies.", ja = "画面の端を忘れない、境界感覚の鋭い盾。" } },
  { id = "record_ring", name = "記録の指輪", name_en = "Record Ring", slot = "accessory", hp = 2, price = 8, rarity = "common", flavor = { en = "It keeps tiny notes of every scratch and bruise.", ja = "小さな傷や打ち身を記録し続ける指輪。" } },
  { id = "guard_amulet", name = "守りの護符", name_en = "Guard Amulet", slot = "accessory", def = 2, price = 10, rarity = "common", flavor = { en = "A calm talisman that tightens its knot in danger.", ja = "危険を感じると結び目が固くなる護符。" } },
  { id = "swift_ring", name = "疾風の指輪", name_en = "Swift Ring", slot = "accessory", atk = 2, price = 12, rarity = "common", flavor = { en = "It hums like a breeze when the wearer starts to sprint.", ja = "駆け出すと風のような音を立てる指輪。" } },
  { id = "sleep_pendant", name = "安眠のペンダント", name_en = "Sleep Pendant", slot = "accessory", hp = 2, price = 9, rarity = "common", flavor = { en = "A steady rhythm drips from it like slow rain.", ja = "ゆっくりした雨音のようなリズムが滴る。" } },
  { id = "fast_sand", name = "早送りの砂時計", name_en = "Fast-Forward Hourglass", slot = "accessory", hp = 2, atk = 2, price = 60, rarity = "rare", flavor = { en = "The sand never settles, urging the wearer onward.", ja = "砂が落ち着かず、持つ者を先へと急かす。" } },
  { id = "silent_ear", name = "静音の耳飾り", name_en = "Silent Earring", slot = "accessory", hp = 1, def = 1, price = 15, rarity = "common", flavor = { en = "It steals the loudest noise first and leaves only focus.", ja = "最も大きな音を奪い、集中だけを残す耳飾り。" } },
  { id = "focus_bracelet", name = "集中の腕輪", name_en = "Focus Bracelet", slot = "accessory", atk = 2, def = 2, price = 65, rarity = "rare", flavor = { en = "A bracelet that tightens when thoughts start to drift.", ja = "意識が逸れると締まる、集中の腕輪。" } },
  -- 属性ごとの装備バリエーションを追加して収集の幅を広げる。
  { id = "flame_dagger", name = "炎刃の短剣", name_en = "Flame Dagger", slot = "weapon", atk = 3, element = "fire", price = 14, rarity = "common", flavor = { en = "A quick dagger that leaves a thin trail of heat.", ja = "薄い熱の軌跡を残す素早い短剣。" } },
  { id = "ember_bow", name = "熾火の弓", name_en = "Ember Bow", slot = "weapon", atk = 3, element = "fire", price = 16, rarity = "common", flavor = { en = "It fires arrows that hiss like embers in dry air.", ja = "乾いた空気で熾火のように鳴る矢を放つ。" } },
  { id = "ash_mail", name = "灰の鎧", name_en = "Ash Mail", slot = "armor", def = 3, hp = 1, price = 14, rarity = "common", flavor = { en = "Ash-dusted armor that stays cool under pressure.", ja = "灰に覆われ、熱気の中でも冷静さを保つ鎧。" } },
  { id = "cinder_band", name = "煤の腕輪", name_en = "Cinder Band", slot = "accessory", atk = 1, price = 12, rarity = "common", flavor = { en = "A warm band that tightens with each swing.", ja = "振るうたびに温かく締まる腕輪。" } },
  { id = "ember_charm", name = "熾火の護符", name_en = "Ember Charm", slot = "accessory", def = 1, price = 12, rarity = "common", flavor = { en = "It dulls sudden sparks and steadies the heart.", ja = "不意の火花を鈍らせ、心を落ち着ける護符。" } },
  { id = "magma_greatsword", name = "溶岩の大剣", name_en = "Magma Greatsword", slot = "weapon", atk = 9, element = "fire", price = 85, rarity = "rare", flavor = { en = "Its edge pulses like lava under a cracked crust.", ja = "割れた地殻の下の溶岩のように脈打つ刃。" } },
  { id = "phoenix_cloak", name = "不死鳥の外套", name_en = "Phoenix Cloak", slot = "armor", def = 5, hp = 3, price = 75, rarity = "rare", flavor = { en = "It warms its wearer each time they stand back up.", ja = "立ち上がるたびに体温を取り戻させる外套。" } },
  { id = "tide_spear", name = "潮槍", name_en = "Tide Spear", slot = "weapon", atk = 3, element = "water", price = 14, rarity = "common", flavor = { en = "A spear that rides the rhythm of the tide.", ja = "潮のリズムに合わせて突き出る槍。" } },
  { id = "mist_blade", name = "霧の刃", name_en = "Mist Blade", slot = "weapon", atk = 3, element = "water", price = 15, rarity = "common", flavor = { en = "A blade that blurs the moment it strikes.", ja = "斬る瞬間に輪郭がぼやける刃。" } },
  { id = "foam_coat", name = "泡の上着", name_en = "Foam Coat", slot = "armor", def = 3, hp = 1, price = 13, rarity = "common", flavor = { en = "Light armor that sheds hits like rolling foam.", ja = "泡が転がるように衝撃を受け流す軽装。" } },
  { id = "ripple_charm", name = "波紋の護符", name_en = "Ripple Charm", slot = "accessory", def = 1, price = 11, rarity = "common", flavor = { en = "Small ripples spread from it whenever danger nears.", ja = "危険が近づくと小さな波紋が広がる護符。" } },
  { id = "tide_compass", name = "潮の羅針", name_en = "Tide Compass", slot = "accessory", atk = 1, price = 12, rarity = "common", flavor = { en = "It pulls its wearer toward the calm current.", ja = "穏やかな流れへと導く羅針。" } },
  { id = "abyss_trident", name = "深海の三叉槍", name_en = "Abyss Trident", slot = "weapon", atk = 9, element = "water", price = 85, rarity = "rare", flavor = { en = "A trident that drags foes into a silent depth.", ja = "静かな深みへと引きずり込む三叉槍。" } },
  { id = "leviathan_scale", name = "リヴァイアサンの鱗鎧", name_en = "Leviathan Scale", slot = "armor", def = 6, hp = 3, price = 80, rarity = "rare", flavor = { en = "Scales that refuse to yield to crushing pressure.", ja = "深圧にも屈しない鱗で編まれた鎧。" } },
  { id = "moss_axe", name = "苔斧", name_en = "Moss Axe", slot = "weapon", atk = 3, element = "grass", price = 13, rarity = "common", flavor = { en = "A heavy axe softened by moss and dew.", ja = "苔と露がまとわり、重さが和らいだ斧。" } },
  { id = "sprout_spear", name = "芽吹きの槍", name_en = "Sprout Spear", slot = "weapon", atk = 3, element = "grass", price = 14, rarity = "common", flavor = { en = "A spear that sprouts fresh tips after each clash.", ja = "ぶつかるたびに新しい先端が芽吹く槍。" } },
  { id = "vine_wrap", name = "蔦の外套", name_en = "Vine Wrap", slot = "armor", def = 3, hp = 1, price = 13, rarity = "common", flavor = { en = "Vines cling to it and cushion incoming hits.", ja = "蔦が絡みつき、衝撃をやわらげる外套。" } },
  { id = "leaf_locket", name = "木の葉のロケット", name_en = "Leaf Locket", slot = "accessory", hp = 1, price = 10, rarity = "common", flavor = { en = "A tiny leaf that keeps a gentle scent close.", ja = "優しい香りを保つ小さな葉の飾り。" } },
  { id = "pollen_charm", name = "花粉の護符", name_en = "Pollen Charm", slot = "accessory", def = 1, price = 11, rarity = "common", flavor = { en = "A charm that blurs the air and softens attacks.", ja = "空気をぼかし、攻撃の鋭さを和らげる護符。" } },
  { id = "grove_reaver", name = "森影の大鎌", name_en = "Grove Reaver", slot = "weapon", atk = 9, element = "grass", price = 85, rarity = "rare", flavor = { en = "A reaver that whispers like an old forest.", ja = "古い森のささやきのように静かな大鎌。" } },
  { id = "ancient_bark", name = "古樹の外殻", name_en = "Ancient Bark", slot = "armor", def = 6, hp = 3, price = 80, rarity = "rare", flavor = { en = "Bark from an ancient tree, dense and unyielding.", ja = "古樹の硬い樹皮で作られた頑丈な外殻。" } },
  { id = "glimmer_rapier", name = "輝光のレイピア", name_en = "Glimmer Rapier", slot = "weapon", atk = 3, element = "light", price = 15, rarity = "common", flavor = { en = "A thin rapier that flashes with each thrust.", ja = "突き出すたびに光が走る細身の剣。" } },
  { id = "halo_sling", name = "輪光のスリング", name_en = "Halo Sling", slot = "weapon", atk = 3, element = "light", price = 16, rarity = "common", flavor = { en = "A sling that arcs projectiles in a bright ring.", ja = "光の輪を描いて弾を放つスリング。" } },
  { id = "radiant_veil", name = "光布のヴェール", name_en = "Radiant Veil", slot = "armor", def = 3, hp = 1, price = 14, rarity = "common", flavor = { en = "A veil that softens the outline of the wearer.", ja = "身の輪郭を柔らかくぼかすヴェール。" } },
  { id = "prism_charm", name = "プリズムの護符", name_en = "Prism Charm", slot = "accessory", atk = 1, price = 12, rarity = "common", flavor = { en = "It splits a flash into many small guiding lights.", ja = "ひとつの光を細かな導きへと分ける護符。" } },
  { id = "beacon_ring", name = "導きの指輪", name_en = "Beacon Ring", slot = "accessory", hp = 1, price = 12, rarity = "common", flavor = { en = "A ring that glows brighter when danger is near.", ja = "危険が近づくと明るく光る指輪。" } },
  { id = "dawn_blade", name = "黎明の剣", name_en = "Dawn Blade", slot = "weapon", atk = 9, element = "light", price = 90, rarity = "rare", flavor = { en = "A blade that clears shadows with a single sweep.", ja = "ひと振りで影を払い、道を明るくする剣。" } },
  { id = "aurora_plate", name = "極光の鎧", name_en = "Aurora Plate", slot = "armor", def = 6, hp = 3, price = 85, rarity = "rare", flavor = { en = "Armor that hums softly like a northern glow.", ja = "極光のように静かに揺らめく鎧。" } },
  { id = "dusk_katana", name = "黄昏の刀", name_en = "Dusk Katana", slot = "weapon", atk = 4, element = "dark", price = 17, rarity = "common", flavor = { en = "A blade that deepens in color as night falls.", ja = "夜が濃くなるほど色が深まる刀。" } },
  { id = "shade_stiletto", name = "影のスティレット", name_en = "Shade Stiletto", slot = "weapon", atk = 3, element = "dark", price = 14, rarity = "common", flavor = { en = "A thin stiletto that slips into blind spots.", ja = "死角へ滑り込む細身の短剣。" } },
  { id = "umbra_mail", name = "陰の鎧", name_en = "Umbra Mail", slot = "armor", def = 3, hp = 1, price = 14, rarity = "common", flavor = { en = "Mail that drinks in light and muffles sound.", ja = "光を吸い込み、音を抑える鎧。" } },
  { id = "void_ring", name = "虚無の指輪", name_en = "Void Ring", slot = "accessory", def = 1, price = 12, rarity = "common", flavor = { en = "It eases the wearer into a quiet, empty focus.", ja = "静かで無の集中へと導く指輪。" } },
  { id = "gloom_pendant", name = "憂影のペンダント", name_en = "Gloom Pendant", slot = "accessory", atk = 1, price = 12, rarity = "common", flavor = { en = "A pendant that sharpens resolve when the room darkens.", ja = "闇が濃くなるほど決意を研ぎ澄ますペンダント。" } },
  { id = "night_reaper", name = "夜刈りの大鎌", name_en = "Night Reaper", slot = "weapon", atk = 9, element = "dark", price = 90, rarity = "rare", flavor = { en = "A scythe that harvests the last light of a corridor.", ja = "回廊の最後の光を刈り取る大鎌。" } },
  { id = "eclipse_cloak", name = "皆既の外套", name_en = "Eclipse Cloak", slot = "armor", def = 6, hp = 3, price = 85, rarity = "rare", flavor = { en = "A cloak that dims the world and steadies the breath.", ja = "世界を薄暗くし、呼吸を整える外套。" } },
  { id = "iron_lance", name = "鉄の槍", name_en = "Iron Lance", slot = "weapon", atk = 3, def = 1, element = "normal", price = 13, rarity = "common", flavor = { en = "A reliable lance that values reach over flair.", ja = "派手さよりも間合いを重視した信頼の槍。" } },
  { id = "stone_maul", name = "石のメイス", name_en = "Stone Maul", slot = "weapon", atk = 4, element = "normal", price = 15, rarity = "common", flavor = { en = "A blunt maul that never chips, only cracks.", ja = "欠けずに割ることだけに徹した鈍器。" } },
  { id = "traveler_coat", name = "旅人の上着", name_en = "Traveler Coat", slot = "armor", def = 3, hp = 1, price = 12, rarity = "common", flavor = { en = "A coat sewn for long roads and sudden weather.", ja = "長旅と不意の天候に備えた上着。" } },
  { id = "steady_band", name = "安定の腕輪", name_en = "Steady Band", slot = "accessory", hp = 1, def = 1, price = 12, rarity = "common", flavor = { en = "It steadies the pulse when the floor shakes.", ja = "床が揺れても脈を整える腕輪。" } },
  { id = "traveler_token", name = "旅路の護符", name_en = "Traveler Token", slot = "accessory", def = 1, price = 11, rarity = "common", flavor = { en = "A token that reminds the wearer to keep moving.", ja = "歩みを止めないように促す小さな護符。" } },
  { id = "guardian_halberd", name = "守護者の斧槍", name_en = "Guardian Halberd", slot = "weapon", atk = 7, def = 2, element = "normal", price = 80, rarity = "rare", flavor = { en = "A halberd carried by gatekeepers who never blink.", ja = "門番が一瞬も目を離さず持つ斧槍。" } },
  { id = "bulwark_plate", name = "城壁の鎧", name_en = "Bulwark Plate", slot = "armor", def = 7, hp = 3, price = 90, rarity = "rare", flavor = { en = "Plate armor that feels like a moving fortress.", ja = "動く城壁のように頼れる鎧。" } },
  { id = "lua_sigil_blade", name = "Luaの紋剣", name_en = "Lua Sigil Blade", slot = "weapon", atk = 7, element = "light", price = 95, rarity = "rare", flavor = { en = "A blade that hums with flowing scripts and quiet sparks.", ja = "流れるスクリプトと静かな火花をまとった刃。" } },
  { id = "vim_focus_ring", name = "Vim集中指輪", name_en = "Vim Focus Ring", slot = "accessory", atk = 1, def = 2, element = "normal", price = 72, rarity = "rare", flavor = { en = "A ring that narrows the world into precise motions.", ja = "世界を正確な動きへと絞り込む指輪。" } },
  { id = "c_forge_spear", name = "C鍛造の槍", name_en = "C Forge Spear", slot = "weapon", atk = 6, def = 1, element = "normal", price = 85, rarity = "rare", flavor = { en = "A spear tempered in raw heat and steady craftsmanship.", ja = "生の熱と職人の粘りで鍛えられた槍。" } },
  { id = "cpp_heap_shield", name = "C++ヒープ盾", name_en = "C++ Heap Shield", slot = "armor", def = 6, hp = 2, element = "dark", price = 90, rarity = "rare", flavor = { en = "A layered shield that stacks protection without a slip.", ja = "積み重ねた守りが崩れない重層の盾。" } },
  { id = "python_coil_whip", name = "Python環鞭", name_en = "Python Coil Whip", slot = "weapon", atk = 6, element = "water", price = 88, rarity = "rare", flavor = { en = "A coiled whip that strikes with smooth, measured arcs.", ja = "滑らかな弧で打ち込む巻き鞭。" } },
  { id = "js_spark_blade", name = "JavaScript火花剣", name_en = "JavaScript Spark Blade", slot = "weapon", atk = 6, element = "fire", price = 86, rarity = "rare", flavor = { en = "It crackles with short-lived bursts that surprise the careless.", ja = "刹那の火花で隙を突く剣。" } },
  { id = "ts_guard_mail", name = "TypeScript守護の鎧", name_en = "TypeScript Guard Mail", slot = "armor", def = 5, hp = 2, element = "light", price = 88, rarity = "rare", flavor = { en = "A disciplined mail that holds every seam in place.", ja = "継ぎ目を整え続ける規律の鎧。" } },
  { id = "go_stride_band", name = "Goストライドバンド", name_en = "Go Stride Band", slot = "accessory", atk = 2, def = 1, element = "fire", price = 75, rarity = "rare", flavor = { en = "A band that turns brief pauses into swift leaps.", ja = "短い間合いを一気に跳ぶためのバンド。" } },
  { id = "rust_crust_armor", name = "Rust外殻装甲", name_en = "Rust Crust Armor", slot = "armor", def = 6, hp = 2, element = "dark", price = 92, rarity = "rare", flavor = { en = "A sturdy shell that never flakes when pressure builds.", ja = "圧が増しても剥がれない堅い外殻。" } },
  { id = "java_forge_staff", name = "Java鍛錬の杖", name_en = "Java Forge Staff", slot = "weapon", atk = 7, element = "fire", price = 95, rarity = "rare", flavor = { en = "A staff forged in steady heat and patient endurance.", ja = "揺るがぬ熱で鍛えられた耐久の杖。" } },
  { id = "kotlin_arc_amulet", name = "Kotlinアークアミュレット", name_en = "Kotlin Arc Amulet", slot = "accessory", atk = 1, def = 2, element = "light", price = 76, rarity = "rare", flavor = { en = "A curved amulet that arcs light into reliable paths.", ja = "光の軌道を安定させる弧形の護符。" } },
  { id = "swift_wind_dagger", name = "Swift風刃短剣", name_en = "Swift Wind Dagger", slot = "weapon", atk = 6, element = "water", price = 86, rarity = "rare", flavor = { en = "A dagger that slips ahead on a thin, cold breeze.", ja = "冷たい風に乗って先へ滑り込む短剣。" } },
  { id = "ruby_bloom_ring", name = "Ruby開花の指輪", name_en = "Ruby Bloom Ring", slot = "accessory", atk = 2, element = "grass", price = 78, rarity = "rare", flavor = { en = "A ring that blooms with a steady, warm glow.", ja = "穏やかな光が花開く指輪。" } },
  { id = "php_bastion_cloak", name = "PHPバスティオン外套", name_en = "PHP Bastion Cloak", slot = "armor", def = 5, hp = 2, element = "grass", price = 86, rarity = "rare", flavor = { en = "A cloak that acts as a soft yet reliable bulwark.", ja = "柔らかくも頼れる防壁となる外套。" } },
  { id = "bash_echo_charm", name = "Bash反響の護符", name_en = "Bash Echo Charm", slot = "accessory", def = 2, element = "dark", price = 72, rarity = "rare", flavor = { en = "A charm that repeats warnings until danger passes.", ja = "危険が去るまで警告を反響させる護符。" } },
  { id = "shell_tide_ring", name = "Shell潮流の指輪", name_en = "Shell Tide Ring", slot = "accessory", hp = 2, element = "water", price = 72, rarity = "rare", flavor = { en = "A ring that draws breath in steady, tidal waves.", ja = "潮のように呼吸を整える指輪。" } },
  { id = "html_canvas_cloak", name = "HTMLキャンバス外套", name_en = "HTML Canvas Cloak", slot = "armor", def = 4, hp = 2, element = "light", price = 82, rarity = "rare", flavor = { en = "A cloak that keeps a blank canvas ready for new paths.", ja = "新しい道筋を描ける白地を保つ外套。" } },
  { id = "css_palette_charm", name = "CSSパレット護符", name_en = "CSS Palette Charm", slot = "accessory", atk = 1, def = 1, element = "light", price = 72, rarity = "rare", flavor = { en = "A charm that balances tones and calms shaky hands.", ja = "色調を整え、震える手を落ち着かせる護符。" } },
  { id = "json_mirror_ring", name = "JSON鏡面指輪", name_en = "JSON Mirror Ring", slot = "accessory", def = 2, element = "water", price = 74, rarity = "rare", flavor = { en = "A ring that reflects patterns without distortion.", ja = "歪みなく型を映す鏡面の指輪。" } },
  { id = "yaml_scroll_robe", name = "YAML書巻ローブ", name_en = "YAML Scroll Robe", slot = "armor", def = 4, hp = 2, element = "grass", price = 84, rarity = "rare", flavor = { en = "A robe embroidered with careful, flowing notes.", ja = "丁寧な書付が流れるローブ。" } },
  { id = "toml_anchor_band", name = "TOMLアンカーバンド", name_en = "TOML Anchor Band", slot = "accessory", hp = 1, def = 2, element = "normal", price = 74, rarity = "rare", flavor = { en = "A band that anchors wandering thoughts in place.", ja = "揺らぐ意識を錨のように留めるバンド。" } },
  { id = "sql_depth_spear", name = "SQL深層の槍", name_en = "SQL Depth Spear", slot = "weapon", atk = 7, element = "dark", price = 92, rarity = "rare", flavor = { en = "A spear that plunges straight into the deepest layer.", ja = "最深部へまっすぐ突き通す槍。" } },
  { id = "markdown_quill_pendant", name = "Markdown羽根ペンダント", name_en = "Markdown Quill Pendant", slot = "accessory", atk = 1, hp = 1, element = "light", price = 70, rarity = "rare", flavor = { en = "A pendant that keeps notes light and easy to read.", ja = "軽やかな筆致を保つ羽根のペンダント。" } },
  { id = "white_slime", name = "白いスライム", name_en = "White Slime", slot = "companion", hp = 2, price = 10, rarity = "pet", flavor = { en = "It quietly absorbs dust and spits out clean pebbles.", ja = "埃を吸い込み、綺麗な小石を吐き出す静かな相棒。" } },
  { id = "stone_spirit", name = "小石の精霊", name_en = "Stone Spirit", slot = "companion", def = 2, price = 15, rarity = "pet", flavor = { en = "A pebble spirit that insists on standing between danger and you.", ja = "危険とあなたの間に立ちたがる小石の精霊。" } },
  { id = "wind_bird", name = "風の小鳥", name_en = "Wind Bird", slot = "companion", atk = 2, price = 18, rarity = "pet", flavor = { en = "It circles ahead to bring back the smell of battle.", ja = "戦いの匂いを先に運んでくる小鳥。" } },
  { id = "tiny_familiar", name = "小さな使い魔", name_en = "Tiny Familiar", slot = "companion", hp = 1, def = 1, price = 20, rarity = "pet", flavor = { en = "A whisper-sized helper that remembers every shortcut.", ja = "ささやきほど小さく、近道を覚えている使い魔。" } },
}

-- 解放条件を統合した装備定義を公開する。
M.items = apply_unlock_rules(base_items, unlock_rules)

return M
