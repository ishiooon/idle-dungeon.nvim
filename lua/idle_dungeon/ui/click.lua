-- このモジュールは右下表示のクリック判定を純粋関数で提供する。

local M = {}

local function is_click_on_ui(mousepos, winid)
  if not mousepos or not winid then
    return false
  end
  local target = tonumber(mousepos.winid or 0) or 0
  if target <= 0 then
    return false
  end
  return target == winid
end

M.is_click_on_ui = is_click_on_ui

return M
