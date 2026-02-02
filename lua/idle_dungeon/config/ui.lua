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
      dust_slime = { fg = "#FFD18A" },
      cave_bat = { fg = "#B7A7FF" },
      moss_goblin = { fg = "#A4FFB5" },
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
