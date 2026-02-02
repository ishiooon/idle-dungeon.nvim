-- このテストはステージの敵プール選択が期待通りであることを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local enemy_catalog = require("idle_dungeon.game.enemy_catalog")

local config_fixed = {
  stages = {
    {
      id = 1,
      enemy_pool = { fixed = { "dust_slime" }, mixed = { "cave_bat" }, fixed_ratio = 100 },
    },
  },
  enemy_names = { "moss_goblin" },
}

local id_fixed = enemy_catalog.pick_enemy_id(1, { stage_id = 1 }, config_fixed)
assert_equal(id_fixed, "dust_slime", "固定プール100%では固定枠が選ばれる")

local config_mixed = {
  stages = {
    {
      id = 2,
      enemy_pool = { fixed = { "dust_slime" }, mixed = { "cave_bat" }, fixed_ratio = 0 },
    },
  },
  enemy_names = { "moss_goblin" },
}

local id_mixed = enemy_catalog.pick_enemy_id(1, { stage_id = 2 }, config_mixed)
assert_equal(id_mixed, "cave_bat", "固定プール0%では混合枠が選ばれる")

local config_fallback = {
  enemy_names = { "moss_goblin" },
}

local id_fallback = enemy_catalog.pick_enemy_id(1, { stage_id = nil }, config_fallback)
assert_equal(id_fallback, "moss_goblin", "ステージ指定なしの場合は設定の敵名を使う")

print("OK")
