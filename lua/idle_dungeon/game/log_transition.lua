-- このモジュールは状態遷移の差分から、ゲーム進行ログを追加する純粋関数を提供する。

local content = require("idle_dungeon.content")
local enemy_catalog = require("idle_dungeon.game.enemy_catalog")
local event_catalog = require("idle_dungeon.game.event_catalog")
local floor_progress = require("idle_dungeon.game.floor.progress")
local game_log = require("idle_dungeon.game.log")

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

local function resolve_item_name(item_id, lang)
  for _, item in ipairs(content.items or {}) do
    if item.id == item_id then
      if lang == "en" then
        return item.name_en or item.name or item.id
      end
      return item.name or item.name_en or item.id
    end
  end
  return tostring(item_id or "-")
end

local function resolve_enemy_name(enemy_id, lang)
  local entry = enemy_catalog.find_enemy(enemy_id)
  if not entry then
    return tostring(enemy_id or "-")
  end
  if is_ja_lang(lang) then
    return entry.name_ja or entry.name or entry.name_en or entry.id
  end
  return entry.name_en or entry.name or entry.name_ja or entry.id
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

local function append_line(state, text)
  local line = tostring(text or "")
  if line == "" then
    return state
  end
  return game_log.append(state, line)
end

local function append_stage_progress_logs(previous_state, next_state, config, lang, state)
  local prev_progress = (previous_state or {}).progress or {}
  local next_progress = (next_state or {}).progress or {}
  local is_ja = is_ja_lang(lang)
  if (tonumber(prev_progress.stage_id) or 0) ~= (tonumber(next_progress.stage_id) or 0) then
    local stage_name = tostring(next_progress.stage_name or "")
    if stage_name == "" then
      stage_name = tostring(next_progress.stage_id or "-")
    end
    if is_ja then
      state = append_line(state, string.format("ステージ移動: %s", stage_name))
    else
      state = append_line(state, string.format("Stage Move: %s", stage_name))
    end
  end
  local floor_length = floor_progress.resolve_floor_length(config or {})
  local prev_floor = floor_progress.floor_index(prev_progress.distance or 0, floor_length)
  local next_floor = floor_progress.floor_index(next_progress.distance or 0, floor_length)
  if next_floor > prev_floor and (tonumber(prev_progress.stage_id) or 0) == (tonumber(next_progress.stage_id) or 0) then
    if is_ja then
      state = append_line(state, string.format("フロア到達: %d階", next_floor + 1))
    else
      state = append_line(state, string.format("Floor Reached: F%d", next_floor + 1))
    end
  end
  return state
end

local function append_mode_logs(previous_state, next_state, lang, state)
  local prev_ui = (previous_state or {}).ui or {}
  local next_ui = (next_state or {}).ui or {}
  local prev_mode = tostring(prev_ui.mode or "")
  local next_mode = tostring(next_ui.mode or "")
  local is_ja = is_ja_lang(lang)
  local context = { reward_logged = false }
  if prev_mode ~= "battle" and next_mode == "battle" then
    local enemy_id = (((next_state or {}).combat or {}).enemy or {}).id or (((next_state or {}).combat or {}).source or {}).id
    local enemy_name = resolve_enemy_name(enemy_id, lang)
    if is_ja then
      state = append_line(state, string.format("戦闘開始: %s", enemy_name))
    else
      state = append_line(state, string.format("Battle Start: %s", enemy_name))
    end
  end
  if prev_mode == "battle" and next_mode == "defeat" then
    local enemy_id = (((previous_state or {}).combat or {}).enemy or {}).id
    local enemy_name = resolve_enemy_name(enemy_id, lang)
    if is_ja then
      state = append_line(state, string.format("戦闘敗北: %s", enemy_name))
    else
      state = append_line(state, string.format("Battle Defeat: %s", enemy_name))
    end
  end
  if prev_mode == "defeat" and next_mode == "move" then
    if is_ja then
      state = append_line(state, "復帰: ステージ開始地点へ戻りました")
    else
      state = append_line(state, "Recovery: Returned to stage start")
    end
  end
  if prev_mode == "reward" and next_mode == "move" then
    local combat = (previous_state or {}).combat or {}
    local reward_exp = tonumber(combat.pending_exp) or 0
    local reward_gold = tonumber(combat.pending_gold) or 0
    local drop_id = combat.pending_drop and combat.pending_drop.id or nil
    context.reward_logged = true
    if drop_id then
      local item_name = resolve_item_name(drop_id, lang)
      if is_ja then
        state = append_line(state, string.format("報酬: EXP+%d Gold+%d 取得=%s", reward_exp, reward_gold, item_name))
      else
        state = append_line(state, string.format("Reward: EXP+%d Gold+%d Drop=%s", reward_exp, reward_gold, item_name))
      end
    else
      if is_ja then
        state = append_line(state, string.format("報酬: EXP+%d Gold+%d", reward_exp, reward_gold))
      else
        state = append_line(state, string.format("Reward: EXP+%d Gold+%d", reward_exp, reward_gold))
      end
    end
  end
  if next_mode == "stage_intro" and prev_mode ~= "stage_intro" then
    local title = resolve_event_title(next_ui.event_id, lang)
    if is_ja then
      state = append_line(state, string.format("ステージ演出開始: %s", title))
    else
      state = append_line(state, string.format("Stage Intro: %s", title))
    end
  end
  return state, context
end

local function append_event_logs(previous_state, next_state, lang, state)
  local prev_ui = (previous_state or {}).ui or {}
  local next_ui = (next_state or {}).ui or {}
  local is_ja = is_ja_lang(lang)
  if next_ui.event_id and next_ui.event_id ~= prev_ui.event_id then
    local title = resolve_event_title(next_ui.event_id, lang)
    if next_ui.mode ~= "stage_intro" then
      if is_ja then
        state = append_line(state, string.format("イベント開始: %s", title))
      else
        state = append_line(state, string.format("Event Start: %s", title))
      end
    end
  end
  local next_message = tostring(next_ui.event_message or "")
  local prev_message = tostring(prev_ui.event_message or "")
  if next_message ~= "" and next_message ~= prev_message then
    if is_ja then
      state = append_line(state, string.format("イベント: %s", next_message))
    else
      state = append_line(state, string.format("Event: %s", next_message))
    end
  end
  return state
end

local function append_item_gain_logs(previous_state, next_state, lang, state)
  local is_ja = is_ja_lang(lang)
  local prev_inventory = (previous_state or {}).inventory or {}
  local next_inventory = (next_state or {}).inventory or {}
  for item_id, next_count in pairs(next_inventory) do
    local previous_count = tonumber(prev_inventory[item_id]) or 0
    local gained = (tonumber(next_count) or 0) - previous_count
    if gained > 0 then
      local item_name = resolve_item_name(item_id, lang)
      if is_ja then
        state = append_line(state, string.format("アイテム取得: %s x%d", item_name, gained))
      else
        state = append_line(state, string.format("Item Acquired: %s x%d", item_name, gained))
      end
    end
  end
  return state
end

local function append_gold_gain_logs(previous_state, next_state, lang, state, skip_reward)
  local prev_gold = tonumber((((previous_state or {}).currency or {}).gold) or 0) or 0
  local next_gold = tonumber((((next_state or {}).currency or {}).gold) or 0) or 0
  local gained = next_gold - prev_gold
  if gained <= 0 or skip_reward then
    return state
  end
  if is_ja_lang(lang) then
    return append_line(state, string.format("Gold増加: +%d", gained))
  end
  return append_line(state, string.format("Gold Increased: +%d", gained))
end

-- 前回状態と今回状態を比較し、ゲーム進行ログを追加して返す。
local function append_tick_logs(previous_state, next_state, config)
  local base = next_state or {}
  local lang = resolve_lang(base, config)
  local state, mode_context = append_mode_logs(previous_state, next_state, lang, base)
  state = append_stage_progress_logs(previous_state, next_state, config, lang, state)
  state = append_event_logs(previous_state, next_state, lang, state)
  state = append_item_gain_logs(previous_state, next_state, lang, state)
  state = append_gold_gain_logs(previous_state, next_state, lang, state, mode_context.reward_logged)
  return state
end

M.append_tick_logs = append_tick_logs

return M
