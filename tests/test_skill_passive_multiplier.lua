-- このテストはパッシブ補正が掛け算で適用されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local skills = require("idle_dungeon.game.skills")

local jobs = {
  {
    id = "a",
    skills = {
      { id = "p1", kind = "passive", level = 1, name = "P1", description = "", bonus_mul = { atk = 1.1 } },
      { id = "p2", kind = "passive", level = 1, name = "P2", description = "", bonus_mul = { atk = 1.2 } },
    },
  },
}

local learned = { active = {}, passive = { p1 = true, p2 = true } }
local enabled = { active = {}, passive = { p1 = true, p2 = true } }
local bonus = skills.resolve_passive_bonus(learned, enabled, jobs)
assert_true(math.abs((bonus.atk or 1) - 1.32) < 0.0001, "パッシブ補正は掛け算で合成される")

print("OK")
