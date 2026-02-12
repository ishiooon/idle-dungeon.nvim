-- このテストはサブメニューで先頭行から上移動した際に末尾へ循環することを確認する。

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
  }

  _G.vim = {
    o = { lines = 40, cmdheight = 1, columns = 120 },
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

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.select({
    { id = "first", label = "TOP_SUB_ENTRY" },
    { id = "second", label = "MIDDLE_SUB_ENTRY" },
    { id = "third", label = "BOTTOM_SUB_ENTRY" },
  }, {
    lang = "en",
    add_back_item = false,
    footer_hints = { "Enter", "q" },
    format_item = function(item)
      return item.label
    end,
  }, function() end, { ui = { language = "en", menu = {} } })

  assert_true(type(keymaps["<Up>"]) == "function", "上移動のキーマップが登録される")
  keymaps["<Up>"]()
  assert_contains(selected_line(rendered_lines), "BOTTOM_SUB_ENTRY", "先頭から上入力すると末尾項目へ循環する")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
