-- このモジュールは階層ごとの遭遇状態を純粋関数で生成する。
-- 同じ階層配下のprogressを参照する。
local enemies = require("idle_dungeon.game.floor.enemies")
local floor_progress = require("idle_dungeon.game.floor.progress")
local util = require("idle_dungeon.util")

local M = {}

local function build_floor_state(progress, config, floor_index)
  local floor_length = floor_progress.resolve_floor_length(config)
  -- 敵の配置生成は専用モジュールに委譲して読みやすさを保つ。
  local floor_enemies, next_seed = enemies.build_floor_enemies(progress, config, floor_length)
  local floor_number = floor_index + 1
  local boss_every = progress.boss_every or config.boss_every or 0
  local boss_pending = boss_every > 0 and floor_number % boss_every == 0
  return util.merge_tables(progress, {
    floor_index = floor_index,
    floor_enemies = floor_enemies,
    floor_encounters_total = #floor_enemies,
    floor_encounters_remaining = #floor_enemies,
    floor_boss_pending = boss_pending,
    rng_seed = next_seed,
  })
end

local function refresh(progress, config)
  local floor_length = floor_progress.resolve_floor_length(config)
  local current_index = floor_progress.floor_index(progress.distance or 0, floor_length)
  if progress.floor_index == current_index
    and progress.floor_enemies ~= nil
    and progress.floor_encounters_total ~= nil
    and progress.floor_encounters_remaining ~= nil
    and progress.floor_boss_pending ~= nil then
    return progress
  end
  return build_floor_state(progress, config, current_index)
end

local function find_enemy_ahead(progress, step)
  local target = (step or 0) + 2
  for _, enemy in ipairs(progress.floor_enemies or {}) do
    if not enemy.defeated and enemy.position == target then
      return enemy
    end
  end
  return nil
end

local function mark_enemy_defeated(progress, enemy)
  if not enemy then
    return progress
  end
  local updated = {}
  local remaining = 0
  for _, entry in ipairs(progress.floor_enemies or {}) do
    if entry.position == enemy.position
      and entry.id == enemy.id
      and (entry.element or "normal") == (enemy.element or "normal") then
      table.insert(updated, util.merge_tables(entry, { defeated = true }))
    else
      table.insert(updated, entry)
    end
  end
  for _, entry in ipairs(updated) do
    if not entry.defeated then
      remaining = remaining + 1
    end
  end
  return util.merge_tables(progress, { floor_enemies = updated, floor_encounters_remaining = remaining })
end

local function clear_boss_pending(progress)
  if not progress.floor_boss_pending then
    return progress
  end
  return util.merge_tables(progress, { floor_boss_pending = false })
end

M.refresh = refresh
M.find_enemy_ahead = find_enemy_ahead
M.mark_enemy_defeated = mark_enemy_defeated
M.clear_boss_pending = clear_boss_pending

return M
