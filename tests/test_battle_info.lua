-- このテストは戦闘中の情報行が必要な要素を含むことを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local render_battle = require("idle_dungeon.ui.render_battle_info")

local state = {
  actor = { name = "Hero", hp = 5, max_hp = 10 },
  metrics = { time_sec = 0 },
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 3, max_hp = 8, is_boss = false },
    last_turn = {
      attacker = "hero",
      time_sec = 0,
      result = { hit = true, damage = 2, element = "fire", attacker = "hero", effectiveness = "strong" },
    },
  },
}

local config = { ui = { icons = { hero = "H", enemy = "E", boss = "B", hp = "", weapon = "WPN", armor = "SHD" } } }
local line_hp = render_battle.build_battle_info_line(state, config, "en")
assert_match(line_hp, "H", "勇者のアイコンが表示される")
assert_match(line_hp, "", "敵アイコンが表示される")
assert_match(line_hp, "5/10", "勇者のHPが表示される")
assert_match(line_hp, "3/8", "敵のHPが表示される")
assert_match(line_hp, "", "ハートアイコンが表示される")

print("OK")
