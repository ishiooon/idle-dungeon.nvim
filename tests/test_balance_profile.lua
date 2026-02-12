-- このテストはバランス定義が1箇所へ集約されていることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local balance = require("idle_dungeon.game.balance")
local stages = require("idle_dungeon.config.stages")

local hero = balance.hero_profile()
assert_true(type(hero) == "table", "勇者の成長定義が取得できる")
assert_true(type(hero.growth) == "table", "勇者の成長率が定義される")
assert_true(type(hero.default_next_level) == "number", "勇者の初期必要経験値が定義される")

local stage_profiles = balance.stage_profiles()
assert_true(type(stage_profiles) == "table", "ステージ補正の一覧が取得できる")
assert_true(type(stage_profiles[1]) == "table", "ステージ1の補正が定義される")
assert_true(type(stage_profiles[1].enemy) == "table", "ステージ1の敵補正が定義される")
assert_true(type(stage_profiles[1].reward) == "table", "ステージ1の報酬補正が定義される")

for _, stage in ipairs(stages.default_stages() or {}) do
  assert_true(stage.enemy_tuning == nil, "ステージ定義には敵補正を持たせずバランス定義へ集約する")
end

print("OK")
