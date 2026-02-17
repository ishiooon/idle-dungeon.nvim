-- このテストはサブメニューが1カラム表示を維持し、詳細は明示操作で下部表示することを確認する。

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

local function assert_not_contains(text, needle, message)
  if string.find(text or "", needle or "", 1, true) then
    error((message or "assert_not_contains failed") .. ": " .. tostring(text) .. " =~ " .. tostring(needle))
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered_lines = {}
  local keymaps = {}

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

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.select({
    { id = "first", label = "TOP_SUB_ENTRY" },
    { id = "second", label = "BOTTOM_SUB_ENTRY" },
  }, {
    lang = "en",
    footer_hints = { "Enter", "q" },
    format_item = function(item)
      return item.label
    end,
    detail_provider = function(item)
      return {
        title = item.label or "",
        lines = {
          "DETAIL TOP",
          "CHANGE: ATK +2",
          "CHANGE: DEF +1",
        },
      }
    end,
  }, function() end, { ui = { language = "en", menu = {} } })

  local joined = table.concat(rendered_lines or {}, "\n")
  assert_not_contains(joined, " │ ", "サブメニューで左右ペインの区切りを表示しない")
  assert_not_contains(joined, "Detail: TOP_SUB_ENTRY", "詳細は初期状態で下部へ表示しない")
  assert_true(type(keymaps["d"]) == "function", "詳細表示を切り替えるdキーが登録される")
  keymaps["d"]()
  local detail_joined = table.concat(rendered_lines or {}, "\n")
  assert_contains(detail_joined, "Detail: TOP_SUB_ENTRY", "dキーで詳細タイトルを下部へ表示する")
  assert_contains(detail_joined, "DETAIL TOP", "dキーで詳細本文を下部へ表示する")
  assert_contains(detail_joined, "CHANGE: ATK +2", "dキーで詳細値を下部へ表示する")
  assert_contains(joined, "↩", "戻る項目の記号が表示される")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
