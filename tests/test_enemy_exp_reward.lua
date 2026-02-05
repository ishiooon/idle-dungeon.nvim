-- このテストは敵ごとの経験値倍率が定義されていることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local config = require("idle_dungeon.config")

local built = config.build({})
local base_exp = (built.battle or {}).reward_exp or 0

local has_rare = false

for _, enemy in ipairs(content.enemies or {}) do
  assert_true(type(enemy.exp_multiplier) == "number", "経験値倍率が数値で定義される: " .. tostring(enemy.id))
  assert_true(enemy.exp_multiplier > 0, "経験値倍率は正の値である: " .. tostring(enemy.id))
  -- ボスは大量経験値になるよう倍率を大きくする。
  if enemy.id and enemy.id:match("^boss_") then
    assert_true(enemy.exp_multiplier >= 15, "ボスの経験値倍率は15以上である: " .. tostring(enemy.id))
    assert_true(base_exp * enemy.exp_multiplier >= base_exp * 15, "ボスの経験値は十分に大きい: " .. tostring(enemy.id))
  end
  if enemy.id == "prism_slime" then
    has_rare = true
    -- レア枠の敵はさらに大量の経験値を持つ。
    assert_true(enemy.exp_multiplier >= 60, "レアスライムは大量経験値である")
  end
end

assert_true(has_rare, "レアスライムが定義される")

print("OK")
