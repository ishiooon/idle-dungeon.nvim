-- このモジュールは設定の既定値と結合処理を提供する。

local content = require("idle_dungeon.content")
local stage_defaults = require("idle_dungeon.config.stages")
local ui_defaults = require("idle_dungeon.config.ui")
local floor_progress = require("idle_dungeon.game.floor.progress")
local util = require("idle_dungeon.util")

local M = {}

-- 敵一覧は敵定義から構築して重複管理を避ける。
local function build_enemy_names()
  local names = {}
  for _, enemy in ipairs(content.enemies or {}) do
    if enemy.id and enemy.id ~= "" then
      table.insert(names, enemy.id)
    end
  end
  return names
end

-- 装備定義の解放条件を設定用のルールへ変換する。
local function build_unlock_rules(items, extra_rules)
  local rules = {}
  local seen = {}
  local function push(rule)
    if not rule or not rule.id or not rule.kind then
      return
    end
    local key = string.format("%s:%s:%s", rule.id, rule.kind, rule.filetype or "")
    if seen[key] then
      return
    end
    seen[key] = true
    table.insert(rules, rule)
  end
  for _, item in ipairs(items or {}) do
    local unlock = item.unlock
    if type(unlock) == "table" and unlock.kind then
      push(util.merge_tables(unlock, { id = item.id, target = "items" }))
    elseif type(unlock) == "table" then
      for _, entry in ipairs(unlock) do
        if type(entry) == "table" and entry.kind then
          push(util.merge_tables(entry, { id = item.id, target = "items" }))
        end
      end
    end
  end
  for _, rule in ipairs(extra_rules or {}) do
    push(rule)
  end
  return rules
end

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
    tick_seconds = 0.5,
    move_step = 1,
    encounter_every = 5,
    -- 会話の待機時間は0秒とし、進行の停止を発生させない。
    dialogue_seconds = 0,
    -- ステージ開始時のアスキーアート表示は短時間で切り替える。
    stage_intro_seconds = 1.5,
    -- 隠しイベントのメッセージ表示は数ティックだけ継続させる。
    event_message_ticks = 5,
    -- 選択イベントの自動決定までの待機秒数を設定する。
    choice_seconds = 10,
    -- 左から右までの歩幅を1階層として扱い、既定は短めに整える。
    floor_length = 32,
    -- 階層ごとの遭遇数を1〜5体で設定する。
    floor_encounters = { min = 1, max = 5 },
    -- 隠しイベントは数フロアに一度だけ発生させる。
    floor_events = { enabled = true, chance = 35, min_floor = 2 },
    -- ボスは10階層ごとに出現する。
    boss_every = 10,
    stage_name = { en = "Glacier Command", ja = "初手の氷回廊" },
    stages = stage_defaults.default_stages(),
    -- 既定のジョブIDを指定して初期能力値を決める。
    default_job_id = "recorder",
    -- 図鑑と遭遇候補のための敵IDは敵定義から生成する。
    enemy_names = build_enemy_names(),
    elements = { "normal", "fire", "water", "grass", "light", "dark" },
    battle = {
      enemy_hp = 6,
      enemy_atk = 1,
      -- 成長計算はステージとフロアの進行度を基準にする。
      growth_base = 1,
      growth_floor = 2,
      growth_stage = 12,
      -- 成長レベルに応じて体力・攻撃・防御を上乗せする。
      growth_hp = 2,
      growth_atk = 1,
      growth_def = 0.5,
      -- 速度の成長は攻撃間隔を短くする方向で作用させる。
      growth_speed = 0.05,
      -- ボスは成長レベルを倍率で上げて強さを際立たせる。
      growth_boss_multiplier = 1.5,
      -- 攻撃速度は1以上の整数で、数値が大きいほど攻撃間隔が長い。
      hero_speed = 2,
      enemy_speed = 2,
      -- アクティブスキルの自動発動率を0〜1で設定する。
      skill_active_rate = 0.35,
      -- ペット保持時に敵がペットを狙う確率を0〜1で設定する。
      pet_target_rate = 0.35,
      -- 経験値の上がり幅を少しだけ増やしてテンポを調整する。
      -- 敵ごとの倍率と合わせて成長が体感できる基礎値にする。
      reward_exp = 30,
      reward_gold = 2,
      -- エンカウントは敵の2マス手前で開始する。
      encounter_gap = 2,
      -- 撃破や敗北時の表示は次の更新まで戦闘表示を維持する。
      outcome_wait = 0,
      -- 戦利品のドロップ率はさらに低めに調整して希少性を強める。
      -- レアとペットはほぼ出ない前提で数値を設定する。
      drop_rates = { common = 3, rare = 1, pet = 1, boss_bonus = 1 },
    },
    storage = {
      -- ユーザー共通の保存を前提とするため、短い同期間隔を既定にする。
      autosave_seconds = 60,
      sync_seconds = 3,
      lock_ttl_seconds = 180,
    },
    event_distances = build_event_distances(),
    ui = ui_defaults.default_ui(),
    -- 解放条件は装備定義から生成する。
    unlock_rules = build_unlock_rules(content.items or {}, nil),
    -- 入力統計で除外するファイル種別を定義する。
    input = {
      ignored_filetypes = {
        "alpha",
        "dashboard",
        "lazy",
        "mason",
        "NvimTree",
        "neo-tree",
        "neo-tree-popup",
        "neo-tree-preview",
        "netrw",
        "oil",
      },
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
  -- 解放条件は装備定義を優先し、追加分だけを統合する。
  merged.unlock_rules = build_unlock_rules(content.items or {}, (user_config or {}).unlock_rules)
  -- 入力統計の除外ファイル種別は配列を丸ごと置き換える。
  if user_config and user_config.input and user_config.input.ignored_filetypes then
    merged.input = util.merge_tables(merged.input or {}, {
      ignored_filetypes = user_config.input.ignored_filetypes,
    })
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
