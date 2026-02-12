-- このテストはサブメニューで2カラム指定した場合のみ右カラム詳細が表示されることを確認する。

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
    { id = "first", label = "TOP_SUB_ENTRY" },
    { id = "second", label = "BOTTOM_SUB_ENTRY" },
  }, {
    lang = "en",
    footer_hints = { "Enter", "q" },
    detail_layout = "split",
    format_item = function(item)
      return item.label
    end,
    detail_provider = function(item)
      return {
        title = item.label or "",
        lines = {
          "DETAIL TOP",
          "LEVEL UP GROWTH",
        },
      }
    end,
  }, function() end, { ui = { language = "en", menu = {} } })

  local joined = table.concat(rendered_lines or {}, "\n")
  assert_contains(joined, " │ ", "2カラム指定時は左右ペインの区切りを表示する")
  assert_contains(joined, "DETAIL TOP", "2カラム指定時は右ペイン詳細が表示される")
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
