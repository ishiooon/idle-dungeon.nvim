-- このモジュールはUIの既定設定を提供する。
local menu_theme = require("idle_dungeon.menu.theme")

local M = {}

local function default_ui()
  return {
    width = 40,
    -- 表示は2行を既定とし、最大2行に制限する。
    height = 2,
    max_height = 2,
    -- 進行トラックは少し短めにして右下の表示密度を抑える。
    track_length = 32,
    render_mode = "visual",
    auto_start = true,
    language = "en",
    languages = { "en", "ja" },
    -- 進行トラックの埋め文字を指定する。
    track_fill = ".",
    -- 表示に使うアイコンを定義する。
    icons = {
      hero = "",
      enemy = "",
      boss = "",
      separator = ">",
      -- 右下の情報表示に使うアイコンを追加する。
      hp = "",
      gold = "",
      exp = "",
    },
    -- 表示はアイコンを優先し、文字スプライトは補助扱いにする。
    icons_only = true,
    -- スプライトの色味をキャラクターや敵ごとに定義する。
    sprite_palette = {
      default_hero = { fg = "#B7E5FF" },
      default_enemy = { fg = "#FFD6D6" },
      boss = { fg = "#FF6B6B" },
      element_normal = { fg = "#CBD5E1" },
      element_fire = { fg = "#FB923C" },
      element_water = { fg = "#38BDF8" },
      element_grass = { fg = "#4ADE80" },
      element_light = { fg = "#FDE047" },
      element_dark = { fg = "#A78BFA" },
      recorder = { fg = "#A8E5FF" },
      guardian = { fg = "#D8D8D8" },
      hunter = { fg = "#C7FF9A" },
      alchemist = { fg = "#F3C2FF" },
      -- ノーマル属性は敵IDの色味を使い、それ以外は属性色を使う。
      -- 敵の色味は主要な種類だけを定義して識別しやすくする。
      dust_slime = { fg = "#FFD18A" },
      tux_penguin = { fg = "#A9D8FF" },
      vim_mantis = { fg = "#C3FF8A" },
      c_sentinel = { fg = "#D1D5DB" },
      cpp_colossus = { fg = "#93C5FD" },
      php_elephant = { fg = "#C6C1FF" },
      docker_whale = { fg = "#7DD3FC" },
      go_gopher = { fg = "#FCA5A5" },
      bash_hound = { fg = "#E5E7EB" },
      mysql_dolphin = { fg = "#60A5FA" },
      postgres_colossus = { fg = "#94A3B8" },
      dbeaver = { fg = "#B0F2C2" },
      ruby_scarab = { fg = "#FCA5C4" },
      clojure_oracle = { fg = "#FDBA74" },
      node_phantom = { fg = "#86EFAC" },
      python_serpent = { fg = "#9CA3AF" },
      java_ifrit = { fg = "#FDBA74" },
      kotlin_fox = { fg = "#F9A8D4" },
      swift_raptor = { fg = "#FCD34D" },
      git_wyrm = { fg = "#F97316" },
      rust_crab = { fg = "#FB7185" },
      gnu_bison = { fg = "#E2E8F0" },
    },
    -- 勇者と敵のドットスプライト表示を設定する。
    sprites = {
      enabled = true,
      frame_seconds = 1,
      show_hero_on_track = true,
      show_enemy_on_track = true,
    },
    -- 画像スプライト設定は廃止したため保持しない。
    -- 中央メニューの表示設定をまとめる。
    menu = {
      width_ratio = 0.72,
      height_ratio = 0.78,
      min_width = 72,
      min_height = 24,
      max_width = 120,
      max_height = 32,
      padding = 2,
      border = "rounded",
      tabs_position = "top",
      -- タブ表示のスタイルを調整する。
      tabs = {
        separator = " │ ",
        active_prefix = "[",
        active_suffix = "]",
        show_index = true,
        icons = {
          status = "󰨇",
          actions = "",
          config = "",
          dex = "󰈔",
          credits = "󰈖",
        },
      },
      -- 項目表示の見た目を整える記号を定義する。
      item_prefix = "  • ",
      section_prefix = "◆ ",
      empty_prefix = "  · ",
      theme = menu_theme.default_theme(),
    },
  }
end

M.default_ui = default_ui

return M
