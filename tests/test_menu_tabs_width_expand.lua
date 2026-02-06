-- このテストはメインメニューが上部表示と項目長に合わせて横幅を拡張し、折り返しを無効化することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local captured_width = nil
  local captured_wrap = nil

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return { string.rep("T", 92), "HP 100" }
    end,
  }
  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function(_, _, _, width, _, _, opts)
      captured_width = width
      captured_wrap = opts and opts.wrap_lines
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
    o = { lines = 40, cmdheight = 1, columns = 140 },
    api = {
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_set_cursor = function() end,
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
  local config = {
    ui = {
      language = "en",
      menu = {
        width = 60,
        min_width = 52,
        max_width = 68,
      },
    },
  }
  tabs_view.set_context(function()
    return { ui = { language = "en" } }
  end, config)
  tabs_view.select({
    {
      id = "status",
      label = "Status",
      items = {
        { id = "line", label = string.rep("X", 90) },
      },
      format_item = function(item)
        return item.label
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "Enter", "Tab", "q" },
  }, config)

  assert_true(captured_width ~= nil and captured_width > 68, "内容幅に応じて既定最大幅を超えて拡張する")
  assert_true(captured_wrap == false, "メインメニューは折り返しを無効にする")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
