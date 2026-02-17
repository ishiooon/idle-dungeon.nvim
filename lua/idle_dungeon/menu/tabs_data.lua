-- このモジュールはメニュー表示に必要なデータを純粋関数として生成する。
-- 図鑑とメニューの参照先は関心ごとに整理する。
local content = require("idle_dungeon.content")
local battle = require("idle_dungeon.game.battle")
local dex_catalog = require("idle_dungeon.game.dex.catalog")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local element = require("idle_dungeon.game.element")
local skills = require("idle_dungeon.game.skills")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")
local floor_progress = require("idle_dungeon.game.floor.progress")
local render_stage = require("idle_dungeon.ui.render_stage")
local stage_progress = require("idle_dungeon.game.stage_progress")
local time_format = require("idle_dungeon.ui.time_format")
local util = require("idle_dungeon.util")

local M = {}
local SPEED_WAIT_BASE = 5

local function clamp_ratio(current, total)
  local safe_total = math.max(tonumber(total) or 0, 0)
  if safe_total <= 0 then
    return 0
  end
  local safe_current = math.max(tonumber(current) or 0, 0)
  return math.max(math.min(safe_current / safe_total, 1), 0)
end

local function resolve_meter_style(config)
  local menu = ((config or {}).ui or {}).menu or {}
  local style = menu.meter or {}
  return {
    on = style.on or "▰",
    off = style.off or "▱",
  }
end

local function align_label(label, label_width)
  local text = label or ""
  local width = math.max(tonumber(label_width) or 0, 0)
  if width <= 0 then
    return text
  end
  local gap = width - util.display_width(text)
  if gap <= 0 then
    return text
  end
  return text .. string.rep(" ", gap)
end

local function build_meter(label, current, total, width, suffix, meter_style, label_width)
  local bar_width = math.max(tonumber(width) or 14, 6)
  local ratio = clamp_ratio(current, total)
  local filled = math.floor(ratio * bar_width + 0.5)
  local empty = math.max(bar_width - filled, 0)
  local style = meter_style or { on = "▰", off = "▱" }
  local bar = string.format("[%s%s]", string.rep(style.on, filled), string.rep(style.off, empty))
  local tail = suffix or string.format("%d/%d", math.floor(current or 0), math.floor(total or 0))
  return string.format("%s %s %s", align_label(label, label_width), bar, tail)
end

local function with_icon(icon, text)
  local safe_icon = icon or ""
  local safe_text = text or ""
  if safe_icon == "" then
    return safe_text
  end
  return string.format("%s %s", safe_icon, safe_text)
end

-- 状態タブの見出しをゲーム風のセクションタイトルとして整形する。
local function status_section_title(icon, text)
  return string.format("━━ %s ━━", with_icon(icon, text))
end

local function resolve_stage_info(state, config, lang)
  local progress = state.progress or {}
  local _, stage = stage_progress.find_stage_index((config or {}).stages or {}, progress)
  local stage_name = render_stage.resolve_stage_name(stage, progress, lang)
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local stage_floor = floor_progress.stage_floor_distance(progress, floor_length)
  local current_floor = math.max(stage_floor + 1, 1)
  local total_floors = floor_progress.stage_total_floors(stage, floor_length)
  local stage_ratio = clamp_ratio(current_floor, total_floors or 0)
  local stage_text = render_stage.build_stage_progress_text(progress, stage, config)
  local floor_step = floor_progress.floor_step(progress.distance or 0, floor_length)
  return {
    name = stage_name,
    text = stage_text,
    ratio = stage_ratio,
    current_floor = current_floor,
    total_floors = total_floors or 0,
    floor_step = floor_step,
    floor_length = floor_length,
  }
end

local function detail_lines_copy(lines)
  local copied = {}
  for _, line in ipairs(lines or {}) do
    table.insert(copied, tostring(line or ""))
  end
  return copied
end

local function status_ratio_text(current, total)
  local safe_current = math.max(tonumber(current) or 0, 0)
  local safe_total = math.max(tonumber(total) or 0, 0)
  if safe_total <= 0 then
    return "0%"
  end
  return string.format("%d%%", math.floor((safe_current / safe_total) * 100 + 0.5))
end

local function build_status_detail(item, state, config, lang)
  if type(item) == "table" and type(item.detail_lines) == "table" and #item.detail_lines > 0 then
    return {
      title = item.detail_title or item.label or "",
      lines = detail_lines_copy(item.detail_lines),
    }
  end
  return nil
end

local function build_action_items()
  return {
    -- 操作系はメニューを閉じてから各サブメニューを開く。
    { id = "equip", key = "menu_action_equip", icon = "󰓥" },
    { id = "stage", key = "menu_action_stage", icon = "󰝰" },
    { id = "purchase", key = "menu_action_purchase", icon = "󰏓" },
    { id = "sell", key = "menu_action_sell", icon = "󰆏" },
    -- ジョブ変更は専用メニューで扱う。
    { id = "job", key = "menu_action_job", icon = "󰘧" },
    -- 習得済みスキルの切り替え用メニューを追加する。
    { id = "skills", key = "menu_action_skills", icon = "󰌵" },
  }
end

local function build_config_items()
  return {
    { id = "toggle_text", key = "menu_action_toggle_text", keep_open = true, kind = "toggle", icon = "󰘎" },
    { id = "auto_start", key = "menu_action_auto_start", keep_open = true, kind = "toggle", icon = "󰐊" },
    { id = "game_speed", key = "menu_action_game_speed", keep_open = true, kind = "cycle", icon = "󰓅" },
    { id = "display_lines", key = "menu_action_display_lines", keep_open = true, kind = "toggle", icon = "󰍹" },
    -- 戦闘中のHP分母表示を切り替える設定を追加する。
    { id = "battle_hp_show_max", key = "menu_action_battle_hp_show_max", keep_open = true, kind = "toggle", icon = "󰓣" },
    -- 設定系は閉じずに選択できるようkeep_openで維持する。
    { id = "language", key = "menu_action_language", keep_open = true, icon = "󰗊" },
    { id = "reset", key = "menu_action_reset", keep_open = true, icon = "󰑐" },
    { id = "reload_plugin", key = "menu_action_reload_plugin", keep_open = true, icon = "󰓭" },
  }
end

-- クレジット表示用のアスキーアートを定義する。
local function build_credits_art()
  return {
    -- 作品名の表記は IdleDungeon に統一する。
    "=== IdleDungeon ===",
    " ___ ____  _____ _       ____  _   _ _   _  ____  _   _ ",
    "|_ _|  _ \\| ____| |     |  _ \\| | | | \\ | |/ ___|| | | |",
    " | || | | |  _| | |     | | | | | | |  \\| | |  _ | | | |",
    " | || |_| | |___| |___  | |_| | |_| | |\\  | |_| || |_| |",
    "|___|____/|_____|_____| |____/ \\___/|_| \\_|\\____| \\___/ ",
  }
end

local function build_item_map()
  local map = {}
  for _, item in ipairs(content.items or {}) do
    map[item.id] = item
  end
  return map
end

local ITEM_BY_ID = build_item_map()

local function resolve_text(text, lang)
  if type(text) ~= "table" then
    return ""
  end
  if lang == "en" then
    return text.en or text.ja or text.jp or ""
  end
  return text.ja or text.jp or text.en or ""
end

local function resolve_item_name(item, lang)
  if not item then
    return "-"
  end
  if lang == "en" then
    return item.name_en or item.name or item.id or "-"
  end
  return item.name or item.name_en or item.id or "-"
end

local function build_item_bonus_text(item, lang)
  if not item then
    return lang == "en" and "No bonus" or "補正なし"
  end
  local parts = {}
  local function push(label, value)
    local amount = tonumber(value) or 0
    if amount ~= 0 then
      table.insert(parts, string.format("%s+%d", label, amount))
    end
  end
  push("HP", item.hp)
  push("ATK", item.atk)
  push("DEF", item.def)
  push("SPD", item.speed)
  if #parts == 0 then
    return lang == "en" and "No bonus" or "補正なし"
  end
  return table.concat(parts, " ")
end

local function find_current_job(job_id)
  for _, job in ipairs(content.jobs or {}) do
    if job.id == job_id then
      return job
    end
  end
  return nil
end

local function with_status_tag(label, kind, lang)
  local text = tostring(label or "")
  if text == "" then
    return text
  end
  -- 操作種別タグは下部Enter説明と重複しやすいため、本文ラベルでは省略する。
  return text
end

local function find_next_enemy(state, config)
  local progress = (state or {}).progress or {}
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local distance = tonumber(progress.distance) or 0
  local step = floor_progress.floor_step(progress.distance or 0, floor_length)
  local floor_index = floor_progress.floor_index(distance, floor_length)
  local floor_start = floor_progress.floor_start_distance(floor_index, floor_length)
  local encounter_gap = math.max(tonumber((((config or {}).battle or {}).encounter_gap) or 2) or 2, 0)
  local next_enemy = nil
  for _, enemy in ipairs(progress.floor_enemies or {}) do
    if enemy and not enemy.defeated then
      local pos = tonumber(enemy.position) or 0
      local remain = pos - step
      if remain >= 0 then
        local enemy_distance = floor_start + math.max(pos - 1, 0)
        local encounter_distance = math.max(enemy_distance - (encounter_gap + 1), floor_start)
        local approach_steps = math.max(encounter_distance - distance, 0)
        if (not next_enemy) or approach_steps < (next_enemy.steps or 9999) then
          next_enemy = {
            steps = approach_steps,
            enemy_steps = remain,
            enemy_distance = enemy_distance,
            encounter_distance = encounter_distance,
            enemy = enemy,
          }
        end
      end
    end
  end
  return next_enemy
end

-- 戦闘開始時と同じ成長式で敵能力を再構築し、メニュー推定との差を減らす。
local function resolve_snapshot_enemy(state, config, next_enemy)
  if not (next_enemy and next_enemy.enemy and next_enemy.enemy.id) then
    return nil
  end
  local progress = (state or {}).progress or {}
  local distance = math.max(tonumber(next_enemy.encounter_distance) or tonumber(progress.distance) or 0, 0)
  local enemy_spec = {
    id = next_enemy.enemy.id,
    element = next_enemy.enemy.element,
    is_boss = next_enemy.enemy.is_boss == true,
  }
  return battle.build_enemy(distance, config or {}, enemy_spec)
end

local function resolve_enemy_name(enemy_id, lang)
  if not enemy_id then
    return (lang == "ja" or lang == "jp") and "不明" or "Unknown"
  end
  local entry = enemy_catalog.find_enemy(enemy_id)
  if not entry then
    return enemy_id
  end
  if lang == "ja" or lang == "jp" then
    return entry.name_ja or entry.name or entry.name_en or enemy_id
  end
  return entry.name_en or entry.name or entry.name_ja or enemy_id
end

local function resolve_speed(value, fallback)
  local speed = tonumber(value)
  if not speed or speed < 1 then
    speed = tonumber(fallback) or 1
  end
  return math.max(speed, 1)
end

-- 戦闘遷移で使っている待機式と同じ計算で、行動ごとの時間を推定する。
local function resolve_action_interval(speed, opponent_speed)
  local safe_speed = math.max(tonumber(speed) or 1, 1)
  local safe_opponent = math.max(tonumber(opponent_speed) or 1, 1)
  local total = safe_speed + safe_opponent
  local scaled = (SPEED_WAIT_BASE * total) / (2 * safe_speed)
  return math.max(math.floor(scaled + 0.5), 1)
end

local function estimate_hits_to_finish(hp, damage)
  local safe_hp = math.max(tonumber(hp) or 0, 1)
  local safe_damage = math.max(tonumber(damage) or 1, 1)
  return math.max(math.ceil(safe_hp / safe_damage), 1)
end

local function estimate_damage(attacker_atk, defender_def)
  return math.max((tonumber(attacker_atk) or 0) - (tonumber(defender_def) or 0), 1)
end

local function resolve_damage_snapshot(state, actor, enemy, config)
  local hero_passive = skills.resolve_passive_bonus((state or {}).skills, (state or {}).skill_settings, content.jobs)
  local enemy_passive = skills.resolve_passive_bonus_from_list((enemy or {}).skills or {})
  local hero_attack = math.max(math.floor((tonumber(actor.atk) or 0) * (hero_passive.atk or 1) + 0.5), 1)
  local hero_def = math.max(math.floor((tonumber(actor.def) or 0) * (hero_passive.def or 1) + 0.5), 0)
  local enemy_attack = math.max(math.floor((tonumber((enemy or {}).atk) or 0) * (enemy_passive.atk or 1) + 0.5), 1)
  local enemy_def = math.max(math.floor((tonumber((enemy or {}).def) or 0) * (enemy_passive.def or 1) + 0.5), 0)
  local outgoing = estimate_damage(hero_attack, enemy_def)
  local incoming = estimate_damage(enemy_attack, hero_def)
  local actor_hp = math.max(tonumber(actor.hp) or tonumber(actor.max_hp) or 0, 1)
  local enemy_hp = math.max(tonumber((enemy or {}).hp) or 0, 1)
  local battle_config = (config or {}).battle or {}
  local hero_speed = resolve_speed(actor.speed or actor.base_speed, battle_config.hero_speed or 2)
  local enemy_speed = resolve_speed((enemy or {}).speed, battle_config.enemy_speed or 2)
  local win_hits = estimate_hits_to_finish(enemy_hp, outgoing)
  local lose_hits = estimate_hits_to_finish(actor_hp, incoming)
  local win_time = win_hits * resolve_action_interval(hero_speed, enemy_speed)
  local lose_time = lose_hits * resolve_action_interval(enemy_speed, hero_speed)
  return {
    outgoing = outgoing,
    incoming = incoming,
    win_hits = win_hits,
    lose_hits = lose_hits,
    win_time = win_time,
    lose_time = lose_time,
    actor_hp = actor_hp,
  }
end

local function resolve_danger_label(model, lang)
  local ratio = (tonumber(model.lose_time) or 1) / math.max(tonumber(model.win_time) or 1, 1)
  local is_ja = lang == "ja" or lang == "jp"
  if (tonumber(model.incoming) or 0) >= (tonumber(model.actor_hp) or 1) or ratio <= 1.0 then
    return is_ja and "高" or "High"
  end
  if ratio <= 1.45 then
    return is_ja and "中" or "Medium"
  end
  return is_ja and "低" or "Low"
end

-- 危険度理由は単発ダメージ比ではなく、勝敗までの見込み時間を主軸に説明する。
local function build_danger_reason_text(model, lang)
  local safe = model or {}
  local incoming = math.max(tonumber(safe.incoming) or 0, 0)
  local outgoing = math.max(tonumber(safe.outgoing) or 1, 1)
  local win_hits = math.max(tonumber(safe.win_hits) or 1, 1)
  local lose_hits = math.max(tonumber(safe.lose_hits) or 1, 1)
  local win_time = math.max(tonumber(safe.win_time) or 1, 1)
  local lose_time = math.max(tonumber(safe.lose_time) or 1, 1)
  local ratio = lose_time / math.max(win_time, 1)
  local is_ja = lang == "ja" or lang == "jp"
  if ratio <= 1.0 then
    if is_ja then
      return string.format(
        "脅威診断: 敵に倒される見込み時間が約%d(被弾%d回)で、こちらの勝利見込み時間%d(攻撃%d回)を下回ります。 推定与ダメージ%d / 推定被ダメージ%d。",
        lose_time,
        lose_hits,
        win_time,
        win_hits,
        outgoing,
        incoming
      )
    end
    return string.format(
      "Threat Scan: Enemy can defeat you in about %d ticks (%d hits), before your estimated win time (%d ticks, %d hits). Estimated outgoing %d / incoming %d.",
      lose_time,
      lose_hits,
      win_time,
      win_hits,
      outgoing,
      incoming
    )
  end
  if ratio <= 1.45 then
    if is_ja then
      return string.format(
        "脅威診断: 勝利見込み時間%d(攻撃%d回)と被撃破見込み時間%d(被弾%d回)が近く、余裕が小さいです。 推定与ダメージ%d / 推定被ダメージ%d。",
        win_time,
        win_hits,
        lose_time,
        lose_hits,
        outgoing,
        incoming
      )
    end
    return string.format(
      "Threat Scan: Estimated win time (%d ticks, %d hits) is close to survival time (%d ticks, %d hits). Estimated outgoing %d / incoming %d.",
      win_time,
      win_hits,
      lose_time,
      lose_hits,
      outgoing,
      incoming
    )
  end
  if is_ja then
    return string.format(
      "脅威診断: 勝利見込み時間%d(攻撃%d回)が被撃破見込み時間%d(被弾%d回)より短く、余裕があります。 推定与ダメージ%d / 推定被ダメージ%d。",
      win_time,
      win_hits,
      lose_time,
      lose_hits,
      outgoing,
      incoming
    )
  end
  return string.format(
    "Threat Scan: You are estimated to win in %d ticks (%d hits) while surviving about %d ticks (%d hits). Estimated outgoing %d / incoming %d.",
    win_time,
    win_hits,
    lose_time,
    lose_hits,
    outgoing,
    incoming
  )
end

local function signed_value(value)
  local number = tonumber(value) or 0
  if number > 0 then
    return string.format("+%d", number)
  end
  if number < 0 then
    return string.format("%d", number)
  end
  return "0"
end

local function resolve_status_action_text(next_enemy, danger_label, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not next_enemy then
    if is_ja then
      return "次行動: ステージを進める"
    end
    return "Next: Push stage progress"
  end
  if (next_enemy.steps or 0) <= 1 or danger_label == (is_ja and "高" or "High") then
    if is_ja then
      return "次行動: 装備とスキルを確認"
    end
    return "Next: Review gear and skills"
  end
  -- 残り歩数はノイズになりやすいため、次行動は抽象度を揃えて表示する。
  if is_ja then
    return "次行動: 進行を続ける"
  end
  return "Next: Keep moving"
end

local function compute_combat_snapshot(state, config, lang)
  local actor = (state or {}).actor or {}
  local next_enemy = find_next_enemy(state, config)
  local estimated_enemy = resolve_snapshot_enemy(state, config, next_enemy)
  local enemy_name = resolve_enemy_name(estimated_enemy and estimated_enemy.id, lang)
  local model = resolve_damage_snapshot(state, actor, estimated_enemy or {}, config)
  local danger = resolve_danger_label(model, lang)
  local breakthrough = math.floor((tonumber(actor.atk) or 0) * 2 + (tonumber(actor.speed) or 0) * 1.2 + 0.5)
  local stability = math.floor((tonumber(actor.max_hp) or 0) + (tonumber(actor.def) or 0) * 6 + 0.5)
  local base_atk = tonumber(actor.base_atk) or tonumber(actor.atk) or 0
  local base_def = tonumber(actor.base_def) or tonumber(actor.def) or 0
  local base_speed = tonumber(actor.base_speed) or tonumber(actor.speed) or 0
  local snapshot = {
    next_enemy = next_enemy,
    enemy_name = enemy_name,
    outgoing = model.outgoing,
    incoming = model.incoming,
    danger = danger,
    danger_reason = build_danger_reason_text(model, lang),
    breakthrough = breakthrough,
    stability = stability,
    atk_diff = (tonumber(actor.atk) or 0) - base_atk,
    def_diff = (tonumber(actor.def) or 0) - base_def,
    speed_diff = (tonumber(actor.speed) or 0) - base_speed,
  }
  snapshot.next_action = resolve_status_action_text(next_enemy, danger, lang)
  return snapshot
end

local function is_ja_lang(lang)
  return lang == "ja" or lang == "jp"
end

local function build_metrics_summary_line(metrics, lang)
  local safe = metrics or {}
  local chars = tonumber(safe.chars) or 0
  local saves = tonumber(safe.saves) or 0
  local time_text = time_format.format_seconds(safe.time_sec or 0, lang)
  local is_ja = is_ja_lang(lang)
  if is_ja then
    return string.format("文字 %d / 保存 %d / 時間 %s", chars, saves, time_text)
  end
  return string.format("Chars %d / Saves %d / Time %s", chars, saves, time_text)
end

local function rule_current_value(rule, metrics)
  local safe_metrics = metrics or {}
  if rule.kind == "chars" then
    return math.max(tonumber(safe_metrics.chars) or 0, 0)
  end
  if rule.kind == "saves" then
    return math.max(tonumber(safe_metrics.saves) or 0, 0)
  end
  if rule.kind == "time_sec" then
    return math.max(tonumber(safe_metrics.time_sec) or 0, 0)
  end
  if rule.kind == "filetype_chars" then
    local filetypes = safe_metrics.filetypes or {}
    return math.max(tonumber(filetypes[rule.filetype or ""]) or 0, 0)
  end
  return 0
end

local function find_next_unlock_rule(state, config)
  local unlock_rules = (config or {}).unlock_rules or {}
  local unlocked_items = ((state or {}).unlocks or {}).items or {}
  local metrics = (state or {}).metrics or {}
  local best = nil
  for _, rule in ipairs(unlock_rules) do
    if rule and rule.target == "items" and unlocked_items[rule.id] ~= true then
      local required = math.max(tonumber(rule.value) or 0, 0)
      local current = rule_current_value(rule, metrics)
      local remain = math.max(required - current, 0)
      local ratio = required > 0 and (current / required) or 1
      if (not best)
        or ratio > best.ratio
        or (ratio == best.ratio and remain < best.remain)
      then
        best = {
          rule = rule,
          required = required,
          current = current,
          remain = remain,
          ratio = ratio,
        }
      end
    end
  end
  return best
end

local function unlock_remaining_text(rule, remain, lang)
  local safe_remain = math.max(tonumber(remain) or 0, 0)
  local is_ja = is_ja_lang(lang)
  if rule.kind == "chars" then
    if is_ja then
      return string.format("残り%d文字", safe_remain)
    end
    return string.format("%d chars left", safe_remain)
  end
  if rule.kind == "saves" then
    if is_ja then
      return string.format("残り%d回保存", safe_remain)
    end
    return string.format("%d saves left", safe_remain)
  end
  if rule.kind == "time_sec" then
    if is_ja then
      return string.format("残り%s", time_format.format_seconds(safe_remain, lang))
    end
    return string.format("%s left", time_format.format_seconds(safe_remain, lang))
  end
  if rule.kind == "filetype_chars" then
    local filetype = tostring(rule.filetype or "")
    if is_ja then
      return string.format("%s 残り%d文字", filetype, safe_remain)
    end
    return string.format("%s %d chars left", filetype, safe_remain)
  end
  if is_ja then
    return string.format("残り%d", safe_remain)
  end
  return string.format("%d left", safe_remain)
end

local function build_next_reward_entry(state, config, lang, to_next)
  local is_ja = is_ja_lang(lang)
  local unlock = find_next_unlock_rule(state, config)
  local unlock_summary = is_ja and "全装備解放済み" or "All equipment unlocked"
  local unlock_detail = is_ja and "現在の解放条件はすべて達成済みです。" or "All unlock conditions are already completed."
  if unlock and unlock.rule then
    local item_name = resolve_item_name(ITEM_BY_ID[unlock.rule.id], lang)
    local remain_text = unlock_remaining_text(unlock.rule, unlock.remain, lang)
    unlock_summary = string.format("%s (%s)", item_name, remain_text)
    if is_ja then
      unlock_detail = string.format("次の装備解放対象: %s", unlock_summary)
    else
      unlock_detail = string.format("Next equipment unlock target: %s", unlock_summary)
    end
  end
  local label = is_ja
      and string.format("次の報酬: LvまでEXP %d / 次の装備解放: %s", to_next, unlock_summary)
    or string.format("Next Reward: EXP to Lv %d / Next Equipment Unlock: %s", to_next, unlock_summary)
  local detail_lines = is_ja
      and {
        string.format("次レベルまでEXP: %d", to_next),
        unlock_detail,
      }
    or {
      string.format("EXP To Next Level: %d", to_next),
      unlock_detail,
    }
  return {
    id = "entry",
    label = with_icon("󰁝", label),
    detail_title = is_ja and "次の報酬と装備解放" or "Next Reward & Equipment Unlock",
    detail_lines = detail_lines,
  }
end

-- 現在所持金で購入可能な候補数を返す。
local function count_affordable_purchase_options(state)
  local safe_state = state or {}
  local gold = tonumber(((safe_state.currency or {}).gold) or 0) or 0
  if gold <= 0 then
    return 0
  end
  local equipment = safe_state.equipment or {}
  local unlocked = ((safe_state.unlocks or {}).items) or {}
  local count = 0
  for _, item in ipairs(content.items or {}) do
    local slot = tostring(item.slot or "")
    local is_combat_slot = slot == "weapon" or slot == "armor" or slot == "accessory"
    if is_combat_slot then
      local price = tonumber(item.price) or 0
      local known = item.rarity == "common" or unlocked[item.id] == true
      local already_equipped = equipment[slot] == item.id
      if known and (not already_equipped) and price <= gold then
        count = count + 1
      end
    end
  end
  return count
end

-- 未装備で売却可能な装備の種類数を返す。
local function count_sellable_inventory(state)
  local safe_state = state or {}
  local inventory = safe_state.inventory or {}
  local equipment = safe_state.equipment or {}
  local count = 0
  for item_id, amount in pairs(inventory) do
    local owned = tonumber(amount) or 0
    local equipped = equipment.weapon == item_id or equipment.armor == item_id or equipment.accessory == item_id
    if owned > 0 and not equipped then
      count = count + 1
    end
  end
  return count
end

-- 状態タブ用の行をまとめて返す。
local function build_status_items(state, config, lang)
  local items = {}
  local stage_info = resolve_stage_info(state, config, lang)
  local actor = state.actor or {}
  local current_job = find_current_job(actor.id)
  local current_job_name = menu_locale.resolve_job_name(current_job, lang)
  local current_job_role = menu_locale.resolve_job_role(current_job, lang)
  local is_ja = is_ja_lang(lang)
  local meter_style = resolve_meter_style(config)
  local hp_label = with_icon("󰓣", i18n.t("label_hp", lang))
  local exp_label = with_icon("", i18n.t("label_exp", lang))
  local meter_label_width = math.max(util.display_width(hp_label), util.display_width(exp_label))
  local hp_ratio = status_ratio_text(actor.hp or 0, actor.max_hp or 0)
  local exp_ratio = status_ratio_text(actor.exp or 0, actor.next_level or 0)
  local to_next = math.max((actor.next_level or 0) - (actor.exp or 0), 0)
  local floor_ratio = status_ratio_text(stage_info.current_floor, stage_info.total_floors)
  local snapshot = compute_combat_snapshot(state, config, lang)
  local gold = tonumber(((state.currency or {}).gold) or 0) or 0
  local affordable_count = count_affordable_purchase_options(state)
  local sellable_count = count_sellable_inventory(state)

  -- 画面導線の上段: 現在地・危険度・次行動・次報酬を表示する。
  table.insert(items, { id = "header", label = status_section_title("󰑓", is_ja and "状況" or "Situation") })
  local stage_label = is_ja
      and string.format("現在位置 F%d/%d  危険度:%s", stage_info.current_floor, stage_info.total_floors, snapshot.danger)
    or string.format("Position F%d/%d  Risk:%s", stage_info.current_floor, stage_info.total_floors, snapshot.danger)
  table.insert(items, {
    id = "entry",
    action_id = "stage",
    keep_open = true,
    label = with_icon("󰝰", stage_label),
    detail_title = is_ja and "状況サマリー" or "Situation Summary",
    detail_lines = is_ja and {
      string.format("現在ステージ: %s", stage_info.name),
      string.format("現在フロア: %d/%d (%s)", stage_info.current_floor, stage_info.total_floors, floor_ratio),
      string.format("危険度: %s", snapshot.danger),
      snapshot.danger_reason,
      snapshot.next_action,
    } or {
      string.format("Current Stage: %s", stage_info.name),
      string.format("Current Floor: %d/%d (%s)", stage_info.current_floor, stage_info.total_floors, floor_ratio),
      string.format("Risk: %s", snapshot.danger),
      snapshot.danger_reason,
      snapshot.next_action,
    },
  })
  table.insert(items, build_next_reward_entry(state, config, lang, to_next))
  table.insert(items, { id = "spacer", label = "" })

  -- 画面導線の中段: 現在の強さを表示する。
  table.insert(items, { id = "header", label = status_section_title("󰀘", is_ja and "強さ" or "Power") })
  table.insert(items, {
    id = "entry",
    action_id = "job",
    keep_open = true,
    label = with_status_tag(with_icon(
      "󰁨",
      string.format(
        "%s %d  %s %s (%s)",
        i18n.t("label_level", lang),
        actor.level or 1,
        i18n.t("label_job", lang),
        current_job_name ~= "" and current_job_name or (actor.id or "-"),
        current_job_role ~= "" and current_job_role or "-"
      )
    ), "change", lang),
    detail_title = is_ja and "ヒーロー情報" or "Hero Overview",
    detail_lines = is_ja and {
      string.format("現在ジョブ: %s", current_job_name ~= "" and current_job_name or (actor.id or "-")),
      string.format("役割: %s", current_job_role ~= "" and current_job_role or "-"),
      string.format("現在レベル: %d", actor.level or 1),
      string.format("次レベルまでEXP: %d", to_next),
    } or {
      string.format("Current Job: %s", current_job_name ~= "" and current_job_name or (actor.id or "-")),
      string.format("Role: %s", current_job_role ~= "" and current_job_role or "-"),
      string.format("Current Level: %d", actor.level or 1),
      string.format("EXP To Next Level: %d", to_next),
    },
  })
  table.insert(items, {
    id = "entry",
    label = build_meter(hp_label, actor.hp or 0, actor.max_hp or 0, 14, nil, meter_style, meter_label_width),
    detail_title = is_ja and "HP詳細" or "HP Detail",
    detail_lines = is_ja and {
      string.format("現在HP: %d/%d (%s)", actor.hp or 0, actor.max_hp or 0, hp_ratio),
      string.format("回復必要量: %d", math.max((actor.max_hp or 0) - (actor.hp or 0), 0)),
      "戦闘開始時はこのHPから処理されます。",
    } or {
      string.format("Current HP: %d/%d (%s)", actor.hp or 0, actor.max_hp or 0, hp_ratio),
      string.format("Recover Needed: %d", math.max((actor.max_hp or 0) - (actor.hp or 0), 0)),
      "Battle starts from this HP state.",
    },
  })
  table.insert(items, {
    id = "entry",
    label = build_meter(exp_label, actor.exp or 0, actor.next_level or 0, 14, nil, meter_style, meter_label_width),
    detail_title = is_ja and "経験値詳細" or "EXP Detail",
    detail_lines = is_ja and {
      string.format("現在EXP: %d/%d (%s)", actor.exp or 0, actor.next_level or 0, exp_ratio),
      string.format("次レベルまで: %d", to_next),
      "ジョブ変更してもプレイヤーレベルEXPは維持されます。",
    } or {
      string.format("Current EXP: %d/%d (%s)", actor.exp or 0, actor.next_level or 0, exp_ratio),
      string.format("EXP To Next: %d", to_next),
      "Player level EXP is kept across job changes.",
    },
  })
  table.insert(items, {
    id = "entry",
    label = with_icon(
      "󰓥",
      string.format(
        "%s %d(%s)  %s %d(%s)  SPD %d(%s)  %s %d",
        i18n.t("label_atk", lang),
        actor.atk or 0,
        signed_value(snapshot.atk_diff),
        i18n.t("label_def", lang),
        actor.def or 0,
        signed_value(snapshot.def_diff),
        actor.speed or 0,
        signed_value(snapshot.speed_diff),
        i18n.t("label_gold", lang),
        ((state.currency or {}).gold) or 0
      )
    ),
    detail_title = is_ja and "戦闘ステータス" or "Combat Status",
    detail_lines = is_ja and {
      string.format("現在ATK: %d", actor.atk or 0),
      string.format("現在DEF: %d", actor.def or 0),
      string.format("現在SPD: %d", actor.speed or 0),
      string.format("推定与ダメージ: %d", snapshot.outgoing),
      string.format("推定被ダメージ: %d", snapshot.incoming),
      snapshot.danger_reason,
      string.format("現在Gold: %d", ((state.currency or {}).gold) or 0),
    } or {
      string.format("Current ATK: %d", actor.atk or 0),
      string.format("Current DEF: %d", actor.def or 0),
      string.format("Current SPD: %d", actor.speed or 0),
      string.format("Estimated Outgoing: %d", snapshot.outgoing),
      string.format("Estimated Incoming: %d", snapshot.incoming),
      snapshot.danger_reason,
      string.format("Current Gold: %d", ((state.currency or {}).gold) or 0),
    },
  })
  table.insert(items, {
    id = "entry",
    action_id = "purchase",
    keep_open = true,
    label = with_status_tag(with_icon(
      "󰏓",
      is_ja
          and string.format("装備購入  候補 %d件  Gold %d", affordable_count, gold)
        or string.format("Purchase Gear  %d options  Gold %d", affordable_count, gold)
    ), "change", lang),
    detail_title = is_ja and "装備購入" or "Purchase Gear",
    detail_lines = is_ja and {
      string.format("現在Gold: %d", gold),
      string.format("購入可能候補: %d件", affordable_count),
      "購入画面を開いて装備を追加できます。",
    } or {
      string.format("Current Gold: %d", gold),
      string.format("Affordable Options: %d", affordable_count),
      "Open purchase menu to add equipment.",
    },
  })
  table.insert(items, {
    id = "entry",
    action_id = "sell",
    keep_open = true,
    label = with_status_tag(with_icon(
      "󰆏",
      is_ja
          and string.format("装備売却  売却可能 %d件  Gold %d", sellable_count, gold)
        or string.format("Sell Gear  %d sellable  Gold %d", sellable_count, gold)
    ), "change", lang),
    detail_title = is_ja and "装備売却" or "Sell Gear",
    detail_lines = is_ja and {
      string.format("現在Gold: %d", gold),
      string.format("売却可能装備: %d件", sellable_count),
      "売却画面で未装備の所持品を整理できます。",
    } or {
      string.format("Current Gold: %d", gold),
      string.format("Sellable Items: %d", sellable_count),
      "Open sell menu to clear unequipped inventory.",
    },
  })
  local axis_label = is_ja
      and string.format("突破力 %d  安定性 %d  対象 %s", snapshot.breakthrough, snapshot.stability, snapshot.enemy_name)
    or string.format("Breakthrough %d  Stability %d  vs %s", snapshot.breakthrough, snapshot.stability, snapshot.enemy_name)
  table.insert(items, {
    id = "entry",
    label = with_icon("󰄦", axis_label),
    detail_title = is_ja and "比較軸" or "Comparison Axis",
    detail_lines = is_ja and {
      string.format("突破力: %d", snapshot.breakthrough),
      string.format("安定性: %d", snapshot.stability),
      string.format("比較対象: %s", snapshot.enemy_name),
      string.format("推定与ダメージ: %d", snapshot.outgoing),
      string.format("推定被ダメージ: %d", snapshot.incoming),
    } or {
      string.format("Breakthrough: %d", snapshot.breakthrough),
      string.format("Stability: %d", snapshot.stability),
      string.format("Compared Enemy: %s", snapshot.enemy_name),
      string.format("Estimated Outgoing: %d", snapshot.outgoing),
      string.format("Estimated Incoming: %d", snapshot.incoming),
    },
  })
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = status_section_title("󰇽", is_ja and "装備と技能" or "Loadout & Skills") })

  local equipment = state.equipment or {}
  local slot_order = { "weapon", "armor", "accessory" }
  for _, slot in ipairs(slot_order) do
    local item_id = equipment[slot]
    local item = ITEM_BY_ID[item_id]
    local slot_label = menu_locale.slot_label(slot, lang)
    local item_name = resolve_item_name(item, lang)
    local bonus_text = build_item_bonus_text(item, lang)
    table.insert(items, {
      id = "entry",
      action_id = "equip",
      keep_open = true,
      label = with_status_tag(string.format("%s %s | %s", slot_label, item_name, bonus_text), "detail", lang),
      detail_title = is_ja and "装備詳細" or "Equipment Detail",
      detail_lines = {
        string.format("%s: %s", slot_label, item_name),
        bonus_text,
        resolve_text(item and item.flavor or nil, lang),
      },
    })
  end

  local pets = state.pet_party or {}
  local pet_parts = {}
  for _, pet in ipairs(pets) do
    if pet and (pet.hp or 0) > 0 then
      table.insert(pet_parts, string.format("%s %d/%d", pet.name or pet.id or "Pet", pet.hp or 0, pet.max_hp or 0))
    end
  end
  if #pet_parts > 0 then
    table.insert(items, {
      id = "entry",
      label = string.format("%s %s", is_ja and "ペット隊列" or "Pet Party", table.concat(pet_parts, " | ")),
      detail_title = is_ja and "ペット詳細" or "Pet Detail",
      detail_lines = pet_parts,
    })
  end

  local active_skills = {}
  local passive_skills = {}
  for _, skill in ipairs((current_job and current_job.skills) or {}) do
    if skills.is_learned(state.skills, skill.id) then
      local enabled = skills.is_enabled(state.skill_settings, skill.id, skill.kind)
      local status_text = enabled and "ON" or "OFF"
      local skill_name = (lang == "en" and (skill.name_en or skill.name)) or (skill.name or skill.name_en or skill.id)
      local line = string.format("Lv%d %s [%s]", skill.level or 1, skill_name, status_text)
      if skill.kind == "active" then
        table.insert(active_skills, line)
      else
        table.insert(passive_skills, line)
      end
    end
  end
  local empty_skill_text = is_ja and "解放待ち (ジョブLvで習得)" or "Pending unlocks (raise job level)"
  local active_text = #active_skills > 0 and table.concat(active_skills, " / ") or empty_skill_text
  local passive_text = #passive_skills > 0 and table.concat(passive_skills, " / ") or empty_skill_text
  table.insert(items, {
    id = "entry",
    action_id = "skills",
    keep_open = true,
    label = with_status_tag(string.format("%s %s", is_ja and "スキル" or "Skill", active_text), "toggle", lang),
    detail_title = is_ja and "アクティブスキル" or "Active Skills",
    detail_lines = active_skills,
  })
  table.insert(items, {
    id = "entry",
    action_id = "skills",
    keep_open = true,
    label = with_status_tag(string.format("%s %s", is_ja and "パッシブ" or "Passive", passive_text), "toggle", lang),
    detail_title = is_ja and "パッシブスキル" or "Passive Skills",
    detail_lines = passive_skills,
  })

  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = status_section_title("󰢚", is_ja and "進行" or "Progress") })
  table.insert(items, {
    id = "entry",
    action_id = "stage",
    keep_open = true,
    label = build_meter(with_icon("󰢚", i18n.t("label_progress", lang)), stage_info.current_floor, stage_info.total_floors, 14, stage_info.text, meter_style),
    detail_title = is_ja and "進行バー詳細" or "Progress Meter",
    detail_lines = is_ja and {
      string.format("現在: %d/%d (%s)", stage_info.current_floor, stage_info.total_floors, floor_ratio),
      string.format("現在位置: %s", stage_info.text),
      "ステージ選択で開始地点を変更できます。",
    } or {
      string.format("Current: %d/%d (%s)", stage_info.current_floor, stage_info.total_floors, floor_ratio),
      string.format("Location: %s", stage_info.text),
      "You can change start point from Stage action.",
    },
  })
  table.insert(items, {
    id = "entry",
    label = with_icon(
      "󰳞",
      string.format(
        "%s %d/%d  %s %d",
        i18n.t("label_floor_step", lang),
        stage_info.floor_step,
        stage_info.floor_length,
        i18n.t("label_distance", lang),
        (state.progress or {}).distance or 0
      )
    ),
    detail_title = is_ja and "フロア歩数" or "Floor Step",
    detail_lines = is_ja and {
      string.format("現在歩数: %d/%d", stage_info.floor_step, stage_info.floor_length),
      string.format("累計距離: %d", (state.progress or {}).distance or 0),
      "歩数が満たされると次フロアへ進行します。",
    } or {
      string.format("Current Step: %d/%d", stage_info.floor_step, stage_info.floor_length),
      string.format("Total Distance: %d", (state.progress or {}).distance or 0),
      "You advance when floor step is filled.",
    },
  })

  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = status_section_title("󰈞", is_ja and "入力統計" or "Input Metrics") })
  local metrics_lines = menu_locale.build_metrics_detail_lines(state.metrics or {}, lang)
  table.insert(items, {
    id = "entry",
    label = with_icon("󰈞", build_metrics_summary_line(state.metrics or {}, lang)),
    detail_title = i18n.t("metrics_detail_title", lang),
    detail_lines = metrics_lines,
    open_detail_on_enter = true,
    keep_open = true,
  })
  return items
end

-- クレジットタブで表示する行をまとめる。
local function build_credits_items(lang)
  local items = {}
  for _, line in ipairs(build_credits_art()) do
    table.insert(items, { id = "art", label = line })
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = i18n.t("credits_title", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_created", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_ui", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_thanks", lang) })
  -- 感謝とフィードバック募集の本文を追加し、読み物としての満足感を高める。
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_01", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_02", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_03", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_04", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_05", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_06", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_07", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_08", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_09", lang) })
  table.insert(items, { id = "entry", label = i18n.t("credits_line_message_10", lang) })
  return items
end

local function count_known(entries)
  local known = 0
  local total = #entries
  for _, entry in ipairs(entries or {}) do
    if entry and entry.known then
      known = known + 1
    end
  end
  return known, total
end

local function pad_right(text, width)
  local safe_text = text or ""
  local safe_width = math.max(tonumber(width) or 0, 0)
  local gap = safe_width - util.display_width(safe_text)
  if gap <= 0 then
    return safe_text
  end
  return safe_text .. string.rep(" ", gap)
end

local function build_inline_meter(current, total, width, meter_style)
  local ratio = clamp_ratio(current, total)
  local bar_width = math.max(tonumber(width) or 10, 6)
  local filled = math.floor(ratio * bar_width + 0.5)
  local empty = math.max(bar_width - filled, 0)
  local style = meter_style or { on = "▰", off = "▱" }
  return string.rep(style.on, filled) .. string.rep(style.off, empty)
end

local function rarity_icon(rarity)
  if rarity == "rare" then
    return "󰎵"
  end
  if rarity == "pet" then
    return "󰚩"
  end
  return "󰄴"
end

local function slot_icon(slot)
  if slot == "weapon" then
    return "󰓥"
  end
  if slot == "armor" then
    return ""
  end
  if slot == "accessory" then
    return "󰓒"
  end
  return "󰏫"
end

-- 敵図鑑の達成率は「遭遇回数」ではなく「ドロップ解放率」で評価する。
local function resolve_drop_progress(entry)
  local known = entry and entry.known == true
  if not known then
    return 0, math.max(tonumber(entry and entry.drop_tiers and (entry.drop_tiers.common or 0)) or 0, 0)
      + math.max(tonumber(entry and entry.drop_tiers and (entry.drop_tiers.rare or 0)) or 0, 0)
      + math.max(tonumber(entry and entry.drop_tiers and (entry.drop_tiers.pet or 0)) or 0, 0)
  end
  local unlocked = 0
  for _, drop in ipairs((entry and entry.drops) or {}) do
    if drop and drop.known then
      unlocked = unlocked + 1
    end
  end
  local tiers = entry and entry.drop_tiers or {}
  local total = math.max(tonumber(tiers.common) or 0, 0)
    + math.max(tonumber(tiers.rare) or 0, 0)
    + math.max(tonumber(tiers.pet) or 0, 0)
  if total <= 0 then
    total = #((entry and entry.drops) or {})
  end
  return unlocked, total
end

-- 解放済みドロップの比率から達成バッジを決定する。
local function build_mastery_badge(unlocked, total, known)
  if not known then
    return "·"
  end
  local safe_total = math.max(tonumber(total) or 0, 0)
  local safe_unlocked = math.max(tonumber(unlocked) or 0, 0)
  if safe_total <= 0 then
    return "NEW"
  end
  local ratio = safe_unlocked / safe_total
  if ratio >= 1 then
    return "★★★"
  end
  if ratio >= 0.66 then
    return "★★☆"
  end
  if ratio > 0 then
    return "★☆☆"
  end
  return "NEW"
end

local function build_mastery_legend(lang)
  if lang == "ja" then
    return "󰓹 NEW=未解放  ★☆☆=一部  ★★☆=半分超  ★★★=全解放"
  end
  return "󰓹 NEW=none  ★☆☆=partial  ★★☆=over half  ★★★=complete"
end

local function has_active_dex_filters(sort_mode, element_filter, keyword)
  local sort_value = (sort_mode == "count" or sort_mode == "rarity") and sort_mode or "encounter"
  local element_value = tostring(element_filter or ""):lower()
  if element_value ~= "normal"
    and element_value ~= "fire"
    and element_value ~= "water"
    and element_value ~= "grass"
    and element_value ~= "light"
    and element_value ~= "dark"
  then
    element_value = "all"
  end
  local keyword_value = tostring(keyword or "")
  return sort_value ~= "encounter" or element_value ~= "all" or keyword_value ~= ""
end

local function build_dex_controls_toggle_label(show_controls, has_active, lang)
  if show_controls then
    if lang == "ja" then
      return "▼ 詳細フィルタを閉じる"
    end
    return "▼ Close Filters"
  end
  if lang == "ja" then
    if has_active then
      return "▶ 詳細フィルタを開く (適用中)"
    end
    return "▶ 詳細フィルタを開く"
  end
  if has_active then
    return "▶ Open Filters (Active)"
  end
  return "▶ Open Filters"
end

local function normalize_dex_sort(sort_mode)
  if sort_mode == "count" or sort_mode == "rarity" then
    return sort_mode
  end
  return "encounter"
end

local function next_dex_sort(sort_mode)
  local current = normalize_dex_sort(sort_mode)
  if current == "encounter" then
    return "count"
  end
  if current == "count" then
    return "rarity"
  end
  return "encounter"
end

local function dex_sort_label(sort_mode, lang)
  local current = normalize_dex_sort(sort_mode)
  if current == "count" then
    return lang == "ja" and "回数順" or "By Count"
  end
  if current == "rarity" then
    return lang == "ja" and "希少順" or "By Rarity"
  end
  return lang == "ja" and "遭遇順" or "By Encounter"
end

local function build_dex_sort_label(sort_mode, lang)
  local current = normalize_dex_sort(sort_mode)
  local next_mode = next_dex_sort(current)
  if lang == "ja" then
    return string.format("󰒺 並び: %s  (Enterで%s)", dex_sort_label(current, lang), dex_sort_label(next_mode, lang))
  end
  return string.format("󰒺 Sort: %s  (Enter -> %s)", dex_sort_label(current, lang), dex_sort_label(next_mode, lang))
end

local function normalize_element_filter(element_id)
  local value = tostring(element_id or ""):lower()
  if value == "normal" or value == "fire" or value == "water" or value == "grass" or value == "light" or value == "dark" then
    return value
  end
  return "all"
end

local function next_element_filter(element_id)
  local order = { "all", "normal", "fire", "water", "grass", "light", "dark" }
  local current = normalize_element_filter(element_id)
  for index, value in ipairs(order) do
    if value == current then
      return order[(index % #order) + 1]
    end
  end
  return "all"
end

local function element_filter_label(element_id, lang)
  local current = normalize_element_filter(element_id)
  if current == "all" then
    return lang == "ja" and "すべて" or "All"
  end
  return element.label(current, lang)
end

local function build_dex_element_label(element_id, lang)
  local current = normalize_element_filter(element_id)
  local next_value = next_element_filter(current)
  if lang == "ja" then
    return string.format("󱧶 属性: %s  (Enterで%s)", element_filter_label(current, lang), element_filter_label(next_value, lang))
  end
  return string.format("󱧶 Element: %s  (Enter -> %s)", element_filter_label(current, lang), element_filter_label(next_value, lang))
end

local function normalize_keyword(keyword)
  return tostring(keyword or "")
end

local function split_search_tokens(text)
  local tokens = {}
  local source = tostring(text or ""):lower()
  for token in source:gmatch("[%w_]+") do
    local normalized = token:gsub("^_+", ""):gsub("_+$", "")
    if #normalized >= 3 then
      table.insert(tokens, normalized)
    end
  end
  return tokens
end

local function build_keyword_options(enemy_entries, item_entries)
  local score = {}
  local function push(entry)
    if not entry or entry.known == false then
      return
    end
    for _, token in ipairs(split_search_tokens(entry.id)) do
      score[token] = (score[token] or 0) + 1
    end
    for _, token in ipairs(split_search_tokens(entry.name)) do
      score[token] = (score[token] or 0) + 1
    end
  end
  for _, entry in ipairs(enemy_entries or {}) do
    push(entry)
  end
  for _, entry in ipairs(item_entries or {}) do
    push(entry)
  end
  local tokens = {}
  for token, _ in pairs(score) do
    table.insert(tokens, token)
  end
  table.sort(tokens, function(a, b)
    if score[a] == score[b] then
      return a < b
    end
    return score[a] > score[b]
  end)
  local picked = { "" }
  for _, token in ipairs(tokens) do
    if #picked > 8 then
      break
    end
    table.insert(picked, token)
  end
  return picked
end

local function next_keyword(current, keywords)
  local normalized = normalize_keyword(current)
  local options = keywords or { "" }
  if #options == 0 then
    return ""
  end
  for index, token in ipairs(options) do
    if token == normalized then
      return options[(index % #options) + 1]
    end
  end
  return options[1]
end

local function build_dex_keyword_label(keyword, keywords, lang)
  local current = normalize_keyword(keyword)
  local next_value = next_keyword(current, keywords)
  local current_text = current ~= "" and current or (lang == "ja" and "なし" or "None")
  local next_text = next_value ~= "" and next_value or (lang == "ja" and "なし" or "None")
  if lang == "ja" then
    return string.format("󰈞 検索: %s  (Enterで%s)", current_text, next_text)
  end
  return string.format("󰈞 Search: %s  (Enter -> %s)", current_text, next_text)
end

local function entry_matches_keyword(entry, keyword)
  local token = normalize_keyword(keyword):lower()
  if token == "" then
    return true
  end
  if not entry or entry.known == false then
    return false
  end
  local id_text = tostring(entry.id or ""):lower()
  local name_text = tostring(entry.name or ""):lower()
  local flavor_text = tostring(entry.flavor or ""):lower()
  return id_text:find(token, 1, true) ~= nil
    or name_text:find(token, 1, true) ~= nil
    or flavor_text:find(token, 1, true) ~= nil
end

local function entry_matches_element(entry, element_filter)
  local target = normalize_element_filter(element_filter)
  if target == "all" then
    return true
  end
  return tostring(entry and entry.element_id or "") == target
end

local function filter_entries(entries, element_filter, keyword)
  local filtered = {}
  for _, entry in ipairs(entries or {}) do
    if entry_matches_element(entry, element_filter) and entry_matches_keyword(entry, keyword) then
      table.insert(filtered, entry)
    end
  end
  return filtered
end

local function enemy_rarity_rank(entry)
  if not entry or entry.known == false then
    return 0
  end
  if entry.is_boss then
    return 4
  end
  if tonumber(entry.exp_multiplier) and tonumber(entry.exp_multiplier) >= 20 then
    return 3
  end
  local tiers = entry.drop_tiers or {}
  if (tiers.pet or 0) > 0 then
    return 3
  end
  if (tiers.rare or 0) > 0 then
    return 2
  end
  return 1
end

local function item_rarity_rank(entry)
  if not entry or entry.known == false then
    return 0
  end
  if entry.rarity == "pet" then
    return 3
  end
  if entry.rarity == "rare" then
    return 2
  end
  return 1
end

local function sort_entries(entries, sort_mode, kind)
  local current = normalize_dex_sort(sort_mode)
  if current == "encounter" then
    return entries
  end
  local sorted = {}
  for _, entry in ipairs(entries or {}) do
    table.insert(sorted, entry)
  end
  table.sort(sorted, function(a, b)
    if a.known ~= b.known then
      return a.known
    end
    if current == "count" then
      if (a.count or 0) ~= (b.count or 0) then
        return (a.count or 0) > (b.count or 0)
      end
    elseif current == "rarity" then
      local left_rank = kind == "enemy" and enemy_rarity_rank(a) or item_rarity_rank(a)
      local right_rank = kind == "enemy" and enemy_rarity_rank(b) or item_rarity_rank(b)
      if left_rank ~= right_rank then
        return left_rank > right_rank
      end
      if (a.count or 0) ~= (b.count or 0) then
        return (a.count or 0) > (b.count or 0)
      end
    end
    if (a.first_time or 0) ~= (b.first_time or 0) then
      return (a.first_time or 0) < (b.first_time or 0)
    end
    return (a.order_index or 0) < (b.order_index or 0)
  end)
  return sorted
end

local function build_enemy_tile_label(entry, index, unknown_label)
  local known = entry and entry.known ~= false
  local icon = known and ((entry and entry.icon) or "") or ""
  if icon == "" then
    icon = known and "󰆈" or "󰇘"
  end
  local name = known and (entry.name or unknown_label) or unknown_label
  local element_text = known and (entry.element_label or unknown_label) or unknown_label
  local count_text = known and tostring(tonumber(entry and entry.count) or 0) or "?"
  local drop_unlocked, drop_total = resolve_drop_progress(entry)
  local index_text = string.format("%03d", tonumber(index) or 0)
  local name_col = pad_right(util.clamp_line(name, 16), 16)
  local element_col = pad_right(util.clamp_line(element_text, 8), 8)
  local badge = build_mastery_badge(drop_unlocked, drop_total, known)
  local drop_text = known and string.format("%d/%d", drop_unlocked, drop_total) or "?/?"
  return string.format("№%s  %s %s [%s] %s 󰆧%s ×%s", index_text, icon, name_col, element_col, badge, drop_text, count_text)
end

local function build_item_tile_label(entry, index, unknown_label)
  local known = entry and entry.known ~= false
  local icon = known and ((entry and entry.icon) or "") or ""
  if icon == "" then
    icon = known and "󰏫" or "󰇘"
  end
  local name = known and (entry.name or unknown_label) or unknown_label
  local count_text = known and tostring(tonumber(entry and entry.count) or 0) or "?"
  local index_text = string.format("%03d", tonumber(index) or 0)
  local slot_mark = slot_icon(entry and entry.slot)
  local rarity_mark = rarity_icon(entry and entry.rarity)
  local name_col = pad_right(util.clamp_line(name, 16), 16)
  local badge = build_mastery_badge(known and 1 or 0, 1, known)
  return string.format("№%s  %s %s %s%s %s ×%s", index_text, icon, name_col, slot_mark, rarity_mark, badge, count_text)
end

local function build_dex_summary_line(icon, title, known, total, meter_style)
  local meter = build_inline_meter(known, total, 10, meter_style)
  local title_col = pad_right(util.clamp_line(title, 8), 8)
  local count_col = string.format("%3d/%-3d", tonumber(known) or 0, tonumber(total) or 0)
  return string.format("%s %s %s [%s]", icon, title_col, count_col, pad_right(meter, 10))
end

local function build_dex_summary_pair(lang, known_enemy, total_enemy, known_item, total_item, meter_style)
  local enemy = build_dex_summary_line("󰆧", i18n.t("dex_title_enemies", lang), known_enemy, total_enemy, meter_style)
  local item = build_dex_summary_line("󰓥", i18n.t("dex_title_items", lang), known_item, total_item, meter_style)
  return enemy .. "   " .. item
end

local function normalize_dex_mode(mode)
  if mode == "item" or mode == "all" then
    return mode
  end
  return "enemy"
end

local function next_dex_mode(mode)
  local current = normalize_dex_mode(mode)
  if current == "enemy" then
    return "item"
  end
  if current == "item" then
    return "all"
  end
  return "enemy"
end

local function mode_label(mode, lang)
  if mode == "item" then
    return i18n.t("dex_title_items", lang)
  end
  if mode == "all" then
    if lang == "ja" then
      return "すべて"
    end
    return "Both"
  end
  return i18n.t("dex_title_enemies", lang)
end

local function build_dex_mode_label(mode, lang)
  local current = normalize_dex_mode(mode)
  local next_mode = next_dex_mode(current)
  if lang == "ja" then
    return string.format("󰈔 表示: %s  (Enterで%sへ)", mode_label(current, lang), mode_label(next_mode, lang))
  end
  return string.format("󰈔 View: %s  (Enter -> %s)", mode_label(current, lang), mode_label(next_mode, lang))
end

local function build_dex_hint_label(lang)
  if lang == "ja" then
    return "󰌑 Enter: 決定  j/k: 移動  Tab: タブ"
  end
  return "󰌑 Enter: Select  j/k: Move  Tab: Switch Tab"
end

local function build_dex_filter_summary(sort_mode, element_filter, keyword, lang)
  local sort_text = dex_sort_label(sort_mode, lang)
  local element_text = element_filter_label(element_filter, lang)
  local keyword_text = normalize_keyword(keyword)
  if keyword_text == "" then
    keyword_text = lang == "ja" and "なし" or "None"
  end
  if lang == "ja" then
    return string.format("󰦨 並び:%s  属性:%s  検索:%s", sort_text, element_text, keyword_text)
  end
  return string.format("󰦨 Sort:%s  Element:%s  Search:%s", sort_text, element_text, keyword_text)
end

local function pick_dex_entries(entries, known_limit, unknown_limit)
  local visible = {}
  local known_count = 0
  local unknown_count = 0
  local hidden = 0
  for index, entry in ipairs(entries or {}) do
    local known = entry and entry.known == true
    if known then
      if known_count < known_limit then
        table.insert(visible, { entry = entry, index = index })
      else
        hidden = hidden + 1
      end
      known_count = known_count + 1
    else
      if unknown_count < unknown_limit then
        table.insert(visible, { entry = entry, index = index })
      else
        hidden = hidden + 1
      end
      unknown_count = unknown_count + 1
    end
  end
  return visible, hidden
end

local function build_more_label(hidden_count, lang)
  local safe_hidden = math.max(tonumber(hidden_count) or 0, 0)
  if safe_hidden <= 0 then
    return ""
  end
  if lang == "ja" then
    return string.format("󰇘 さらに %d 件は省略表示中", safe_hidden)
  end
  return string.format("󰇘 %d more entries are collapsed", safe_hidden)
end

local function build_dex_toggle_label(lang, kind, expand, hidden_count)
  local safe_hidden = math.max(tonumber(hidden_count) or 0, 0)
  local target = kind == "enemy" and i18n.t("dex_title_enemies", lang) or i18n.t("dex_title_items", lang)
  if lang == "ja" then
    if expand then
      return string.format("▶ %sを展開表示 (%d件)", target, safe_hidden)
    end
    return string.format("▼ %sを折りたたむ", target)
  end
  if expand then
    return string.format("▶ Expand %s (%d hidden)", target, safe_hidden)
  end
  return string.format("▼ Collapse %s", target)
end

-- レアリティの表示名を整形する。
local function rarity_label(rarity, lang)
  if rarity == "rare" then
    return i18n.t("dex_rarity_rare", lang)
  end
  if rarity == "pet" then
    return i18n.t("dex_rarity_pet", lang)
  end
  return i18n.t("dex_rarity_common", lang)
end

local function build_enemy_danger_label(entry, lang)
  local stats = (entry and entry.stats) or {}
  local score = (stats.hp or 0)
    + ((stats.atk or 0) * 2)
    + ((stats.def or 0) * 2)
    + (stats.speed or 0)
    + (math.max(tonumber(entry and entry.exp_multiplier) or 1, 1) * 1.5)
  if score >= 80 then
    return lang == "ja" and "極高" or "Extreme"
  end
  if score >= 45 then
    return lang == "ja" and "高" or "High"
  end
  if score >= 24 then
    return lang == "ja" and "中" or "Medium"
  end
  return lang == "ja" and "低" or "Low"
end

local function build_drop_band(entry, config)
  local drop = ((config or {}).battle or {}).drop_rates or {}
  local common = math.max(tonumber(drop.common) or 0, 0)
  local rare = math.max(tonumber(drop.rare) or 0, 0)
  local pet = math.max(tonumber(drop.pet) or 0, 0)
  if entry and entry.is_boss then
    local bonus = math.max(tonumber(drop.boss_bonus) or 0, 0)
    common = common + bonus
    rare = rare + math.max(math.floor(bonus / 2), 0)
    pet = pet + math.max(bonus - math.floor(bonus / 2), 0)
  end
  return string.format("C%d%% / R%d%% / P%d%%", common, rare, pet)
end

local DETAIL_CARD_INNER_WIDTH = 30

-- 詳細カードの1行を固定幅へ整形し、表示崩れを防ぐ。
local function detail_card_line(text)
  local safe_text = util.clamp_line(text or "", DETAIL_CARD_INNER_WIDTH)
  local gap = math.max(DETAIL_CARD_INNER_WIDTH - util.display_width(safe_text), 0)
  return "┃" .. safe_text .. string.rep(" ", gap) .. "┃"
end

local function detail_card_top()
  return "┏" .. string.rep("━", DETAIL_CARD_INNER_WIDTH) .. "┓"
end

local function detail_card_mid()
  return "┣" .. string.rep("━", DETAIL_CARD_INNER_WIDTH) .. "┫"
end

local function detail_card_bottom()
  return "┗" .. string.rep("━", DETAIL_CARD_INNER_WIDTH) .. "┛"
end

local function detail_stat_meter(value, max_value, width)
  local current = math.max(tonumber(value) or 0, 0)
  local max_v = math.max(tonumber(max_value) or 1, 1)
  local bar_w = math.max(tonumber(width) or 8, 4)
  local ratio = math.max(math.min(current / max_v, 1), 0)
  local filled = math.floor(ratio * bar_w + 0.5)
  local empty = math.max(bar_w - filled, 0)
  return string.format("[%s%s]", string.rep("▰", filled), string.rep("▱", empty))
end

local function wrap_detail_text(text, width)
  local lines = {}
  local limit = math.max(tonumber(width) or (DETAIL_CARD_INNER_WIDTH - 3), 10)
  local chars = util.split_utf8(text or "")
  if #chars == 0 then
    return lines
  end
  local buffer = {}
  local current_width = 0
  for _, ch in ipairs(chars) do
    local ch_width = util.display_width(ch)
    if current_width + ch_width > limit and #buffer > 0 then
      table.insert(lines, table.concat(buffer, ""))
      buffer = { ch }
      current_width = ch_width
    else
      table.insert(buffer, ch)
      current_width = current_width + ch_width
    end
  end
  if #buffer > 0 then
    table.insert(lines, table.concat(buffer, ""))
  end
  return lines
end

local function detail_type_value(kind, lang)
  return kind == "enemy" and i18n.t("dex_detail_kind_enemy", lang) or i18n.t("dex_detail_kind_item", lang)
end

local function append_flavor(lines, entry, lang)
  local flavor = entry and entry.flavor or ""
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(lang == "ja" and "Flavor 物語" or "Flavor"))
  if flavor == "" then
    table.insert(lines, detail_card_line(" -"))
    return
  end
  for _, line in ipairs(wrap_detail_text(flavor, DETAIL_CARD_INNER_WIDTH - 2)) do
    table.insert(lines, detail_card_line(" " .. line))
  end
end

local function append_enemy_card(lines, entry, lang, unknown_label, config)
  local is_known = entry and entry.known == true
  local icon = is_known and ((entry and entry.icon) or "󰆈") or "󰇘"
  local name = is_known and (entry.name or unknown_label) or unknown_label
  local element_text = is_known and (entry.element_label or unknown_label) or unknown_label
  local count = is_known and tostring(tonumber(entry and entry.count) or 0) or unknown_label
  local drop_unlocked, drop_total = resolve_drop_progress(entry)
  local badge = build_mastery_badge(drop_unlocked, drop_total, is_known)
  local mastery_text = is_known and string.format("%d/%d", drop_unlocked, drop_total) or unknown_label
  table.insert(lines, detail_card_line(string.format("[%s]", lang == "ja" and "ENEMY DEX" or "ENEMY DEX")))
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(string.format("%s %s", icon, name)))
  table.insert(lines, detail_card_line(string.format("Type: %s", detail_type_value("enemy", lang))))
  table.insert(lines, detail_card_line(string.format("Element: %s", element_text)))
  table.insert(lines, detail_card_line(string.format("Seen: %s  Mastery: %s (%s)", count, badge, mastery_text)))
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(lang == "ja" and "Battle Data 戦闘情報" or "Battle Data"))
  if not is_known then
    table.insert(lines, detail_card_line(string.format("%s %s", i18n.t("dex_detail_danger", lang), unknown_label)))
    table.insert(lines, detail_card_line(string.format("%s %s", i18n.t("dex_detail_drop_band", lang), unknown_label)))
  else
    local stats = entry.stats or {}
    table.insert(lines, detail_card_line(string.format("HP  %s %d", detail_stat_meter(stats.hp or 0, 60, 6), stats.hp or 0)))
    table.insert(lines, detail_card_line(string.format("ATK %s %d", detail_stat_meter(stats.atk or 0, 20, 6), stats.atk or 0)))
    table.insert(lines, detail_card_line(string.format("DEF %s %d", detail_stat_meter(stats.def or 0, 20, 6), stats.def or 0)))
    table.insert(lines, detail_card_line(string.format("SPD %s %d", detail_stat_meter(stats.speed or 0, 10, 6), stats.speed or 0)))
    table.insert(lines, detail_card_line(string.format("%s %s", i18n.t("dex_detail_danger", lang), build_enemy_danger_label(entry, lang))))
    table.insert(lines, detail_card_line(string.format("%s %s", i18n.t("dex_detail_drop_band", lang), build_drop_band(entry, config))))
  end
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(lang == "ja" and "Drops ドロップ一覧" or "Drops"))
  if not is_known then
    table.insert(lines, detail_card_line(" ◌ ???"))
    return
  end
  if #(entry.drops or {}) == 0 then
    table.insert(lines, detail_card_line(" ◌ -"))
    return
  end
  for _, drop in ipairs(entry.drops or {}) do
    local marker = drop.known and "◉" or "◌"
    local drop_name = drop.name or unknown_label
    table.insert(lines, detail_card_line(string.format(" %s %s", marker, drop_name)))
  end
end

local function append_item_card(lines, entry, lang, unknown_label)
  local is_known = entry and entry.known == true
  local icon = is_known and ((entry and entry.icon) or "󰏫") or "󰇘"
  local name = is_known and (entry.name or unknown_label) or unknown_label
  local slot_text = is_known and (entry.slot and menu_locale.slot_label(entry.slot, lang) or unknown_label) or unknown_label
  local rarity_text = is_known and rarity_label(entry.rarity, lang) or unknown_label
  local element_text = is_known and (entry.element_label or unknown_label) or unknown_label
  local count = is_known and tostring(tonumber(entry and entry.count) or 0) or unknown_label
  table.insert(lines, detail_card_line(string.format("[%s]", lang == "ja" and "ITEM DEX" or "ITEM DEX")))
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(string.format("%s %s", icon, name)))
  table.insert(lines, detail_card_line(string.format("Type: %s", detail_type_value("item", lang))))
  table.insert(lines, detail_card_line(string.format("Slot: %s", slot_text)))
  table.insert(lines, detail_card_line(string.format("Seen: %s  Rarity: %s", count, rarity_text)))
  table.insert(lines, detail_card_line(string.format("Element: %s", element_text)))
  table.insert(lines, detail_card_mid())
  table.insert(lines, detail_card_line(lang == "ja" and "Item Notes 装備メモ" or "Item Notes"))
  if not is_known then
    table.insert(lines, detail_card_line(" ???"))
    return
  end
  if lang == "ja" then
    table.insert(lines, detail_card_line(" 装備効果は戦闘計算へ自動反映。"))
  else
    table.insert(lines, detail_card_line(" Equipped effects apply in battle."))
  end
end

-- 図鑑の詳細表示用に行を組み立てる。
local function build_detail_lines(entry, kind, lang, unknown_label, config)
  local lines = {}
  table.insert(lines, detail_card_top())
  if kind == "enemy" then
    append_enemy_card(lines, entry, lang, unknown_label, config)
  else
    append_item_card(lines, entry, lang, unknown_label)
  end
  append_flavor(lines, entry, lang)
  table.insert(lines, detail_card_bottom())
  return lines
end

-- 図鑑タブで表示する敵と装備の一覧を生成する。
local function build_dex_items(state, config, lang, view_state)
  local items = {}
  local enemy_entries = dex_catalog.build_enemy_entries(state, lang)
  local item_entries = dex_catalog.build_item_entries(state, lang)
  local unknown_label = i18n.t("dex_unknown", lang)
  local meter_style = resolve_meter_style(config)
  local dex_view = view_state or {}
  local mode = normalize_dex_mode(dex_view.mode)
  local sort_mode = normalize_dex_sort(dex_view.sort_mode)
  local filter_element = normalize_element_filter(dex_view.filter_element)
  local filter_keyword = normalize_keyword(dex_view.filter_keyword)
  local show_controls = dex_view.show_controls == true
  local show_all_enemies = dex_view.show_all_enemies == true
  local show_all_items = dex_view.show_all_items == true
  local menu_config = ((config or {}).ui or {}).menu or {}
  local dex_known_limit = math.max(tonumber(menu_config.dex_known_limit) or 10, 4)
  local dex_unknown_limit = math.max(tonumber(menu_config.dex_unknown_limit) or 2, 0)
  local keyword_options = build_keyword_options(enemy_entries, item_entries)
  local known_enemy, total_enemy = count_known(enemy_entries)
  local known_item, total_item = count_known(item_entries)
  local filtered_enemies = sort_entries(filter_entries(enemy_entries, filter_element, filter_keyword), sort_mode, "enemy")
  local filtered_items = sort_entries(filter_entries(item_entries, filter_element, filter_keyword), sort_mode, "item")
  local active_filters = has_active_dex_filters(sort_mode, filter_element, filter_keyword)
  table.insert(items, {
    id = "header",
    label = build_dex_summary_pair(lang, known_enemy, total_enemy, known_item, total_item, meter_style),
  })
  table.insert(items, {
    id = "dex_control",
    action = "cycle_mode",
    label = build_dex_mode_label(mode, lang),
    keep_open = true,
  })
  table.insert(items, {
    id = "dex_control",
    action = "toggle_controls",
    label = build_dex_controls_toggle_label(show_controls, active_filters, lang),
    keep_open = true,
  })
  if show_controls then
    table.insert(items, {
      id = "dex_control",
      action = "cycle_sort",
      label = build_dex_sort_label(sort_mode, lang),
      keep_open = true,
    })
    table.insert(items, {
      id = "dex_control",
      action = "cycle_filter_element",
      label = build_dex_element_label(filter_element, lang),
      keep_open = true,
    })
    table.insert(items, {
      id = "dex_control",
      action = "cycle_filter_keyword",
      keywords = keyword_options,
      label = build_dex_keyword_label(filter_keyword, keyword_options, lang),
      keep_open = true,
    })
  elseif active_filters then
    table.insert(items, { id = "header", label = build_dex_filter_summary(sort_mode, filter_element, filter_keyword, lang) })
  end
  table.insert(items, { id = "header", label = build_dex_hint_label(lang) })
  table.insert(items, { id = "spacer", label = "" })
  if mode ~= "item" then
    table.insert(items, { id = "header", label = string.format("— %s —", i18n.t("dex_title_enemies", lang)) })
    if #filtered_enemies == 0 then
      table.insert(items, { id = "empty", label = i18n.t("dex_empty_enemies", lang) })
    else
      local enemy_visible, enemy_hidden = pick_dex_entries(
        filtered_enemies,
        show_all_enemies and #filtered_enemies or dex_known_limit,
        show_all_enemies and #filtered_enemies or dex_unknown_limit
      )
      for _, picked in ipairs(enemy_visible) do
        local entry = picked.entry
        local index = picked.index
        local element_key = entry.known and ("element_" .. (entry.element_id or "normal")) or nil
        table.insert(items, {
          id = "dex_entry",
          kind = "enemy",
          label = build_enemy_tile_label(entry, index, unknown_label),
          tile_label = build_enemy_tile_label(entry, index, unknown_label),
          detail_title = entry.known and entry.name or unknown_label,
          detail_lines = build_detail_lines(entry, "enemy", lang, unknown_label, config),
          open_detail_on_enter = true,
          highlight_key = element_key,
          highlight_icon = entry.icon or "",
          keep_open = true,
        })
      end
      if enemy_hidden > 0 or show_all_enemies then
        table.insert(items, {
          id = "dex_control",
          kind = "enemy",
          action = show_all_enemies and "collapse_enemy" or "expand_enemy",
          label = build_dex_toggle_label(lang, "enemy", not show_all_enemies, enemy_hidden),
          keep_open = true,
        })
        if enemy_hidden > 0 and not show_all_enemies then
          table.insert(items, { id = "header", label = build_more_label(enemy_hidden, lang) })
        end
      end
    end
    table.insert(items, { id = "spacer", label = "" })
  end
  if mode ~= "enemy" then
    table.insert(items, { id = "header", label = string.format("— %s —", i18n.t("dex_title_items", lang)) })
    if #filtered_items == 0 then
      table.insert(items, { id = "empty", label = i18n.t("dex_empty_items", lang) })
    else
      local item_visible, item_hidden = pick_dex_entries(
        filtered_items,
        show_all_items and #filtered_items or dex_known_limit,
        show_all_items and #filtered_items or dex_unknown_limit
      )
      for _, picked in ipairs(item_visible) do
        local entry = picked.entry
        local index = picked.index
        table.insert(items, {
          id = "dex_entry",
          kind = "item",
          label = build_item_tile_label(entry, index, unknown_label),
          tile_label = build_item_tile_label(entry, index, unknown_label),
          detail_title = entry.known and entry.name or unknown_label,
          detail_lines = build_detail_lines(entry, "item", lang, unknown_label, config),
          open_detail_on_enter = true,
          keep_open = true,
        })
      end
      if item_hidden > 0 or show_all_items then
        table.insert(items, {
          id = "dex_control",
          kind = "item",
          action = show_all_items and "collapse_item" or "expand_item",
          label = build_dex_toggle_label(lang, "item", not show_all_items, item_hidden),
          keep_open = true,
        })
        if item_hidden > 0 and not show_all_items then
          table.insert(items, { id = "header", label = build_more_label(item_hidden, lang) })
        end
      end
    end
  end
  table.insert(items, { id = "spacer", label = "" })
  table.insert(items, { id = "header", label = build_mastery_legend(lang) })
  return items
end

M.build_action_items = build_action_items
M.build_config_items = build_config_items
M.build_credits_items = build_credits_items
M.build_dex_items = build_dex_items
M.build_status_detail = build_status_detail
M.build_status_items = build_status_items

return M
