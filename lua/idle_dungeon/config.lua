-- このモジュールは設定の既定値と結合処理を提供する。

local content = require("idle_dungeon.content")
local stage_defaults = require("idle_dungeon.config.stages")
local ui_defaults = require("idle_dungeon.config.ui")
local floor_progress = require("idle_dungeon.game.floor.progress")
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
    -- 進行テンポを上げるため、1ティックで進む距離を増やす。
    move_step = 2,
    encounter_every = 5,
    -- 会話の待機時間は0秒とし、進行の停止を発生させない。
    dialogue_seconds = 0,
    -- 左から右までの歩幅を1階層として扱い、既定は短めに整える。
    floor_length = 32,
    -- 階層ごとの遭遇数を1〜5体で設定する。
    floor_encounters = { min = 1, max = 5 },
    -- ボスは10階層ごとに出現する。
    boss_every = 10,
    stage_name = "Glacier Command",
    stages = stage_defaults.default_stages(),
    -- 図鑑と連携するため、敵のIDを指定する。
    -- 敵の種類を増やしたため、初期候補を広めに設定する。
    enemy_names = {
      "dust_slime",
      "tux_penguin",
      "vim_mantis",
      "c_sentinel",
      "cpp_colossus",
      "php_elephant",
      "docker_whale",
      "go_gopher",
      "bash_hound",
      "mysql_dolphin",
      "postgres_colossus",
      "dbeaver",
      "ruby_scarab",
      "node_phantom",
      "python_serpent",
      "java_ifrit",
      "kotlin_fox",
      "swift_raptor",
      "git_wyrm",
      "rust_crab",
      "gnu_bison",
      "clojure_oracle",
    },
    elements = { "normal", "fire", "water", "grass", "light", "dark" },
    battle = { enemy_hp = 6, enemy_atk = 1, reward_exp = 2, reward_gold = 2 },
    storage = {
      -- ユーザー共通の保存を前提とするため、短い同期間隔を既定にする。
      autosave_seconds = 60,
      sync_seconds = 3,
      lock_ttl_seconds = 180,
    },
    event_distances = build_event_distances(),
    ui = ui_defaults.default_ui(),
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

-- ステージの開始距離を階層数から計算して埋める。
local function apply_stage_starts(stages, config)
  local result = {}
  local cursor = 0
  local floor_length = floor_progress.resolve_floor_length(config)
  for _, stage in ipairs(stages or {}) do
    local next_stage = util.merge_tables(stage, {})
    if next_stage.start == nil then
      next_stage.start = cursor
    end
    local length = floor_progress.stage_length_steps(next_stage, floor_length)
    if length and not next_stage.infinite then
      cursor = next_stage.start + length
    else
      cursor = next_stage.start
    end
    table.insert(result, next_stage)
  end
  return result
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
  -- ステージ開始距離を自動補完する。
  merged.stages = apply_stage_starts(merged.stages or {}, merged)
  return merged
end

M.build = build

return M
