-- このモジュールは状態に図鑑データを反映する純粋関数を提供する。
-- 図鑑の本体はgame/dexへ集約する。
local dex = require("idle_dungeon.game.dex")
local util = require("idle_dungeon.util")

local M = {}

-- 状態に図鑑が無い場合は空の図鑑を用意する。
local function ensure_dex(state)
  local current = state.dex or dex.new_dex()
  return current
end

-- 記録時刻として使う経過秒を取り出す。
local function time_sec(state)
  return (state.metrics or {}).time_sec or 0
end

-- 図鑑データを状態へ反映する。
local function with_dex(state, next_dex)
  return util.merge_tables(state, { dex = next_dex })
end

-- 初期所持品を図鑑へ反映する。
local function apply_inventory_initial(state, inventory)
  local next_dex = dex.new_dex()
  for item_id, count in pairs(inventory or {}) do
    next_dex = dex.record_item(next_dex, item_id, count, 0)
  end
  return with_dex(state, next_dex)
end

-- 所持品の増分だけ図鑑へ反映する。
local function apply_inventory_delta(state, previous_inventory, next_inventory)
  local next_dex = ensure_dex(state)
  local now = time_sec(state)
  for item_id, count in pairs(next_inventory or {}) do
    local before = (previous_inventory or {})[item_id] or 0
    if count > before then
      next_dex = dex.record_item(next_dex, item_id, count - before, now)
    end
  end
  return with_dex(state, next_dex)
end

-- 装備の取得を図鑑へ記録する。
local function record_item(state, item_id, count)
  local next_dex = dex.record_item(ensure_dex(state), item_id, count, time_sec(state))
  return with_dex(state, next_dex)
end

-- 敵との遭遇を図鑑へ記録する。
local function record_enemy(state, enemy_id, element)
  local next_dex = dex.record_enemy(ensure_dex(state), enemy_id, element, time_sec(state))
  return with_dex(state, next_dex)
end

M.apply_inventory_initial = apply_inventory_initial
M.apply_inventory_delta = apply_inventory_delta
M.record_item = record_item
M.record_enemy = record_enemy

return M
