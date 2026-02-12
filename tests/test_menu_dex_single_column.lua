-- このテストは図鑑タブが常に1カラムで描画されることを確認する。

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
  end
end

local function assert_not_contains(text, needle, message)
  if string.find(text or "", needle or "", 1, true) then
    error((message or "assert_not_contains failed") .. ": " .. tostring(text) .. " =~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered = {}

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return {}
    end,
  }
  package.loaded["idle_dungeon.ui.render_stage"] = {
    build_menu_header = function()
      return ""
    end,
  }
  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function() end,
    set_lines = function(_, lines)
      rendered = lines
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
    return {
      ui = { language = "en" },
      progress = { distance = 0 },
      metrics = { time_sec = 0 },
    }
  end, config)

  tabs_view.select({
    {
      id = "dex",
      label = "Dex",
      items = {
        {
          id = "dex_entry",
          label = "SLIME",
          detail_title = "SLIME",
          detail_lines = {
            "DETAIL HEADER",
            "DETAIL BODY",
          },
        },
      },
      format_item = function(item)
        return item.label
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, config)

  local text = table.concat(rendered or {}, "\n")
  assert_contains(text, "SLIME", "図鑑本文が左カラムに表示される")
  assert_not_contains(text, "DETAIL HEADER", "図鑑では右カラムの詳細プレビューを表示しない")
  assert_not_contains(text, "│", "図鑑は1カラム描画で区切り線を表示しない")
  tabs_view.close(true)
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
