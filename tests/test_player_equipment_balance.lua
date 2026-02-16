-- このテストは装備補正がスロットと希少度で差別化されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local player = require("idle_dungeon.game.player")

local base_actor = {
  base_hp = 30,
  base_atk = 12,
  base_def = 8,
  base_speed = 3,
  max_hp = 30,
  hp = 30,
  atk = 12,
  def = 8,
  speed = 3,
}

local items = {
  { id = "weapon_common", slot = "weapon", rarity = "common", hp = 2, atk = 2, def = 2, speed = 1 },
  { id = "armor_common", slot = "armor", rarity = "common", hp = 2, atk = 2, def = 2, speed = 1 },
  { id = "accessory_common", slot = "accessory", rarity = "common", hp = 2, atk = 2, def = 2, speed = 1 },
  { id = "weapon_rare", slot = "weapon", rarity = "rare", atk = 2 },
}

-- 装備なしを基準値にする。
local no_equip = player.apply_equipment(base_actor, {}, items)
local weapon_actor = player.apply_equipment(base_actor, { weapon = "weapon_common" }, items)
local armor_actor = player.apply_equipment(base_actor, { armor = "armor_common" }, items)
local accessory_actor = player.apply_equipment(base_actor, { accessory = "accessory_common" }, items)
local rare_weapon_actor = player.apply_equipment(base_actor, { weapon = "weapon_rare" }, items)

local weapon_atk_gain = weapon_actor.atk - no_equip.atk
local weapon_def_gain = weapon_actor.def - no_equip.def
assert_true(weapon_atk_gain > weapon_def_gain, "武器は攻撃力の伸びが防御力より大きい")

local armor_def_gain = armor_actor.def - no_equip.def
local armor_atk_gain = armor_actor.atk - no_equip.atk
assert_true(armor_def_gain > armor_atk_gain, "防具は防御力の伸びが攻撃力より大きい")

local accessory_speed_gain = accessory_actor.speed - no_equip.speed
local accessory_def_gain = accessory_actor.def - no_equip.def
assert_true(accessory_speed_gain > accessory_def_gain, "装飾品は速度の伸びが防御力より大きい")

local common_weapon_actor = player.apply_equipment(base_actor, { weapon = "weapon_common" }, items)
local common_weapon_gain = common_weapon_actor.atk - no_equip.atk
local rare_weapon_gain = rare_weapon_actor.atk - no_equip.atk
assert_true(rare_weapon_gain > common_weapon_gain, "同等基礎値ならレア武器の伸びが通常武器を上回る")

print("OK")
