-- このテストはジョブ変更後もスキルが引き継がれることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local skills = require("idle_dungeon.game.skills")

local rogue = {
  id = "rogue",
  skills = {
    { id = "ambush", kind = "active", level = 5, name = "奇襲", description = "先制攻撃を行う。" },
  },
}
local cleric = {
  id = "cleric",
  skills = {
    { id = "prayer", kind = "passive", level = 5, name = "祈り", description = "回復を意識する。" },
  },
}

local learned = skills.empty()
learned = skills.unlock_from_job(learned, rogue, { level = 5 })
learned = skills.unlock_from_job(learned, cleric, { level = 5 })

assert_true(skills.is_learned(learned, "ambush"), "盗賊のスキルが引き継がれる")
assert_true(skills.is_learned(learned, "prayer"), "神官のスキルが引き継がれる")

print("OK")
