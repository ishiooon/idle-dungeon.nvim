-- このテストは敗北時の表示に勇者と敗北アイコンが含まれることを確認する。

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local render_info = require("idle_dungeon.ui.render_info")

local state = {
  ui = { mode = "defeat", language = "en" },
  actor = { hp = 0, max_hp = 10 },
}

local config = {
  ui = {
    width = 80,
    icons = { hero = "H", defeat = "X" },
  },
}

local line = render_info.build_info_line(state, config)
assert_match(line, "H", "敗北表示に勇者アイコンが含まれる")
assert_match(line, "X", "敗北表示に敗北アイコンが含まれる")

print("OK")
