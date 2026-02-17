-- このテストはメインタブが1カラム表示を維持し、詳細は明示操作で表示することを確認する。

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
  local rendered = {}
  local keymaps = {}

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
      set = function(_, lhs, rhs)
        keymaps[lhs] = rhs
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
  assert_not_contains(text, " │ ", "メインタブに左右ペインの区切りを表示しない")
  assert_not_contains(text, "Detail: TOP", "詳細は初期状態で下部へ表示しない")
  assert_true(type(keymaps["d"]) == "function", "詳細表示を切り替えるdキーが登録される")
  keymaps["d"]()
  local detail_text = table.concat(rendered or {}, "\n")
  assert_contains(detail_text, "Detail: TOP", "dキーで詳細タイトルを下部へ表示する")
  assert_contains(detail_text, "DETAIL HEADER", "dキーで詳細本文を下部へ表示する")
  assert_contains(detail_text, "VALUE: 42", "dキーで詳細値を下部へ表示する")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
