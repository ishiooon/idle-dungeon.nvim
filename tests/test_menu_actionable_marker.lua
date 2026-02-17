-- このテストは実行可能行と表示専用行で先頭マーカーが分かれることを確認する。

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered_tabs = {}
  local rendered_sub = {}

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return {}
    end,
  }
  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function() end,
    set_lines = function(_, lines)
      if #rendered_tabs == 0 then
        rendered_tabs = lines
      else
        rendered_sub = lines
      end
    end,
    apply_highlights = function() end,
    close_window = function() end,
    is_valid_window = function()
      return true
    end,
    is_valid_buffer = function()
      return true
    end,
  }

  _G.vim = {
    o = { lines = 40, cmdheight = 1, columns = 120 },
    api = {
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_set_cursor = function() end,
      nvim_win_is_valid = function()
        return true
      end,
      nvim_buf_is_valid = function()
        return true
      end,
      nvim_set_option_value = function() end,
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
  tabs_view.set_context(function()
    return { ui = { language = "en" } }
  end, { ui = { language = "en", menu = {} } })
  tabs_view.select({
    {
      id = "status",
      label = "Status",
      items = {
        { id = "entry", label = "EXECUTE", exec = true },
        { id = "entry", label = "INFO", exec = false },
      },
      format_item = function(item)
        return item.label
      end,
      can_execute_on_enter = function(item)
        return item.exec == true
      end,
      on_choice = function() end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, { ui = { language = "en", menu = {} } })

  local joined_tabs = table.concat(rendered_tabs or {}, "\n")
  assert_contains(joined_tabs, "󰌑 EXECUTE", "メインメニューの実行可能行は実行マーカーを表示する")
  assert_contains(joined_tabs, "󰇀 INFO", "メインメニューの表示専用行は情報マーカーを表示する")
  tabs_view.close()

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.select({
    { id = "first", label = "EXECUTE_SUB", exec = true, keep_open = true },
    { id = "second", label = "INFO_SUB", exec = false, keep_open = true },
  }, {
    lang = "en",
    footer_hints = { "q" },
    format_item = function(item)
      return item.label
    end,
    can_execute_on_enter = function(item)
      return item.exec == true
    end,
  }, function() end, { ui = { language = "en", menu = {} } })

  local joined_sub = table.concat(rendered_sub or {}, "\n")
  assert_contains(joined_sub, "󰌑 EXECUTE_SUB", "サブメニューの実行可能行は実行マーカーを表示する")
  assert_contains(joined_sub, "󰇀 INFO_SUB", "サブメニューの表示専用行は情報マーカーを表示する")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
