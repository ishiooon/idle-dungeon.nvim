-- このモジュールは実績条件に応じて解放状態を更新する。

local util = require("idle_dungeon.util")

local M = {}

local function meets_rule(metrics, rule)
  if rule.kind == "chars" then
    return (metrics.chars or 0) >= rule.value
  end
  if rule.kind == "saves" then
    return (metrics.saves or 0) >= rule.value
  end
  if rule.kind == "time_sec" then
    return (metrics.time_sec or 0) >= rule.value
  end
  if rule.kind == "filetype_chars" then
    local count = (metrics.filetypes or {})[rule.filetype] or 0
    return count >= rule.value
  end
  return false
end

local function apply_rules(unlocks, metrics, rules)
  local result = util.merge_tables(unlocks, {})
  for _, rule in ipairs(rules or {}) do
    if meets_rule(metrics, rule) then
      local target = result[rule.target] or {}
      local next_target = util.shallow_copy(target)
      next_target[rule.id] = true
      result[rule.target] = next_target
    end
  end
  return result
end

M.apply_rules = apply_rules

return M
