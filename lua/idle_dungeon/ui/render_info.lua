-- このモジュールは表示用の補助情報を生成する純粋関数を提供する。
-- 参照先はgameとui配下の構成に合わせて更新する。
local render_battle = require("idle_dungeon.ui.render_battle_info")
local render_event = require("idle_dungeon.ui.render_event")
local render_stage = require("idle_dungeon.ui.render_stage")
local icon_module = require("idle_dungeon.ui.icon")
local i18n = require("idle_dungeon.i18n")
local util = require("idle_dungeon.util")

local M = {}

-- アイコンと数値を区切って読みやすくする。
local function format_icon_value(icon, text)
  if not icon or icon == "" then
    return text
  end
  return string.format("%s %s", icon, text)
end

-- 表示言語の優先順位を決めて返す。
local function resolve_language(state, config)
  return (state.ui and state.ui.language) or (config.ui or {}).language or "en"
end

-- ステージ進行と基本ステータスを短くまとめる。
local function build_status_line(state, config)
  local actor = state.actor or {}
  local gold = (state.currency or {}).gold or 0
  local lang = resolve_language(state, config)
  local summary = render_stage.build_stage_summary(state.progress or {}, config, lang)
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

-- 移動中の情報を切り替え表示できるように候補をまとめる。
local function build_move_info_variants(state, lang, icons)
  local actor = state.actor or {}
  local currency = state.currency or {}
  local hp_label = format_icon_value(icons.hp or "", string.format("%d/%d", actor.hp or 0, actor.max_hp or 0))
  local exp_label = format_icon_value(icons.exp or "", string.format("%d/%d", actor.exp or 0, actor.next_level or 0))
  local gold_label = format_icon_value(icons.gold or "", string.format("%d", currency.gold or 0))
  return {
    string.format("%s %s", hp_label, exp_label),
    string.format("%s %s", hp_label, gold_label),
  }
end

local function build_move_info_line(state, config)
  local lang = resolve_language(state, config)
  if state.ui and state.ui.event_message_remaining and state.ui.event_message_remaining > 0 then
    local message = state.ui.event_message or ""
    if message ~= "" then
      return message
    end
  end
  local parts = render_stage.build_stage_parts(state.progress or {}, config or {}, lang)
  local icons = icon_module.config(config)
  local variants = build_move_info_variants(state, lang, icons)
  local time_sec = (state.metrics or {}).time_sec or 0
  local index = (#variants > 0) and ((math.floor(time_sec / 2) % #variants) + 1) or 1
  local info_text = variants[index] or ""
  local token = parts.token or ""
  local width = (config.ui or {}).width or 36
  local bracket_prefix = "["
  local bracket_suffix = "]" .. token
  local fixed_width = util.display_width(bracket_prefix)
    + util.display_width(bracket_suffix)
    + util.display_width(info_text)
    + 1
  local name_width = math.max(width - fixed_width, 1)
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

-- 選択肢のラベルを表示言語に合わせて解決する。
local function resolve_choice_label(choice, lang, fallback_key)
  if choice and type(choice.label) == "table" then
    return choice.label[lang] or choice.label.en or choice.label.ja or i18n.t(fallback_key, lang)
  end
  if choice and type(choice.label) == "string" and choice.label ~= "" then
    return choice.label
  end
  return i18n.t(fallback_key, lang)
end

-- 選択イベント用の情報行を組み立てる。
local function build_choice_info_line(state, lang)
  local event = render_event.find_event_by_id(state.ui.event_id)
  local message = render_event.resolve_event_message(event, lang)
  local title = render_event.resolve_event_title(event, lang)
  local base = message ~= "" and message or title
  if base == "" then
    base = "Choice"
  end
  local choices = event and event.choices or {}
  local choice_1 = resolve_choice_label(choices[1], lang, "choice_yes")
  local choice_2 = resolve_choice_label(choices[2], lang, "choice_no")
  local remaining = math.max(math.floor(state.ui.choice_remaining or 0), 0)
  local auto_label = i18n.t("choice_auto", lang)
  return string.format("%s 1:%s 2:%s %s%d", base, choice_1, choice_2, auto_label, remaining)
end

-- 報酬表示の短文を生成する。
local function resolve_item_name(item, lang)
  if not item then
    return ""
  end
  if lang == "en" and item.name_en then
    return item.name_en
  end
  return item.name or item.name_en or item.id or ""
end

-- 報酬表示の短文を生成する。
local function build_reward_info_line(state, config, lang)
  local reward = config.battle or {}
  local bonus_gold = (state.combat and state.combat.pending_gold) or 0
  local reward_gold = (reward.reward_gold or 0) + bonus_gold
  local base = string.format("+%dexp +%dg", reward.reward_exp or 0, reward_gold)
  local drop = state.combat and state.combat.pending_drop or nil
  if not drop or not drop.id then
    return base
  end
  local content = require("idle_dungeon.content")
  local drop_item = nil
  for _, item in ipairs(content.items or {}) do
    if item.id == drop.id then
      drop_item = item
      break
    end
  end
  local name = resolve_item_name(drop_item, lang)
  if name == "" then
    name = drop.id
  end
  return string.format("%s Drop:%s", base, name)
end

-- 画面下段の情報行をモードに応じて切り替える。
local function build_info_line(state, config)
  local lang = resolve_language(state, config)
  local width = (config.ui or {}).width or 36
  if state.ui.mode == "move" then
    -- 移動中は位置と体力が分かる情報を優先する。
    return util.clamp_line(build_move_info_line(state, config), width)
  end
  if state.ui.mode == "stage_intro" then
    local event = render_event.find_event_by_id(state.ui.event_id)
    local title = render_event.resolve_event_title(event, lang)
    local message = render_event.resolve_event_message(event, lang)
    local text = title ~= "" and title or message
    if text == "" then
      text = "Stage Intro"
    end
    return util.clamp_line(text, width)
  end
  if state.ui.mode == "battle" then
    -- 戦闘中の情報表示は専用整形に委譲する。
    return util.clamp_line(render_battle.build_battle_info_line(state, config, lang), width)
  end
  if state.ui.mode == "dialogue" then
    return util.clamp_line(build_dialogue_info_line(state, lang), width)
  end
  if state.ui.mode == "choice" then
    return util.clamp_line(build_choice_info_line(state, lang), width)
  end
  if state.ui.mode == "reward" then
    return util.clamp_line(build_reward_info_line(state, config, lang), width)
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
  local lang = resolve_language(state, config)
  local summary = render_stage.build_stage_summary(state.progress or {}, config, lang)
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
  if mode == "choice" then
    local lang = resolve_language(state, config)
    local event = render_event.find_event_by_id(state.ui.event_id)
    local title = render_event.resolve_event_title(event, lang)
    local label = title ~= "" and title or summary
    return string.format("[Choice %s]%s", label, ro_label)
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
