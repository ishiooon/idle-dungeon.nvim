-- このモジュールはタブ付きの中央メニュー表示を提供する。
-- タブ描画の参照先はmenu配下に統一する。
local detail_window = require("idle_dungeon.menu.detail_window")
local layout = require("idle_dungeon.menu.layout")
local menu_tabs = require("idle_dungeon.menu.tabs")
local menu_view_util = require("idle_dungeon.menu.view_util")
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
  items = {},
  opts = {},
  config = {},
  on_close = nil,
  tabs_line_index = nil,
  tab_segments = {},
  grid = nil,
  detail = { win = nil, buf = nil },
}
-- 描画関数を先に宣言してグリッド移動から参照できるようにする。
local render

-- グリッド表示を使うタブかどうかを判定する。
local function is_grid_tab(tab)
  return tab and tab.layout == "grid"
end

-- タイルの幅をコンテンツ幅から決定する。
local function resolve_tile_width(content_width, grid_opts)
  local opts = grid_opts or {}
  local gap = opts.gap or 2
  local min_width = opts.min_width or 18
  local target_cols = opts.columns or 3
  if opts.tile_width then
    return math.max(8, math.floor(opts.tile_width))
  end
  local candidate = math.floor((content_width - gap * (target_cols - 1)) / target_cols)
  return math.max(candidate, min_width)
end

-- タイルのラベルを固定幅に整形する。
local function pad_tile_label(label, width)
  local clamped = util.clamp_line(label or "", width)
  local length = util.display_width(clamped)
  if length < width then
    clamped = clamped .. string.rep(" ", width - length)
  end
  return clamped
end

-- グリッド表示用の行とセル情報を構築する。
local function build_grid_state(tab, config, max_width)
  local padding = math.max(config.padding or 0, 0)
  local content_width = math.max(max_width - padding * 2, 1)
  local grid_opts = tab and tab.grid or {}
  local gap = grid_opts.gap or 2
  local tile_width = resolve_tile_width(content_width, grid_opts)
  local columns = math.max(1, math.floor((content_width + gap) / (tile_width + gap)))
  local rows = {}
  local current = {}
  local function flush_row()
    if #current > 0 then
      table.insert(rows, { type = "tiles", cells = current })
      current = {}
    end
  end
  for _, item in ipairs((tab and tab.items) or {}) do
    if item and (item.id == "header" or item.id == "empty" or item.id == "art" or item.id == "spacer") then
      flush_row()
      table.insert(rows, { type = item.id, item = item })
    else
      table.insert(current, item)
      if #current >= columns then
        flush_row()
      end
    end
  end
  flush_row()
  local lines = {}
  local cells = {}
  local tile_rows = {}
  local max_line_width = 1
  local row_index = 0
  local tile_row_index = 0
  for _, row in ipairs(rows) do
    row_index = row_index + 1
    row.display_row = row_index
    if row.type == "tiles" then
      tile_row_index = tile_row_index + 1
      row.tile_row = tile_row_index
      local parts = {}
      local row_cells = {}
      for col, item in ipairs(row.cells or {}) do
        local label = (tab and tab.format_tile and tab.format_tile(item)) or (item and item.tile_label) or (item and item.label) or ""
        local tile_text = pad_tile_label(label, tile_width)
        table.insert(parts, tile_text)
        local start_col = padding + (col - 1) * (tile_width + gap) + 1
        local cell = {
          item = item,
          tile_row = tile_row_index,
          col = col,
          display_row = row_index,
          start_col = start_col,
          -- 行と列移動のため、セルの並び順インデックスを保持する。
          index = #cells + 1,
        }
        table.insert(cells, cell)
        table.insert(row_cells, cell)
      end
      local line = string.rep(" ", padding) .. table.concat(parts, string.rep(" ", gap))
      line = util.clamp_line(line, max_width)
      table.insert(lines, line)
      tile_rows[tile_row_index] = { display_row = row_index, cells = row_cells }
    else
      local label = (row.item and row.item.label) or ""
      local line = ""
      if row.type == "header" then
        line = (config.section_prefix or "") .. label
      elseif row.type == "empty" then
        line = (config.empty_prefix or "") .. label
      else
        line = label
      end
      line = util.clamp_line(string.rep(" ", padding) .. line, max_width)
      table.insert(lines, line)
    end
    max_line_width = math.max(max_line_width, util.display_width(lines[#lines] or ""))
  end
  for index, cell in ipairs(cells) do
    cell.index = index
  end
  return {
    rows = rows,
    lines = lines,
    cells = cells,
    tile_rows = tile_rows,
    columns = columns,
    tile_width = tile_width,
    gap = gap,
    width = max_line_width,
  }
end

-- グリッド表示の可視範囲を切り出す。
local function slice_grid_lines(grid, offset, visible)
  local lines = {}
  for index = 1, math.max(visible or 0, 0) do
    lines[index] = grid.lines[(offset or 0) + index] or ""
  end
  return lines
end

-- グリッド表示の見出し行をハイライト対象に追加する。
local function collect_grid_highlights(grid, header_lines, offset, visible)
  local specs = {}
  for index = 1, math.max(visible or 0, 0) do
    local row = grid.rows[(offset or 0) + index]
    if row and row.type == "header" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuSection" })
    elseif row and row.type == "empty" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuMuted" })
    elseif row and row.type == "art" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuTitle" })
    end
  end
  return specs
end

local function resolve_grid_selected_cell()
  local grid = ui_state.grid
  if not grid or #grid.cells == 0 then
    return nil
  end
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #grid.cells)
  return grid.cells[ui_state.selected]
end

local function move_grid_row(delta)
  local grid = ui_state.grid
  local cell = resolve_grid_selected_cell()
  if not grid or not cell then
    return
  end
  local target_row = math.max(1, math.min(cell.tile_row + delta, #grid.tile_rows))
  local row = grid.tile_rows[target_row]
  if not row or #row.cells == 0 then
    return
  end
  local target_col = math.min(cell.col, #row.cells)
  ui_state.selected = row.cells[target_col].index
  render()
end

local function move_grid_col(delta)
  local grid = ui_state.grid
  local cell = resolve_grid_selected_cell()
  if not grid or not cell then
    return
  end
  local row = grid.tile_rows[cell.tile_row]
  if not row then
    return
  end
  local target_col = math.max(1, math.min(cell.col + delta, #row.cells))
  ui_state.selected = row.cells[target_col].index
  render()
end

local function jump_grid(first)
  local grid = ui_state.grid
  if not grid or #grid.cells == 0 then
    return
  end
  ui_state.selected = first and 1 or #grid.cells
  render()
end

-- タブ内の表示行を整形し、セクションごとの見た目を揃える。
local function format_tab_item(tab, item, config)
  local format_item = tab and tab.format_item or nil
  local label = format_item and format_item(item) or (item and item.label) or tostring(item or "")
  if label == "" then
    return ""
  end
  if item and item.id == "art" then
    return label
  end
  if item and item.id == "spacer" then
    return ""
  end
  if item and item.id == "header" then
    return (config.section_prefix or "") .. label
  end
  if item and item.id == "empty" then
    return (config.empty_prefix or "") .. label
  end
  return (config.item_prefix or "") .. label
end

-- タブ内の項目を表示用のラベル配列へ変換する。
local function build_tab_labels(tab, config)
  local labels = {}
  for _, item in ipairs((tab and tab.items) or {}) do
    table.insert(labels, format_tab_item(tab, item, config))
  end
  return labels
end

-- セクション見出しなどに対応するハイライト行を集計する。
local function collect_item_highlights(tab, built, header_lines)
  local specs = {}
  local items = (tab and tab.items) or {}
  local offset = built.offset or 0
  local count = built.items_count or 0
  for index = 1, count do
    local item = items[offset + index]
    if item and item.id == "header" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuSection" })
    elseif item and item.id == "empty" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuMuted" })
    elseif item and item.id == "art" then
      table.insert(specs, { line = header_lines + index, group = "IdleDungeonMenuTitle" })
    elseif item and item.highlight_key then
      table.insert(specs, {
        line = header_lines + index,
        group = "IdleDungeonMenuElement_" .. item.highlight_key,
        palette_key = item.highlight_key,
      })
    end
  end
  return specs
end

local function palette_config(config)
  return ((config or {}).ui or {}).sprite_palette or {}
end

local function apply_element_highlights(config, highlight_specs)
  local palette = palette_config(config)
  local seen = {}
  for _, spec in ipairs(highlight_specs or {}) do
    local key = spec.palette_key
    if key and not seen[key] then
      local colors = palette[key] or {}
      if colors.fg or colors.bg then
        -- 依存する配色を反映するためハイライトグループを更新する。
        vim.api.nvim_set_hl(0, "IdleDungeonMenuElement_" .. key, { fg = colors.fg, bg = colors.bg, bold = true })
      end
      seen[key] = true
    end
  end
end

-- 表示領域に合わせてコンテンツ行数を埋める。
local function pad_content_lines(lines, height)
  local padded = {}
  for _, line in ipairs(lines or {}) do
    table.insert(padded, line)
  end
  while #padded < math.max(height or 0, 0) do
    table.insert(padded, "")
  end
  if height and #padded > height then
    local trimmed = {}
    for index = 1, height do
      trimmed[index] = padded[index]
    end
    return trimmed
  end
  return padded
end

local function close()
  local callback = ui_state.on_close
  ui_state.on_close = nil
  -- 表示中のメニューウィンドウを閉じる。
  window.close_window(ui_state.win, ui_state.prev_win)
  ui_state.detail = detail_window.close(ui_state.detail)
  ui_state.win = nil
  ui_state.buf = nil
  if callback then callback() end
end
-- 詳細パネルの内容を先に宣言して描画から参照できるようにする。
local resolve_detail
render = function()
  local tab = ui_state.tabs[ui_state.active]
  if not tab then return end
  local config = menu_view_util.menu_config(ui_state.config)
  local tabs_line = menu_tabs.build_tabs_line(ui_state.tabs, ui_state.active, config.tabs_style)
  local title = (ui_state.opts or {}).title or ""
  local footer_hints = (ui_state.opts or {}).footer_hints or {}
  -- メニュー下部の案内文は幅に合わせて整形する。
  local hint_lines = menu_view_util.build_footer_hint_lines(footer_hints, config, math.max(config.width or 0, 24))
  local hint_block = #hint_lines > 0 and (#hint_lines + 1) or 0
  local header_count = (title ~= "" and 1 or 0) + (config.tabs_position == "bottom" and 1 or 2)
  local footer_count = (config.tabs_position == "bottom" and 2 or 0) + hint_block
  local visible = math.max((config.height or config.max_height) - header_count - footer_count, 1)
  local max_width = math.max(config.width or 0, 24)
  local sections = nil
  local content_lines = nil
  local labels = nil
  local built = nil
  if is_grid_tab(tab) then
    local grid = build_grid_state(tab, config, max_width)
    ui_state.grid = grid
    local selected_cell = resolve_grid_selected_cell()
    local selected_line = selected_cell and selected_cell.display_row or 1
    ui_state.offset = menu_view_util.adjust_offset(selected_line, ui_state.offset, visible, #grid.lines)
    content_lines = slice_grid_lines(grid, ui_state.offset, visible)
    built = { width = grid.width }
    sections = menu_view_util.build_tabs_sections(ui_state.opts, config, tabs_line, built, max_width, hint_lines)
    labels = grid.lines
  else
    ui_state.grid = nil
    labels = build_tab_labels(tab, config)
    ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #labels)
    ui_state.offset = menu_view_util.adjust_offset(ui_state.selected, ui_state.offset, visible, #labels)
    built = layout.build_lines("", labels, {
      padding = config.padding,
      offset = ui_state.offset,
      max_items = visible,
      max_width = max_width,
    })
    sections = menu_view_util.build_tabs_sections(ui_state.opts, config, tabs_line, built, max_width, hint_lines)
    content_lines = pad_content_lines(built.lines, visible)
  end
  local lines = {}
  for _, line in ipairs(sections.header_lines) do
    table.insert(lines, line)
  end
  for _, line in ipairs(content_lines) do
    table.insert(lines, line)
  end
  for _, line in ipairs(sections.footer_lines) do
    table.insert(lines, line)
  end
  local height = math.max(config.height or #lines, 1)
  -- タブ付きの中央メニュー表示を固定サイズで更新する。
  local win, buf = window.ensure_window(ui_state.win, ui_state.buf, height, config.width, config.border, config.theme)
  window.update_window(win, height, config.width)
  window.set_lines(buf, lines)
  local highlight_specs = {}
  if title ~= "" then
    highlight_specs[#highlight_specs + 1] = { line = 1, group = "IdleDungeonMenuTitle" }
  end
  local tabs_line_index = config.tabs_position == "bottom"
    and (#sections.header_lines + #content_lines + (sections.tabs_line_offset or 0))
    or (title ~= "" and 2 or 1)
  highlight_specs[#highlight_specs + 1] = { line = tabs_line_index, group = "IdleDungeonMenuTabs" }
  local divider_line_top = config.tabs_position == "bottom"
    and #sections.header_lines
    or (title ~= "" and 3 or 2)
  if divider_line_top > 0 then
    highlight_specs[#highlight_specs + 1] = { line = divider_line_top, group = "IdleDungeonMenuDivider" }
  end
  if config.tabs_position == "bottom" then
    local divider_line_bottom = #sections.header_lines + #content_lines + 1
    highlight_specs[#highlight_specs + 1] = { line = divider_line_bottom, group = "IdleDungeonMenuDivider" }
  end
  if #hint_lines > 0 then
    local hint_divider = #lines - #hint_lines
    highlight_specs[#highlight_specs + 1] = { line = hint_divider, group = "IdleDungeonMenuDivider" }
    for index = (#lines - #hint_lines + 1), #lines do
      highlight_specs[#highlight_specs + 1] = { line = index, group = "IdleDungeonMenuMuted" }
    end
  end
  if is_grid_tab(tab) then
    for _, spec in ipairs(collect_grid_highlights(ui_state.grid, #sections.header_lines, ui_state.offset, #content_lines)) do
      table.insert(highlight_specs, spec)
    end
  else
    for _, spec in ipairs(collect_item_highlights(tab, built, #sections.header_lines)) do
      table.insert(highlight_specs, spec)
    end
  end
  apply_element_highlights(ui_state.config, highlight_specs)
  window.apply_highlights(buf, highlight_specs)
  if is_grid_tab(tab) then
    local selected_cell = resolve_grid_selected_cell()
    if selected_cell then
      local line = #sections.header_lines + (selected_cell.display_row - ui_state.offset)
      if line >= 1 and line <= #lines then
        vim.api.nvim_win_set_cursor(win, { math.max(line, 1), math.max(selected_cell.start_col - 1, 0) })
      end
    end
  elseif ui_state.selected > 0 and #labels > 0 then
    vim.api.nvim_win_set_cursor(win, { math.max(#sections.header_lines + (ui_state.selected - (built.offset or 0)), 1), 0 })
  end
  -- 選択中の項目に合わせて詳細ウィンドウを更新する。
  ui_state.detail = detail_window.render(ui_state.detail, win, config, resolve_detail(tab))
  ui_state.labels, ui_state.items = labels, (tab.items or {})
  ui_state.tabs_line_index = tabs_line_index
  ui_state.tab_segments = {}
  do
    local padding = math.max(config.padding or 0, 0)
    -- タブ行のクリック判定用に列の範囲を保存する。
    for _, segment in ipairs(menu_tabs.build_tabs_segments(ui_state.tabs, ui_state.active, config.tabs_style)) do
      table.insert(ui_state.tab_segments, {
        index = segment.index,
        start_col = segment.start_col + padding,
        end_col = segment.end_col + padding,
      })
    end
  end
  ui_state.win, ui_state.buf = win, buf
end
local function move(delta)
  if is_grid_tab(ui_state.tabs[ui_state.active]) then
    move_grid_row(delta)
    return
  end
  if #ui_state.labels == 0 then return end
  ui_state.selected = menu_view_util.clamp_selected(ui_state.selected + delta, #ui_state.labels)
  render()
end
local function switch_tab(delta)
  local total = #ui_state.tabs
  if total <= 0 then return end
  ui_state.active = menu_tabs.shift_index(ui_state.active, delta, total)
  local tab = ui_state.tabs[ui_state.active] or {}
  ui_state.selected = 1
  ui_state.offset = 0
  render()
end

local function resolve_choice(tab)
  if is_grid_tab(tab) then
    local cell = resolve_grid_selected_cell()
    return cell and cell.item or nil
  end
  return #ui_state.items > 0 and ui_state.items[ui_state.selected] or nil
end

-- 選択中の項目から詳細表示用の情報を組み立てる。
resolve_detail = function(tab)
  if not tab then
    return nil
  end
  local choice = resolve_choice(tab)
  if tab.detail_provider then
    return tab.detail_provider(choice)
  end
  if choice and choice.detail_lines then
    return { title = choice.detail_title or "", lines = choice.detail_lines }
  end
  return nil
end

local function select_current()
  local tab = ui_state.tabs[ui_state.active]
  if not tab or not tab.on_choice then return end
  local choice = resolve_choice(tab)
  local callback = tab.on_choice
  if choice and choice.keep_open then
    callback(choice)
    render()
    return
  end
  close()
  callback(choice)
end
local function cancel()
  close()
end
local function set_keymaps(buf)
  -- タブ付きメニュー操作用のキーマップを設定する。
  local mappings = {
    { "j", function() move(1) end },
    { "k", function() move(-1) end },
    { "<Down>", function() move(1) end },
    { "<Up>", function() move(-1) end },
    { "h", function() move_grid_col(-1) end },
    { "l", function() move_grid_col(1) end },
    { "<Tab>", function() switch_tab(1) end },
    { "<S-Tab>", function() switch_tab(-1) end },
    { "<Right>", function() switch_tab(1) end },
    { "<Left>", function() switch_tab(-1) end },
    { "gg", function()
      if is_grid_tab(ui_state.tabs[ui_state.active]) then
        jump_grid(true)
        return
      end
      ui_state.selected = menu_view_util.clamp_selected(1, #ui_state.items)
      render()
    end },
    { "G", function()
      if is_grid_tab(ui_state.tabs[ui_state.active]) then
        jump_grid(false)
        return
      end
      ui_state.selected = menu_view_util.clamp_selected(#ui_state.items, #ui_state.items)
      render()
    end },
    { "<CR>", select_current },
    { "<LeftMouse>", function()
      -- タブ行クリック時のみタブ切り替えを行う。
      local pos = vim.fn.getmousepos()
      if pos.winid ~= ui_state.win then
        return
      end
      if pos.line ~= ui_state.tabs_line_index then
        return
      end
      for _, segment in ipairs(ui_state.tab_segments or {}) do
        if pos.column >= segment.start_col and pos.column <= segment.end_col then
          ui_state.active = menu_view_util.clamp_selected(segment.index, #ui_state.tabs)
          local tab = ui_state.tabs[ui_state.active] or {}
          ui_state.selected = menu_view_util.clamp_selected(1, #(tab.items or {}))
          ui_state.offset = 0
          render()
          return
        end
      end
    end },
    { "<Esc>", cancel },
    { "q", cancel },
  }
  for _, map in ipairs(mappings) do
    vim.keymap.set("n", map[1], map[2], { buffer = buf, silent = true })
  end
end

local function update(tabs)
  if not window.is_valid_window(ui_state.win) or not window.is_valid_buffer(ui_state.buf) then return end
  if tabs and #tabs > 0 then ui_state.tabs = tabs end
  ui_state.active = menu_view_util.clamp_selected(ui_state.active, #ui_state.tabs)
  local active_items = ui_state.tabs[ui_state.active] and ui_state.tabs[ui_state.active].items or {}
  if not is_grid_tab(ui_state.tabs[ui_state.active]) then
    ui_state.selected = menu_view_util.clamp_selected(ui_state.selected, #active_items)
  end
  -- 最新の内容に合わせてメニュー表示を再描画する。
  render()
end
local function select(tabs, opts, config)
  close()
  if not tabs or #tabs == 0 then return end
  -- タブ付きメニューの状態を初期化して表示する。
  ui_state.prev_win = vim.api.nvim_get_current_win()
  ui_state.tabs = tabs
  ui_state.opts = opts or {}
  ui_state.config = config or {}
  local active = ui_state.opts.active or 1
  if ui_state.opts.active_id then
    for index, tab in ipairs(tabs) do
      if tab.id == ui_state.opts.active_id then active = index break end
    end
  end
  ui_state.active = menu_view_util.clamp_selected(active, #tabs)
  ui_state.selected = 1
  ui_state.offset = 0
  ui_state.on_close = ui_state.opts.on_close
  render()
  local buf = ui_state.buf
  if buf then set_keymaps(buf) end
end
M.select = select
M.update = update
M.close = close
return M
