-- このテストはメニュー本文の左クリックで行選択が切り替わることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered_lines = {}
  local maps = {}
  local mouse_pos = { winid = 0, line = 0, column = 0 }
  local selected_id = nil

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
      rendered_lines = lines or {}
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
        maps[lhs] = rhs
      end,
    },
    fn = {
      getmousepos = function()
        return mouse_pos
      end,
      strdisplaywidth = function(text)
        return #(text or "")
      end,
    },
  }

  local tabs_view = require("idle_dungeon.menu.tabs_view")
  local config = { ui = { language = "en", menu = { detail_preview = false, min_height = 16 } } }
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
        { id = "alpha", label = "ALPHA" },
        { id = "beta", label = "BETA" },
      },
      format_item = function(item)
        return item.label
      end,
      on_choice = function(item)
        selected_id = item and item.id or nil
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, config)

  local beta_line = nil
  for index, line in ipairs(rendered_lines or {}) do
    if string.find(line or "", "BETA", 1, true) then
      beta_line = index
      break
    end
  end
  assert_true(beta_line ~= nil, "本文にBETA行が描画される")
  assert_true(type(maps["<LeftMouse>"]) == "function", "左クリックのキーマップが設定される")
  assert_true(type(maps["<CR>"]) == "function", "Enterキーのキーマップが設定される")

  mouse_pos = { winid = 1, line = beta_line, column = 4 }
  maps["<LeftMouse>"]()
  maps["<CR>"]()

  assert_true(selected_id == "beta", "本文の左クリック後にEnterするとクリックした行が実行される")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
