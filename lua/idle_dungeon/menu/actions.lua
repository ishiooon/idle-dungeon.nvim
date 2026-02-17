-- このモジュールはメニュー内の個別操作をまとめる。
-- メニュー操作に必要な参照先を関心ごとに整理する。
local content = require("idle_dungeon.content")
-- 階層状態の再計算はgame/floor/stateに委譲する。
local floor_state = require("idle_dungeon.game.floor.state")
local i18n = require("idle_dungeon.i18n")
local inventory = require("idle_dungeon.game.inventory")
local choice_style = require("idle_dungeon.menu.choice_style")
local equip_detail = require("idle_dungeon.menu.equip_detail")
local menu_detail = require("idle_dungeon.menu.detail")
local menu_logging = require("idle_dungeon.menu.logging")
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
local item_by_id = {}
local apply_equipment
for _, item in ipairs(content.items or {}) do
  item_by_id[item.id] = item
end

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

-- 言語設定に応じて表示文言を切り替える。
local function localized_text(lang, ja_text, en_text)
  if lang == "ja" or lang == "jp" then
    return ja_text
  end
  return en_text
end

-- ジョブ固有の成長値を1行で比較しやすい形式に整える。
local function build_job_growth_line(job, lang)
  local growth = (job and job.growth) or {}
  local head = "LvUp"
  return string.format(
    "%s HP+%d ATK+%d DEF+%d SPD+%d",
    head,
    tonumber(growth.hp) or 0,
    tonumber(growth.atk) or 0,
    tonumber(growth.def) or 0,
    tonumber(growth.speed) or 0
  )
end

-- ジョブ詳細の表示内容を構築する。
local function build_job_detail(job, state, lang)
  if not job then
    return nil
  end
  local progress = (state.job_levels or {})[job.id] or player.default_job_progress()
  local lines = {
    string.format("%s %d", i18n.t("label_job_level", lang), progress.level or 1),
    "",
    localized_text(lang, "Level Up Growth", "Level Up Growth"),
    build_job_growth_line(job, lang),
    localized_text(lang, "ジョブ切替直後にステータスは変わりません。", "No immediate stat change on switch."),
    localized_text(lang, "勇者レベルが上がる時だけこの成長が反映されます。", "Growth applies only when hero levels up."),
  }
  if job.skills and #job.skills > 0 then
    table.insert(lines, "")
    table.insert(lines, localized_text(lang, "スキル習得一覧", "Skill Unlocks"))
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
  return { title = menu_locale.resolve_job_name(job, lang), lines = lines }
end

-- 装備名の先頭にスロットアイコンを付けて識別しやすくする。
local function format_item_label(item, config, lang)
  if not item then
    return ""
  end
  local icons = icon_module.config(config)
  local icon = icon_module.resolve_slot_icon(item.slot, icons)
  local base_name = (lang == "en" and (item.name_en or item.name)) or (item.name or item.name_en or item.id)
  if icon == "" then
    return base_name
  end
  return string.format("%s %s", icon, base_name)
end

-- スロットに属する所持装備数を返す。
local function count_owned_items_by_slot(state, slot)
  local total = 0
  local bag = (state and state.inventory) or {}
  for _, item in ipairs(content.items or {}) do
    if item.slot == slot and inventory.has_item(bag, item.id) then
      total = total + 1
    end
  end
  return total
end

-- スロット選択行を、現在装備と候補数が分かる形で整形する。
local function format_slot_line(slot, state, config, lang)
  local icons = icon_module.config(config)
  local icon = icon_module.resolve_slot_icon(slot, icons)
  local slot_label = menu_locale.slot_label(slot, lang)
  local equipped_id = ((state or {}).equipment or {})[slot]
  local equipped_item = item_by_id[equipped_id]
  local equipped_name = equipped_item and ((lang == "en" and (equipped_item.name_en or equipped_item.name)) or equipped_item.name)
    or localized_text(lang, "なし", "None")
  local owned = count_owned_items_by_slot(state, slot)
  local equipped_label = localized_text(lang, "装備中", "Equipped")
  local choices_label = localized_text(lang, "候補", "Choices")
  if icon == "" then
    return string.format("%s | %s: %s | %s: %d", slot_label, equipped_label, equipped_name, choices_label, owned)
  end
  return string.format("%s %s | %s: %s | %s: %d", icon, slot_label, equipped_label, equipped_name, choices_label, owned)
end

-- 装備候補行を、現在装備との能力差分が見える形式へ整形する。
local function format_equip_choice_line(item, state, slot, config, lang)
  local equipped_id = ((state or {}).equipment or {})[slot]
  local marker = item.id == equipped_id and "◆EQUIPPED" or "◇CANDIDATE"
  local next_state = apply_equipment(state, slot, item.id)
  local delta = choice_style.build_actor_delta(state.actor or {}, (next_state.actor or {}))
  local delta_text = choice_style.format_actor_delta(delta)
  local owned = ((state.inventory or {})[item.id]) or 0
  return string.format("%s %-20s x%-2d | %s", marker, format_item_label(item, config, lang), owned, delta_text)
end

-- ジョブごとの習得済みスキル数を集計する。
local function count_learned_job_skills(job, state)
  local total = 0
  for _, skill in ipairs((job and job.skills) or {}) do
    if skills.is_learned((state or {}).skills, skill.id) then
      total = total + 1
    end
  end
  return total
end

-- ジョブ一覧で表示するスキル進捗を、習得数/総数の短い表現で返す。
local function build_job_skill_progress_line(job, state, lang)
  local total = #((job and job.skills) or {})
  local learned = count_learned_job_skills(job, state)
  local label = localized_text(lang, "Skill", "Skill")
  return string.format("%s %d/%d", label, learned, total)
end

-- ジョブ一覧の行を、成長方針とスキル進捗だけに絞って整形する。
local function format_job_line(job, state, lang)
  local progress = (state.job_levels or {})[job.id] or player.default_job_progress()
  local is_active = ((state.actor or {}).id == job.id)
  local marker = is_active and "◆ACTIVE" or "◇CANDIDATE"
  local growth_text = build_job_growth_line(job, lang)
  local skill_line = build_job_skill_progress_line(job, state, lang)
  return string.format(
    "%s %-12s Lv%-2d %s | %s | %s",
    marker,
    menu_locale.resolve_job_name(job, lang),
    progress.level or 1,
    menu_locale.resolve_job_role(job, lang),
    growth_text,
    skill_line
  )
end

-- ジョブ詳細画面で扱う行の実行可否を判定するため、適用行かどうかを識別する。
local function is_job_apply_row(item)
  return type(item) == "table" and item.id == "apply_job"
end

-- ジョブ詳細画面の表示行を組み立てる。
local function build_job_detail_items(job, state, lang)
  local detail = build_job_detail(job, state, lang) or { lines = {} }
  local items = {}
  local is_active = ((state.actor or {}).id == (job or {}).id
    and (job or {}).id ~= nil)
  local apply_label = is_active
      and localized_text(lang, "◆現在のジョブです", "◆Current Job")
    or localized_text(lang, "󰌑 Enterでこのジョブに変更", "󰌑 Enter: Apply this job")
  table.insert(items, {
    id = "apply_job",
    label = apply_label,
    job_id = (job or {}).id,
  })
  table.insert(items, { id = "divider", label = string.rep("─", 24) })
  for index, line in ipairs(detail.lines or {}) do
    local text = tostring(line or "")
    if text == "" then
      text = " "
    end
    table.insert(items, {
      id = string.format("detail_%d", index),
      label = text,
    })
  end
  return items
end

-- ジョブ一覧で選択中の行に対するEnter説明を返す。
local function build_job_list_enter_hint(choice, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not choice then
    if is_ja then
      return { "󰌑 Enterでジョブ詳細を開きます。" }
    end
    return { "󰌑 Press Enter to open job details." }
  end
  if is_ja then
    return {
      "󰌑 Enter: ジョブ詳細を開きます。",
      "󰇀 詳細画面の適用行でジョブ変更します。",
    }
  end
  return {
    "󰌑 Enter: Open job details.",
    "󰇀 Change job from the apply row in detail view.",
  }
end

-- ジョブ詳細で選択中の行に対するEnter説明を返す。
local function build_job_detail_enter_hint(choice, job, state, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not is_job_apply_row(choice) then
    if is_ja then
      return { "󰇀 この行は表示専用です。Enterでは何も起きません。" }
    end
    return { "󰇀 This row is display-only. Enter does nothing." }
  end
  local is_active = ((state.actor or {}).id == (job or {}).id)
  if is_active then
    if is_ja then
      return { "󰇀 すでに現在のジョブです。Enterでは何も起きません。" }
    end
    return { "󰇀 Already the current job. Enter does nothing." }
  end
  if is_ja then
    return {
      "󰌑 Enter: このジョブへ変更します。",
      "󰇀 一覧画面へ戻って結果を確認できます。",
    }
  end
  return {
    "󰌑 Enter: Apply this job.",
    "󰇀 Returns to job list after applying.",
  }
end

-- スキル一覧の行を、現在の有効状態と効果要点が見える形式で整形する。
local function format_skill_line(item, state, lang)
  local enabled = skills.is_enabled(state.skill_settings, item.id, item.kind)
  local marker = enabled and "◆ON" or "◇OFF"
  local kind_label = item.kind == "active" and i18n.t("skill_kind_active", lang) or i18n.t("skill_kind_passive", lang)
  local summary = choice_style.format_skill_summary(item)
  return string.format("%s %s [%s] | %s", marker, resolve_skill_name(item, lang), kind_label, summary)
end

-- 設定系の操作は別モジュールへ委譲する。
apply_equipment = function(state, slot, item_id)
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
  local open_job_list

  -- ジョブ詳細を1カラムで表示し、適用行のみEnterで実行可能にする。
  local function open_job_detail(job)
    menu_view.select(build_job_detail_items(job, get_state(), lang), {
      prompt_provider = function()
        local title = i18n.t("prompt_job", lang)
        local legend = localized_text(lang, "ジョブ詳細", "Job Detail")
        return string.format("%s | %s", title, legend)
      end,
      lang = lang,
      footer_hints = menu_locale.submenu_footer_hints(lang),
      format_item = function(item)
        return item.label or ""
      end,
      can_execute_on_enter = function(item)
        if not is_job_apply_row(item) then
          return false
        end
        return ((get_state().actor or {}).id ~= job.id)
      end,
      enter_hint_provider = function(item)
        return build_job_detail_enter_hint(item, job, get_state(), lang)
      end,
    }, function(choice)
      if not choice then
        return open_job_list()
      end
      if not is_job_apply_row(choice) then
        return
      end
      local current = get_state()
      if (current.actor or {}).id ~= job.id then
        local next_state = state_module.change_job(current, job.id)
        local job_name = menu_locale.resolve_job_name(job, lang)
        set_state(menu_logging.append_localized(
          next_state,
          lang,
          string.format("ジョブ変更: %s", job_name ~= "" and job_name or tostring(job.id or "-")),
          string.format("Job Changed: %s", job_name ~= "" and job_name or tostring(job.id or "-"))
        ))
      end
      open_job_list()
    end, config)
  end

  -- ジョブ一覧は要約表示に絞り、Enterで詳細画面へ遷移させる。
  open_job_list = function()
    menu_view.select(entries, {
      prompt_provider = function()
        local title = i18n.t("prompt_job", lang)
        local legend = localized_text(lang, "◆現在  ◇候補  Enterで詳細", "◆ACTIVE  ◇CANDIDATE  Enter for details")
        return string.format("%s | %s", title, legend)
      end,
      lang = lang,
      footer_hints = menu_locale.submenu_footer_hints(lang),
      format_item = function(item)
        return format_job_line(item, get_state(), lang)
      end,
      enter_hint_provider = function(item)
        return build_job_list_enter_hint(item, lang)
      end,
    }, function(choice)
      if not choice then
        if on_close then
          -- キャンセル時は状態画面へ戻る。
          on_close()
        end
        return
      end
      open_job_detail(choice)
    end, config)
  end

  open_job_list()
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
    prompt_provider = function()
      local title = i18n.t("prompt_skills", lang)
      local legend = localized_text(lang, "◆ON  ◇OFF  Enterで切替", "◆ON  ◇OFF  Enter to toggle")
      return string.format("%s | %s", title, legend)
    end,
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      return format_skill_line(item, get_state(), lang)
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
    local next_enabled = not enabled
    bucket[choice.id] = next_enabled
    local next_state = util.merge_tables(current_state, { skill_settings = settings })
    local skill_name = resolve_skill_name(choice, lang)
    set_state(menu_logging.append_localized(
      next_state,
      lang,
      string.format("スキル設定: %s -> %s", skill_name, next_enabled and "有効" or "無効"),
      string.format("Skill Toggled: %s -> %s", skill_name, next_enabled and "ON" or "OFF")
    ))
  end, config)
end

-- ステージ選択時に、適用後の開始条件を右ペインへ表示する。
local function build_stage_detail(stage, state, config, lang)
  if not stage then
    return nil
  end
  local stage_name = render_stage.resolve_stage_name(stage, nil, lang)
  local current_stage_id = (state.progress or {}).stage_id
  local lines = {}
  if lang == "ja" or lang == "jp" then
    table.insert(lines, string.format("開始地点: %d", tonumber(stage.start) or 0))
    table.insert(lines, string.format("区間長: %d", tonumber(stage.length) or 0))
    table.insert(lines, string.format("無限ステージ: %s", (stage.infinite == true) and "有効" or "無効"))
    table.insert(lines, string.format("ボス間隔: %d", tonumber(stage.boss_every or config.boss_every) or 0))
    table.insert(lines, string.format("マイルストーン数: %d", #((stage.boss_milestones or {}))))
    table.insert(lines, "")
    table.insert(lines, string.format("選択後は %s から開始します。", stage_name))
    if stage.id == current_stage_id then
      table.insert(lines, "現在の開始ダンジョンです。")
    end
  else
    table.insert(lines, string.format("Start Distance: %d", tonumber(stage.start) or 0))
    table.insert(lines, string.format("Segment Length: %d", tonumber(stage.length) or 0))
    table.insert(lines, string.format("Infinite Stage: %s", (stage.infinite == true) and "On" or "Off"))
    table.insert(lines, string.format("Boss Interval: %d", tonumber(stage.boss_every or config.boss_every) or 0))
    table.insert(lines, string.format("Milestone Count: %d", #((stage.boss_milestones or {}))))
    table.insert(lines, "")
    table.insert(lines, string.format("After select, run starts at %s.", stage_name))
    if stage.id == current_stage_id then
      table.insert(lines, "This is your current starting dungeon.")
    end
  end
  return { title = stage_name, lines = lines }
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
    detail_provider = function(item)
      return build_stage_detail(item, get_state(), config, lang)
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
    local stage_name = render_stage.resolve_stage_name(choice, nil, lang)
    local next_state = util.merge_tables(current, { progress = refreshed })
    set_state(menu_logging.append_localized(
      next_state,
      lang,
      string.format("開始ステージ変更: %s", stage_name),
      string.format("Start Stage Changed: %s", stage_name)
    ))
  end, config)
end

local function open_equip_menu(get_state, set_state, config, on_close)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local slots = { "weapon", "armor", "accessory" }
  local function open_slot_menu()
    -- 装備枠を選択するためのメニューを表示する。
    menu_view.select(slots, {
      prompt_provider = function()
        local title = i18n.t("prompt_slot", lang)
        local legend = localized_text(lang, "現在装備と候補数を確認", "Check equipped item and choices")
        return string.format("%s | %s", title, legend)
      end,
      lang = lang,
      footer_hints = menu_locale.submenu_footer_hints(lang),
      keep_open = true,
      format_item = function(item)
        return format_slot_line(item, get_state(), config, lang)
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
        prompt_provider = function()
          local title = i18n.t("prompt_equipment", lang)
          local slot_name = menu_locale.slot_label(slot, lang)
          local legend = localized_text(lang, "◆装備中  ◇候補  Δ=変更差分", "◆EQUIPPED  ◇CANDIDATE  Δ=Change")
          return string.format("%s [%s] | %s", title, slot_name, legend)
        end,
        lang = lang,
        footer_hints = menu_locale.submenu_footer_hints(lang),
        -- 装備確定後もメニューを閉じずに連続で選択できるようにする。
        keep_open = true,
        format_item = function(item)
          return format_equip_choice_line(item, get_state(), slot, config, lang)
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
        local current_state = get_state()
        if ((current_state.equipment or {})[slot]) == item.id then
          return
        end
        local slot_name = menu_locale.slot_label(slot, lang)
        local item_name = menu_logging.resolve_item_name(item, lang)
        local next_state = apply_equipment(current_state, slot, item.id)
        set_state(menu_logging.append_localized(
          next_state,
          lang,
          string.format("装備変更: %s -> %s", slot_name, item_name),
          string.format("Equipment Changed: %s -> %s", slot_name, item_name)
        ))
      end, config)
    end, config)
  end
  open_slot_menu()
end

M.open_job_menu = open_job_menu
M.open_skills_menu = open_skills_menu
M.open_stage_menu = open_stage_menu
M.open_equip_menu = open_equip_menu

return M
