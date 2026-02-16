-- このテストはメニュー上部ライブヘッダに右下表示と同じパレット色ハイライトが適用されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function find_group(items, group)
  for _, item in ipairs(items or {}) do
    if item and item.group == group then
      return item
    end
  end
  return nil
end

local function leading_spaces(text)
  local matched = (tostring(text or "")):match("^(%s*)") or ""
  return #matched
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered = {}
  local applied = {}

  package.loaded["idle_dungeon.menu.live_header"] = {
    build_lines = function()
      return { "ABC", "Moving through the dungeon." }
    end,
  }
  package.loaded["idle_dungeon.ui.sprite_highlight"] = {
    build = function()
      -- トラック上のB文字だけを色付けする想定の疑似データ。
      return {
        { line = 0, start_col = 1, end_col = 2, palette = "test_enemy" },
      }
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
    apply_highlights = function(_, items)
      applied = items or {}
    end,
    close_window = function() end,
    is_valid_window = function()
      return true
    end,
    is_valid_buffer = function()
      return true
    end,
    ensure_palette_highlights = function() end,
    palette_group_name = function(key)
      return "IdleDungeonMenuPalette_" .. tostring(key)
    end,
  }

  _G.vim = {
    o = { lines = 40, cmdheight = 1, columns = 120 },
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
      track_length = 12,
      sprite_palette = {
        test_enemy = { fg = "#ff0000" },
      },
      menu = { width = 60, min_width = 52, max_width = 68 },
    },
    floor_length = 12,
    stages = {
      { id = 1, name = "Highlight Test", start = 0, floors = 6 },
    },
  }
  tabs_view.set_context(function()
    return {
      ui = { language = "en" },
      progress = {
        stage_id = 1,
        stage_name = "Highlight Test",
        distance = 0,
        stage_start = 0,
      },
      actor = { id = "recorder", hp = 10, max_hp = 10, exp = 0, next_level = 10 },
    }
  end, config)
  tabs_view.select({
    {
      id = "status",
      label = "Status",
      items = {
        { id = "entry", label = "A" },
      },
      format_item = function(item)
        return item.label
      end,
    },
  }, {
    title = "Idle Dungeon",
    footer_hints = { "Enter", "q" },
  }, config)

  local colored = find_group(applied, "IdleDungeonMenuPalette_test_enemy")
  assert_true(colored ~= nil, "ライブヘッダのトラック行にパレット色ハイライトが追加される")
  assert_true(colored.line == 2, "ライブトラック1行目にハイライトが適用される")
  local track_line = rendered[2] or ""
  local expected_start = leading_spaces(track_line) + 1
  assert_true(colored.start_col == expected_start, "中央寄せ後の列位置に合わせてハイライト開始位置が補正される")
  assert_true(colored.end_col == expected_start + 1, "中央寄せ後の列位置に合わせてハイライト終了位置が補正される")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
