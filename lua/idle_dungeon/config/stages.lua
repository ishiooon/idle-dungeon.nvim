-- このモジュールはステージの既定設定を提供する。

local M = {}

local function default_stages()
  return {
    {
      id = 1,
      name = "dungeon1",
      floors = 6,
      boss_every = 10,
      -- 初期は固定枠を多めにして基礎敵を覚えやすくする。
      enemy_pool = { fixed = { "dust_slime", "cave_bat", "frost_penguin" }, mixed = { "moss_goblin" }, fixed_ratio = 85 },
    },
    {
      id = 2,
      name = "dungeon2",
      floors = 7,
      boss_every = 10,
      -- 固定と混合の比率を少し下げ、種類を増やす。
      enemy_pool = { fixed = { "moss_goblin", "php_elephant" }, mixed = { "cave_bat", "ember_wisp", "frost_penguin" }, fixed_ratio = 70 },
    },
    {
      id = 3,
      name = "dungeon3",
      floors = 8,
      boss_every = 10,
      enemy_pool = { fixed = { "ember_wisp", "dbeaver" }, mixed = { "tidal_urchin", "moss_goblin", "go_gopher" }, fixed_ratio = 60 },
    },
    {
      id = 4,
      name = "dungeon4",
      floors = 9,
      boss_every = 10,
      enemy_pool = { fixed = { "tidal_urchin", "go_gopher" }, mixed = { "ember_wisp", "python_serpent" }, fixed_ratio = 55 },
    },
    {
      id = 5,
      name = "dungeon5",
      floors = 10,
      boss_every = 10,
      enemy_pool = { fixed = { "python_serpent", "shade_wraith" }, mixed = { "tidal_urchin", "rust_crab" }, fixed_ratio = 50 },
    },
    {
      id = 6,
      name = "dungeon6",
      floors = 11,
      boss_every = 10,
      enemy_pool = { fixed = { "shade_wraith", "rust_crab" }, mixed = { "python_serpent", "dbeaver" }, fixed_ratio = 45 },
    },
    {
      id = 7,
      name = "dungeon7",
      floors = 12,
      boss_every = 10,
      enemy_pool = { fixed = { "rust_crab", "shade_wraith" }, mixed = { "go_gopher", "tidal_urchin", "python_serpent" }, fixed_ratio = 40 },
    },
    -- 無限に進み続けるラストダンジョンの設定。
    {
      id = 8,
      name = "last-dungeon",
      floors = 14,
      infinite = true,
      boss_every = 10,
      enemy_pool = { fixed = { "shade_wraith", "rust_crab", "python_serpent" }, mixed = { "tidal_urchin", "dbeaver", "go_gopher", "ember_wisp" }, fixed_ratio = 35 },
    },
  }
end

M.default_stages = default_stages

return M
