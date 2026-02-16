-- このテストはメインメニューで選択中項目のEnter説明がフッター上段に表示されることを確認する。

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

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return { "TRACK", "HP 10" }
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
    apply_highlights = function(_, highlights)
      rendered_highlights = highlights or {}
    end,
    close_window = function() end,
    is_valid_window = function()
      return false
    end,
    is_valid_buffer = function()
      return false
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
  local config = { ui = { language = "en", menu = { min_height = 16 } } }
  tabs_view.set_context(function()
    return { ui = { language = "en" } }
  end, config)
  tabs_view.select({
    {
      id = "config",
      label = "Config",
      items = {
        { id = "toggle_text", label = "Text Mode: [ ON ]", keep_open = true },
      },
      format_item = function(item)
        return item.label
      end,
      enter_hint_provider = function()
        return {
          "󰌑 Enter: Toggle text mode",
          "󰇀 Text -> Visual",
        }
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "FOOTER-HINT" },
  }, config)

  local footer_line = 0
  for index, line in ipairs(rendered_lines or {}) do
    if string.find(line or "", "FOOTER%-HINT", 1) then
      footer_line = index
      break
    end
  end
  assert_true(footer_line > 2, "最下部に基本操作のフッターが描画される")
  assert_contains(rendered_lines[footer_line - 3] or "", "─", "フッター説明の手前に区切り線が表示される")
  assert_contains(rendered_lines[footer_line - 2] or "", "Enter: Toggle text mode", "フッターの上段にEnter説明が表示される")
  assert_contains(rendered_lines[footer_line - 1] or "", "Text -> Visual", "フッター直上に変更内容が表示される")
  local has_hint_highlight = false
  for _, item in ipairs(rendered_highlights) do
    if type(item) == "table" and item.group == "IdleDungeonMenuHint" then
      has_hint_highlight = true
      break
    end
  end
  assert_true(has_hint_highlight, "Enter説明行には専用ハイライトが適用される")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
