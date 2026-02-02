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
    enemy = { name = "Goblin", hp = 3, max_hp = 8, is_boss = false },
    last_turn = {
      hero = { hit = true, damage = 2, element = "fire", attacker = "hero", effectiveness = "strong" },
      enemy = { hit = false, damage = 0, element = "water", attacker = "enemy", effectiveness = "weak" },
    },
  },
}

local config = { ui = { icons = { hero = "H", enemy = "E", boss = "B", hp = "" } } }
local line_hp = render_battle.build_battle_info_line(state, config, "en")
assert_match(line_hp, "H", "勇者のアイコンが表示される")
assert_match(line_hp, "Enemy", "敵ラベルが表示される")
assert_match(line_hp, "5/10", "勇者のHPが表示される")
assert_match(line_hp, "3/8", "敵のHPが表示される")

state.metrics.time_sec = 1
local line_log = render_battle.build_battle_info_line(state, config, "en")
assert_match(line_log, "Hit", "攻撃の命中表示が含まれる")
assert_match(line_log, "Evade", "攻撃の回避表示が含まれる")

print("OK")
