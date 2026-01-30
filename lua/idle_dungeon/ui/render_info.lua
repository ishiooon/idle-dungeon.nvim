-- このモジュールは表示用の補助情報を生成する純粋関数を提供する。
-- 参照先はgameとui配下の構成に合わせて更新する。
local render_event = require("idle_dungeon.ui.render_event"); local render_stage = require("idle_dungeon.ui.render_stage")
local sprite = require("idle_dungeon.ui.sprite"); local util = require("idle_dungeon.util"); local M = {}
local function resolve_language(state, config) return (state.ui and state.ui.language) or (config.ui or {}).language or "en" end
local function build_status_line(state)
  local actor = state.actor or {}; local gold = (state.currency or {}).gold or 0
  return string.format("HP%d/%d Lv%d G%d", actor.hp or 0, actor.max_hp or 0, actor.level or 1, gold)
end
local function build_battle_info_line(state, config)
  local enemy = state.combat and state.combat.enemy or {}
  local icons = sprite.icon_config(config)
  local icon = enemy.is_boss and icons.boss or icons.enemy
  local enemy_max = enemy.max_hp or enemy.hp or 0
  return string.format("%s %d/%d", icon, enemy.hp or 0, enemy_max)
end
local function build_dialogue_info_line(state, lang)
  local event = render_event.find_event_by_id(state.ui.event_id); local message = render_event.resolve_event_message(event, lang)
  if message ~= "" then
    return message
  end
  local title = render_event.resolve_event_title(event, lang)
  if title ~= "" then
    return title
  end
  return "Story"
end
local function build_reward_info_line(config)
  local reward = config.battle or {}
  return string.format("+%dexp +%dg", reward.reward_exp or 0, reward.reward_gold or 0)
end
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
    return util.clamp_line(build_status_line(state), width)
  end
  if state.ui.mode == "battle" then
    return util.clamp_line(build_battle_info_line(state, config), width)
  end
  if state.ui.mode == "dialogue" then
    return util.clamp_line(build_dialogue_info_line(state, lang), width)
  end
  if state.ui.mode == "reward" then
    return util.clamp_line(build_reward_info_line(config), width)
  end
  if state.ui.mode == "defeat" then
    return util.clamp_line("Defeated", width)
  end
  return util.clamp_line(build_status_line(state), width)
end
local function build_header(track, state, config)
  local summary = render_stage.build_stage_summary(state.progress or {}, config)
  local width = (config.ui or {}).width or 36
  local read_only = state.ui and state.ui.read_only
  local header_track = track
  if read_only and type(track) == "string" and #track >= 1 then
    -- 読み取り専用の状態は先頭にROを付与して強調する。
    header_track = "RO" .. track
  end
  local line = string.format("%s %s", header_track, summary)
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
