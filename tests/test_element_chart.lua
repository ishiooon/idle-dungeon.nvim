-- このテストは属性相性の倍率が期待通りであることを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function assert_close(actual, expected, message)
  if math.abs((actual or 0) - (expected or 0)) > 0.0001 then
    error((message or "assert_close failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local element = require("idle_dungeon.game.element")

local mult_fire_grass, rel_fire_grass = element.effectiveness("fire", "grass")
assert_close(mult_fire_grass, 1.25, "炎は草に強い")
assert_equal(rel_fire_grass, "strong", "炎は草に強い分類")

local mult_fire_water, rel_fire_water = element.effectiveness("fire", "water")
assert_close(mult_fire_water, 0.75, "炎は水に弱い")
assert_equal(rel_fire_water, "weak", "炎は水に弱い分類")

local mult_water_fire, rel_water_fire = element.effectiveness("water", "fire")
assert_close(mult_water_fire, 1.25, "水は炎に強い")
assert_equal(rel_water_fire, "strong", "水は炎に強い分類")

local mult_grass_water, rel_grass_water = element.effectiveness("grass", "water")
assert_close(mult_grass_water, 1.25, "草は水に強い")
assert_equal(rel_grass_water, "strong", "草は水に強い分類")

local mult_light_dark, rel_light_dark = element.effectiveness("light", "dark")
assert_close(mult_light_dark, 1.25, "光は闇に強い")
assert_equal(rel_light_dark, "strong", "光は闇に強い分類")

local mult_dark_light, rel_dark_light = element.effectiveness("dark", "light")
assert_close(mult_dark_light, 1.25, "闇は光に強い")
assert_equal(rel_dark_light, "strong", "闇は光に強い分類")

local mult_normal, rel_normal = element.effectiveness("normal", "dark")
assert_close(mult_normal, 1.0, "ノーマルは等倍")
assert_equal(rel_normal, "neutral", "ノーマルは等倍分類")

print("OK")
