-- このテストはメインメニューのカーソルを選択記号上に置かないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local cursor_col = nil

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
    set_lines = function() end,
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
    o = { lines = 40, cmdheight = 1, columns = 120 },
    api = {
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_set_cursor = function(_, pos)
        cursor_col = pos[2]
      end,
    },
    keymap = {
      set = function() end,
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

  local tabs_view = require("idle_dungeon.menu.tabs_view")
  local config = { ui = { language = "en", menu = {} } }
  tabs_view.set_context(function()
    return { ui = { language = "en" } }
  end, config)
  tabs_view.select({
    {
      id = "status",
      label = "Status",
      items = {
        { id = "entry", label = "First item" },
      },
      format_item = function(item)
        return item.label
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "Enter", "Tab", "q" },
  }, config)

  assert_true(type(cursor_col) == "number", "カーソル位置が設定される")
  assert_true(cursor_col > 2, "カーソルは選択記号の列より右に配置される")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
