-- このモジュールはステージ表示用の整形処理を提供する。
-- 進行計算はgame配下の進行モジュールへ集約する。
local floor_progress = require("idle_dungeon.game.floor.progress")
local stage_progress = require("idle_dungeon.game.stage_progress")

local M = {}

local function abbreviate_stage_name(name)
  if not name or name == "" then
    return "stage"
  end
  local shortened = name:gsub("^dungeon", "d")
  shortened = shortened:gsub("last%-dungeon", "last")
  return shortened
end

local function find_stage(progress, config)
  local _, stage = stage_progress.find_stage_index(config.stages or {}, progress)
  return stage
end

-- ステージ名は短縮せずにそのまま返す。
local function resolve_stage_name(stage, progress)
  return (stage and stage.name) or (progress and progress.stage_name) or "stage"
end

-- ステージ内の階層進行を表示用の文字列に整形する。
local function build_stage_progress_text(progress, stage, config)
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local stage_floor = floor_progress.stage_floor_distance(progress, floor_length)
  local current_floor = math.max(stage_floor + 1, 1)
  local total_floors = floor_progress.stage_total_floors(stage, floor_length)
  if stage and stage.infinite or progress.stage_infinite then
    return string.format("%d/INF", current_floor)
  end
  if total_floors then
    return string.format("%d/%d", current_floor, total_floors)
  end
  return string.format("%d", current_floor)
end

-- ステージ番号と階層進行をまとめた短いトークンを返す。
local function build_stage_token(progress, stage, config)
  local progress_text = build_stage_progress_text(progress, stage, config)
  local stage_id = stage and stage.id or (progress and progress.stage_id) or nil
  if stage_id then
    return string.format("%d-%s", stage_id, progress_text)
  end
  return progress_text
end

-- 表示用のステージ名とトークンをまとめて返す。
local function build_stage_parts(progress, config)
  local stage = find_stage(progress or {}, config or {}) or {}
  return {
    stage = stage,
    name = resolve_stage_name(stage, progress or {}),
    token = build_stage_token(progress or {}, stage, config or {}),
  }
end

local function build_stage_summary(progress, config)
  local stage = find_stage(progress, config) or {}
  local name = abbreviate_stage_name(stage.name or progress.stage_name or "stage")
  local progress_text = build_stage_progress_text(progress, stage, config)
  return string.format("%s %s", name, progress_text)
end

M.abbreviate_stage_name = abbreviate_stage_name
M.build_stage_progress_text = build_stage_progress_text
M.build_stage_summary = build_stage_summary
M.build_stage_parts = build_stage_parts

return M
