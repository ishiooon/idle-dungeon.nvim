-- このモジュールはメニュー表示用のウィンドウ操作をまとめる。

local M = {}

local namespace = vim.api.nvim_create_namespace("IdleDungeonMenu")

local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function ensure_highlights()
  -- メニュー表示用のハイライトを定義して視認性を保つ。
  vim.api.nvim_set_hl(0, "IdleDungeonMenuTitle", { link = "Title" })
  vim.api.nvim_set_hl(0, "IdleDungeonMenuSelected", { link = "Visual" })
end

local function calculate_center(height, width)
  local lines = vim.o.lines
  local columns = vim.o.columns
  local cmdheight = vim.o.cmdheight
  local row = math.max(math.floor((lines - cmdheight - height) / 2), 0)
  local col = math.max(math.floor((columns - width) / 2), 0)
  return row, col
end

local function open_window(height, width, border)
  -- 新しいバッファと浮動ウィンドウを作成してメニューを表示する。
  ensure_highlights()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  local row, col = calculate_center(height, width)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = border,
    focusable = true,
    noautocmd = true,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })
  vim.api.nvim_set_option_value("cursorlineopt", "line", { win = win })
  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:IdleDungeonMenuSelected", { win = win })
  return win, buf
end

local function ensure_window(win, buf, height, width, border)
  if is_valid_window(win) and is_valid_buffer(buf) then
    return win, buf
  end
  -- 既存の表示が無い場合は新規ウィンドウを作る。
  return open_window(height, width, border)
end

local function update_window(win, height, width)
  local row, col = calculate_center(height, width)
  -- 画面サイズ変更に追従して中央位置を更新する。
  vim.api.nvim_win_set_config(win, { relative = "editor", row = row, col = col, width = width, height = height })
end

local function set_lines(buf, lines)
  -- バッファの内容を更新してメニュー表示を反映する。
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function apply_highlights(buf, lines)
  -- ハイライトを更新して見出し行を強調する。
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if type(lines) == "table" then
    for _, line in ipairs(lines) do
      if line then
        vim.api.nvim_buf_add_highlight(buf, namespace, "IdleDungeonMenuTitle", line - 1, 0, -1)
      end
    end
    return
  end
  if lines then
    vim.api.nvim_buf_add_highlight(buf, namespace, "IdleDungeonMenuTitle", lines - 1, 0, -1)
  end
end

local function close_window(win, prev_win)
  if is_valid_window(win) then
    -- メニュー表示を終了し、開く前のウィンドウへ戻す。
    vim.api.nvim_win_close(win, true)
  end
  if prev_win and is_valid_window(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

M.ensure_window = ensure_window
M.update_window = update_window
M.set_lines = set_lines
M.apply_highlights = apply_highlights
M.close_window = close_window
M.is_valid_window = is_valid_window
M.is_valid_buffer = is_valid_buffer

return M
