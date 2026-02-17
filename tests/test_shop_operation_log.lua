-- このテストは購入と売却の確定時に操作ログが追加されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local function has_log_line(state, token)
  for _, line in ipairs((state and state.logs) or {}) do
    if string.find(tostring(line or ""), token, 1, true) then
      return true
    end
  end
  return false
end

local function with_shop_stubbed(select_fn, run_fn)
  package.loaded["idle_dungeon.menu.view"] = {
    select = select_fn,
    close = function() end,
    set_context = function() end,
  }
  package.loaded["idle_dungeon.menu.shop"] = nil
  local shop = require("idle_dungeon.menu.shop")
  run_fn(shop)
end

local config = {
  stage_name = "shop-operation-log",
  stages = {
    { id = 1, name = "shop-operation-log", start = 0, length = 8 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  currency = { gold = 999 },
})

local function get_state()
  return state
end

local function set_state(next_state)
  state = next_state
end

do
  local call_count = 0
  with_shop_stubbed(function(items, _, on_choice)
    call_count = call_count + 1
    if call_count == 1 and on_choice then
      on_choice(items and items[1] or nil)
      return
    end
    if call_count == 2 and on_choice then
      local picked = nil
      for _, item in ipairs(items or {}) do
        local equipped = ((state.equipment or {})[item.slot])
        if equipped ~= item.id then
          picked = item
          break
        end
      end
      on_choice(picked or (items and items[1] or nil))
    end
  end, function(shop)
    shop.open_purchase_menu(get_state, set_state, "en", config)
  end)
  assert_true(has_log_line(state, "Purchased:"), "購入を確定した時に操作ログが追加される")
end

do
  with_shop_stubbed(function(items, _, on_choice)
    if on_choice then
      on_choice(items and items[1] or nil)
    end
  end, function(shop)
    shop.open_sell_menu(get_state, set_state, "en", config)
  end)
  assert_true(has_log_line(state, "Sold:"), "売却を確定した時に操作ログが追加される")
end

print("OK")
