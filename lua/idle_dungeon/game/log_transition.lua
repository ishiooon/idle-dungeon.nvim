-- このモジュールは状態遷移の差分から、ゲーム進行ログを追加する純粋関数を提供する。

local content = require("idle_dungeon.content")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local event_catalog = require("idle_dungeon.game.event_catalog")
local floor_progress = require("idle_dungeon.game.floor.progress")
local game_log = require("idle_dungeon.game.log")
local log_format = require("idle_dungeon.game.log_format")

local M = {}

local function is_ja_lang(lang)
  return lang == "ja" or lang == "jp"
end

local function resolve_lang(state, config)
  return ((state or {}).ui or {}).language or ((config or {}).ui or {}).language or "en"
end

local function resolve_text(value, lang)
  if type(value) ~= "table" then
    return tostring(value or "")
  end
  if lang == "en" then
    return value.en or value.ja or value.jp or ""
  end
  return value.ja or value.jp or value.en or ""
end

local function resolve_stage_intro_title(event_id, lang)
  for _, intro in ipairs(content.stage_intros or {}) do
    if intro.id == event_id then
      return resolve_text(intro.title, lang)
    end
  end
  return ""
end

local function resolve_event_title(event_id, lang)
  if not event_id then
    return ""
  end
  local event = event_catalog.find_event(event_id)
  if event then
    local title = resolve_text(event.title, lang)
    if title ~= "" then
      return title
    end
  end
  local intro_title = resolve_stage_intro_title(event_id, lang)
  if intro_title ~= "" then
    return intro_title
  end
  return tostring(event_id)
end

local function resolve_elapsed_sec(state)
  local metrics = ((state or {}).metrics) or {}
  return log_format.normalize_elapsed_sec(metrics.time_sec)
end

local function append_line(state, text, category, elapsed_sec)
  local rich_line = log_format.build_line(text, elapsed_sec, category)
  if rich_line == "" then
    return state
  end
  return game_log.append(state, rich_line)
end

-- ログ表示で扱う数値は0以上の整数として正規化する。
local function normalize_non_negative_int(value)
  return math.max(math.floor(tonumber(value) or 0), 0)
end

-- ペット一覧のHP/経験値を合計して扱う。
local function summarize_pet_progress(party)
  local hp_total = 0
  local exp_total = 0
  for _, pet in ipairs(party or {}) do
    hp_total = hp_total + normalize_non_negative_int((pet or {}).hp)
    exp_total = exp_total + normalize_non_negative_int((pet or {}).exp)
  end
  return { hp = hp_total, exp = exp_total }
end

-- 戦闘開始時スナップショットが欠けている場合でも破綻しないように補完する。
local function normalize_encounter_start(snapshot, fallback_state)
  local actor = (fallback_state or {}).actor or {}
  local fallback_pet = summarize_pet_progress((fallback_state or {}).pet_party)
  local start_hero = (snapshot or {}).hero or {}
  local start_pet = (snapshot or {}).pet or {}
  return {
    hero = {
      hp = normalize_non_negative_int(start_hero.hp or actor.hp),
      exp = normalize_non_negative_int(start_hero.exp or actor.exp),
    },
    pet = {
      hp = normalize_non_negative_int(start_pet.hp or fallback_pet.hp),
      exp = normalize_non_negative_int(start_pet.exp or fallback_pet.exp),
    },
  }
end

local function resolve_encounter_start(previous_state)
  local snapshot = (((previous_state or {}).combat or {}).encounter_start) or {}
  return normalize_encounter_start(snapshot, previous_state)
end

-- 遭遇した敵の表示名を言語設定に合わせて解決する。
local function resolve_enemy_display_name(enemy, lang, catalog_entry)
  local safe_enemy = enemy or {}
  local entry = catalog_entry or {}
  if is_ja_lang(lang) then
    return tostring(entry.name_ja or entry.name or entry.name_en or safe_enemy.name_ja or safe_enemy.name or safe_enemy.name_en or safe_enemy.id or "")
  end
  return tostring(entry.name_en or entry.name or entry.name_ja or safe_enemy.name_en or safe_enemy.name or safe_enemy.name_ja or safe_enemy.id or "")
end

-- 戦闘状態から敵アイコンと敵名を組み合わせた見出しを作る。
local function resolve_encounter_enemy_label(previous_state, lang)
  local combat = ((previous_state or {}).combat) or {}
  local enemy = combat.enemy or combat.source or {}
  local enemy_id = enemy.id
  local catalog_entry = enemy_id and enemy_catalog.find_enemy(enemy_id) or nil
  local icon = tostring((catalog_entry and catalog_entry.icon) or enemy.icon or "")
  local name = resolve_enemy_display_name(enemy, lang, catalog_entry)
  if icon ~= "" and name ~= "" then
    return string.format("%s %s", icon, name)
  end
  return icon ~= "" and icon or name
end

-- 遭遇前後の状態にペット情報が存在する場合のみペット差分を表示する。
local function should_include_pet_delta(previous_state, next_state, start, finish_pet)
  local prev_has_pet = #(((previous_state or {}).pet_party) or {}) > 0
  local next_has_pet = #(((next_state or {}).pet_party) or {}) > 0
  if prev_has_pet or next_has_pet then
    return true
  end
  if normalize_non_negative_int(((start or {}).pet or {}).hp) > 0 then
    return true
  end
  if normalize_non_negative_int(((start or {}).pet or {}).exp) > 0 then
    return true
  end
  if normalize_non_negative_int((finish_pet or {}).hp) > 0 then
    return true
  end
  if normalize_non_negative_int((finish_pet or {}).exp) > 0 then
    return true
  end
  return false
end

-- 数値差分の表示用テキストを配列へ追加する。
local function append_numeric_delta(changes, label, before, after)
  local prev_value = tonumber(before)
  local next_value = tonumber(after)
  if prev_value == nil or next_value == nil then
    return
  end
  if prev_value == next_value then
    return
  end
  table.insert(changes, string.format("%s %d->%d", label, prev_value, next_value))
end

-- 勇者の成長差分を要約して返す。変化が無ければ空文字を返す。
local function build_actor_growth_text(previous_actor, next_actor, lang)
  local changes = {}
  local prev = previous_actor or {}
  local nextv = next_actor or {}
  append_numeric_delta(changes, "MaxHP", prev.max_hp, nextv.max_hp)
  append_numeric_delta(changes, "ATK", prev.atk, nextv.atk)
  append_numeric_delta(changes, "DEF", prev.def, nextv.def)
  append_numeric_delta(changes, "SPD", prev.speed, nextv.speed)
  if #changes <= 0 then
    return ""
  end
  local body = table.concat(changes, ", ")
  if is_ja_lang(lang) then
    return "成長 " .. body
  end
  return "Growth " .. body
end

-- レベルアップ差分を独立ログ行用に整形して返す。変化が無ければ空文字を返す。
local function build_level_up_text(previous_actor, next_actor, lang)
  local changes = {}
  local prev = previous_actor or {}
  local nextv = next_actor or {}
  append_numeric_delta(changes, "Lv", prev.level, nextv.level)
  append_numeric_delta(changes, "JobLv", prev.job_level, nextv.job_level)
  if #changes <= 0 then
    return ""
  end
  local body = table.concat(changes, ", ")
  if is_ja_lang(lang) then
    return "レベルアップ: " .. body
  end
  return "Level Up: " .. body
end

-- レベル差分と成長差分を1つの独立ログ行へ集約する。
local function build_level_summary_text(previous_actor, next_actor, lang)
  local level_text = build_level_up_text(previous_actor, next_actor, lang)
  local growth_text = build_actor_growth_text(previous_actor, next_actor, lang)
  if level_text == "" and growth_text == "" then
    return ""
  end
  if level_text ~= "" and growth_text ~= "" then
    return level_text .. " | " .. growth_text
  end
  if level_text ~= "" then
    return level_text
  end
  return growth_text
end

-- 遭遇前後の勇者/ペットHP・経験値差分を1行メッセージへ整形する。
local function build_encounter_delta_text(previous_state, next_state, lang)
  local start = resolve_encounter_start(previous_state)
  local actor = (next_state or {}).actor or {}
  local pet = summarize_pet_progress((next_state or {}).pet_party)
  local enemy_label = resolve_encounter_enemy_label(previous_state, lang)
  local enemy_prefix = enemy_label ~= "" and (enemy_label .. " | ") or ""
  local hero_hp = normalize_non_negative_int(actor.hp)
  local hero_exp = normalize_non_negative_int(actor.exp)
  local include_pet_delta = should_include_pet_delta(previous_state, next_state, start, pet)
  local base_text = nil
  if is_ja_lang(lang) then
    if not include_pet_delta then
      base_text = string.format(
        "%s勇者 HP %d->%d EXP %d->%d",
        enemy_prefix,
        start.hero.hp,
        hero_hp,
        start.hero.exp,
        hero_exp
      )
      return base_text
    end
    base_text = string.format(
      "%s勇者 HP %d->%d EXP %d->%d | ペット HP %d->%d EXP %d->%d",
      enemy_prefix,
      start.hero.hp,
      hero_hp,
      start.hero.exp,
      hero_exp,
      start.pet.hp,
      pet.hp,
      start.pet.exp,
      pet.exp
    )
    return base_text
  end
  if not include_pet_delta then
    base_text = string.format(
      "%sHero HP %d->%d EXP %d->%d",
      enemy_prefix,
      start.hero.hp,
      hero_hp,
      start.hero.exp,
      hero_exp
    )
    return base_text
  end
  base_text = string.format(
    "%sHero HP %d->%d EXP %d->%d | Pet HP %d->%d EXP %d->%d",
    enemy_prefix,
    start.hero.hp,
    hero_hp,
    start.hero.exp,
    hero_exp,
    start.pet.hp,
    pet.hp,
    start.pet.exp,
    pet.exp
  )
  return base_text
end

local function append_stage_progress_logs(previous_state, next_state, config, lang, state, elapsed_sec)
  local prev_progress = (previous_state or {}).progress or {}
  local next_progress = (next_state or {}).progress or {}
  local is_ja = is_ja_lang(lang)
  if (tonumber(prev_progress.stage_id) or 0) ~= (tonumber(next_progress.stage_id) or 0) then
    local stage_name = tostring(next_progress.stage_name or "")
    if stage_name == "" then
      stage_name = tostring(next_progress.stage_id or "-")
    end
    if is_ja then
      state = append_line(state, string.format("ステージ移動: %s", stage_name), "STAGE", elapsed_sec)
    else
      state = append_line(state, string.format("Stage Move: %s", stage_name), "STAGE", elapsed_sec)
    end
  end
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local prev_floor = floor_progress.floor_index(prev_progress.distance or 0, floor_length)
  local next_floor = floor_progress.floor_index(next_progress.distance or 0, floor_length)
  if next_floor > prev_floor and (tonumber(prev_progress.stage_id) or 0) == (tonumber(next_progress.stage_id) or 0) then
    local stage_floor = floor_progress.stage_floor_distance(next_progress, floor_length) + 1
    local stage_id = tonumber(next_progress.stage_id)
    local floor_token = stage_id and string.format("%d-%d", stage_id, stage_floor) or tostring(stage_floor)
    if is_ja then
      state = append_line(state, string.format("フロア到達: %s", floor_token), "STAGE", elapsed_sec)
    else
      state = append_line(state, string.format("Floor Reached: %s", floor_token), "STAGE", elapsed_sec)
    end
  end
  return state
end

local function append_mode_logs(previous_state, next_state, lang, state, elapsed_sec)
  local prev_ui = (previous_state or {}).ui or {}
  local next_ui = (next_state or {}).ui or {}
  local prev_mode = tostring(prev_ui.mode or "")
  local next_mode = tostring(next_ui.mode or "")
  local is_ja = is_ja_lang(lang)

  -- 戦闘終了時だけ、遭遇前後の差分を1行で記録する。
  if (prev_mode == "reward" and next_mode == "move") or (prev_mode == "battle" and next_mode == "defeat") then
    local text = build_encounter_delta_text(previous_state, next_state, lang)
    state = append_line(state, text, "BATTLE", elapsed_sec)
    local level_text = build_level_summary_text((previous_state or {}).actor or {}, (next_state or {}).actor or {}, lang)
    if level_text ~= "" then
      state = append_line(state, level_text, "BATTLE", elapsed_sec)
    end
  end

  if next_mode == "stage_intro" and prev_mode ~= "stage_intro" then
    local title = resolve_event_title(next_ui.event_id, lang)
    if is_ja then
      return append_line(state, string.format("ステージ演出開始: %s", title), "EVENT", elapsed_sec)
    end
    return append_line(state, string.format("Stage Intro: %s", title), "EVENT", elapsed_sec)
  end

  return state
end

local function append_event_logs(previous_state, next_state, lang, state, elapsed_sec)
  local prev_ui = (previous_state or {}).ui or {}
  local next_ui = (next_state or {}).ui or {}
  local is_ja = is_ja_lang(lang)
  if next_ui.event_id and next_ui.event_id ~= prev_ui.event_id then
    local title = resolve_event_title(next_ui.event_id, lang)
    if next_ui.mode ~= "stage_intro" then
      if is_ja then
        state = append_line(state, string.format("イベント開始: %s", title), "EVENT", elapsed_sec)
      else
        state = append_line(state, string.format("Event Start: %s", title), "EVENT", elapsed_sec)
      end
    end
  end
  local next_message = tostring(next_ui.event_message or "")
  local prev_message = tostring(prev_ui.event_message or "")
  if next_message ~= "" and next_message ~= prev_message then
    if is_ja then
      state = append_line(state, string.format("イベント: %s", next_message), "EVENT", elapsed_sec)
    else
      state = append_line(state, string.format("Event: %s", next_message), "EVENT", elapsed_sec)
    end
  end
  return state
end

-- 前回状態と今回状態を比較し、ゲーム進行ログを追加して返す。
local function append_tick_logs(previous_state, next_state, config)
  local base = next_state or {}
  local lang = resolve_lang(base, config)
  local elapsed_sec = resolve_elapsed_sec(base)
  local state = append_mode_logs(previous_state, next_state, lang, base, elapsed_sec)
  state = append_stage_progress_logs(previous_state, next_state, config, lang, state, elapsed_sec)
  state = append_event_logs(previous_state, next_state, lang, state, elapsed_sec)
  return state
end

M.append_tick_logs = append_tick_logs

return M
