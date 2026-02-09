-- このテストは右下表示のcloseでステージイントロ表示も閉じることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local calls = { stage_intro_close = 0 }

  package.loaded["idle_dungeon.ui.click"] = {
    is_click_on_ui = function()
      return false
    end,
  }
  package.loaded["idle_dungeon.ui.render"] = {
    build_lines = function()
      return { "" }
    end,
  }
  package.loaded["idle_dungeon.ui.sprite_highlight"] = {
    build = function()
      return {}
    end,
    apply = function() end,
  }
  package.loaded["idle_dungeon.ui.stage_intro"] = {
    render = function() end,
    close = function()
      calls.stage_intro_close = calls.stage_intro_close + 1
    end,
  }

  _G.vim = {
    api = {
      nvim_create_namespace = function()
        return 1
      end,
      nvim_win_is_valid = function()
        return false
      end,
      nvim_buf_is_valid = function()
        return false
      end,
      nvim_win_close = function() end,
    },
  }

  local ui = require("idle_dungeon.ui")
  ui.close()
  assert_true(calls.stage_intro_close == 1, "右下表示クローズ時にステージイントロも閉じる")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
