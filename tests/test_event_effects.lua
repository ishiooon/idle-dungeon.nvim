-- このテストはイベント効果が状態へ反映されることを確認する。

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local effects = require("idle_dungeon.game.event_effects")
local state_module = require("idle_dungeon.core.state")

local config = {
  tick_seconds = 1,
  event_message_ticks = 2,
  ui = { language = "en" },
}

local state = state_module.new_state(config)
local heal_event = {
  id = "event_heal_test",
  message = { en = "A warm breeze mends your wounds.", ja = "温かな風が傷を癒やす。" },
  effect = { kind = "heal", amount = 3 },
}

local healed, seed1 = effects.apply_event(state, heal_event, config, 1)
assert_equal(healed.actor.hp, math.min(state.actor.max_hp, state.actor.hp + 3), "回復効果が反映される")
assert_equal(healed.ui.event_message_remaining, config.event_message_ticks, "イベントメッセージの残り回数が設定される")
assert_equal(type(seed1), "number", "乱数シードが数値で返る")

local speed_event = {
  id = "event_speed_test",
  message = { en = "The path accelerates.", ja = "道が加速する。" },
  effect = { kind = "speed", tick_seconds = 0.5, duration_ticks = 3 },
}

local boosted = effects.apply_event(state, speed_event, config, 1)
assert_equal(boosted.ui.speed_boost.remaining_ticks, 3, "速度上昇の残り回数が設定される")
assert_equal(boosted.ui.speed_boost.tick_seconds, 0.5, "速度上昇のティック秒が設定される")

print("OK")
