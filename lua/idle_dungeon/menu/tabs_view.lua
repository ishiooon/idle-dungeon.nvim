-- このモジュールはタブ付きメニュー本体の描画と操作を提供する。

local frame = require("idle_dungeon.menu.frame")
local live_header = require("idle_dungeon.menu.live_header")
local menu_locale = require("idle_dungeon.menu.locale")
local selection_fx = require("idle_dungeon.menu.selection_fx")
local menu_view = require("idle_dungeon.menu.view")
local menu_tabs = require("idle_dungeon.menu.tabs")
local menu_view_util = require("idle_dungeon.menu.view_util")
local sprite_highlight = require("idle_dungeon.ui.sprite_highlight")
local util = require("idle_dungeon.util")
local window = require("idle_dungeon.menu.window")

local M = {}

local ui_state = {
  win = nil,
  buf = nil,
  prev_win = nil,
  tabs = {},
  active = 1,
  selected = 1,
  offset = 0,
  labels = {},
  opts = {},
  config = {},
  on_close = nil,
  tabs_line_index = nil,
  tab_segments = {},
  visible_items = {},
  body_start = nil,
  body_end = nil,
  layout = { width = nil, height = nil },
  selection_fx = {},
  credits = {
    finished = false,
    scroll_offset = 0,
    scroll_max = 0,
    started_at_sec = nil,
  },
}
local shared_context = { get_state = nil, config = nil }

-- クレジット表示の状態を初期化し、再表示時に前回のスクロール位置を持ち越さない。
local function reset_credits_state()
  ui_state.credits = {
    finished = false,
    scroll_offset = 0,
    scroll_max = 0,
    started_at_sec = nil,
  }
end

local function close(silent)
  local callback = ui_state.on_close
  ui_state.on_close = nil
  selection_fx.stop(ui_state.selection_fx)
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.win = nil
  ui_state.buf = nil
  ui_state.tabs = {}
  ui_state.tab_segments = {}
  ui_state.body_start = nil
  ui_state.body_end = nil
  reset_credits_state()
  if (not silent) and callback then
    callback()
  end
end

local function current_tab()
  return ui_state.tabs[ui_state.active]
end

local function is_credits_tab(tab)
  return tab and tab.id == "credits"
end

local function is_selectable(item)
  if not item then
    return false
  end
  return not (item.id == "header" or item.id == "empty" or item.id == "art" or item.id == "spacer")
end

local function selectable_indexes(tab)
  if is_credits_tab(tab) then
    return {}
  end
  local rows = {}
  for index, item in ipairs((tab and tab.items) or {}) do
    if is_selectable(item) then
      table.insert(rows, index)
    end
  end
  return rows
end

local function ensure_selection(tab)
  local indexes = selectable_indexes(tab)
  if #indexes == 0 then
    ui_state.selected = 1
    return
  end
  local current = menu_view_util.clamp_selected(ui_state.selected, #(tab.items or {}))
  if is_selectable((tab.items or {})[current]) then
    ui_state.selected = current
    return
  end
  ui_state.selected = indexes[1]
end

local function current_choice(tab)
  local item = (tab and tab.items or {})[ui_state.selected]
  if is_selectable(item) then
    return item
  end
  return nil
end

local function build_tab_lines(tab, config)
  local lines = {}
  local visible_items = {}
  local items = (tab and tab.items) or {}
  local total = #items
  for index, item in ipairs(items) do
    local format_item = tab and tab.format_item or nil
    local label = format_item and format_item(item, index, total) or (item and item.label) or ""
    if item and item.id == "header" then
      local prefix = config.section_prefix or ""
      if prefix ~= "" then
        table.insert(lines, string.format("  %s%s", prefix, label))
      else
        table.insert(lines, "  " .. label)
      end
      table.insert(visible_items, item)
    elseif item and item.id == "empty" then
      table.insert(lines, string.format("  %s%s", config.empty_prefix or "󰇘 ", label))
      table.insert(visible_items, item)
    elseif item and item.id == "spacer" then
      table.insert(lines, "")
      table.insert(visible_items, item)
    else
      table.insert(lines, label)
      table.insert(visible_items, item)
    end
  end
  return lines, visible_items
end

local function build_credit_lines(tab)
  local lines = {}
  local items = (tab and tab.items) or {}
  local total = #items
  for index, item in ipairs(items) do
    if item and item.id == "spacer" then
      table.insert(lines, "")
    else
      local format_item = tab and tab.format_item or nil
      local label = format_item and format_item(item, index, total) or (item and item.label) or ""
      table.insert(lines, label)
    end
  end
  return lines
end

local function build_formatted_lines(tab, config)
  local labels = {}
  local items = (tab and tab.items) or {}
  local total = #items
  for index, item in ipairs(items) do
    local format_item = tab and tab.format_item or nil
    local label = format_item and format_item(item, index, total) or (item and item.label) or ""
    if item and item.id == "header" then
      local prefix = config.section_prefix or ""
      if prefix ~= "" then
        label = string.format("  %s%s", prefix, label)
      else
        label = "  " .. label
      end
    elseif item and item.id == "empty" then
      label = string.format("  %s%s", config.empty_prefix or "󰇘 ", label)
    elseif item and item.id == "spacer" then
      label = ""
    end
    table.insert(labels, label)
  end
  return labels
end

local function build_width_lines(title, tabs_line, footer_hints, top_lines, left_lines, all_tabs, config)
  local lines = { title, tabs_line }
  for _, line in ipairs(top_lines or {}) do
    table.insert(lines, line)
  end
  for _, line in ipairs(left_lines or {}) do
    table.insert(lines, line)
  end
  -- タブ切替時の横幅ジャンプを避けるため、全タブの本文長も幅計算へ含める。
  for _, tab in ipairs(all_tabs or {}) do
    for _, line in ipairs(build_formatted_lines(tab, config)) do
      table.insert(lines, line)
    end
  end
  return lines
end

local function center_line(line, width)
  local safe_width = math.max(tonumber(width) or 0, 0)
  local safe_line = tostring(line or "")
  if safe_width <= 0 then
    return safe_line
  end
  local content_width = util.display_width(safe_line)
  if content_width >= safe_width then
    return safe_line
  end
  -- メニュー全体の左右中央に上部ゲーム画面を置くため、左側の余白だけ先に付ける。
  local left_padding = math.floor((safe_width - content_width) / 2)
  return string.rep(" ", math.max(left_padding, 0)) .. safe_line
end

local function center_lines(lines, width)
  local centered = {}
  for _, line in ipairs(lines or {}) do
    table.insert(centered, center_line(line, width))
  end
  return centered
end

local function build_credits_crawl_lines(lines, visible, time_sec, step_seconds)
  local source = lines or {}
  local count = #source
  local rows = math.max(tonumber(visible) or count, 0)
  if rows <= 0 then
    return {}, true
  end
  if count == 0 then
    local blanks = {}
    for index = 1, rows do
      blanks[index] = ""
    end
    return blanks, true
  end
  local step = math.max(tonumber(step_seconds) or 0.4, 0.1)
  local max_shift = math.max(count + rows - 1, 1)
  local shift = math.floor((tonumber(time_sec) or 0) / step) + 1
  shift = math.min(math.max(shift, 1), max_shift)
  local finished = shift >= max_shift
  local rendered = {}
  for row = 1, rows do
    local source_index = row + shift - rows
    rendered[row] = source[source_index] or ""
  end
  return rendered, finished
end

-- クレジット停止後は通常の縦スクロール表示へ切り替える。
local function build_credits_scroll_lines(lines, visible, offset)
  local source = lines or {}
  local count = #source
  local rows = math.max(tonumber(visible) or 0, 0)
  local max_offset = math.max(count - rows, 0)
  local safe_offset = tonumber(offset)
  if safe_offset == nil then
    safe_offset = max_offset
  end
  safe_offset = math.min(math.max(safe_offset, 0), max_offset)
  local rendered = {}
  for row = 1, rows do
    rendered[row] = source[safe_offset + row] or ""
  end
  return rendered, safe_offset, max_offset
end

local function build_top_lines(state, config, lang)
  if not state then
    return {}, {}
  end
  local live_lines = live_header.build_lines(state, config, lang)
  -- 状態タブ本文と重なるため、上部はライブヘッダだけを表示して情報重複を抑える。
  return live_lines, live_lines
end

local function resolve_stable_layout(config, width, height)
  local max_width = tonumber(config.available_width) or width
  local max_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 10)
  local next_width = math.max(ui_state.layout.width or 0, width)
  local next_height = math.max(ui_state.layout.height or 0, height)
  ui_state.layout.width = math.min(next_width, max_width)
  ui_state.layout.height = math.min(next_height, max_height)
  return ui_state.layout.width, ui_state.layout.height
end

local function has_detail_lines(lines)
  for _, line in ipairs(lines or {}) do
    if line and tostring(line) ~= "" then
      return true
    end
  end
  return false
end

-- 詳細データを安全な形式へ正規化する。
local function normalize_detail(detail)
  if type(detail) ~= "table" then
    return nil
  end
  local title = tostring(detail.title or "")
  local lines = {}
  for _, line in ipairs(detail.lines or {}) do
    table.insert(lines, tostring(line or ""))
  end
  if title == "" and #lines == 0 then
    return nil
  end
  return { title = title, lines = lines }
end

-- タブの選択項目から、実体のある詳細情報だけを抽出する。
local function resolve_explicit_detail(tab, item)
  if not item then
    return nil
  end
  local detail = nil
  if tab and type(tab.detail_provider) == "function" then
    detail = normalize_detail(tab.detail_provider(item))
  end
  if not detail and type(item) == "table" and type(item.detail_lines) == "table" then
    detail = normalize_detail({
      title = item.detail_title or item.label or "",
      lines = item.detail_lines,
    })
  end
  if detail and has_detail_lines(detail.lines) then
    return detail
  end
  return nil
end

-- タブの選択項目から詳細プレビューを生成する。
local function resolve_tab_detail(tab, item)
  local detail = resolve_explicit_detail(tab, item)
  if detail then
    return detail
  end
  if not item then
    return nil
  end
  local label = tostring(item.label or "")
  if label ~= "" then
    return {
      title = label,
      lines = {
        "Select this row to apply the change.",
      },
    }
  end
  return nil
end

-- 選択行でEnter時に詳細画面を開くべきかを判定する。
local function can_open_detail_on_enter(tab, choice)
  if type(choice) ~= "table" then
    return false
  end
  local detail = resolve_explicit_detail(tab, choice)
  if choice.open_detail_on_enter == true then
    return detail ~= nil
  end
  if detail == nil then
    return false
  end
  if type(tab and tab.can_execute_on_enter) == "function" then
    return tab.can_execute_on_enter(choice) ~= true
  end
  if tab and type(tab.on_choice) == "function" then
    return false
  end
  return true
end

-- 図鑑とクレジットは一覧性を優先し、下部の詳細欄を出さない。
local function supports_inline_detail(tab)
  if not tab then
    return false
  end
  if tab.id == "credits" then
    return false
  end
  if tab.id == "dex" then
    return false
  end
  return true
end

local function normalize_enter_hint_lines(lines)
  if type(lines) == "string" then
    local text = tostring(lines or "")
    if text == "" then
      return {}
    end
    return { text }
  end
  if type(lines) ~= "table" then
    return {}
  end
  local normalized = {}
  for _, line in ipairs(lines) do
    local text = tostring(line or "")
    if text ~= "" then
      table.insert(normalized, text)
    end
  end
  return normalized
end

-- フッター直上へ表示するEnter説明を、タブ定義と項目状態から決定する。
local function resolve_enter_hint_lines(tab, item, lang)
  local hints = {}
  if tab and type(tab.enter_hint_provider) == "function" then
    hints = normalize_enter_hint_lines(tab.enter_hint_provider(item, lang))
  end
  if #hints > 0 then
    return hints
  end
  if is_credits_tab(tab) then
    return {}
  end
  if not item then
    if lang == "ja" or lang == "jp" then
      return { "󰌑 Enterで実行する項目を選択してください。" }
    end
    return { "󰌑 Select a row to execute with Enter." }
  end
  if can_open_detail_on_enter(tab, item) then
    if lang == "ja" or lang == "jp" then
      return { "󰌑 Enter: 詳細画面を開きます。" }
    end
    return { "󰌑 Enter: Open detail view." }
  end
  if item.keep_open then
    if lang == "ja" or lang == "jp" then
      return { "󰌑 Enter: メニューを開いたまま反映します。" }
    end
    return { "󰌑 Enter: Apply while keeping this menu open." }
  end
  if lang == "ja" or lang == "jp" then
    return { "󰌑 Enter: 選択項目を実行します。" }
  end
  return { "󰌑 Enter: Execute selected item." }
end

-- 下部詳細欄の長文を、指定幅に収まる行へ分割する。
local function wrap_detail_footer_line(line, width)
  local safe_width = math.max(tonumber(width) or 0, 1)
  local text = tostring(line or "")
  if text == "" then
    return { "" }
  end
  if util.display_width(text) <= safe_width then
    return { text }
  end
  local chunks = {}
  local current = ""
  local tokens = {}
  for token in text:gmatch("%S+") do
    table.insert(tokens, token)
  end
  if #tokens == 0 then
    return { util.clamp_line(text, safe_width) }
  end
  local function flush()
    if current ~= "" then
      table.insert(chunks, current)
      current = ""
    end
  end
  local function split_long_token(token)
    local piece = ""
    for _, char in ipairs(util.split_utf8(token)) do
      local candidate = piece .. char
      if util.display_width(candidate) > safe_width then
        if piece ~= "" then
          table.insert(chunks, piece)
        end
        piece = char
      else
        piece = candidate
      end
    end
    if piece ~= "" then
      current = piece
    end
  end
  for _, token in ipairs(tokens) do
    local candidate = current == "" and token or (current .. " " .. token)
    if util.display_width(candidate) <= safe_width then
      current = candidate
    else
      flush()
      if util.display_width(token) <= safe_width then
        current = token
      else
        split_long_token(token)
      end
    end
  end
  flush()
  return chunks
end

-- 選択中の詳細を下部欄へ圧縮して表示する。
local function build_detail_footer_lines(detail, lang, width, allow_open_detail)
  if not detail then
    return {}
  end
  local safe_width = math.max(tonumber(width) or 0, 1)
  local is_ja = lang == "ja" or lang == "jp"
  local title_prefix = is_ja and "󰋼 詳細: " or "󰋼 Detail: "
  local lines = { util.clamp_line(title_prefix .. tostring(detail.title or "-"), safe_width) }
  local flattened = {}
  for _, line in ipairs(detail.lines or {}) do
    for _, piece in ipairs(wrap_detail_footer_line(line, safe_width - 2)) do
      local safe_piece = tostring(piece or "")
      if safe_piece ~= "" then
        table.insert(flattened, safe_piece)
      end
    end
  end
  -- 下部詳細は少し行数を増やして、省略感を減らす。
  local max_body_rows = 3
  for index = 1, math.min(#flattened, max_body_rows) do
    table.insert(lines, util.clamp_line("  " .. flattened[index], safe_width))
  end
  if #flattened > max_body_rows then
    if allow_open_detail then
      local more = is_ja and "  …続きはEnterで詳細を開く" or "  …Open detail with Enter"
      table.insert(lines, util.clamp_line(more, safe_width))
    end
  end
  return lines
end

local function append_dex_icon_highlights(highlights, left_lines, visible_items, shell)
  if type(window.palette_group_name) ~= "function" then
    return
  end
  local base_col = (shell.left_col or 1) - 1
  for row, line in ipairs(left_lines or {}) do
    local absolute = ui_state.offset + row
    local item = (visible_items or {})[absolute]
    if item and item.id == "dex_entry" and item.highlight_key and item.highlight_icon and item.highlight_icon ~= "" then
      local icon_start = string.find(line, item.highlight_icon, 1, true)
      if icon_start then
        table.insert(highlights, {
          line = shell.body_start + row - 1,
          group = window.palette_group_name(item.highlight_key),
          start_col = base_col + icon_start - 1,
          end_col = base_col + icon_start - 1 + #item.highlight_icon,
        })
      end
    end
  end
end

local function build_visual_state_for_live_header(state)
  if not state then
    return nil
  end
  local next_ui = util.merge_tables(state.ui or {}, { render_mode = "visual" })
  return util.merge_tables(state, { ui = next_ui })
end

local function append_live_header_highlights(highlights, state, config, live_lines, centered_top_lines, shell)
  if type(window.palette_group_name) ~= "function" then
    return
  end
  if not state or #(live_lines or {}) == 0 then
    return
  end
  local visual_state = build_visual_state_for_live_header(state)
  local source_lines = live_lines or {}
  local live_highlights = sprite_highlight.build(visual_state, config or {}, source_lines)
  if #live_highlights == 0 then
    return
  end
  local top_line_start = (shell.title_line_index and (shell.title_line_index + 1)) or 1
  local live_start_index = math.max(#(centered_top_lines or {}) - #source_lines + 1, 1)
  for _, item in ipairs(live_highlights) do
    local local_line = (tonumber(item.line) or 0) + 1
    local top_index = live_start_index + local_line - 1
    local centered_line = (centered_top_lines or {})[top_index] or ""
    local padding = #((centered_line:match("^(%s*)") or ""))
    local start_col = math.max((tonumber(item.start_col) or 0) + padding, 0)
    local end_col = item.end_col
    if end_col ~= nil then
      end_col = math.max((tonumber(end_col) or 0) + padding, 0)
    else
      end_col = -1
    end
    -- ライブヘッダのトラック行だけにスプライト色を反映する。
    table.insert(highlights, {
      line = top_line_start + top_index - 1,
      group = window.palette_group_name(item.palette),
      start_col = start_col,
      end_col = end_col,
    })
  end
end

local function render()
  local tab = current_tab()
  if not tab then
    return
  end
  ensure_selection(tab)
  local config = menu_view_util.menu_config(ui_state.config)
  local current_state = shared_context.get_state and shared_context.get_state() or nil
  local lang = ((current_state or {}).ui or {}).language
    or ((shared_context.config or {}).ui or {}).language
    or "en"
  local source_config = shared_context.config or ui_state.config
  local top_lines, live_lines = build_top_lines(current_state, source_config, lang)
  local tabs_line = menu_tabs.build_tabs_line(ui_state.tabs, ui_state.active, config.tabs_style)
  local base_title = (ui_state.opts and ui_state.opts.title) or "Idle Dungeon"
  local title = string.format("󰀘 %s", base_title)
  local footer_hints = (ui_state.opts and ui_state.opts.footer_hints) or {}
  local screen_height = math.max(vim.o.lines - vim.o.cmdheight - 4, 12)
  local labels, visible_items = build_tab_lines(tab, config)
  local selected_item = (tab.items or {})[ui_state.selected]
  -- 右ペインは廃止し、選択中詳細を下部へ圧縮表示する。
  local detail_width = tonumber(config.min_width) or 56
  local detail_notes = {}
  if supports_inline_detail(tab) then
    detail_notes = build_detail_footer_lines(
      resolve_tab_detail(tab, selected_item),
      lang,
      detail_width,
      can_open_detail_on_enter(tab, selected_item)
    )
  end
  local enter_notes = resolve_enter_hint_lines(tab, selected_item, lang)
  local footer_notes = {}
  for _, line in ipairs(detail_notes) do
    table.insert(footer_notes, line)
  end
  for _, line in ipairs(enter_notes) do
    table.insert(footer_notes, line)
  end
  if type(window.ensure_palette_highlights) == "function" then
    local palette = ((ui_state.config or {}).ui or {}).sprite_palette or {}
    window.ensure_palette_highlights(palette)
  end
  local width = menu_view_util.resolve_compact_width(config, top_lines, tabs_line)
  local height = menu_view_util.resolve_compact_height(
    config,
    screen_height,
    #labels,
    top_lines,
    tabs_line ~= "",
    #footer_notes
  )
  -- 下部説明行を含めた本文高さでスクロール量を計算し、選択項目が画面外に消えないようにする。
  local visible = frame.resolve_content_height({
    height = height,
    tabs_line = tabs_line,
    top_lines = top_lines,
    footer_notes = footer_notes,
  })
  local left_lines, selected_row
  if is_credits_tab(tab) then
    ui_state.offset = 0
    local credit_lines = build_credit_lines(tab)
    local current_time = ((current_state or {}).metrics or {}).time_sec or 0
    if ui_state.credits.finished then
      left_lines, ui_state.credits.scroll_offset, ui_state.credits.scroll_max =
        build_credits_scroll_lines(credit_lines, visible, ui_state.credits.scroll_offset)
    else
      if ui_state.credits.started_at_sec == nil then
        -- クレジット演出はタブを開いた時刻を起点にし、総プレイ時間の影響を受けないようにする。
        ui_state.credits.started_at_sec = current_time
      end
      local crawl_step = ((((source_config or {}).ui or {}).menu or {}).credits_scroll_seconds)
      local elapsed = math.max(current_time - (ui_state.credits.started_at_sec or current_time), 0)
      local crawl_lines, finished = build_credits_crawl_lines(credit_lines, visible, elapsed, crawl_step)
      if finished then
        ui_state.credits.finished = true
        left_lines, ui_state.credits.scroll_offset, ui_state.credits.scroll_max =
          build_credits_scroll_lines(credit_lines, visible, nil)
      else
        left_lines = crawl_lines
        ui_state.credits.scroll_offset = 0
        ui_state.credits.scroll_max = math.max(#credit_lines - visible, 0)
      end
    end
    selected_row = nil
  else
    ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
    left_lines, selected_row = menu_view_util.build_select_lines({
      labels = labels,
      items = visible_items,
      selected = ui_state.selected,
      offset = ui_state.offset,
      visible = visible,
      prefix = config.item_prefix or "󰜴 ",
      non_select_prefix = "  ",
      is_selectable = is_selectable,
      render_line = function(label, _, mark, _, selectable)
        if selectable then
          return mark .. label
        end
        return "  " .. label
      end,
    })
  end
  local width_lines = build_width_lines(title, tabs_line, footer_hints, top_lines, left_lines, ui_state.tabs, config)
  for _, note in ipairs(footer_notes or {}) do
    table.insert(width_lines, note)
  end
  width = menu_view_util.resolve_display_width(config, width, width_lines)
  width, height = resolve_stable_layout(config, width, height)
  if is_credits_tab(tab) then
    left_lines = center_lines(left_lines, width)
  end
  local centered_top_lines = center_lines(top_lines, width)
  local shell = frame.compose({
    title = title,
    top_lines = centered_top_lines,
    tabs_line = tabs_line,
    left_title = "MENU",
    left_lines = left_lines,
    -- メインメニューは常に1カラムで表示し、詳細は下部欄へ集約する。
    show_right = false,
    footer_notes = footer_notes,
    footer_hints = footer_hints,
    width = width,
    height = height,
  })
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, width, config.border, config.theme, {
    -- メイン画面は折り返さず1行で表示して視認性を保つ。
    wrap_lines = false,
  })
  window.update_window(win, height, width)
  window.set_lines(buf, shell.lines)
  local highlights = {
    { line = shell.title_line_index, group = "IdleDungeonMenuTitle" },
    { line = shell.footer_hint_line, group = "IdleDungeonMenuMuted" },
  }
  if shell.footer_note_divider_line then
    table.insert(highlights, { line = shell.footer_note_divider_line, group = "IdleDungeonMenuDivider" })
  end
  if shell.footer_note_start_line and shell.footer_note_end_line then
    for line = shell.footer_note_start_line, shell.footer_note_end_line do
      table.insert(highlights, { line = line, group = "IdleDungeonMenuHint" })
    end
  end
  if shell.tabs_line_index then
    table.insert(highlights, { line = shell.tabs_line_index, group = "IdleDungeonMenuTabs" })
  end
  local selected_marker_width = 0
  if selected_row then
    local marker_width = string.len(config.item_prefix or "󰜴 ")
    selected_marker_width = marker_width
    table.insert(highlights, {
      line = shell.body_start + selected_row - 1,
      group = selection_fx.selected_group(ui_state.selection_fx),
      start_col = shell.left_col - 1,
      end_col = (shell.left_col - 1) + marker_width,
    })
  end
  local cursor_row = shell.body_start + (ui_state.selected - ui_state.offset) - 1
  local cursor_col = (shell.left_col - 1) + math.max(selected_marker_width, 2)
  vim.api.nvim_win_set_cursor(win, { math.max(cursor_row, shell.body_start), cursor_col })
  ui_state.labels = labels
  ui_state.visible_items = visible_items
  ui_state.tabs_line_index = shell.tabs_line_index
  ui_state.body_start = shell.body_start
  ui_state.body_end = shell.body_start + math.max(visible, 1) - 1
  ui_state.tab_segments = {}
  if shell.tabs_line_index then
    for _, segment in ipairs(menu_tabs.build_tabs_segments(ui_state.tabs, ui_state.active, config.tabs_style)) do
      table.insert(ui_state.tab_segments, {
        index = segment.index,
        start_col = segment.start_col,
        end_col = segment.end_col,
      })
      table.insert(highlights, {
        line = shell.tabs_line_index,
        group = segment.index == ui_state.active and "IdleDungeonMenuTabActive" or "IdleDungeonMenuTabInactive",
        start_col = math.max(segment.start_col - 1, 0),
        end_col = segment.end_col,
      })
    end
  end
  append_live_header_highlights(highlights, current_state, source_config, live_lines, centered_top_lines, shell)
  append_dex_icon_highlights(highlights, left_lines, visible_items, shell)
  window.apply_highlights(buf, highlights)
  ui_state.win = win
  ui_state.buf = buf
end

local function is_card_style_lines(lines)
  local first = tostring((lines or {})[1] or "")
  return first:sub(1, 1) == "┏"
end

local function pad_right_for_card(text, width)
  local safe = util.clamp_line(tostring(text or ""), width)
  local gap = math.max(width - util.display_width(safe), 0)
  return safe .. string.rep(" ", gap)
end

-- 詳細画面はゲーム画面らしいカード枠へ変換して読みやすさを上げる。
local function build_detail_card_lines(detail, lang, max_width)
  local lines = detail and detail.lines or {}
  if is_card_style_lines(lines) then
    return lines
  end
  local safe_max = math.max(tonumber(max_width) or 56, 34)
  local body = {}
  for _, line in ipairs(lines) do
    for _, piece in ipairs(wrap_detail_footer_line(line, safe_max - 4)) do
      local text = tostring(piece or "")
      if text ~= "" then
        table.insert(body, text)
      end
    end
  end
  if #body == 0 then
    if lang == "ja" or lang == "jp" then
      body = { "この項目の詳細はありません。" }
    else
      body = { "No additional detail for this item." }
    end
  end
  local title = tostring(detail and detail.title or "-")
  local inner_width = util.display_width(title) + 2
  for _, line in ipairs(body) do
    inner_width = math.max(inner_width, util.display_width(line) + 2)
  end
  inner_width = math.max(math.min(inner_width, safe_max - 2), 28)
  local top = "┏" .. string.rep("━", inner_width) .. "┓"
  local sep = "┣" .. string.rep("━", inner_width) .. "┫"
  local bottom = "┗" .. string.rep("━", inner_width) .. "┛"
  local card = {
    top,
    "┃" .. pad_right_for_card(" " .. title, inner_width) .. "┃",
    sep,
  }
  for _, line in ipairs(body) do
    table.insert(card, "┃" .. pad_right_for_card(" " .. line, inner_width) .. "┃")
  end
  table.insert(card, bottom)
  return card
end

local function open_detail_page(tab, choice)
  if not choice then
    return false
  end
  local detail = nil
  if tab and tab.detail_provider then
    detail = tab.detail_provider(choice)
  end
  if not detail and choice.detail_lines then
    detail = {
      title = choice.detail_title or (choice.label or ""),
      lines = choice.detail_lines,
    }
  end
  if not detail or not has_detail_lines(detail.lines) then
    return false
  end
  local state = shared_context.get_state and shared_context.get_state() or {}
  local lang = ((state.ui or {}).language) or ((shared_context.config or {}).ui or {}).language or "en"
  local config = menu_view_util.menu_config(ui_state.config)
  local card_lines = build_detail_card_lines(
    detail,
    lang,
    math.max((tonumber(config.available_width) or tonumber(config.width) or 72) - 4, 34)
  )
  menu_view.select(card_lines, {
    prompt = detail.title or "",
    lang = lang,
    keep_open = true,
    static_view = true,
    add_back_item = false,
    item_prefix = "",
    non_select_prefix = "",
    wrap_lines = false,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    format_item = function(line)
      return tostring(line)
    end,
  }, function()
  end, ui_state.config)
  return true
end

local function move(delta)
  local tab = current_tab()
  if not tab then
    return
  end
  if is_credits_tab(tab) then
    -- クレジットは最後まで流れた時点で停止し、手動入力で位置を変えない。
    return
  end
  local indexes = selectable_indexes(tab)
  if #indexes == 0 then
    return
  end
  local cursor = 1
  for index, value in ipairs(indexes) do
    if value == ui_state.selected then
      cursor = index
      break
    end
  end
  -- 選択可能項目のみを対象に循環させ、先頭で上入力したときに末尾へ回す。
  local next_cursor = menu_view_util.wrap_selected(cursor + delta, #indexes)
  ui_state.selected = indexes[next_cursor]
  render()
  selection_fx.start(ui_state.selection_fx, render)
end

local function switch_tab(delta)
  ui_state.active = menu_tabs.shift_index(ui_state.active, delta, #ui_state.tabs)
  ui_state.offset = 0
  ui_state.selected = 1
  reset_credits_state()
  render()
  selection_fx.start(ui_state.selection_fx, render)
end

local function select_current()
  local tab = current_tab()
  if not tab then
    return
  end
  local choice = current_choice(tab)
  if not choice then
    return
  end
  -- 実行操作を阻害しないよう、詳細画面は明示指定された項目だけで開く。
  if can_open_detail_on_enter(tab, choice) and open_detail_page(tab, choice) then
    return
  end
  if type(tab.can_execute_on_enter) == "function" and tab.can_execute_on_enter(choice) ~= true then
    -- 実行対象ではない行はEnterを無視し、メニューを閉じない。
    return
  end
  if not tab.on_choice then
    return
  end
  local keep_open = choice and choice.keep_open == true
  if keep_open then
    tab.on_choice(choice)
    render()
    return
  end
  close()
  tab.on_choice(choice)
end

local function cancel()
  close()
end

local function set_keymaps(buf)
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "<Tab>", function() switch_tab(1) end },
    { "<S-Tab>", function() switch_tab(-1) end },
    { "<Right>", function() switch_tab(1) end },
    { "<Left>", function() switch_tab(-1) end },
    { "h", function() switch_tab(-1) end },
    { "l", function() switch_tab(1) end },
    { "gg", function() ui_state.selected = 1 render() end },
    { "G", function()
      local tab = current_tab()
      ui_state.selected = #(tab and tab.items or {})
      render()
    end },
    { "o", function()
      local tab = current_tab()
      if not tab then
        return
      end
      local choice = current_choice(tab)
      open_detail_page(tab, choice)
    end },
    { "<CR>", select_current },
    { "<LeftMouse>", function()
      local pos = vim.fn.getmousepos()
      if pos.winid ~= ui_state.win then
        return
      end
      if pos.line == ui_state.tabs_line_index then
        for _, segment in ipairs(ui_state.tab_segments or {}) do
          if pos.column >= segment.start_col and pos.column <= segment.end_col then
            ui_state.active = menu_view_util.clamp_selected(segment.index, #ui_state.tabs)
            ui_state.selected = 1
            ui_state.offset = 0
            render()
            selection_fx.start(ui_state.selection_fx, render)
            return
          end
        end
        return
      end
      local tab = current_tab()
      if not tab or is_credits_tab(tab) then
        return
      end
      local body_start = ui_state.body_start or 0
      local body_end = ui_state.body_end or 0
      if pos.line < body_start or pos.line > body_end then
        return
      end
      local clicked_index = ui_state.offset + (pos.line - body_start + 1)
      local item = (tab.items or {})[clicked_index]
      if not is_selectable(item) then
        return
      end
      -- 本文行のクリックは選択だけを更新し、確定操作はEnterへ分離する。
      ui_state.selected = clicked_index
      render()
      selection_fx.start(ui_state.selection_fx, render)
    end },
    { "b", cancel },
    { "<BS>", cancel },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
  for index = 1, #ui_state.tabs do
    vim.keymap.set("n", tostring(index), function()
      ui_state.active = index
      ui_state.selected = 1
      ui_state.offset = 0
      render()
      selection_fx.start(ui_state.selection_fx, render)
    end, { buffer = buf, silent = true })
  end
end

local function update(tabs)
  if not window.is_valid_window(ui_state.win) or not window.is_valid_buffer(ui_state.buf) then
    return
  end
  if tabs and #tabs > 0 then
    ui_state.tabs = tabs
  end
  ui_state.active = menu_view_util.clamp_selected(ui_state.active, #ui_state.tabs)
  render()
end

local function select(tabs, opts, config)
  close()
  if not tabs or #tabs == 0 then
    return
  end
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.tabs = tabs
  ui_state.opts = opts or {}
  ui_state.config = config or {}
  ui_state.on_close = ui_state.opts.on_close
  local active = ui_state.opts.active or 1
  if ui_state.opts.active_id then
    for index, tab in ipairs(tabs) do
      if tab.id == ui_state.opts.active_id then
        active = index
        break
      end
    end
  end
  ui_state.active = menu_view_util.clamp_selected(active, #tabs)
  ui_state.selected = 1
  ui_state.offset = 0
  ui_state.layout = { width = nil, height = nil }
  ui_state.selection_fx = {}
  reset_credits_state()
  render()
  if ui_state.buf then
    set_keymaps(ui_state.buf)
  end
end

M.select = select
M.update = update
M.close = close
M.set_context = function(get_state, config)
  shared_context.get_state = get_state
  shared_context.config = config
end

return M
