-- このテストは詳細プレビューが存在してもEnterで項目実行を優先することを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local maps = {}
  local action_called = 0
  local detail_opened = 0

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
    set_lines = function() end,
    apply_highlights = function() end,
    close_window = function() end,
    is_valid_window = function()
      return true
    end,
    is_valid_buffer = function()
      return true
    end,
  }
  package.loaded["idle_dungeon.menu.view"] = {
    select = function()
      -- 詳細画面が開かれた回数を記録する。
      detail_opened = detail_opened + 1
    end,
    close = function() end,
    set_context = function() end,
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
      id = "actions",
      label = "Actions",
      items = {
        { id = "first", label = "FIRST", keep_open = true },
      },
      format_item = function(item)
        return item.label
      end,
      detail_provider = function(item)
        return {
          title = item.label or "",
          lines = { "DETAIL" },
        }
      end,
      on_choice = function()
        -- Enter時に項目実行が呼ばれる回数を記録する。
        action_called = action_called + 1
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, config)

  assert_true(type(maps["<CR>"]) == "function", "Enterキーのマッピングが設定される")
  maps["<CR>"]()
  assert_true(action_called == 1, "Enterで詳細画面より先に項目実行が呼ばれる")
  assert_true(detail_opened == 0, "Enterでは不要な詳細画面を開かない")

  assert_true(type(maps["o"]) == "function", "詳細表示キーoのマッピングが設定される")
  maps["o"]()
  assert_true(detail_opened == 1, "oキーでは明示的に詳細画面を開ける")

  tabs_view.close(true)
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
