-- このモジュールは戦闘時の敵生成とダメージ計算を提供する。
-- 階層計算はgame/floor/progressに委譲して整理する。
local content = require("idle_dungeon.content")
local floor_progress = require("idle_dungeon.game.floor.progress")
local M = {}

-- 設定のIDから図鑑用の表示名を解決する。
local function resolve_enemy_name(enemy_id)
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.id == enemy_id then
      return enemy.name_en or enemy.name_ja or enemy.id
    end
  end
  return enemy_id
end

local function build_enemy(distance, config)
  local names = config.enemy_names or { "a" }
  local index = (distance % #names) + 1
  local enemy_id = names[index]
  -- 階層数を基準に敵の成長を計算する。
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local floor_index = floor_progress.floor_index(distance or 0, floor_length)
  local growth = floor_index
  local battle = config.battle or { enemy_hp = 5, enemy_atk = 1 }
  return {
    id = enemy_id,
    name = resolve_enemy_name(enemy_id),
    hp = battle.enemy_hp + growth,
    -- 最大体力を保持して表示に使う。
    max_hp = battle.enemy_hp + growth,
    atk = battle.enemy_atk + math.floor(growth / 2),
    def = math.floor(growth / 3),
  }
end

local function calc_damage(atk, def)
  return math.max(1, atk - def)
end

M.build_enemy = build_enemy
M.calc_damage = calc_damage

return M
