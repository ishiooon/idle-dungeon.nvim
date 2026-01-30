-- このモジュールは表示用の状態を組み立てる純粋関数を提供する。

local util = require("idle_dungeon.util")

local M = {}

local function with_read_only(state, is_owner)
  if not state then
    return nil
  end
  local read_only = not (is_owner == true)
  local current = state.ui and state.ui.read_only or false
  if current == read_only then
    return state
  end
  return util.merge_tables(state, { ui = util.merge_tables(state.ui or {}, { read_only = read_only }) })
end

M.with_read_only = with_read_only

return M
