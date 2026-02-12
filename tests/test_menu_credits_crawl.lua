-- このテストはクレジット表示が下から上へ流れ、中央寄せで描画されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_equals(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_equals failed") .. ": actual=" .. tostring(actual) .. ", expected=" .. tostring(expected))
  end
end

local function assert_not_equals(actual, expected, message)
  if actual == expected then
    error((message or "assert_not_equals failed") .. ": both=" .. tostring(actual))
  end
end

local function leading_spaces(text)
  local matched = (tostring(text or "")):match("^(%s*)") or ""
  return #matched
end

local function find_line(lines, token)
  for index, line in ipairs(lines or {}) do
    if tostring(line or ""):find(token, 1, true) then
      return index, line
    end
  end
  return nil, ""
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local rendered = {}
  local last_width = 0
  -- 総プレイ時間が大きい状態で開いても、クレジット演出が先頭から始まることを検証する。
  local now_sec = 3600
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
    update_window = function(_, _, width)
      last_width = width
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
  local tabs = {
    {
      id = "credits",
      label = "Credits",
      items = {
        { id = "art", label = "CREDITS" },
        { id = "entry", label = "CASTLE OF CODE" },
        { id = "entry", label = "CREATED BY IDLEDUNGEON TEAM" },
        { id = "entry", label = "BATTLE DESIGN UNIT" },
        { id = "entry", label = "SYSTEM ENGINEERING CREW" },
        { id = "entry", label = "UI DIRECTION TEAM" },
        { id = "entry", label = "QA AND LOCALIZATION" },
        { id = "entry", label = "SPECIAL THANKS 01" },
        { id = "entry", label = "SPECIAL THANKS 02" },
        { id = "entry", label = "SPECIAL THANKS 03" },
        { id = "entry", label = "SPECIAL THANKS 04" },
        { id = "entry", label = "SPECIAL THANKS 05" },
        { id = "entry", label = "SPECIAL THANKS 06" },
        { id = "entry", label = "SPECIAL THANKS 07" },
        { id = "entry", label = "SPECIAL THANKS 08" },
        { id = "entry", label = "SPECIAL THANKS 09" },
        { id = "entry", label = "SPECIAL THANKS 10" },
        { id = "entry", label = "SPECIAL THANKS 11" },
        { id = "entry", label = "SPECIAL THANKS 12" },
        { id = "entry", label = "THANKS FOR PLAYING" },
      },
      format_item = function(item)
        return item.label
      end,
    },
  }
  local config = {
    ui = {
      language = "en",
      menu = { width = 60, min_width = 52, max_width = 68 },
    },
  }
  tabs_view.set_context(function()
    return {
      ui = { language = "en" },
      progress = { distance = 0 },
      metrics = { time_sec = now_sec },
    }
  end, config)
  tabs_view.select(tabs, {
    active_id = "credits",
    title = "Idle Dungeon",
    footer_hints = { "q" },
  }, config)

  local row1, line1 = find_line(rendered, "CREDITS")
  assert_true(row1 ~= nil, "クレジット行が表示される")
  assert_true(last_width > 0, "メニュー幅が取得できる")
  local expected_pad = math.floor((last_width - #"CREDITS") / 2)
  assert_true(leading_spaces(line1) == expected_pad, "クレジット行が中央寄せされる")

  now_sec = now_sec + 1.2
  tabs_view.update(tabs)
  local row2 = find_line(rendered, "CREDITS")
  assert_true(row2 ~= nil, "更新後もクレジット行が表示される")
  assert_true(row2 < row1, "時間経過でクレジット行が下から上へ流れる")

  -- 十分な時間が経過した後は終端で停止し、ループ再生しないことを確認する。
  now_sec = now_sec + 999
  tabs_view.update(tabs)
  local stopped = table.concat(rendered, "\n")
  now_sec = now_sec + 8
  tabs_view.update(tabs)
  local stopped_again = table.concat(rendered, "\n")
  assert_equals(stopped_again, stopped, "終端到達後はクレジット表示がループしない")

  -- 停止後は入力しても表示が変化しないことを確認する。
  assert_true(type(keymaps.k) == "function", "上入力の操作が登録される")
  keymaps.k()
  local after_key = table.concat(rendered, "\n")
  assert_equals(after_key, stopped, "終端到達後は上入力しても表示を固定する")
  tabs_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
