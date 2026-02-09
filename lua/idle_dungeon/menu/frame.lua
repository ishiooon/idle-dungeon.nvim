-- このモジュールはメニュー表示の最小構成レイアウトを組み立てる純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

local function build_hint_line(hints, width)
  local safe_width = math.max(tonumber(width) or 0, 0)
  if safe_width == 0 then
    return ""
  end
  local tokens = hints or {}
  local line = ""
  for _, token in ipairs(tokens) do
    local safe_token = tostring(token or "")
    local candidate = line == "" and safe_token or (line .. "   " .. safe_token)
    if util.display_width(candidate) <= safe_width then
      line = candidate
    else
      break
    end
  end
  if line == "" and tokens[1] then
    line = util.clamp_line(tostring(tokens[1]), safe_width)
  end
  -- Nerd Fontの幅差で溢れにくいよう、少しだけ余白を残して丸める。
  local safety_margin = math.min(#tokens, 3)
  local clamped_width = math.max(safe_width - safety_margin, 0)
  return util.clamp_line(line, clamped_width)
end

local function fixed_text(text, width)
  local safe_width = math.max(tonumber(width) or 0, 0)
  local safe_text = text or ""
  -- 収まらない文字列は切り詰めず、ウィンドウ側の折り返し表示に委ねる。
  if util.display_width(safe_text) >= safe_width then
    return safe_text
  end
  local gap = math.max(safe_width - util.display_width(safe_text), 0)
  return safe_text .. string.rep(" ", gap)
end

local function fixed_hint_text(text, width)
  local safe_width = math.max(tonumber(width) or 0, 0)
  local clamped = util.clamp_line(text or "", safe_width)
  local gap = math.max(safe_width - util.display_width(clamped), 0)
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
  local hide_title = opts.hide_title == true
  local hide_divider = opts.hide_divider == true
  local top_gap = (top_count > 0 and has_tabs) and 1 or 0
  -- title/top/tabs/divider/footer を除いた本文高さを返す。
  local fixed = 1 + top_count + top_gap + (has_tabs and 1 or 0) + (hide_title and 0 or 1) + (hide_divider and 0 or 1)
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
  local hide_title = opts.hide_title == true
  local hide_divider = opts.hide_divider == true
  local body_height = resolve_content_height({
    height = height,
    tabs_line = tabs_line,
    top_lines = top_lines,
    hide_title = hide_title,
    hide_divider = hide_divider,
  })
  local lines = {}
  local title_line_index = nil
  if not hide_title then
    table.insert(lines, fixed_text(title, width))
    title_line_index = #lines
  end
  for _, line in ipairs(top_lines) do
    table.insert(lines, fixed_text(line, width))
  end
  local tabs_line_index = nil
  if tabs_line ~= "" then
    if #top_lines > 0 then
      table.insert(lines, fixed_text("", width))
    end
    table.insert(lines, fixed_text(tabs_line, width))
    tabs_line_index = #lines
  end
  -- 境界線は細い点線にして情報を分断しすぎない見た目にする。
  if not hide_divider then
    table.insert(lines, fixed_text(string.rep("·", width), width))
  end
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
  -- フッター案内は横幅を超えないように丸め、レイアウト崩れを防ぐ。
  table.insert(lines, fixed_hint_text(build_hint_line(opts.footer_hints or {}, width), width))
  local normalized = trim_lines(lines, height)
  return {
    lines = normalized,
    title_line_index = title_line_index,
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
