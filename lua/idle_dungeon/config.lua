-- このモジュールは設定の既定値と結合処理を提供する。

local content = require("idle_dungeon.content")
local util = require("idle_dungeon.util")

local M = {}

local function build_event_distances()
  local distances = {}
  for _, event in ipairs(content.events) do
    if event.stage_id then
      table.insert(distances, { stage_id = event.stage_id, distance = event.distance })
    else
      table.insert(distances, event.distance)
    end
  end
  return distances
end

local function default_config()
  return {
    tick_seconds = 1,
    move_step = 1,
    encounter_every = 5,
    -- 会話の待機時間は0秒とし、進行の停止を発生させない。
    dialogue_seconds = 0,
    -- 左から右までの歩幅を1階層として扱う。
    floor_length = 18,
    -- 階層ごとの遭遇数を1〜5体で設定する。
    floor_encounters = { min = 1, max = 5 },
    -- ボスは10階層ごとに出現する。
    boss_every = 10,
    stage_name = "dungeon1-1",
    stages = {
      { id = 1, name = "dungeon1-1", start = 0, floors = 14, boss_every = 10 },
      { id = 2, name = "dungeon1-2", start = 0, floors = 15, boss_every = 10 },
      -- 無限に進み続けるラストダンジョンの設定。
      { id = 3, name = "last-dungeon", start = 0, infinite = true, boss_every = 10 },
    },
    -- 図鑑と連携するため、敵のIDを指定する。
    enemy_names = { "dust_slime", "cave_bat", "moss_goblin" },
    battle = { enemy_hp = 6, enemy_atk = 1, reward_exp = 2, reward_gold = 2 },
    storage = {
      -- ユーザー共通の保存を前提とするため、短い同期間隔を既定にする。
      autosave_seconds = 60,
      sync_seconds = 3,
      lock_ttl_seconds = 180,
    },
    event_distances = build_event_distances(),
    ui = {
      width = 36,
      -- 表示は1行を既定とし、最大2行に制限する。
      height = 1,
      max_height = 2,
      track_length = 18,
      render_mode = "visual",
      auto_start = true,
      language = "en",
      languages = { "en", "ja" },
      -- 情報表示の切り替え間隔を秒で指定する。
      info_cycle_seconds = 4,
      -- ペット表示は既定で有効とし、1行の中で動きを表現する。
      pet = {
        enabled = true,
        style = "auto",
        frame_seconds = 1,
        ground_char = ".",
      },
      -- スプライトの色味をキャラクターや敵ごとに定義する。
      sprite_palette = {
        default_hero = { fg = "#B7E5FF" },
        default_enemy = { fg = "#FFD6D6" },
        boss = { fg = "#FF6B6B" },
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
      -- 画像スプライトはオプションで有効化する。
      image_sprites = {
        enabled = false,
        backend = "kitty",
        asset_dir = "assets/idle_dungeon/sprites",
        frame_seconds = 1,
        rows = 1,
        cols = 4,
        opacity = 1,
        row_offset = 0,
        col_offset = 0,
        show_hero = true,
        show_enemy = true,
        boss = { "enemy_boss_idle_1.png", "enemy_boss_battle.png" },
      },
      -- 中央メニューの表示設定をまとめる。
      menu = {
        width = 72,
        max_height = 22,
        padding = 1,
        border = "single",
        tabs_position = "top",
      },
    },
    unlock_rules = {
      { id = "typing_blade", target = "items", kind = "chars", value = 200 },
      { id = "save_hammer", target = "items", kind = "saves", value = 10 },
      { id = "repeat_cloak", target = "items", kind = "time_sec", value = 1800 },
      { id = "edge_shield", target = "items", kind = "filetype_chars", filetype = "lua", value = 200 },
      { id = "focus_bracelet", target = "items", kind = "chars", value = 600 },
      { id = "wind_bird", target = "items", kind = "time_sec", value = 900 },
    },
  }
end

-- 利用者の設定を安全に統合して新しい設定を返す。
local function build(user_config)
  local merged = util.merge_tables(default_config(), user_config or {})
  -- 階層幅は利用者設定を優先し、未指定なら表示幅に合わせる。
  if user_config and user_config.floor_length ~= nil then
    merged.floor_length = user_config.floor_length
  else
    merged.floor_length = (merged.ui or {}).track_length or merged.floor_length or 18
  end
  if not merged.event_distances or #merged.event_distances == 0 then
    merged.event_distances = build_event_distances()
  end
  return merged
end

M.build = build

return M
