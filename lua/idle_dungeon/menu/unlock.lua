-- このモジュールは解放条件の表示整形を担当する。

local i18n = require("idle_dungeon.i18n")
local time_format = require("idle_dungeon.ui.time_format")

local M = {}

-- 装備ごとの解放条件を抽出して返す。
local function resolve_unlock_rules(config, item)
  local rules = {}
  local unlock_rules = (config or {}).unlock_rules or {}
  for _, rule in ipairs(unlock_rules) do
    if rule.target == "items" and item and rule.id == item.id then
      table.insert(rules, rule)
    end
  end
  return rules
end

-- 解放条件の進行度を行配列へ整形して返す。
local function build_unlock_lines(item, state, config, lang)
  local rules = resolve_unlock_rules(config, item)
  if #rules == 0 then
    return { i18n.t("unlock_none", lang) }
  end
  local metrics = (state or {}).metrics or {}
  local lines = {}
  for _, rule in ipairs(rules) do
    local required = rule.value or 0
    if rule.kind == "chars" then
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_chars", lang), metrics.chars or 0, required))
    elseif rule.kind == "saves" then
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_saves", lang), metrics.saves or 0, required))
    elseif rule.kind == "time_sec" then
      local current = time_format.format_seconds(metrics.time_sec or 0, lang)
      local required_text = time_format.format_seconds(required, lang)
      table.insert(lines, string.format("%s %s/%s", i18n.t("unlock_time", lang), current, required_text))
    elseif rule.kind == "filetype_chars" then
      local filetype = rule.filetype or ""
      local count = ((metrics.filetypes or {})[filetype]) or 0
      local label = string.format(i18n.t("unlock_filetype", lang), filetype)
      table.insert(lines, string.format("%s %d/%d", label, count, required))
    else
      table.insert(lines, string.format("%s %d/%d", i18n.t("unlock_unknown", lang), 0, required))
    end
  end
  return lines
end

-- 解放条件の見出しと内容をまとめて返す。
local function build_unlock_section(item, state, config, lang)
  local lines = build_unlock_lines(item, state, config, lang)
  if #lines == 0 then
    return {}
  end
  local result = { i18n.t("unlock_title", lang) }
  for _, line in ipairs(lines) do
    table.insert(result, line)
  end
  return result
end

M.build_unlock_lines = build_unlock_lines
M.build_unlock_section = build_unlock_section

return M
