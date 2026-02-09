-- このテストは図鑑の表示モード切り替えで表示対象が変わることを確認する。

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
state = state_dex.record_enemy(state, "dust_slime")
state = state_dex.record_item(state, "wood_sword", 1)

local function has_header(items, pattern)
  for _, item in ipairs(items or {}) do
    if item.id == "header" and (item.label or ""):match(pattern) then
      return true
    end
  end
  return false
end

local enemy_only = menu_data.build_dex_items(state, config, "en", { mode = "enemy" })
assert_true(has_header(enemy_only, "— Enemies —"), "敵モードでは敵セクションを表示する")
assert_true(not has_header(enemy_only, "— Items —"), "敵モードではアイテムセクションを表示しない")

local item_only = menu_data.build_dex_items(state, config, "en", { mode = "item" })
assert_true(has_header(item_only, "— Items —"), "アイテムモードではアイテムセクションを表示する")
assert_true(not has_header(item_only, "— Enemies —"), "アイテムモードでは敵セクションを表示しない")

local both = menu_data.build_dex_items(state, config, "en", { mode = "all" })
assert_true(has_header(both, "— Enemies —"), "両方モードでは敵セクションを表示する")
assert_true(has_header(both, "— Items —"), "両方モードではアイテムセクションを表示する")

print("OK")
