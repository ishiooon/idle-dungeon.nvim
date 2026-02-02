-- このテストは進行トラックの表示と位置計算が期待通りであることを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local track = require("idle_dungeon.ui.track")

local enemies = {
  { position = 5, icon = "E", id = "slime" },
}

local model = track.build_track(3, 10, "H", ".", enemies)
assert_true(type(model.line) == "string", "トラック行が生成される")
assert_equal(model.hero.position, 4, "距離に応じて勇者の位置が決まる")
assert_equal(model.enemies[1].position, 5, "敵の位置が反映される")
assert_true(#model.offsets == 10, "セルごとのオフセットが算出される")
assert_true(model.line:match("H") ~= nil, "勇者アイコンが配置される")
assert_true(model.line:match("E") ~= nil, "敵アイコンが配置される")

print("OK")
