-- このモジュールはメニュータブの文字列生成と切り替え計算を提供する純粋関数をまとめる。

local util = require("idle_dungeon.util")

local M = {}

-- タブ表示の既定スタイルを定義して統一感を保つ。
local DEFAULT_STYLE = {
  separator = " 󰇙 ",
  active_prefix = "󰐊",
  active_suffix = "",
  show_index = false,
  icons = {},
}

local function resolve_label(tab, index)
  if type(tab) == "table" then
    return tab.label or tab.id or tostring(index)
  end
  return tostring(tab)
end

local function resolve_style(style)
  local merged = {}
  for key, value in pairs(DEFAULT_STYLE) do
    merged[key] = value
  end
  for key, value in pairs(style or {}) do
    merged[key] = value
  end
  return merged
end

local function build_tab_label(tab, index, style, is_active)
  local label = resolve_label(tab, index)
  local icon = ""
  if type(tab) == "table" and tab.id and style.icons and style.icons[tab.id] then
    icon = style.icons[tab.id]
  end
  local parts = {}
  if style.show_index then
    table.insert(parts, tostring(index))
  end
  if icon ~= "" then
    table.insert(parts, icon)
  end
  table.insert(parts, label)
  local joined = table.concat(parts, " ")
  if is_active then
    if style.active_prefix ~= "" and style.active_suffix ~= "" then
      return string.format("%s %s %s", style.active_prefix, joined, style.active_suffix)
    end
    if style.active_prefix ~= "" then
      return string.format("%s %s", style.active_prefix, joined)
    end
    if style.active_suffix ~= "" then
      return string.format("%s %s", joined, style.active_suffix)
    end
    return joined
  end
  return joined
end

local function build_tabs_line(tabs, active_index, style)
  local resolved = resolve_style(style)
  local labels = {}
  for index, tab in ipairs(tabs or {}) do
    local label = build_tab_label(tab, index, resolved, index == active_index)
    table.insert(labels, label)
  end
  return table.concat(labels, resolved.separator or " ")
end

-- タブ文字列の各タブ位置を列情報として返す。
local function build_tabs_segments(tabs, active_index, style)
  local resolved = resolve_style(style)
  local segments = {}
  local cursor = 0
  local separator = resolved.separator or " "
  local sep_width = util.display_width(separator)
  for index, tab in ipairs(tabs or {}) do
    local label = build_tab_label(tab, index, resolved, index == active_index)
    local width = util.display_width(label)
    table.insert(segments, { index = index, start_col = cursor + 1, end_col = cursor + width })
    cursor = cursor + width + sep_width
  end
  return segments
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
M.build_tabs_segments = build_tabs_segments
M.shift_index = shift_index

return M
