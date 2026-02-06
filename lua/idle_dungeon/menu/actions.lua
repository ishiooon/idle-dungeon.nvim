-- このモジュールはメニュー内の個別操作をまとめる。
-- メニュー操作に必要な参照先を関心ごとに整理する。
local content = require("idle_dungeon.content")
-- 階層状態の再計算はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local equip_detail = require("idle_dungeon.menu.equip_detail")
local menu_detail = require("idle_dungeon.menu.detail")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_view = require("idle_dungeon.menu.view")
local skills = require("idle_dungeon.game.skills")
local icon_module = require("idle_dungeon.ui.icon")
local player = require("idle_dungeon.game.player")
local render_stage = require("idle_dungeon.ui.render_stage")
local stage_unlock = require("idle_dungeon.game.stage_unlock")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")

local M = {}

-- 言語設定に応じてスキル名を切り替える。
local function resolve_skill_name(skill, lang)
  if not skill then
    return ""
  end
  if lang == "en" then
    return skill.name_en or skill.name or ""
  end
  return skill.name or ""
end

-- 言語設定に応じてスキル説明を切り替える。
local function resolve_skill_description(skill, lang)
  if not skill then
    return ""
  end
  if lang == "en" then
    return skill.description_en or skill.description or ""
  end
  return skill.description or ""
end

-- ジョブ詳細の表示内容を構築する。
local function build_job_detail(job, state, lang)
  if not job then
    return nil
  end
  local progress = (state.job_levels or {})[job.id] or player.default_progress()
  local growth = job.growth or {}
  local lines = {
    string.format("%s %d", i18n.t("label_job_level", lang), progress.level or 1),
    string.format("%s %d/%d", i18n.t("label_job_exp", lang), progress.exp or 0, progress.next_level or 0),
    string.format("%s HP+%d ATK+%d DEF+%d SPD+%d", i18n.t("label_job_growth", lang), growth.hp or 0, growth.atk or 0, growth.def or 0, growth.speed or 0),
  }
  if job.skills and #job.skills > 0 then
    table.insert(lines, i18n.t("label_job_skills", lang))
    for _, skill in ipairs(job.skills) do
      local learned = skills.is_learned(state.skills, skill.id)
      local status = learned and i18n.t("status_unlocked", lang) or i18n.t("status_locked", lang)
      local kind_label = (skill.kind == "active")
        and i18n.t("skill_kind_active", lang)
        or i18n.t("skill_kind_passive", lang)
      local skill_name = resolve_skill_name(skill, lang)
      table.insert(lines, string.format("Lv%d %s (%s) [%s]", skill.level or 1, skill_name, kind_label, status))
      local skill_description = resolve_skill_description(skill, lang)
      if skill_description ~= "" then
        -- スキルの効果説明を補足として表示する。
        table.insert(lines, string.format("  %s", skill_description))
      end
    end
  end
  return { title = job.name, lines = lines }
end

-- 装備名の先頭にスロットアイコンを付けて識別しやすくする。
local function format_item_label(item, config)
  local icons = icon_module.config(config)
  local icon = icon_module.resolve_slot_icon(item.slot, icons)
  if icon == "" then
    return item.name
  end
  return string.format("%s %s", icon, item.name)
end

-- 設定系の操作は別モジュールへ委譲する。
local function apply_equipment(state, slot, item_id)
  local next_equipment = util.merge_tables(state.equipment, { [slot] = item_id })
  local next_actor = player.apply_equipment(state.actor, next_equipment, content.items)
  return state_module.with_actor(state_module.with_equipment(state, next_equipment), next_actor)
end

local function open_job_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local entries = {}
  for _, job in ipairs(content.jobs) do
    table.insert(entries, job)
  end
  -- ジョブ選択のメニューを表示する。
  menu_view.select(entries, {
    prompt = i18n.t("prompt_job", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      local current = get_state()
      local active = (current.actor or {}).id == item.id and "●" or " "
      local progress = (current.job_levels or {})[item.id] or player.default_progress()
      return string.format("%s %-20s Lv%-3d %s", active, item.name, progress.level or 1, item.role or "")
    end,
    detail_provider = function(item)
      -- ジョブの成長と習得技を詳細に表示する。
      return build_job_detail(item, get_state(), lang)
    end,
  }, function(choice)
    if not choice then
      if on_close then
        -- キャンセル時は状態画面へ戻る。
        on_close()
      end
      return
    end
    local next_state = state_module.change_job(get_state(), choice.id)
    set_state(next_state)
  end, config)
end

-- スキル一覧の表示と有効/無効の切り替えを行う。
local function open_skills_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local state = get_state()
  local active = skills.list_learned(state.skills, content.jobs, "active", nil)
  local passive = skills.list_learned(state.skills, content.jobs, "passive", nil)
  local entries = {}
  for _, skill in ipairs(active) do
    table.insert(entries, util.merge_tables(skill, { kind = "active" }))
  end
  for _, skill in ipairs(passive) do
    table.insert(entries, util.merge_tables(skill, { kind = "passive" }))
  end
  menu_view.select(entries, {
    prompt = i18n.t("prompt_skills", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      local current = get_state()
      local enabled = skills.is_enabled(current.skill_settings, item.id, item.kind)
      local status = enabled and i18n.t("status_on", lang) or i18n.t("status_off", lang)
      local kind_label = item.kind == "active" and i18n.t("skill_kind_active", lang) or i18n.t("skill_kind_passive", lang)
      local skill_name = resolve_skill_name(item, lang)
      return string.format("%s (%s) [%s]", skill_name, kind_label, status)
    end,
    detail_provider = function(item)
      if not item then
        return nil
      end
      local lines = {}
      if item.kind == "active" then
        table.insert(lines, string.format("%s %d%%", i18n.t("label_skill_rate", lang), math.floor((item.rate or 0) * 100 + 0.5)))
        table.insert(lines, string.format("%s x%.2f", i18n.t("label_skill_power", lang), item.power or 1))
        table.insert(lines, string.format("%s %+d", i18n.t("label_skill_accuracy", lang), item.accuracy or 0))
      else
        local mul = item.bonus_mul or {}
        table.insert(lines, string.format("%s ATK x%.2f", i18n.t("label_skill_bonus", lang), mul.atk or 1))
        table.insert(lines, string.format("%s DEF x%.2f", i18n.t("label_skill_bonus", lang), mul.def or 1))
        table.insert(lines, string.format("%s ACC x%.2f", i18n.t("label_skill_bonus", lang), mul.accuracy or 1))
      end
      local description = resolve_skill_description(item, lang)
      if description ~= "" then
        table.insert(lines, "")
        table.insert(lines, description)
      end
      local title = resolve_skill_name(item, lang)
      return { title = title, lines = lines }
    end,
  }, function(choice)
    if not choice then
      if on_close then
        -- キャンセル時は状態画面へ戻る。
        on_close()
      end
      return
    end
    local current_state = get_state()
    local settings = skills.normalize_settings(current_state.skill_settings)
    local bucket = choice.kind == "active" and settings.active or settings.passive
    local enabled = bucket[choice.id]
    if enabled == nil then
      enabled = true
    end
    bucket[choice.id] = not enabled
    local next_state = util.merge_tables(current_state, { skill_settings = settings })
    set_state(next_state)
  end, config)
end

-- ジョブごとのレベル一覧を表示する。
local function open_job_levels_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local state = get_state()
  local lines = menu_locale.build_job_level_lines(state, lang, content.jobs or {})
  local entries = {}
  for _, line in ipairs(lines) do
    table.insert(entries, { label = line })
  end
  menu_view.select(entries, {
    prompt = i18n.t("menu_job_levels_title", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice and on_close then
      -- キャンセル時は状態画面へ戻る。
      on_close()
    end
  end, config)
end

local function open_stage_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local entries = config.stages or {}
  local initial_state = get_state()
  local unlocks = (initial_state.unlocks or {}).stages or {}
  local first_stage = (config.stages or {})[1]
  -- 開始ダンジョンを選択するためのメニューを表示する。
  menu_view.select(entries, {
    prompt = i18n.t("prompt_stage", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      local unlocked = stage_unlock.is_unlocked(unlocks, item.id)
        or item.id == (initial_state.progress or {}).stage_id
        or (first_stage and item.id == first_stage.id)
      local label = unlocked and i18n.t("status_unlocked", lang) or i18n.t("status_locked", lang)
      local stage_name = render_stage.resolve_stage_name(item, nil, lang)
      return string.format("%s [%s]", stage_name, label)
    end,
  }, function(choice)
    if not choice then
      if on_close then
        -- キャンセル時は状態画面へ戻る。
        on_close()
      end
      return
    end
    local current = get_state()
    local current_unlocks = (current.unlocks or {}).stages or {}
    local is_current = choice.id == (current.progress or {}).stage_id
    local is_first = first_stage and choice.id == first_stage.id
    if not (stage_unlock.is_unlocked(current_unlocks, choice.id) or is_current or is_first) then
      return
    end
    local progress = util.merge_tables(current.progress, {
      stage_id = choice.id,
      stage_name = choice.name,
      distance = choice.start,
      stage_start = choice.start,
      stage_infinite = choice.infinite or false,
      boss_every = choice.boss_every or config.boss_every,
      boss_milestones = choice.boss_milestones or {},
    })
    -- 開始階層の遭遇状態を再計算して反映する。
    local refreshed = floor_state.refresh(progress, config)
    set_state(util.merge_tables(current, { progress = refreshed }))
  end, config)
end

local function open_equip_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local slots = { "weapon", "armor", "accessory", "companion" }
  local function open_slot_menu()
    -- 装備枠を選択するためのメニューを表示する。
    menu_view.select(slots, {
      prompt = i18n.t("prompt_slot", lang),
      lang = lang,
      footer_hints = menu_locale.submenu_footer_hints(lang),
      keep_open = true,
      format_item = function(item)
        return menu_locale.slot_label(item, lang)
      end,
    }, function(slot)
      if not slot then
        if on_close then
          on_close()
        end
        return
      end
      local state = get_state()
      local choices = {}
      for _, item in ipairs(content.items) do
        if item.slot == slot and inventory.has_item(state.inventory, item.id) then
          table.insert(choices, item)
        end
      end
      -- 選択可能な装備を表示し、差分を詳細で確認できるようにする。
      menu_view.select(choices, {
        prompt = i18n.t("prompt_equipment", lang),
        lang = lang,
        footer_hints = menu_locale.submenu_footer_hints(lang),
        -- 装備確定後もメニューを閉じずに連続で選択できるようにする。
        keep_open = true,
        format_item = function(item)
          return format_item_label(item, config)
        end,
        detail_provider = function(item)
          -- 装備差分と解放条件をまとめて表示する。
          return equip_detail.build_detail(item, get_state(), lang, config)
            or menu_detail.build_item_detail(item, get_state(), lang, config)
        end,
      }, function(item)
        if not item then
          -- 装備枠の選択へ戻る。
          return open_slot_menu()
        end
        local next_state = apply_equipment(state, slot, item.id)
        set_state(next_state)
      end, config)
    end, config)
  end
  open_slot_menu()
end

M.open_job_menu = open_job_menu
M.open_skills_menu = open_skills_menu
M.open_job_levels_menu = open_job_levels_menu
M.open_stage_menu = open_stage_menu
M.open_equip_menu = open_equip_menu

return M
