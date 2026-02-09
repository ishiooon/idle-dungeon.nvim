-- このテストは図鑑詳細がカード形式で表示されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")

local config = {
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = state_dex.record_enemy(state, "tux_penguin", "water")
state = state_dex.record_item(state, "short_bow", 1)

local items = menu_data.build_dex_items(state, config, "en", {
  mode = "all",
  show_all_enemies = true,
  show_all_items = true,
})

local enemy_detail = nil
local item_detail = nil
for _, item in ipairs(items or {}) do
  if item.id == "dex_entry" and item.kind == "enemy" and (item.label or ""):match("Tux Penguin") then
    enemy_detail = item.detail_lines
  end
  if item.id == "dex_entry" and item.kind == "item" and (item.label or ""):match("Short Bow") then
    item_detail = item.detail_lines
  end
end

assert_true(type(enemy_detail) == "table" and #enemy_detail > 0, "敵詳細カードが生成される")
assert_true((enemy_detail[1] or ""):match("┏") ~= nil, "敵詳細カードの上枠が表示される")
local enemy_joined = table.concat(enemy_detail or {}, " ")
assert_true(enemy_joined:match("ENEMY DEX") ~= nil, "敵詳細カードの見出しが表示される")
assert_true(enemy_joined:match("Battle Data") ~= nil, "敵詳細に戦闘情報セクションが表示される")
assert_true(enemy_joined:match("Drops") ~= nil, "敵詳細にドロップセクションが表示される")
assert_true((enemy_detail[#enemy_detail] or ""):match("┗") ~= nil, "敵詳細カードの終端枠が表示される")

assert_true(type(item_detail) == "table" and #item_detail > 0, "装備詳細カードが生成される")
assert_true((item_detail[1] or ""):match("┏") ~= nil, "装備詳細カードの上枠が表示される")
local item_joined = table.concat(item_detail or {}, " ")
assert_true(item_joined:match("ITEM DEX") ~= nil, "装備詳細カードの見出しが表示される")
assert_true(item_joined:match("Item Notes") ~= nil, "装備詳細にメモセクションが表示される")

print("OK")
