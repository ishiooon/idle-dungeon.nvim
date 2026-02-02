-- このモジュールは装備定義を提供する。

local M = {}

-- 図鑑表示に使う英語名とフレーバーテキストも定義する。
-- 武器の属性タイプはelementで定義する。
M.items = {
  { id = "wood_sword", name = "木の剣", name_en = "Wooden Sword", slot = "weapon", atk = 1, element = "grass", price = 5, flavor = { en = "A starter blade that smells faintly of forest rain.", ja = "森の雨の匂いが残る初心者向けの木剣。" } },
  { id = "round_shield", name = "丸盾", name_en = "Round Shield", slot = "weapon", def = 1, element = "normal", price = 6, flavor = { en = "A sturdy circle that never looks away from danger.", ja = "危険から目を逸らさない堅実な円盾。" } },
  { id = "typing_blade", name = "タイピングブレード", name_en = "Typing Blade", slot = "weapon", atk = 3, element = "light", price = 20, flavor = { en = "Each keystroke sharpens its edge just a little more.", ja = "キーを叩くたびに刃が僅かに研ぎ澄まされる。" } },
  { id = "save_hammer", name = "連続保存の槌", name_en = "Save Hammer", slot = "weapon", atk = 4, element = "dark", price = 35, flavor = { en = "A heavy hammer that leaves save marks on the ground.", ja = "地面に保存の刻印を残す重たい槌。" } },
  { id = "short_spell_staff", name = "短い詠唱の杖", name_en = "Short Spell Staff", slot = "weapon", atk = 2, element = "fire", price = 25, flavor = { en = "Built for quick chants and even quicker escapes.", ja = "短い詠唱と素早い撤退のための杖。" } },
  { id = "short_bow", name = "近距離弓", name_en = "Short Bow", slot = "weapon", atk = 2, element = "water", price = 12, flavor = { en = "A compact bow that thrives in narrow corridors.", ja = "狭い通路で真価を発揮する小型の弓。" } },
  { id = "sand_staff", name = "砂の杖", name_en = "Sand Staff", slot = "weapon", atk = 2, element = "normal", price = 14, flavor = { en = "A faint grit follows its swings, blinding foes briefly.", ja = "振るうたびに微かな砂が舞い、敵の視界を曇らせる。" } },
  { id = "cloth_armor", name = "布の上着", name_en = "Cloth Armor", slot = "armor", def = 1, price = 5, flavor = { en = "Light and flexible, it favors speed over pride.", ja = "軽くしなやかで、誇りよりも速度を選ぶ。" } },
  { id = "leather_armor", name = "革の上着", name_en = "Leather Armor", slot = "armor", def = 2, price = 10, flavor = { en = "Softened by long travel, it moves with the wearer.", ja = "長旅で柔らかくなり、身体の動きに寄り添う。" } },
  { id = "thick_cloak", name = "厚手の外套", name_en = "Thick Cloak", slot = "armor", def = 2, price = 12, flavor = { en = "A cloak that feels like a small campfire on cold floors.", ja = "冷たい床でも小さな焚き火のように温かい外套。" } },
  { id = "light_robe", name = "薄手のローブ", name_en = "Light Robe", slot = "armor", def = 1, price = 8, flavor = { en = "A robe that whispers with every step.", ja = "歩くたびにかすかなささやきが聞こえるローブ。" } },
  { id = "repeat_cloak", name = "反復作業の外套", name_en = "Repeat Cloak", slot = "armor", def = 3, price = 25, flavor = { en = "Its threads memorize patterns and avoid the same scratch.", ja = "糸が動きを覚え、同じ傷を避けるように揺れる。" } },
  { id = "rest_armor", name = "小休止の鎧", name_en = "Rest Armor", slot = "armor", def = 4, price = 35, flavor = { en = "Built with quiet gaps that let the wearer breathe.", ja = "静かな隙間があり、着る者に小さな休息を与える。" } },
  { id = "edge_shield", name = "画面端の盾", name_en = "Edge Shield", slot = "armor", def = 2, price = 18, flavor = { en = "A shield that always knows where the border lies.", ja = "画面の端を忘れない、境界感覚の鋭い盾。" } },
  { id = "record_ring", name = "記録の指輪", name_en = "Record Ring", slot = "accessory", hp = 1, price = 8, flavor = { en = "It keeps tiny notes of every scratch and bruise.", ja = "小さな傷や打ち身を記録し続ける指輪。" } },
  { id = "guard_amulet", name = "守りの護符", name_en = "Guard Amulet", slot = "accessory", def = 1, price = 10, flavor = { en = "A calm talisman that tightens its knot in danger.", ja = "危険を感じると結び目が固くなる護符。" } },
  { id = "swift_ring", name = "疾風の指輪", name_en = "Swift Ring", slot = "accessory", atk = 1, price = 12, flavor = { en = "It hums like a breeze when the wearer starts to sprint.", ja = "駆け出すと風のような音を立てる指輪。" } },
  { id = "sleep_pendant", name = "安眠のペンダント", name_en = "Sleep Pendant", slot = "accessory", hp = 1, price = 9, flavor = { en = "A steady rhythm drips from it like slow rain.", ja = "ゆっくりした雨音のようなリズムが滴る。" } },
  { id = "fast_sand", name = "早送りの砂時計", name_en = "Fast-Forward Hourglass", slot = "accessory", hp = 0, price = 18, flavor = { en = "The sand never settles, urging the wearer onward.", ja = "砂が落ち着かず、持つ者を先へと急かす。" } },
  { id = "silent_ear", name = "静音の耳飾り", name_en = "Silent Earring", slot = "accessory", hp = 0, price = 15, flavor = { en = "It steals the loudest noise first and leaves only focus.", ja = "最も大きな音を奪い、集中だけを残す耳飾り。" } },
  { id = "focus_bracelet", name = "集中の腕輪", name_en = "Focus Bracelet", slot = "accessory", hp = 0, price = 22, flavor = { en = "A bracelet that tightens when thoughts start to drift.", ja = "意識が逸れると締まる、集中の腕輪。" } },
  { id = "white_slime", name = "白いスライム", name_en = "White Slime", slot = "companion", hp = 1, price = 10, flavor = { en = "It quietly absorbs dust and spits out clean pebbles.", ja = "埃を吸い込み、綺麗な小石を吐き出す静かな相棒。" } },
  { id = "stone_spirit", name = "小石の精霊", name_en = "Stone Spirit", slot = "companion", def = 1, price = 15, flavor = { en = "A pebble spirit that insists on standing between danger and you.", ja = "危険とあなたの間に立ちたがる小石の精霊。" } },
  { id = "wind_bird", name = "風の小鳥", name_en = "Wind Bird", slot = "companion", atk = 1, price = 18, flavor = { en = "It circles ahead to bring back the smell of battle.", ja = "戦いの匂いを先に運んでくる小鳥。" } },
  { id = "tiny_familiar", name = "小さな使い魔", name_en = "Tiny Familiar", slot = "companion", hp = 1, price = 20, flavor = { en = "A whisper-sized helper that remembers every shortcut.", ja = "ささやきほど小さく、近道を覚えている使い魔。" } },
}

return M
