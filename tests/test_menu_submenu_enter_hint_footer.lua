-- このテストはサブメニューでも選択中項目のEnter説明がフッター上段に表示されることを確認する。

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
  assert_contains(rendered_lines[footer_line - 3] or "", "─", "サブメニューでもフッター説明の手前に区切り線が表示される")
  assert_contains(rendered_lines[footer_line - 2] or "", "Enter: Apply selected item", "サブメニューでもEnter説明が表示される")
  assert_contains(rendered_lines[footer_line - 1] or "", "Keep this menu open", "サブメニューでも補足説明が表示される")
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
