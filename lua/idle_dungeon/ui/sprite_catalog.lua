-- このモジュールはジョブと敵の定義参照を提供する。

local content = require("idle_dungeon.content")

local M = {}

local function find_job(actor_id)
  for _, job in ipairs(content.jobs or {}) do
    if job.id == actor_id then
      return job
    end
  end
  return nil
end

local function find_enemy(enemy_id)
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.id == enemy_id then
      return enemy
    end
  end
  return nil
end

-- ジョブ参照はスプライト色分けにのみ利用する。
M.find_job = find_job
M.find_enemy = find_enemy

return M
