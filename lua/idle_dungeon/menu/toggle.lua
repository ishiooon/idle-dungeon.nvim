-- このモジュールはメニュー開閉の状態遷移を行う純粋関数を提供する。

local M = {}

local function toggle_open(is_open)
  return not (is_open == true)
end

M.toggle_open = toggle_open

return M
