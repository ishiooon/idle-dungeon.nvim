-- このテストは図鑑データの記録と表示生成が期待通りであることを確認する。
-- 図鑑モジュールの配置変更に合わせて参照先を更新する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")

local config = {
  move_step = 1,
  encounter_every = 99,
  dialogue_seconds = 0,
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  enemy_names = { "dust_slime" },
  battle = { enemy_hp = 3, enemy_atk = 0, reward_exp = 1, reward_gold = 1 },
  event_distances = {},
  ui = { language = "en" },
}

local base_state = state_module.new_state(config)
local enemy_state = state_dex.record_enemy(base_state, "dust_slime")
assert_true(enemy_state.dex.enemies.dust_slime.count == 1, "遭遇した敵が図鑑に記録される")

local item_state = state_dex.record_item(enemy_state, "wood_sword", 1)
assert_true(item_state.dex.items.wood_sword.count >= 1, "取得した装備が図鑑に記録される")

local dex_items = menu_data.build_dex_items(item_state, config, "en")
assert_true(#dex_items > 0, "図鑑タブの表示項目が生成される")
assert_match(dex_items[1].label or "", "Enemies", "敵の見出しが含まれる")

print("OK")
