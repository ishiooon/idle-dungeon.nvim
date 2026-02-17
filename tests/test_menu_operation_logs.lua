-- このテストはメニュー操作の確定時に操作ログが追加されることを確認する。

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

local function with_actions_stubbed(select_fn, run_fn)
  package.loaded["idle_dungeon.menu.view"] = {
    select = select_fn,
    close = function() end,
    set_context = function() end,
  }
  package.loaded["idle_dungeon.menu.actions"] = nil
  local actions = require("idle_dungeon.menu.actions")
  run_fn(actions)
end

local config = {
  stage_name = "menu-operation-log",
  stages = {
    { id = 1, name = "menu-operation-log", start = 0, length = 8 },
    { id = 2, name = "menu-operation-log-2", start = 8, length = 8 },
  },
  ui = { language = "en" },
}

do
  local state = state_module.new_state(config)
  state = util.merge_tables(state, {
    inventory = util.merge_tables(state.inventory or {}, {
      wood_sword = 1,
      short_bow = 1,
    }),
  })
  local call_count = 0
  local function get_state()
    return state
  end
  local function set_state(next_state)
    state = next_state
  end
  with_actions_stubbed(function(items, _, on_choice)
    call_count = call_count + 1
    if call_count == 1 and on_choice then
      on_choice("weapon")
      return
    end
    if call_count == 2 and on_choice then
      local equipped = ((state.equipment or {}).weapon)
      for _, item in ipairs(items or {}) do
        if type(item) == "table" and item.id ~= equipped then
          on_choice(item)
          return
        end
      end
      error("武器候補が見つからないため装備変更を検証できない")
    end
  end, function(actions)
    actions.open_equip_menu(get_state, set_state, config)
  end)
  assert_true(has_log_line(state, "Equipment Changed"), "装備変更を確定した時に操作ログが追加される")
end

do
  local state = state_module.new_state(config)
  local function get_state()
    return state
  end
  local function set_state(next_state)
    state = next_state
  end
  with_actions_stubbed(function(items, _, on_choice)
    if on_choice then
      on_choice(items and items[1] or nil)
    end
  end, function(actions)
    actions.open_stage_menu(get_state, set_state, config)
  end)
  assert_true(has_log_line(state, "Start Stage Changed"), "開始ステージを選択した時に操作ログが追加される")
end

do
  local state = state_module.new_state(config)
  state = util.merge_tables(state, {
    skills = {
      active = { slash = true },
      passive = { blade_aura = true },
    },
    skill_settings = {
      active = { slash = true },
      passive = { blade_aura = false },
    },
  })
  local function get_state()
    return state
  end
  local function set_state(next_state)
    state = next_state
  end
  with_actions_stubbed(function(items, _, on_choice)
    if on_choice then
      on_choice(items and items[1] or nil)
    end
  end, function(actions)
    actions.open_skills_menu(get_state, set_state, config)
  end)
  assert_true(has_log_line(state, "Skill Toggled"), "スキル有効状態を切り替えた時に操作ログが追加される")
end

print("OK")
