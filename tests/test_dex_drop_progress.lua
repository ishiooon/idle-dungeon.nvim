-- このテストは敵図鑑の達成率がドロップ解放率で評価されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_dex = require("idle_dungeon.game.dex.state")
local state_module = require("idle_dungeon.core.state")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")

local config = {
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  ui = { language = "en" },
}

-- 検索名を文字列として照合するために、正規表現メタ文字を無効化する。
local function escape_pattern(text)
  return (tostring(text):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function find_enemy_label(items, name)
  local pattern = escape_pattern(name)
  for _, item in ipairs(items or {}) do
    if item.id == "dex_entry" and item.kind == "enemy" and (item.label or ""):match(pattern) then
      return item.label or ""
    end
  end
  return ""
end

local state0 = state_module.new_state(config)
local target_name = ((enemy_catalog.find_enemy("tux_penguin") or {}).name_en) or ""
assert_true(target_name ~= "", "検証対象の敵名が取得できる")
local state1 = state_dex.record_enemy(state0, "tux_penguin", "water")
local items1 = menu_data.build_dex_items(state1, config, "en", { mode = "enemy", show_all_enemies = true })
local label1 = find_enemy_label(items1, target_name)
assert_true(label1 ~= "", "敵図鑑の対象行が生成される")
assert_true(label1:match("NEW") ~= nil, "ドロップ未解放ではNEW表示になる")
assert_true(label1:match("󰆧0/%d+") ~= nil, "ドロップ解放率が0で表示される")

local state2 = state_dex.record_item(state1, "short_bow", 1)
local items2 = menu_data.build_dex_items(state2, config, "en", { mode = "enemy", show_all_enemies = true })
local label2 = find_enemy_label(items2, target_name)
assert_true(label2:match("★☆☆") ~= nil, "ドロップを1種解放すると達成バッジが進む")
assert_true(label2:match("󰆧1/%d+") ~= nil, "ドロップ解放率が更新される")

print("OK")
