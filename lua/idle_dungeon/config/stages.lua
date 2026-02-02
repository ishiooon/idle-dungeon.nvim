-- このモジュールはステージの既定設定を提供する。

local M = {}

local function default_stages()
  return {
    {
      id = 1,
      name = "Glacier Command",
      floors = 6,
      boss_every = 10,
      boss_id = "boss_ice_regent",
      -- 初期は固定枠を多めにして基礎敵を覚えやすくする。
      enemy_pool = {
        fixed = { "dust_slime", "tux_penguin", "vim_mantis", "c_sentinel" },
        mixed = { "php_elephant" },
        fixed_ratio = 85,
      },
    },
    {
      id = 2,
      name = "Whale Dock",
      floors = 7,
      boss_every = 10,
      boss_id = "boss_docker_leviathan",
      -- 固定と混合の比率を少し下げ、種類を増やす。
      enemy_pool = {
        fixed = { "php_elephant", "docker_whale", "go_gopher" },
        mixed = { "bash_hound", "mysql_dolphin" },
        fixed_ratio = 70,
      },
    },
    {
      id = 3,
      name = "Dataflow Dam",
      floors = 8,
      boss_every = 10,
      boss_id = "boss_ruby_empress",
      enemy_pool = {
        fixed = { "dbeaver", "ruby_scarab", "node_phantom" },
        mixed = { "mysql_dolphin", "clojure_oracle" },
        fixed_ratio = 60,
      },
    },
    {
      id = 4,
      name = "Script Coil",
      floors = 9,
      boss_every = 10,
      boss_id = "boss_python_prime",
      enemy_pool = {
        fixed = { "python_serpent", "java_ifrit", "kotlin_fox" },
        mixed = { "swift_raptor", "git_wyrm" },
        fixed_ratio = 55,
      },
    },
    {
      id = 5,
      name = "Rust Oath Forge",
      floors = 10,
      boss_every = 10,
      boss_id = "boss_git_overlord",
      enemy_pool = {
        fixed = { "rust_crab", "gnu_bison", "postgres_colossus" },
        mixed = { "git_wyrm", "java_ifrit" },
        fixed_ratio = 50,
      },
    },
    {
      id = 6,
      name = "Twin Compiler Citadel",
      floors = 11,
      boss_every = 10,
      boss_id = "boss_rust_juggernaut",
      enemy_pool = {
        fixed = { "cpp_colossus", "c_sentinel", "bash_hound" },
        mixed = { "node_phantom", "python_serpent" },
        fixed_ratio = 45,
      },
    },
    {
      id = 7,
      name = "Ancestral Stampede",
      floors = 12,
      boss_every = 10,
      boss_id = "boss_gnu_ancestral",
      enemy_pool = {
        fixed = { "swift_raptor", "kotlin_fox", "git_wyrm" },
        mixed = { "rust_crab", "postgres_colossus" },
        fixed_ratio = 40,
      },
    },
    -- 無限に進み続けるラストダンジョンの設定。
    {
      id = 8,
      name = "Null Horizon",
      floors = 14,
      infinite = true,
      boss_every = 10,
      boss_id = "boss_null_horizon",
      enemy_pool = {
        fixed = { "rust_crab", "git_wyrm", "python_serpent", "java_ifrit" },
        mixed = { "gnu_bison", "cpp_colossus", "clojure_oracle", "node_phantom", "docker_whale" },
        fixed_ratio = 35,
      },
    },
  }
end

M.default_stages = default_stages

return M
