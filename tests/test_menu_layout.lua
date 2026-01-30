-- このテストはメニューのレイアウト生成が期待通りであることを確認する。
-- メニュー階層の整理に合わせて参照先を更新する。

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

local layout = require("idle_dungeon.menu.layout")

local items = {
  { id = "a", label = "First" },
  { id = "b", label = "Second" },
  { id = "c", label = "Third" },
}

local labels = layout.build_labels(items, function(item)
  return item.label
end)

assert_equal(#labels, 3, "ラベル数は項目数と一致する")

local built = layout.build_lines("Menu", labels, { padding = 1, offset = 1, max_items = 2, max_width = 10 })
assert_equal(built.items_start, 2, "タイトルの後に項目が配置される")
assert_equal(built.items_count, 2, "最大件数分の項目が表示される")
assert_true(#built.lines <= 3, "表示行数が制限内に収まる")
assert_true(built.offset >= 0, "オフセットは0以上になる")
assert_true(built.width <= 10, "表示幅が最大幅以内に収まる")

print("OK")
