-- このテストはメニュー表示中にカーソル表示を隠し、終了時に元へ戻すことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local guicursor_value = "n-v-c:block"
  local win_valid = {}
  local opened = nil
  local win_options = {}

  _G.vim = {
    o = { lines = 40, columns = 120, cmdheight = 1 },
    api = {
      nvim_create_namespace = function()
        return 1
      end,
      nvim_set_hl = function() end,
      nvim_create_buf = function()
        return 1
      end,
      nvim_set_option_value = function(name, value, opts)
        if name == "guicursor" and (not opts or opts.win == nil) then
          guicursor_value = value
          return
        end
        if opts and opts.win ~= nil then
          win_options[name] = value
        end
      end,
      nvim_get_option_value = function(name)
        if name == "guicursor" then
          return guicursor_value
        end
        return nil
      end,
      nvim_open_win = function()
        opened = 11
        win_valid[opened] = true
        return opened
      end,
      nvim_win_is_valid = function(win)
        return win_valid[win] == true
      end,
      nvim_buf_is_valid = function()
        return true
      end,
      nvim_win_close = function(win)
        win_valid[win] = false
      end,
      nvim_set_current_win = function() end,
    },
  }

  local window = require("idle_dungeon.menu.window")
  local win = nil
  local buf = nil
  win, buf = window.ensure_window(win, buf, 18, 80, "none", { background = "#202324" })
  assert_true(type(win) == "number", "ウィンドウが生成される")
  assert_true(type(buf) == "number", "バッファが生成される")
  assert_true(guicursor_value == "a:IdleDungeonMenuHiddenCursor", "メニュー表示中はカーソルを隠す")
  assert_true(win_options.scrolloff == 0, "メニューウィンドウは上部が隠れないようscrolloffを0に固定する")
  assert_true(win_options.sidescrolloff == 0, "メニューウィンドウは横スクロール余白を0に固定する")

  window.close_window(win, nil)
  assert_true(guicursor_value == "n-v-c:block", "メニュー終了時にカーソル設定を復元する")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
