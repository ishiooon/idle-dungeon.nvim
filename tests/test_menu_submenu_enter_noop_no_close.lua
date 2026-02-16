-- このテストはサブメニューでEnter実行対象ではない行を押しても何も実行せず閉じないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local maps = {}
  local callback_called = 0
  local close_called = 0

  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function() end,
    set_lines = function() end,
    apply_highlights = function() end,
    close_window = function(win)
      if win then
        close_called = close_called + 1
      end
    end,
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
        maps[lhs] = rhs
      end,
    },
    fn = {
      strdisplaywidth = function(text)
        return #(text or "")
      end,
    },
  }

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.select({
    { id = "readonly", label = "READ_ONLY" },
  }, {
    lang = "en",
    add_back_item = false,
    can_execute_on_enter = function(item)
      return type(item) == "table" and item.id == "executable"
    end,
    format_item = function(item)
      return item.label
    end,
  }, function()
    callback_called = callback_called + 1
  end, { ui = { language = "en", menu = {} } })

  assert_true(type(maps["<CR>"]) == "function", "Enterキーのマッピングが登録される")
  maps["<CR>"]()
  assert_true(callback_called == 0, "非実行行でEnterを押してもコールバックは呼ばれない")
  assert_true(close_called == 0, "非実行行でEnterを押してもサブメニューは閉じない")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
