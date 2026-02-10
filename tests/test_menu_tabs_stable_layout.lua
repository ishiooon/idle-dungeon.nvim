-- このテストはタブ更新時にメニューの横幅と高さが縮まず、上部表示が安定することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equal failed") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end
end

local function leading_spaces(text)
  local matched = (tostring(text or "")):match("^(%s*)") or ""
  return #matched
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local widths = {}
  local heights = {}
  local rendered = {}
  local long_mode = true

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      if long_mode then
        return { string.rep("L", 88), "HP 100" }
      end
      return { "short", "HP 100" }
    end,
  }

  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function(_, height, width)
      table.insert(widths, width)
      table.insert(heights, height)
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
    o = { lines = 40, cmdheight = 1, columns = 140 },
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
  local config = {
    ui = {
      language = "en",
      menu = { width = 60, min_width = 52, max_width = 68 },
    },
  }
  local tabs = {
    { id = "status", label = "Status", items = { { id = "entry", label = "A" } }, format_item = function(item) return item.label end },
    { id = "actions", label = "Actions", items = { { id = "entry", label = "B" } }, format_item = function(item) return item.label end },
  }
  tabs_view.set_context(function()
    return { ui = { language = "en" } }
  end, config)
  tabs_view.select(tabs, { title = "Idle Dungeon", footer_hints = { "Enter", "Tab", "q" } }, config)
  local first_width = widths[#widths] or 0
  local first_height = heights[#heights] or 0

  long_mode = false
  tabs_view.update(tabs)
  local second_width = widths[#widths] or 0
  local second_height = heights[#heights] or 0

  assert_true(first_width > 68, "初回描画で内容幅に応じて拡張する")
  assert_true(second_width >= first_width, "更新後も横幅が縮まない")
  assert_true(second_height >= first_height, "更新後も高さが縮まない")
  local top_line_1 = rendered[2] or ""
  local top_line_2 = rendered[3] or ""
  assert_true(top_line_1 ~= "", "上部ゲーム表示の1行目が表示される")
  assert_true(top_line_2 ~= "", "上部ゲーム表示の2行目が表示される")
  -- 上部のゲーム表示はメニュー幅の中央に来るよう、左余白が計算されることを確認する。
  assert_equal(leading_spaces(top_line_1), math.floor((second_width - #"short") / 2), "1行目が中央寄せされる")
  assert_equal(leading_spaces(top_line_2), math.floor((second_width - #"HP 100") / 2), "2行目が中央寄せされる")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
