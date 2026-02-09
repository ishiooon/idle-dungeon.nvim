-- このテストは詳細画面を静的カード表示として描画できることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function text_width(text)
  local safe = tostring(text or "")
  if _G.vim and vim.fn and vim.fn.strdisplaywidth then
    return vim.fn.strdisplaywidth(safe)
  end
  local count = 0
  for _ in safe:gmatch("[\1-\127\194-\244][\128-\191]*") do
    count = count + 1
  end
  return count
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local ensure_opts = nil
  local ensure_height = nil
  local ensure_width = nil
  local rendered_lines = nil

  package.loaded["idle_dungeon.menu.window"] = {
    ensure_window = function(_, _, height, width, _, _, opts)
      ensure_height = height
      ensure_width = width
      ensure_opts = opts
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
  local detail_lines = {
    "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓",
    "┃ENEMY DEX                     ┃",
    "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫",
    "┃Battle Data                   ┃",
    "┃HP  [▰▰▱▱▱▱] 12              ┃",
    "┃ATK [▰▰▰▱▱▱] 8               ┃",
    "┃DEF [▰▰▱▱▱▱] 6               ┃",
    "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫",
    "┃Drops                         ┃",
    "┃◉ short_bow                   ┃",
    "┃◌ ???                         ┃",
    "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫",
    "┃Flavor                        ┃",
    "┃A calm glider in frozen halls.┃",
    "┃A calm glider in frozen halls.┃",
    "┃A calm glider in frozen halls.┃",
    "┃A calm glider in frozen halls.┃",
    "┃A calm glider in frozen halls.┃",
    "┃A calm glider in frozen halls.┃",
    "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛",
  }
  menu_view.select(detail_lines, {
    lang = "en",
    add_back_item = false,
    static_view = true,
    item_prefix = "",
    non_select_prefix = "",
    wrap_lines = false,
    prompt = "Detail",
  }, function() end, { ui = { language = "en", menu = {} } })

  assert_true(type(ensure_opts) == "table", "ウィンドウ生成にオプションが渡る")
  assert_true(ensure_opts.wrap_lines == false, "静的詳細画面では折り返しを無効にする")
  local joined = table.concat(rendered_lines or {}, "\n")
  local first_line = (rendered_lines or {})[1] or ""
  assert_true(first_line:find("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓", 1, true) == 1, "静的詳細画面は先頭行からカードを描画する")
  assert_true((tonumber(ensure_width) or 0) == text_width(first_line), "静的詳細画面の幅はカード実幅に一致する")
  assert_true(joined:find("Sub Menu", 1, true) == nil, "静的詳細画面ではSub Menuを表示しない")
  assert_true(joined:find("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓", 1, true) ~= nil, "カード上枠が描画される")
  assert_true(joined:find("󰜴", 1, true) == nil, "静的詳細画面では選択記号を描画しない")
  assert_true((tonumber(ensure_height) or 0) >= 22, "静的詳細画面は十分な高さでウィンドウを確保する")
  assert_true(#(rendered_lines or {}) >= 22, "静的詳細画面は縦幅を十分に確保して表示する")
  for _, line in ipairs(rendered_lines or {}) do
    assert_true(text_width(line or "") <= (tonumber(ensure_width) or 0), "描画行がウィンドウ幅を超えない")
  end
  menu_view.close()
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
