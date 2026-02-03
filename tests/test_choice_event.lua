-- このテストは選択イベントの開始と決定処理を確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local event_choice = require("idle_dungeon.game.event_choice")
local state_module = require("idle_dungeon.core.state")

local config = { choice_seconds = 10, ui = { language = "ja" } }
local state = state_module.new_state(config)
local event = {
  id = "choice_test",
  title = { en = "Test Chest", ja = "試験の宝箱" },
  message = { en = "Open it?", ja = "開けますか？" },
  choices = {
    {
      id = "open",
      label = { en = "Open", ja = "開ける" },
      results = {
        { id = "good", weight = 1, message = { en = "Lucky!", ja = "大当たり！" }, effect = { kind = "heal", amount = 2 } },
      },
    },
    {
      id = "leave",
      label = { en = "Leave", ja = "立ち去る" },
      results = {
        { id = "none", weight = 1, message = { en = "You walk away.", ja = "そっと立ち去った。" } },
      },
    },
  },
}

local started = event_choice.start_choice(state, event, config)
assert_equal(started.ui.mode, "choice", "選択イベントに入る")
assert_equal(started.ui.choice_remaining, 10, "選択の残り秒数が初期化される")

local seeded = {
  progress = { floor_event = { id = "choice_test", position = 1 } },
}
local with_event = require("idle_dungeon.util").merge_tables(started, seeded)
local resolved = event_choice.apply_choice_event(with_event, event, config, 1)
assert_equal(resolved.ui.mode, "move", "選択後は移動に戻る")
assert_equal(resolved.ui.choice_remaining, 0, "選択後に残り秒数がクリアされる")
assert_equal((resolved.progress.floor_event or {}).resolved, true, "イベントが解決済みになる")

print("OK")
