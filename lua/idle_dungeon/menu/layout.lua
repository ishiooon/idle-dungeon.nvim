-- このモジュールはメニュー表示用の行とレイアウト情報を生成する純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

local function build_labels(items, format_item)
  local labels = {}
  for _, item in ipairs(items or {}) do
    local label = format_item and format_item(item) or tostring(item)
    table.insert(labels, label)
  end
  return labels
end

local function normalize_offset(offset, total, visible)
  local safe_total = math.max(total or 0, 0)
  local safe_visible = math.max(visible or safe_total, 0)
  if safe_total <= safe_visible then
    return 0
  end
  local max_offset = math.max(safe_total - safe_visible, 0)
  local current = math.max(offset or 0, 0)
  return math.min(current, max_offset)
end

local function slice_labels(labels, offset, count)
  local result = {}
  local start = math.max(offset or 0, 0)
  local max_count = math.max(count or #labels, 0)
  for index = 1, max_count do
    local label = labels[start + index]
    if label == nil then
      break
    end
    table.insert(result, label)
  end
  return result
end

local function build_lines(title, labels, options)
  local opts = options or {}
  local padding = math.max(opts.padding or 1, 0)
  local pad = string.rep(" ", padding)
  local max_items = math.max(opts.max_items or #labels, 0)
  local offset = normalize_offset(opts.offset or 0, #labels, max_items)
  local lines = {}
  if title and title ~= "" then
    table.insert(lines, pad .. title)
  end
  local items_start = #lines + 1
  local view_labels = slice_labels(labels, offset, max_items)
  for _, label in ipairs(view_labels) do
    table.insert(lines, pad .. label)
  end
  local items_count = #view_labels
  local width = 0
  -- 表示幅はマルチバイト文字も考慮して計算する。
  for index, line in ipairs(lines) do
    local clamped = util.clamp_line(line, opts.max_width)
    lines[index] = clamped
    width = math.max(width, util.display_width(clamped))
  end
  return {
    lines = lines,
    items_start = items_start,
    items_count = items_count,
    width = math.max(width, 1),
    offset = offset,
    total = #labels,
  }
end

M.build_labels = build_labels
M.normalize_offset = normalize_offset
M.build_lines = build_lines

return M
