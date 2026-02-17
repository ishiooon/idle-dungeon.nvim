-- このテストはサブメニューでも選択中項目の詳細とEnter説明がフッター上段に表示されることを確認する。

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
  local rendered_lines = {}
  local rendered_highlights = {}

  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function()
      return 1, 1
    end,
    update_window = function() end,
    set_lines = function(_, lines)
      rendered_lines = lines
    end,
    apply_highlights = function(_, highlights)
      rendered_highlights = highlights or {}
    end,
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
      set = function() end,
    },
    fn = {
      strdisplaywidth = function(text)
        return #(text or "")
      end,
    },
  }

  local menu_view = require("idle_dungeon.menu.view")
  menu_view.select({
    { id = "sample", label = "SAMPLE", keep_open = true },
  }, {
    lang = "en",
    footer_hints = { "FOOTER-HINT" },
    detail_provider = function()
      return {
        title = "Sample Detail",
        lines = {
          "DETAIL HEADER",
          "VALUE: 42",
        },
      }
    end,
    enter_hint_provider = function()
      return {
        "󰌑 Enter: Apply selected item",
        "󰇀 Keep this menu open",
      }
    end,
    format_item = function(item)
      return item.label
    end,
  }, function() end, { ui = { language = "en", menu = {} } })

  local footer_line = 0
  for index, line in ipairs(rendered_lines or {}) do
    if string.find(line or "", "FOOTER%-HINT", 1) then
      footer_line = index
      break
    end
  end
  assert_true(footer_line > 2, "サブメニューの最下部に基本操作フッターが描画される")
  local found_divider = false
  local found_detail_title = false
  local found_detail_header = false
  local found_detail_value = false
  local found_enter = false
  local found_hint = false
  for index, line in ipairs(rendered_lines or {}) do
    if index < footer_line and string.find(line or "", "─", 1, true) then
      found_divider = true
    end
    if index < footer_line and string.find(line or "", "Detail: Sample Detail", 1, true) then
      found_detail_title = true
    end
    if index < footer_line and string.find(line or "", "DETAIL HEADER", 1, true) then
      found_detail_header = true
    end
    if index < footer_line and string.find(line or "", "VALUE: 42", 1, true) then
      found_detail_value = true
    end
    if index < footer_line and string.find(line or "", "Enter: Apply selected item", 1, true) then
      found_enter = true
    end
    if index < footer_line and string.find(line or "", "Keep this menu open", 1, true) then
      found_hint = true
    end
  end
  assert_true(found_divider, "サブメニューでもフッター説明の手前に区切り線が表示される")
  assert_true(found_detail_title, "サブメニューでも詳細タイトルが下部に表示される")
  assert_true(found_detail_header, "サブメニューでも詳細本文が下部に表示される")
  assert_true(found_detail_value, "サブメニューでも詳細値が下部に表示される")
  assert_true(found_enter, "サブメニューでもEnter説明が表示される")
  assert_true(found_hint, "サブメニューでも補足説明が表示される")
  local has_hint_highlight = false
  for _, item in ipairs(rendered_highlights) do
    if type(item) == "table" and item.group == "IdleDungeonMenuHint" then
      has_hint_highlight = true
      break
    end
  end
  assert_true(has_hint_highlight, "サブメニューのEnter説明行に専用ハイライトが適用される")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
