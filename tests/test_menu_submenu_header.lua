-- このテストはサブメニューで上部のゲーム進捗表示を使わないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local live_called = false
  local rendered_lines = nil

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      live_called = true
      return { "TRACK-L1", "TRACK-L2" }
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
  }

  _G.vim = {
    o = { lines = 40, cmdheight = 1 },
    api = {
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_set_cursor = function() end,
    },
    keymap = {
      set = function() end,
    },
  }

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.set_context(function()
    return { ui = { language = "en" } }
  end, { ui = { language = "en", menu = {} } })
  menu_view.select({ { id = "sample", label = "Sample" } }, {
    lang = "en",
    add_back_item = false,
    footer_hints = { "hints" },
  }, function() end, { ui = { language = "en", menu = {} } })

  assert_true(live_called == false, "サブメニュー表示でライブヘッダーを呼ばない")
  local joined = table.concat(rendered_lines or {}, "\n")
  assert_true(not string.find(joined, "TRACK-L1", 1, true), "サブメニュー本文に上部進捗を含めない")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
