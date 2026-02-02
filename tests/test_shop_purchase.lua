-- このテストは購入メニューの分類と解錠判定が期待通りであることを確認する。

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

local content = require("idle_dungeon.content")
local shop = require("idle_dungeon.menu.shop")

local categories = shop.build_purchase_categories("en")
-- ペット購入は廃止し、装備カテゴリは3種に絞る。
assert_equal(#categories, 3, "購入カテゴリは3種である")
assert_equal(categories[1].id, "weapon", "購入カテゴリの先頭は武器である")
assert_equal(categories[2].id, "armor", "購入カテゴリの2番目は防具である")
assert_equal(categories[3].id, "accessory", "購入カテゴリの3番目は装飾品である")

local weapons = shop.filter_items_by_slot(content.items, "weapon")
assert_true(#weapons > 0, "武器カテゴリに装備が含まれる")
for _, item in ipairs(weapons) do
  assert_equal(item.slot, "weapon", "武器カテゴリに武器以外が混ざらない")
end

local state = { unlocks = { items = {} }, inventory = {}, currency = { gold = 999 } }
local common_item = { id = "test_common", rarity = "common", slot = "weapon" }
local rare_item = { id = "test_rare", rarity = "rare", slot = "weapon" }
assert_true(shop.is_item_unlocked(state, common_item), "通常装備は解錠無しでも購入可能である")
assert_true(shop.is_item_unlocked(state, rare_item) == false, "レア装備は解錠が必要である")

print("OK")
