-- このモジュールはtriforce風の2ペインメニュー枠を純粋関数で組み立てる。

local util = require("idle_dungeon.util")

local M = {}

-- フッターの案内文は1行へ集約して視認性を上げる。
local function join_hints(hints)
  if not hints or #hints == 0 then
    return ""
  end
  return table.concat(hints, "  •  ")
end

-- 左右ペインの幅を画面幅から計算する。
local function resolve_panel_width(width)
  local inner = math.max(width - 2, 10)
  local left = math.max(math.floor(inner * 0.45), 28)
  local right = inner - left - 3
  if right < 24 then
    right = 24
    left = math.max(inner - right - 3, 20)
  end
  return left, right
end

-- 文字列を固定幅に切り詰めて右側を空白で埋める。
local function fixed_text(text, width)
  local clamped = util.clamp_line(text or "", width)
  local gap = math.max(width - util.display_width(clamped), 0)
  return clamped .. string.rep(" ", gap)
end

-- タイトル、タブ、下部案内を除いた本文行数を返す。
local function resolve_content_height(opts)
  local height = math.max(tonumber(opts.height) or 1, 1)
  local has_tabs = type(opts.tabs_line) == "string" and opts.tabs_line ~= ""
  -- 上枠/タイトル/タブ/分割線/下分割線/フッター/下枠
  local fixed = 6 + (has_tabs and 1 or 0)
  return math.max(height - fixed, 1)
end

-- ヘッダー行を組み立てる。
local function build_header(lines, width, title, tabs_line)
  local inner = math.max(width - 2, 1)
  table.insert(lines, "╭" .. string.rep("─", inner) .. "╮")
  table.insert(lines, "│" .. fixed_text(" " .. (title or ""), inner) .. "│")
  local tabs_line_index = nil
  if tabs_line and tabs_line ~= "" then
    table.insert(lines, "│" .. fixed_text(" " .. tabs_line, inner) .. "│")
    tabs_line_index = #lines
  end
  return tabs_line_index
end

-- 本文行を左右ペイン形式で組み立てる。
local function build_body(lines, body_height, left_width, right_width, left_lines, right_lines)
  table.insert(lines, "├" .. string.rep("─", left_width + 1) .. "┬" .. string.rep("─", right_width + 1) .. "┤")
  local body_start = #lines + 1
  for index = 1, body_height do
    local left = fixed_text(left_lines[index] or "", left_width)
    local right = fixed_text(right_lines[index] or "", right_width)
    table.insert(lines, "│ " .. left .. " │ " .. right .. " │")
  end
  return body_start
end

-- フッター行を組み立てる。
local function build_footer(lines, width, hint_text)
  local inner = math.max(width - 2, 1)
  table.insert(lines, "├" .. string.rep("─", inner) .. "┤")
  table.insert(lines, "│" .. fixed_text(" " .. hint_text, inner) .. "│")
  table.insert(lines, "╰" .. string.rep("─", inner) .. "╯")
end

-- 共通フレームの全行を組み立てる。
local function compose(opts)
  local width = math.max(tonumber(opts.width) or 84, 60)
  local height = math.max(tonumber(opts.height) or 20, 12)
  local tabs_line = opts.tabs_line or ""
  local title = opts.title or ""
  local body_height = resolve_content_height({ height = height, tabs_line = tabs_line })
  local left_width, right_width = resolve_panel_width(width)
  local left_lines = opts.left_lines or {}
  local right_lines = opts.right_lines or {}
  local hint_text = join_hints(opts.footer_hints or {})
  local lines = {}
  local tabs_line_index = build_header(lines, width, title, tabs_line)
  local body_start = build_body(lines, body_height, left_width, right_width, left_lines, right_lines)
  build_footer(lines, width, hint_text)
  while #lines < height do
    table.insert(lines, "")
  end
  if #lines > height then
    local trimmed = {}
    for index = 1, height do
      trimmed[index] = lines[index]
    end
    lines = trimmed
  end
  return {
    lines = lines,
    title_line_index = 2,
    tabs_line_index = tabs_line_index,
    body_start = body_start,
    left_col = 3,
    left_width = left_width,
    right_col = left_width + 6,
    right_width = right_width,
    footer_hint_line = #lines - 1,
  }
end

M.compose = compose
M.resolve_content_height = resolve_content_height
M.resolve_panel_width = resolve_panel_width

return M
