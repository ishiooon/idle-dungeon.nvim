-- このテストは下部説明行がある場合でも、本文領域だけが正しくスクロールすることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local keymaps = {}
  local rendered_lines = {}

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return { "TRACK", "HP 10" }
    end,
  }
  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function() end,
    set_lines = function(_, lines)
      rendered_lines = lines
    end,
    apply_highlights = function() end,
    close_window = function() end,
    is_valid_window = function()
      return false
    end,
    is_valid_buffer = function()
      return false
    end,
  }

  _G.vim = {
    o = { lines = 32, cmdheight = 1, columns = 120 },
    api = {
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_set_cursor = function() end,
    },
    keymap = {
      set = function(_, lhs, rhs)
        keymaps[lhs] = rhs
      end,
    },
    fn = {
      getmousepos = function()
        return { winid = 0, line = 0, column = 0 }
      end,
      strdisplaywidth = function(text)
        return #(text or "")
      end,
    },
  }

  local function selected_line(lines)
    for _, line in ipairs(lines or {}) do
      if string.find(line or "", "󰜴 ", 1, true) then
        return line
      end
    end
    return ""
  end

  local items = {}
  for index = 1, 10 do
    table.insert(items, { id = "entry", label = string.format("ITEM_%02d", index), keep_open = true })
  end

  local tabs_view = require("idle_dungeon.menu.tabs_view")
  local config = {
    ui = {
      language = "en",
      menu = {
        width = 60,
        min_width = 60,
        max_width = 60,
        height = 18,
        min_height = 18,
        max_height = 18,
      },
    },
    floor_length = 12,
    stages = {
      { id = 1, name = "Scroll Test", start = 0, floors = 6 },
    },
  }
  tabs_view.set_context(function()
    return {
      ui = { language = "en" },
      progress = {
        stage_id = 1,
        stage_name = "Scroll Test",
        distance = 0,
        stage_start = 0,
      },
    }
  end, config)
  tabs_view.select({
    {
      id = "config",
      label = "Config",
      items = items,
      format_item = function(item)
        return item.label
      end,
      enter_hint_provider = function()
        return {
          "󰌑 Enter: Apply selected setting",
          "󰇀 Current -> Next",
        }
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q Close" },
  }, config)

  assert_true(type(keymaps["j"]) == "function", "下移動のキーマップが登録される")
  for _ = 1, 8 do
    keymaps["j"]()
  end
  assert_contains(selected_line(rendered_lines), "ITEM_09", "下部説明があっても本文領域だけがスクロールし選択項目が表示される")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
