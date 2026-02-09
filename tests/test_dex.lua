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

local found_header = false
local found_entry = false
local found_detail = false
local found_stylish_row = false
local found_toggle = false
for _, entry in ipairs(dex_items) do
  if entry.id == "header" and (entry.label or ""):match("Enemies") then
    found_header = true
  end
  if entry.id == "dex_control" and (entry.label or ""):match("Expand") then
    found_toggle = true
  end
  if entry.id == "dex_entry" then
    found_entry = true
    if (entry.label or ""):match("№%d%d%d") then
      found_stylish_row = true
    end
    if entry.detail_lines and #entry.detail_lines > 0 then
      found_detail = true
    end
  end
end
assert_true(found_header, "敵の見出しが含まれる")
assert_true(found_entry, "図鑑のタイル項目が生成される")
assert_true(found_stylish_row, "図鑑の行に番号付きデザインが適用される")
assert_true(found_toggle, "図鑑の展開トグルが含まれる")
assert_true(found_detail, "図鑑の詳細行が生成される")

local expanded_items = menu_data.build_dex_items(item_state, config, "en", {
  show_all_enemies = true,
  show_all_items = true,
})
local found_collapse_toggle = false
for _, entry in ipairs(expanded_items) do
  if entry.id == "dex_control" and (entry.label or ""):match("Collapse") then
    found_collapse_toggle = true
  end
end
assert_true(found_collapse_toggle, "図鑑の展開後に折りたたみトグルが含まれる")

print("OK")
