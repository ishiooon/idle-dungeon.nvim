-- このモジュールはステージの既定設定を提供する。

local M = {}

local function default_stages()
  return {
    {
      id = 1,
      name = { en = "Glacier Command", ja = "初手の氷回廊" },
      floors = 6,
      boss_every = 10,
      boss_id = "boss_ice_regent",
      -- 初期は固定枠を多めにして基礎敵を覚えやすくする。
      -- 低階層はペンギンとマンティスの派生を中心にして役割を学びやすくする。
      enemy_pool = {
        fixed = { "dust_slime", "tux_penguin", "vim_mantis", "penguin_tide", "mantis_mist" },
        mixed = {
          "penguin_ember",
          "penguin_moss",
          "penguin_lumen",
          "penguin_umbral",
          "mantis_blaze",
          "mantis_verdant",
          "mantis_radiant",
          "mantis_gloom",
          "c_sentinel",
        },
        fixed_ratio = 85,
      },
    },
    {
      id = 2,
      name = { en = "Whale Dock", ja = "温路の鯨湾" },
      floors = 7,
      boss_every = 10,
      boss_id = "boss_docker_leviathan",
      -- 固定と混合の比率を少し下げ、種類を増やす。
      enemy_pool = {
        fixed = { "docker_whale", "go_gopher", "whale_rill", "gopher_cinder", "whale_pyre" },
        mixed = {
          "whale_sprout",
          "whale_halo",
          "whale_shade",
          "gopher_surge",
          "gopher_bloom",
          "gopher_dawn",
          "gopher_dusk",
          "bash_hound",
          "mysql_dolphin",
        },
        fixed_ratio = 70,
      },
    },
    {
      id = 3,
      name = { en = "Dataflow Dam", ja = "流路のビーバー堤" },
      floors = 8,
      boss_every = 10,
      boss_id = "boss_ruby_empress",
      enemy_pool = {
        fixed = { "php_elephant", "dbeaver", "ruby_scarab", "elephant_grove", "scarab_lumen" },
        mixed = {
          "elephant_sear",
          "elephant_abyss",
          "elephant_aurora",
          "elephant_void",
          "scarab_ember",
          "scarab_tide",
          "scarab_moss",
          "scarab_umbral",
          "mysql_dolphin",
          "clojure_oracle",
        },
        fixed_ratio = 60,
      },
    },
    {
      id = 4,
      name = { en = "Script Coil", ja = "スクリプトの蛇環" },
      floors = 9,
      boss_every = 10,
      boss_id = "boss_python_prime",
      enemy_pool = {
        fixed = {
          "python_serpent",
          "kotlin_fox",
          "serpent_verdant",
          "serpent_radiant",
          "fox_sprout",
          "fox_halo",
        },
        mixed = {
          "serpent_blaze",
          "serpent_mist",
          "serpent_gloom",
          "fox_pyre",
          "fox_rill",
          "fox_shade",
          "swift_raptor",
          "git_wyrm",
          "java_ifrit",
        },
        fixed_ratio = 55,
      },
    },
    {
      id = 5,
      name = { en = "Rust Oath Forge", ja = "錆誓の鍛冶炉" },
      floors = 10,
      boss_every = 10,
      boss_id = "boss_git_overlord",
      enemy_pool = {
        fixed = { "rust_crab", "gnu_bison", "crab_cinder", "crab_surge", "bison_sear" },
        mixed = {
          "crab_bloom",
          "crab_dawn",
          "crab_dusk",
          "bison_grove",
          "bison_aurora",
          "bison_abyss",
          "bison_void",
          "postgres_colossus",
          "git_wyrm",
        },
        fixed_ratio = 50,
      },
    },
    {
      id = 6,
      name = { en = "Twin Compiler Citadel", ja = "双コンパイラの城砦" },
      floors = 11,
      boss_every = 10,
      boss_id = "boss_rust_juggernaut",
      enemy_pool = {
        fixed = { "cpp_colossus", "c_sentinel", "bash_hound", "serpent_blaze", "fox_pyre" },
        mixed = {
          "node_phantom",
          "python_serpent",
          "serpent_radiant",
          "fox_halo",
          "crab_surge",
          "bison_grove",
        },
        fixed_ratio = 45,
      },
    },
    {
      id = 7,
      name = { en = "Ancestral Stampede", ja = "祖霊の踏圧" },
      floors = 12,
      boss_every = 10,
      boss_id = "boss_gnu_ancestral",
      enemy_pool = {
        fixed = { "rust_crab", "gnu_bison", "crab_cinder", "bison_aurora", "git_wyrm" },
        mixed = {
          "crab_bloom",
          "crab_dusk",
          "bison_abyss",
          "bison_void",
          "postgres_colossus",
          "swift_raptor",
        },
        fixed_ratio = 40,
      },
    },
    -- 無限に進み続けるラストダンジョンの設定。
    {
      id = 8,
      name = { en = "Null Horizon", ja = "終端ヌルホライゾン" },
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
