-- このモジュールは表示用の補助情報を生成する純粋関数を提供する。
-- 参照先はgameとui配下の構成に合わせて更新する。
-- 階層進行の計算はfloor/progressに委譲する。
local floor_progress = require("idle_dungeon.game.floor.progress"); local render_event = require("idle_dungeon.ui.render_event"); local render_stage = require("idle_dungeon.ui.render_stage")
local sprite = require("idle_dungeon.ui.sprite"); local util = require("idle_dungeon.util"); local M = {}
local function resolve_language(state, config) return (state.ui and state.ui.language) or (config.ui or {}).language or "en" end
local function build_status_line(state)
  local actor = state.actor or {}; local gold = (state.currency or {}).gold or 0
  return string.format("HP%d/%d Lv%d Exp%d/%d G%d", actor.hp or 0, actor.max_hp or 0, actor.level or 1, actor.exp or 0, actor.next_level or 0, gold)
end
local function find_next_boss_distance(progress, config)
  local boss_every = progress.boss_every or config.boss_every
  if boss_every and boss_every > 0 then
    -- 次のボス階層までの残り数を算出する。
    local floor_length = floor_progress.resolve_floor_length(config or {})
    local current_floor = floor_progress.floor_index(progress.distance or 0, floor_length) + 1
    local remainder = current_floor % boss_every
    if remainder == 0 then
      return 0
    end
    return boss_every - remainder
  end
  local current = progress.distance or 0
  local next_distance = nil
  for _, distance in ipairs(progress.boss_milestones or {}) do
    if distance > current and (not next_distance or distance < next_distance) then
      next_distance = distance
    end
  end
  if not next_distance then return nil end
  local floor_length = floor_progress.resolve_floor_length(config or {})
  return math.floor(math.max(next_distance - current, 0) / floor_length)
end
local function build_move_info_candidates(state, config)
  local progress = state.progress or {}
  local candidates = { build_status_line(state) }
  local next_event = render_event.find_next_event_distance(progress, config)
  local next_boss = find_next_boss_distance(progress, config)
  if next_event or next_boss then
    local parts = {}
    if next_event then
      table.insert(parts, string.format("NextE %dF", next_event))
    end
    if next_boss then
      table.insert(parts, string.format("Boss %dF", next_boss))
    end
    table.insert(candidates, table.concat(parts, " "))
  end
  return candidates
end
local function select_cycle_line(lines, time_sec, cycle_seconds)
  if #lines == 0 then return "" end
  local span = math.max(cycle_seconds or 4, 1); local index = (math.floor((time_sec or 0) / span) % #lines) + 1
  return lines[index]
end
local function build_battle_info_line(state, config)
  local enemy = state.combat and state.combat.enemy or {}; local actor = state.actor or {}
  local label = enemy.is_boss and "Boss" or "EN"
  local enemy_max = enemy.max_hp or enemy.hp or 0
  local icons = sprite.build_battle_icons(state, config); local prefix = icons ~= "" and (icons .. " ") or ""
  return string.format("%s%s %s HP%d/%d You %d/%d", prefix, label, enemy.name or "?", enemy.hp or 0, enemy_max, actor.hp or 0, actor.max_hp or 0)
end
local function build_dialogue_info_line(state, lang)
  local event = render_event.find_event_by_id(state.ui.event_id); local message = render_event.resolve_event_message(event, lang); local remaining = state.ui.dialogue_remaining or 0
  if message ~= "" then
    return string.format("%s (%ds)", message, remaining)
  end
  local title = render_event.resolve_event_title(event, lang)
  if title ~= "" then
    return string.format("%s (%ds)", title, remaining)
  end
  return string.format("Story (%ds)", remaining)
end
local function build_reward_info_line(config) local reward = config.battle or {}; return string.format("+%dexp +%dg", reward.reward_exp or 0, reward.reward_gold or 0) end
local function build_info_line(state, config)
  local lang = resolve_language(state, config)
  local width = (config.ui or {}).width or 36
  if state.ui.mode == "move" then
    -- 移動中でもイベントのメッセージを一度だけ表示する。
    if state.ui.event_id then
      local event = render_event.find_event_by_id(state.ui.event_id)
      local message = render_event.resolve_event_message(event, lang)
      if message ~= "" then
        return util.clamp_line(message, width)
      end
      local title = render_event.resolve_event_title(event, lang)
      if title ~= "" then
        return util.clamp_line(title, width)
      end
    end
    local candidates = build_move_info_candidates(state, config)
    local time_sec = (state.metrics or {}).time_sec or 0
    local cycle = (config.ui or {}).info_cycle_seconds or 4
    return util.clamp_line(select_cycle_line(candidates, time_sec, cycle), width)
  end
  if state.ui.mode == "battle" then
    return util.clamp_line(build_battle_info_line(state, config), width)
  end
  if state.ui.mode == "dialogue" then
    return util.clamp_line(build_dialogue_info_line(state, lang), width)
  end
  if state.ui.mode == "reward" then
    return util.clamp_line("Reward " .. build_reward_info_line(config), width)
  end
  if state.ui.mode == "defeat" then
    return util.clamp_line("Defeated -> restart", width)
  end
  return util.clamp_line(build_status_line(state), width)
end
local function build_header(track, state, config, mode_label)
  local summary = render_stage.build_stage_summary(state.progress or {}, config)
  local width = (config.ui or {}).width or 36
  local read_only = state.ui and state.ui.read_only
  local header_track = track
  if read_only and type(track) == "string" and #track >= 1 then
    local suffix = #track >= 3 and track:sub(3) or ""
    header_track = "RO" .. suffix
  end
  local line = string.format("%s %s %s", header_track, summary, mode_label)
  return util.clamp_line(line, width)
end
local function build_text_status(state, config)
  local summary = render_stage.build_stage_summary(state.progress or {}, config)
  local mode = state.ui.mode
  local ro_label = state.ui and state.ui.read_only and " RO" or ""
  if mode == "move" then
    return string.format("[Walking %s]%s", summary, ro_label)
  end
  if mode == "battle" then
    local enemy = state.combat and state.combat.enemy or {}
    local label = enemy.is_boss and "boss" or "enemy"
    return string.format("[Encountered %s %s]%s", label, enemy.name or "?", ro_label)
  end
  if mode == "dialogue" then
    local lang = resolve_language(state, config)
    local event = render_event.find_event_by_id(state.ui.event_id)
    local title = render_event.resolve_event_title(event, lang)
    return string.format("[Story %s]%s", title ~= "" and title or summary, ro_label)
  end
  if mode == "reward" then
    return string.format("[Reward %s]%s", build_reward_info_line(config), ro_label)
  end
  if mode == "defeat" then
    return "[Defeated -> restart]" .. ro_label
  end
  return string.format("[Idle %s]%s", summary, ro_label)
end
M.build_header = build_header
M.build_info_line = build_info_line
M.build_text_status = build_text_status
M.resolve_language = resolve_language
return M
