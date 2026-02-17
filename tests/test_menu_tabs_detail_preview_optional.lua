-- このテストは詳細情報を下部へ表示してもメインタブが1カラム表示を維持することを確認する。

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
  local rendered = {}
  local window_width = 0

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
    update_window = function(_, _, width)
      window_width = width or 0
    end,
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
      id = "status",
      label = "Status",
      items = {
        { id = "entry", label = "TOP" },
        { id = "entry", label = "BOTTOM" },
      },
      format_item = function(item)
        return item.label
      end,
      detail_provider = function(item)
        return {
          title = item.label or "",
          lines = {
            "DETAIL HEADER",
            "VALUE: 42",
            "This detail text is intentionally long to verify wrapping behavior keeps the tail token visible ENDTOKEN.",
          },
        }
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, config)

  local text = table.concat(rendered or {}, "\n")
  assert_contains(text, "TOP", "メインタブ本文が表示される")
  assert_true(not string.find(text, " │ ", 1, true), "詳細情報を表示しても左右ペインの区切りを表示しない")
  assert_contains(text, "Detail: TOP", "詳細タイトルを下部へ表示する")
  assert_contains(text, "DETAIL HEADER", "詳細本文を下部へ表示する")
  assert_contains(text, "VALUE: 42", "詳細の値を下部へ表示する")
  assert_contains(text, "Open detail with Enter", "長文がある場合は下部に詳細画面への案内を表示する")
  assert_true(window_width <= 84, "詳細表示時もメニュー横幅は広がりすぎない")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
