-- このテストは図鑑の並び替えと検索フィルタのふるまいを確認する。

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

local state = state_module.new_state(config)
state = state_dex.record_enemy(state, "dust_slime", "normal")
for _ = 1, 4 do
  state = state_dex.record_enemy(state, "tux_penguin", "water")
end
local target_name = ((enemy_catalog.find_enemy("tux_penguin") or {}).name_en) or ""

-- 検証名に正規表現文字が含まれても安全に照合できるようにする。
local function escape_pattern(text)
  return (tostring(text):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local sorted = menu_data.build_dex_items(state, config, "en", {
  mode = "enemy",
  sort_mode = "count",
  show_all_enemies = true,
})

local first_enemy_label = nil
for _, item in ipairs(sorted) do
  if item.id == "dex_entry" and item.kind == "enemy" then
    first_enemy_label = item.label or ""
    break
  end
end
assert_true(first_enemy_label ~= nil, "敵エントリが生成される")
assert_true(first_enemy_label:match(escape_pattern(target_name)) ~= nil, "回数順では遭遇回数の多い敵が先頭になる")

-- 英語名から検索キーワードを抽出して、名前変更に依存しない検索挙動を確認する。
local filter_keyword = string.lower((target_name:match("([A-Za-z]+)") or ""))
assert_true(filter_keyword ~= "", "検索キーワードが抽出できる")

local filtered = menu_data.build_dex_items(state, config, "en", {
  mode = "enemy",
  filter_keyword = filter_keyword,
  show_all_enemies = true,
})

local filtered_count = 0
for _, item in ipairs(filtered) do
  if item.id == "dex_entry" and item.kind == "enemy" then
    filtered_count = filtered_count + 1
    assert_true((item.label or ""):match(escape_pattern(target_name)) ~= nil, "キーワード検索で一致する敵だけが表示される")
  end
end
assert_true(filtered_count > 0, "キーワード検索でエントリが残る")

print("OK")
