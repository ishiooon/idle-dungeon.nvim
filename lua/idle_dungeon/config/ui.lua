-- このモジュールはUIの既定設定を提供する。
local menu_theme = require("idle_dungeon.menu.theme")
local icon_module = require("idle_dungeon.ui.icon")

local M = {}

local function default_ui()
  return {
    width = 40,
    -- 表示は2行を既定とし、最大2行に制限する。
    height = 2,
    max_height = 2,
    -- 戦闘中のHP分母表示は既定で隠す。
    battle_hp_show_max = false,
    -- 進行トラックは少し短めにして右下の表示密度を抑える。
    track_length = 32,
    render_mode = "visual",
    auto_start = true,
    language = "en",
    languages = { "en", "ja" },
    -- 進行トラックの埋め文字を指定する。
    track_fill = ".",
    -- 表示に使うアイコンは専用モジュールの既定値を採用する。
    icons = icon_module.default_icons(),
    -- 表示はアイコンを優先し、文字スプライトは補助扱いにする。
    icons_only = true,
    -- スプライトの色味はgruvbox-material系に寄せて全体を落ち着かせる。
    sprite_palette = {
      default_hero = { fg = "#d8a657" },
      default_enemy = { fg = "#ea6962" },
      boss = { fg = "#ea6962" },
      element_normal = { fg = "#d4be98" },
      element_fire = { fg = "#ea6962" },
      element_water = { fg = "#89b482" },
      element_grass = { fg = "#a9b665" },
      element_light = { fg = "#d8a657" },
      element_dark = { fg = "#d3869b" },
      recorder = { fg = "#d8a657" },
      guardian = { fg = "#bdae93" },
      hunter = { fg = "#a9b665" },
      alchemist = { fg = "#d3869b" },
      -- ノーマル属性は敵IDの色味を使い、それ以外は属性色を使う。
      -- 敵の色味は主要な種類だけを定義して識別しやすくする。
      dust_slime = { fg = "#d8a657" },
      tux_penguin = { fg = "#7daea3" },
      vim_mantis = { fg = "#a9b665" },
      c_sentinel = { fg = "#928374" },
      cpp_colossus = { fg = "#7daea3" },
      php_elephant = { fg = "#d3869b" },
      docker_whale = { fg = "#89b482" },
      go_gopher = { fg = "#ea6962" },
      bash_hound = { fg = "#bdae93" },
      mysql_dolphin = { fg = "#89b482" },
      postgres_colossus = { fg = "#928374" },
      dbeaver = { fg = "#a9b665" },
      ruby_scarab = { fg = "#ea6962" },
      clojure_oracle = { fg = "#e78a4e" },
      node_phantom = { fg = "#a9b665" },
      python_serpent = { fg = "#7c6f64" },
      java_ifrit = { fg = "#e78a4e" },
      kotlin_fox = { fg = "#d3869b" },
      swift_raptor = { fg = "#d8a657" },
      git_wyrm = { fg = "#e78a4e" },
      rust_crab = { fg = "#ea6962" },
      gnu_bison = { fg = "#d4be98" },
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
      width_ratio = 0.52,
      height_ratio = 0.56,
      min_width = 52,
      min_height = 16,
      max_width = 68,
      max_height = 26,
      padding = 2,
      border = "none",
      tabs_position = "top",
      -- タブ表示のスタイルを調整する。
      tabs = {
        separator = " 󰇙 ",
        active_prefix = "󰐊",
        active_suffix = "",
        show_index = false,
        icons = {
          status = "󰍉",
          actions = "󱎫",
          config = "󰒓",
          dex = "󰈔",
          credits = "󰨭",
        },
      },
      -- 進行バーはtriforce風に縦棒を使って視認性を上げる。
      meter = {
        on = "▬",
        off = "▭",
      },
      -- 項目表示の見た目を整える記号を定義する。
      item_prefix = "󰜴 ",
      section_prefix = "󰉖 ",
      empty_prefix = "󰇘 ",
      theme = menu_theme.default_theme(),
    },
  }
end

M.default_ui = default_ui

return M
