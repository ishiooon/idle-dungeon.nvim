-- このテストはステージ1の敵が極端に弱くならないように基準値を確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_false(value, message)
  if value then
    error(message or "assert_false failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local stages = require("idle_dungeon.config.stages")

local function find_enemy(enemies, enemy_id)
  for _, enemy in ipairs(enemies or {}) do
    if enemy.id == enemy_id then
      return enemy
    end
  end
  return nil
end

local function find_item(items, item_id)
  for _, item in ipairs(items or {}) do
    if item.id == item_id then
      return item
    end
  end
  return nil
end

local stage1 = (stages.default_stages() or {})[1] or {}
local pool = stage1.enemy_pool or {}
local ids = {}
for _, entry in ipairs(pool.fixed or {}) do
  ids[entry] = true
end
for _, entry in ipairs(pool.mixed or {}) do
  ids[entry] = true
end

-- 序盤はスライムと動物系の敵で固め、マンティス系は出さない。
local allowed_stage1_ids = {
  dust_slime = true,
  tux_penguin = true,
  penguin_tide = true,
  penguin_ember = true,
  penguin_moss = true,
  penguin_lumen = true,
  penguin_umbral = true,
  go_gopher = true,
  bash_hound = true,
}

for enemy_id, _ in pairs(ids) do
  assert_false(enemy_id:match("mantis"), "序盤ステージにマンティス系を含めない: " .. enemy_id)
  assert_false(enemy_id == "c_sentinel", "序盤ステージに非動物系センチネルを含めない")
  assert_false(enemy_id == "prism_slime", "序盤ステージに大量経験値のレアスライムを含めない")
  assert_true(allowed_stage1_ids[enemy_id] == true, "序盤ステージの敵IDはスライム/動物系に限定する: " .. enemy_id)
  local enemy = find_enemy(content.enemies or {}, enemy_id)
  assert_true(enemy ~= nil, "ステージ1の敵が定義されている: " .. enemy_id)
  local hp = (enemy.stats or {}).hp or 0
  local exp_multiplier = tonumber(enemy.exp_multiplier) or 1
  assert_true(hp >= 6, "ステージ1の敵HPは6以上である: " .. enemy_id)
  assert_true(exp_multiplier <= 2, "ステージ1の敵経験値倍率は2以下に抑える: " .. enemy_id)
end

assert_true(ids.dust_slime == true, "序盤ステージにスライム系が含まれる")
assert_true(ids.tux_penguin == true, "序盤ステージに動物系が含まれる")
assert_true(ids.go_gopher == true, "序盤ステージに追加した動物系ゴーファーが含まれる")
assert_true(ids.bash_hound == true, "序盤ステージに追加した動物系ハウンドが含まれる")

local bow = find_item(content.items or {}, "short_bow")
assert_true(bow ~= nil, "short_bow が定義されている")
assert_true((bow.atk or 0) <= 2, "short_bow の攻撃力は抑えめである")

print("OK")
