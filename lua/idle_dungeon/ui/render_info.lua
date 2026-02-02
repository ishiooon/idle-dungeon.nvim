-- このモジュールは表示用の補助情報を生成する純粋関数を提供する。
-- 参照先はgameとui配下の構成に合わせて更新する。
local render_battle = require("idle_dungeon.ui.render_battle_info")
local render_event = require("idle_dungeon.ui.render_event")
local render_stage = require("idle_dungeon.ui.render_stage")
local icon_module = require("idle_dungeon.ui.icon")
local util = require("idle_dungeon.util")

local M = {}

-- 表示言語の優先順位を決めて返す。
local function resolve_language(state, config)
  return (state.ui and state.ui.language) or (config.ui or {}).language or "en"
end

-- ステージ進行と基本ステータスを短くまとめる。
local function build_status_line(state, config)
  local actor = state.actor or {}
  local gold = (state.currency or {}).gold or 0
  local summary = render_stage.build_stage_summary(state.progress or {}, config)
  return string.format("%s HP%d/%d Lv%d G%d", summary, actor.hp or 0, actor.max_hp or 0, actor.level or 1, gold)
end

-- 移動中に必要な情報を1行でまとめる。
local function build_scrolling_text(text, max_width, time_sec)
  local width = math.max(tonumber(max_width) or 0, 0)
  if width <= 0 then
    return ""
  end
  if util.display_width(text) <= width then
    return text
  end
  -- 表示に余白を入れてスクロールの切れ目を作る。
  local spacer = "   "
  local base = util.split_utf8(text .. spacer)
  local stream = util.split_utf8(text .. spacer .. text)
  local offset_base = #base
  local offset = ((math.floor(time_sec or 0) % offset_base) + 1)
  local parts = {}
  local used = 0
  local index = offset
  while used < width and #parts < #stream do
    local chunk = stream[((index - 1) % #stream) + 1]
    local w = util.display_width(chunk)
    if used + w > width then
      break
    end
    used = used + w
    table.insert(parts, chunk)
    index = index + 1
  end
  return table.concat(parts, "")
end

local function build_move_info_line(state, config)
  local actor = state.actor or {}
  local currency = state.currency or {}
  local parts = render_stage.build_stage_parts(state.progress or {}, config or {})
  local icons = icon_module.config(config)
  local hp_label = string.format("%s%d/%d", icons.hp or "", actor.hp or 0, actor.max_hp or 0)
  local exp_label = string.format("%s%d/%d", icons.exp or "", actor.exp or 0, actor.next_level or 0)
  local gold_label = string.format("%s%d", icons.gold or "", currency.gold or 0)
  local info_text = table.concat({ hp_label, exp_label, gold_label }, " ")
  local token = parts.token or ""
  local width = (config.ui or {}).width or 36
  local bracket_prefix = "["
  local bracket_suffix = "]" .. token
  local fixed_width = util.display_width(bracket_prefix)
    + util.display_width(bracket_suffix)
    + util.display_width(info_text)
    + 1
  local name_width = math.max(width - fixed_width, 1)
  local time_sec = (state.metrics or {}).time_sec or 0
  -- 長いステージ名は自動でスクロールする。
  local name = build_scrolling_text(parts.name or "stage", name_width, time_sec)
  local label = string.format("%s%s%s", bracket_prefix, name, bracket_suffix)
  return string.format("%s %s", label, info_text)
end


-- 会話イベントの文言を優先順で返す。
local function build_dialogue_info_line(state, lang)
  local event = render_event.find_event_by_id(state.ui.event_id)
  local message = render_event.resolve_event_message(event, lang)
  if message ~= "" then
    return message
  end
  local title = render_event.resolve_event_title(event, lang)
  if title ~= "" then
    return title
  end
  return "Story"
end

-- 報酬表示の短文を生成する。
local function build_reward_info_line(config)
  local reward = config.battle or {}
  return string.format("+%dexp +%dg", reward.reward_exp or 0, reward.reward_gold or 0)
end

-- 画面下段の情報行をモードに応じて切り替える。
local function build_info_line(state, config)
  local lang = resolve_language(state, config)
  local width = (config.ui or {}).width or 36
  if state.ui.mode == "move" then
    -- 移動中は位置と体力が分かる情報を優先する。
    return util.clamp_line(build_move_info_line(state, config), width)
  end
  if state.ui.mode == "battle" then
    -- 戦闘中の情報表示は専用整形に委譲する。
    return util.clamp_line(render_battle.build_battle_info_line(state, config, lang), width)
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
  return util.clamp_line(build_status_line(state, config), width)
end

-- 進行トラックの行に読み取り専用の表示を重ねる。
local function build_header(track, state, config)
  local width = (config.ui or {}).width or 36
  local read_only = state.ui and state.ui.read_only
  local line = track or ""
  if read_only then
    -- 読み取り専用の状態は先頭にROを付与して強調する。
    line = "RO" .. line
  end
  return util.clamp_line(line, width)
end

-- テキストモード用の状態表示を組み立てる。
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
