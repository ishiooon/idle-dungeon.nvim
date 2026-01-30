-- このモジュールはメニュータブの文字列生成と切り替え計算を提供する純粋関数をまとめる。

local M = {}

local function resolve_label(tab, index)
  if type(tab) == "table" then
    return tab.label or tab.id or tostring(index)
  end
  return tostring(tab)
end

local function build_tabs_line(tabs, active_index)
  local labels = {}
  for index, tab in ipairs(tabs or {}) do
    local label = resolve_label(tab, index)
    if index == active_index then
      label = string.format("[%s]", label)
    end
    table.insert(labels, label)
  end
  return table.concat(labels, " | ")
end

local function shift_index(current, delta, total)
  local count = math.max(total or 0, 0)
  if count <= 0 then
    return 0
  end
  local start = math.max(current or 1, 1)
  local shift = delta or 0
  local next_index = ((start - 1 + shift) % count) + 1
  return next_index
end

M.build_tabs_line = build_tabs_line
M.shift_index = shift_index

return M
