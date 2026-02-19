-- このモジュールはメニュー関連の操作ログを整形して追記する純粋関数を提供する。

local game_log = require("idle_dungeon.game.log")
local log_format = require("idle_dungeon.game.log_format")

local M = {}

local function is_ja_lang(lang)
  return lang == "ja" or lang == "jp"
end

-- ログ本文が空行にならないように正規化する。
local function normalize_text(text)
  local value = tostring(text or "")
  if value == "" then
    return nil
  end
  return value
end

-- 装備名は言語設定に応じた優先順で解決する。
local function resolve_item_name(item, lang)
  if type(item) ~= "table" then
    return "-"
  end
  if lang == "en" then
    return item.name_en or item.name or item.id or "-"
  end
  return item.name or item.name_en or item.id or "-"
end

-- 言語設定に応じてログ本文を選択する。
local function resolve_localized_text(lang, ja_text, en_text)
  if is_ja_lang(lang) then
    return tostring(ja_text or "")
  end
  return tostring(en_text or ja_text or "")
end

-- メニュー操作ログを経過秒付きで追記する。
local function append(state, text)
  local safe_text = normalize_text(text)
  if not safe_text then
    return state
  end
  -- ログタブでカテゴリ表示できるよう、メニュー操作には明示タグを付与する。
  local line = log_format.build_line(safe_text, "MENU")
  return game_log.append(state, line)
end

-- 言語設定に応じた本文でメニュー操作ログを追記する。
local function append_localized(state, lang, ja_text, en_text)
  return append(state, resolve_localized_text(lang, ja_text, en_text))
end

M.append = append
M.append_localized = append_localized
M.is_ja_lang = is_ja_lang
M.resolve_item_name = resolve_item_name
M.resolve_localized_text = resolve_localized_text

return M
