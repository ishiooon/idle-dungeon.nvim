-- このテストはアクティブタブの強調で背景色を使わないことを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local original_vim = _G.vim
local ok, err = pcall(function()
  local applied = {}
  _G.vim = {
    o = { lines = 40, columns = 120, cmdheight = 1 },
    api = {
      nvim_create_namespace = function()
        return 1
      end,
      nvim_set_hl = function(_, group, spec)
        applied[group] = spec
      end,
      nvim_create_buf = function()
        return 1
      end,
      nvim_set_option_value = function() end,
      nvim_open_win = function()
        return 1
      end,
      nvim_win_is_valid = function()
        return false
      end,
      nvim_buf_is_valid = function()
        return false
      end,
    },
  }

  local window = require("idle_dungeon.menu.window")
  window.ensure_window(nil, nil, 20, 80, "none", {
    inherit = false,
    accent = "#7daea3",
    text = "#e2cca9",
    muted = "#928374",
    border = "#3c3836",
    divider = "#504945",
    background = "#202324",
    selected_bg = "#32363a",
    selected_bg_alt = "#40464b",
    selected_fg = "#f5e6c8",
  })

  local tab_active = applied["IdleDungeonMenuTabActive"] or {}
  assert_true(tab_active.bg == nil, "アクティブタブの背景色は未設定である")
  assert_true(tab_active.fg == "#e2cca9", "アクティブタブの文字色は通常文字色と一致する")
  local selected = applied["IdleDungeonMenuSelected"] or {}
  assert_true(selected.bg == nil, "選択記号の背景色は未設定である")
  local selected_pulse = applied["IdleDungeonMenuSelectedPulse"] or {}
  assert_true(selected_pulse.bg == nil, "選択アニメーションの背景色は未設定である")
  local cursor_group = applied["IdleDungeonMenuCursor"] or {}
  assert_true(cursor_group.bg == "NONE", "カーソル表示用ハイライトの背景色はNONEである")
  local hidden_cursor_group = applied["IdleDungeonMenuHiddenCursor"] or {}
  assert_true(hidden_cursor_group.bg == "NONE", "隠しカーソル用ハイライトの背景色はNONEである")
end)

_G.vim = original_vim

if not ok then
  error(err)
end

print("OK")
