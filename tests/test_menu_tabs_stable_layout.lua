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

local function assert_contains(text, needle, message)
  if not string.find(text or "", needle or "", 1, true) then
    error((message or "assert_contains failed") .. ": " .. tostring(text) .. " !~ " .. tostring(needle))
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
  local keymaps = {}
  local long_mode = true
  local state_missing = false

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
      set = function(_, lhs, rhs)
        if type(lhs) == "string" and type(rhs) == "function" then
          keymaps[lhs] = rhs
        end
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

  local tabs_view = require("idle_dungeon.menu.tabs_view")
  local config = {
    ui = {
      language = "en",
      track_length = 12,
      menu = { width = 60, min_width = 52, max_width = 68 },
    },
    floor_length = 12,
    stages = {
      { id = 1, name = "Test Dungeon", start = 0, floors = 6 },
    },
  }
  local tabs = {
    { id = "status", label = "Status", items = { { id = "entry", label = "A" } }, format_item = function(item) return item.label end },
    { id = "actions", label = "Actions", items = { { id = "entry", label = "B" } }, format_item = function(item) return item.label end },
  }
  tabs_view.set_context(function()
    if state_missing then
      return nil
    end
    return {
      ui = { language = "en" },
      progress = {
        stage_id = 1,
        stage_name = "Test Dungeon",
        distance = 0,
        stage_start = 0,
      },
    }
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
  assert_true(type(keymaps["<Tab>"]) == "function", "タブ移動キーが登録される")
  assert_true(type(keymaps["<S-Tab>"]) == "function", "逆方向のタブ移動キーが登録される")
  assert_true(type(keymaps["d"]) == "function", "詳細切り替えキーが登録される")
  local top_line_1 = rendered[2] or ""
  local top_line_2 = rendered[3] or ""
  assert_true(top_line_1 ~= "", "上部ゲーム表示の1行目が表示される")
  assert_true(top_line_2 ~= "", "上部ゲーム表示の2行目が表示される")
  assert_contains(top_line_1, "short", "更新後の上部1行目にライブ表示が残る")
  assert_contains(top_line_2, "HP 100", "更新後の上部2行目にライブ表示が残る")
  -- 上部のゲーム表示はメニュー幅の中央に来るよう、左余白が計算されることを確認する。
  assert_equal(leading_spaces(top_line_1), math.floor((second_width - #"short") / 2), "1行目が中央寄せされる")
  assert_equal(leading_spaces(top_line_2), math.floor((second_width - #"HP 100") / 2), "2行目が中央寄せされる")

  -- 詳細表示を切り替えた後でも、タブ移動で上部ゲーム表示が隠れないことを確認する。
  local before_switch_height = heights[#heights] or 0
  keymaps["d"]()
  local detail_open_height = heights[#heights] or 0
  assert_true(detail_open_height >= before_switch_height, "詳細表示を開いても高さが縮まない")
  keymaps["<Tab>"]()
  local switched_height = heights[#heights] or 0
  assert_true(switched_height >= detail_open_height, "タブ移動後も高さが縮まない")
  local switched_top_line_1 = rendered[2] or ""
  local switched_top_line_2 = rendered[3] or ""
  assert_contains(switched_top_line_1, "short", "タブ移動後も上部1行目が維持される")
  assert_contains(switched_top_line_2, "HP 100", "タブ移動後も上部2行目が維持される")

  -- 状態取得が一時的に欠落しても、直前の上部表示を維持して隠れないことを確認する。
  state_missing = true
  keymaps["<S-Tab>"]()
  local fallback_top_line_1 = rendered[2] or ""
  local fallback_top_line_2 = rendered[3] or ""
  assert_contains(fallback_top_line_1, "short", "状態欠落時も上部1行目の表示を保持する")
  assert_contains(fallback_top_line_2, "HP 100", "状態欠落時も上部2行目の表示を保持する")

  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
