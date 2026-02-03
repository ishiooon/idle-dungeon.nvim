-- このテストは戦利品ドロップの抽選が期待通りであることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local loot = require("idle_dungeon.game.loot")
local config_module = require("idle_dungeon.config")

local items = {
  { id = "common_item", slot = "weapon", rarity = "common" },
  { id = "rare_item", slot = "weapon", rarity = "rare" },
  { id = "pet_item", slot = "companion", rarity = "pet" },
}

-- 敵ごとのドロッププールを指定して抽選が反映されることを確認する。
-- ドロップ定義が敵データ内に統合されても挙動が変わらないことを意図する。
local enemy = {
  is_boss = false,
  drops = {
    common = { "common_item" },
    rare = { "rare_item" },
    pet = { "pet_item" },
    gold = { min = 2, max = 4 },
  },
}

local config_pet = { battle = { drop_rates = { common = 0, rare = 0, pet = 100 } } }
local drop_pet = loot.roll_drop(1, config_pet, items, enemy)
assert_true(drop_pet ~= nil, "ペットのドロップが発生する")
assert_equal(drop_pet.id, "pet_item", "ペットのドロップはペット枠から選ばれる")
assert_equal(drop_pet.rarity, "pet", "ペットのレアリティが記録される")

local config_common = { battle = { drop_rates = { common = 100, rare = 0, pet = 0 } } }
local drop_common = loot.roll_drop(1, config_common, items, enemy)
assert_true(drop_common ~= nil, "通常ドロップが発生する")
assert_equal(drop_common.id, "common_item", "通常ドロップは通常枠から選ばれる")
assert_equal(drop_common.rarity, "common", "通常ドロップのレアリティが記録される")

local config_none = { battle = { drop_rates = { common = 0, rare = 0, pet = 0 } } }
local drop_none = loot.roll_drop(1, config_none, items, enemy)
assert_true(drop_none == nil, "ドロップ率0では戦利品が出ない")

local gold_amount, gold_seed = loot.roll_gold(1, enemy)
assert_true(gold_amount >= 2 and gold_amount <= 4, "ゴールドドロップは範囲内の値になる")
assert_true(type(gold_seed) == "number", "ゴールドドロップの乱数シードが更新される")

local gold_none, gold_seed_none = loot.roll_gold(1, {})
assert_true(gold_none == 0, "ゴールド定義が無い場合は0になる")
assert_true(type(gold_seed_none) == "number", "ゴールド無しでも乱数シードが返る")

-- 既定のドロップ率が低めに設定されていることを確認する。
-- 希少ドロップの抑制が反映されているかを明示的に検証する。
local default_config = config_module.build({})
local default_rates = (default_config.battle or {}).drop_rates or {}
assert_equal(default_rates.common, 3, "通常ドロップ率の既定値が低めである")
assert_equal(default_rates.rare, 1, "レアドロップ率の既定値がかなり低めである")
assert_equal(default_rates.pet, 1, "ペットドロップ率の既定値がさらに低めである")
assert_equal(default_rates.boss_bonus, 1, "ボス補正の既定値が低めである")

print("OK")
