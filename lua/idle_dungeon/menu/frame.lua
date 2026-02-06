-- このモジュールはメニュー表示の最小構成レイアウトを組み立てる純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

local function join_hints(hints)
  if not hints or #hints == 0 then
    return ""
  end
  return table.concat(hints, "   ")
end

local function fixed_text(text, width)
  local safe_width = math.max(tonumber(width) or 0, 0)
  local safe_text = text or ""
  local clamped = util.clamp_line(safe_text, safe_width)
  -- 収まらない文字列は末尾に省略記号を付けて可読性を保つ。
  if util.display_width(safe_text) > safe_width and safe_width >= 4 then
    local core = util.clamp_line(safe_text, safe_width - 3)
    clamped = core .. "..."
  end
  local gap = math.max(width - util.display_width(clamped), 0)
  return clamped .. string.rep(" ", gap)
end

local function resolve_panel_width(width)
  -- 本文は「left │ right」の1本区切りで組み立てる。
  local usable = math.max(width - 3, 20)
  local left = math.max(math.floor(usable * 0.5), 24)
  local right = usable - left
  if right < 20 then
    right = 20
    left = math.max(usable - right, 16)
  end
  return left, right
end

local function resolve_single_width(width)
  return math.max(width, 20)
end

local function resolve_content_height(opts)
  local height = math.max(tonumber(opts.height) or 1, 1)
  local has_tabs = type(opts.tabs_line) == "string" and opts.tabs_line ~= ""
  local top_count = type(opts.top_lines) == "table" and #opts.top_lines or 0
  -- title/top/tabs/divider/footer を除いた本文高さを返す。
  local fixed = 3 + top_count + (has_tabs and 1 or 0)
  return math.max(height - fixed, 1)
end

local function trim_lines(lines, height)
  if #lines == height then
    return lines
  end
  local result = {}
  for index = 1, math.min(#lines, height) do
    result[index] = lines[index]
  end
  while #result < height do
    table.insert(result, "")
  end
  return result
end

local function compose(opts)
  local width = math.max(tonumber(opts.width) or 96, 72)
  local height = math.max(tonumber(opts.height) or 30, 16)
  local title = opts.title or "Idle Dungeon"
  local top_lines = opts.top_lines or {}
  local tabs_line = opts.tabs_line or ""
  local show_right = opts.show_right ~= false
  local left_width, right_width = resolve_panel_width(width)
  if not show_right then
    left_width = resolve_single_width(width)
    right_width = 0
  end
  local body_height = resolve_content_height({ height = height, tabs_line = tabs_line, top_lines = top_lines })
  local lines = {}
  table.insert(lines, fixed_text(title, width))
  for _, line in ipairs(top_lines) do
    table.insert(lines, fixed_text(line, width))
  end
  local tabs_line_index = nil
  if tabs_line ~= "" then
    table.insert(lines, fixed_text(tabs_line, width))
    tabs_line_index = #lines
  end
  table.insert(lines, fixed_text(string.rep("─", width), width))
  local body_start = #lines + 1
  for index = 1, body_height do
    local left = fixed_text((opts.left_lines or {})[index] or "", left_width)
    if show_right then
      local right = fixed_text((opts.right_lines or {})[index] or "", right_width)
      table.insert(lines, fixed_text(left .. " │ " .. right, width))
    else
      table.insert(lines, fixed_text(left, width))
    end
  end
  local footer_hint_line = #lines + 1
  table.insert(lines, fixed_text(join_hints(opts.footer_hints or {}), width))
  local normalized = trim_lines(lines, height)
  return {
    lines = normalized,
    title_line_index = 1,
    tabs_line_index = tabs_line_index,
    body_start = body_start,
    left_col = 1,
    left_width = left_width,
    right_col = show_right and (left_width + 4) or 1,
    right_width = right_width,
    footer_hint_line = math.min(footer_hint_line, #normalized),
  }
end

M.compose = compose
M.resolve_content_height = resolve_content_height
M.resolve_panel_width = resolve_panel_width

return M
