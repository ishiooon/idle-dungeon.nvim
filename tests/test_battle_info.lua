-- このテストは戦闘中の情報行が必要な要素を含むことを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end
local function assert_not_match(text, pattern, message)
  if text:match(pattern) then
    error((message or "assert_not_match failed") .. ": " .. tostring(text) .. " =~ " .. pattern)
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

local config = { ui = { width = 60, icons = { hero = "H", enemy = "E", boss = "B", hp = "", weapon = "WPN", armor = "SHD" } } }
local line_hp = render_battle.build_battle_info_line(state, config, "en")
assert_match(line_hp, "H", "勇者のアイコンが表示される")
assert_match(line_hp, "", "敵アイコンが表示される")
assert_match(line_hp, "5", "勇者のHPが表示される")
assert_match(line_hp, "3", "敵のHPが表示される")
assert_not_match(line_hp, "5/10", "HPの分母は既定では表示しない")
assert_not_match(line_hp, "3/8", "HPの分母は既定では表示しない")
assert_match(line_hp, "", "ハートアイコンが表示される")
assert_match(line_hp, "^H〉", "勇者表示が左端から始まる")
assert_match(line_hp, "〈%s*$", "敵表示が右端に配置される")
assert_match(line_hp, "〉Attack〉", "中央に通常攻撃の表示が入る")

local enemy_state = {
  actor = { name = "Hero", hp = 5, max_hp = 10 },
  metrics = { time_sec = 0 },
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 3, max_hp = 8, is_boss = false },
    last_turn = {
      attacker = "enemy",
      time_sec = 0,
      result = { hit = true, damage = 2, element = "fire", attacker = "enemy", effectiveness = "strong" },
    },
  },
}
local enemy_line = render_battle.build_battle_info_line(enemy_state, config, "en")
assert_match(enemy_line, "〈Attack〈", "敵側の攻撃は右側の向きで表示される")

-- HP分母表示を切り替えた場合の表示を確認する。
local max_state = {
  actor = { name = "Hero", hp = 7, max_hp = 12 },
  ui = { battle_hp_show_max = true },
  metrics = { time_sec = 0 },
  combat = {
    enemy = { id = "dust_slime", name = "Lua Slime", hp = 4, max_hp = 9, is_boss = false },
  },
}
local max_line = render_battle.build_battle_info_line(max_state, config, "en")
assert_match(max_line, "7/12", "HPの分母表示を有効にできる")
assert_match(max_line, "4/9", "敵の分母表示も有効にできる")

print("OK")
