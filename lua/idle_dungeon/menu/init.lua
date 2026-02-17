-- このモジュールはメニューの入口とアクション選択を提供する。
-- メニュー関連の参照先はmenu配下へ揃える。
local actions = require("idle_dungeon.menu.actions")
local game_speed = require("idle_dungeon.core.game_speed")
local i18n = require("idle_dungeon.i18n")
local menu_logging = require("idle_dungeon.menu.logging")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_view = require("idle_dungeon.menu.view")
local settings = require("idle_dungeon.menu.settings")
local shop = require("idle_dungeon.menu.shop")
local tabs_data = require("idle_dungeon.menu.tabs_data")
local toggle = require("idle_dungeon.menu.toggle")
local state_module = require("idle_dungeon.core.state")
local tabs_view = require("idle_dungeon.menu.tabs_view")
local M = {}
local menu_open = false
local open_status_root
local on_close_callback = nil
local view_state = {
  dex = {
    mode = "enemy",
    sort_mode = "encounter",
    filter_element = "all",
    filter_keyword = "",
    show_controls = false,
    show_all_enemies = false,
    show_all_items = false,
  },
}

local function reset_view_state()
  view_state = {
    dex = {
      mode = "enemy",
      sort_mode = "encounter",
      filter_element = "all",
      filter_keyword = "",
      show_controls = false,
      show_all_enemies = false,
      show_all_items = false,
    },
  }
end

local function with_item_icon(item, text)
  if not item or not item.icon or item.icon == "" then
    return text
  end
  return string.format("%s %s", item.icon, text)
end

-- メニュー操作ログを状態へ追記する。行数上限はgame/logで制御する。
local function append_menu_log(get_state, set_state, text)
  local safe_text = tostring(text or "")
  if safe_text == "" then
    return
  end
  set_state(menu_logging.append(get_state(), safe_text))
end

-- タブ行は項目名を主体にし、識別タグや連番は表示しない。
local function format_card_row(label, _, _, _, hint)
  local safe_label = tostring(label or "")
  local safe_hint = tostring(hint or "")
  if safe_hint == "" then
    return safe_label
  end
  return string.format("%s | %s", safe_label, safe_hint)
end

-- 表示行数トグルの次値を、設定保存前にプレビューするために計算する。
local function next_display_lines(current)
  local safe = tonumber(current) or 2
  if safe >= 2 then
    return 1
  end
  if safe == 1 then
    return 0
  end
  return 2
end

local function render_mode_name(is_text, lang)
  if is_text then
    return lang == "ja" and "Text" or "Text"
  end
  return lang == "ja" and "Visual" or "Visual"
end

-- 操作タブで、選択後に起きる変化を短文で説明する。
local function action_effect_hint(action_id, lang)
  local is_ja = lang == "ja" or lang == "jp"
  local hints_ja = {
    equip = "装備差分を比較して即時反映",
    stage = "開始ダンジョンと進行位置を変更",
    purchase = "所持金を消費して装備を追加",
    sell = "装備売却で所持金を増加",
    job = "ジョブ変更で成長と技能を切替",
    skills = "技能の有効/無効を切替",
  }
  local hints_en = {
    equip = "Compare gear and apply stat changes",
    stage = "Change starting dungeon and progress",
    purchase = "Spend gold to add equipment",
    sell = "Sell gear to gain gold",
    job = "Switch job growth and skill set",
    skills = "Toggle active and passive skills",
  }
  if is_ja then
    return hints_ja[action_id] or "選択後に状態が更新されます"
  end
  return hints_en[action_id] or "State will be updated after select"
end

-- 設定タブで、現在値と次の値を比較できる短文を返す。
local function config_effect_hint(item, state, config, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if item.id == "auto_start" then
    local current = state.ui.auto_start ~= false
    local now = i18n.t(current and "status_on" or "status_off", lang)
    local next = i18n.t((not current) and "status_on" or "status_off", lang)
    return string.format("%s -> %s", now, next)
  end
  if item.id == "toggle_text" then
    local is_text = (state.ui and state.ui.render_mode) == "text"
    local now = render_mode_name(is_text, lang)
    local next = render_mode_name(not is_text, lang)
    return string.format("%s -> %s", now, next)
  end
  if item.id == "display_lines" then
    local current = (state.ui and state.ui.display_lines) or 2
    local next_lines = next_display_lines(current)
    local now = menu_locale.display_lines_label(current, lang)
    local next = menu_locale.display_lines_label(next_lines, lang)
    return string.format("%s -> %s", now, next)
  end
  if item.id == "game_speed" then
    local current_id = game_speed.resolve_game_speed_id(state, config)
    local next_id = game_speed.cycle_game_speed_id(current_id, config)
    local now = game_speed.label_from_id(current_id, config)
    local next = game_speed.label_from_id(next_id, config)
    return string.format("%s -> %s", now, next)
  end
  if item.id == "battle_hp_show_max" then
    local enabled = (state.ui and state.ui.battle_hp_show_max) or false
    local now = i18n.t(enabled and "status_on" or "status_off", lang)
    local next = i18n.t((not enabled) and "status_on" or "status_off", lang)
    return string.format("%s -> %s", now, next)
  end
  if item.id == "language" then
    if is_ja then
      return "言語選択メニューを開く"
    end
    return "Open language selection"
  end
  if item.id == "reset" then
    if is_ja then
      return "確認後に全データを初期化"
    end
    return "Reset all data after confirmation"
  end
  if item.id == "reload_plugin" then
    if is_ja then
      return "設定と内容を再読込"
    end
    return "Reload plugin settings and content"
  end
  if is_ja then
    return "選択すると設定を適用"
  end
  return "Apply setting on select"
end

local function notify_config_applied(message, lang)
  if not (_G.vim and type(vim.notify) == "function") then
    return
  end
  local title = (lang == "ja" or lang == "jp") and "設定を反映" or "Config Applied"
  local level = (vim.log and vim.log.levels and vim.log.levels.INFO) or nil
  -- 設定反映を短時間通知して、変更結果を即時に認識できるようにする。
  pcall(vim.notify, tostring(message or ""), level, {
    title = title,
    timeout = 1000,
  })
end

-- 設定項目の現在値と次値を分離して返す。
local function resolve_config_current_next(item, state, config, lang)
  local hint = config_effect_hint(item, state, config, lang)
  local current, next = hint:match("^(.-)%s%-%>%s(.+)$")
  if current and next then
    return current, next
  end
  return hint, hint
end

-- 設定タブの右ペインで現在値と次値を比較表示する。
local function build_config_detail(item, get_state, config, lang)
  if not item then
    return nil
  end
  local state = get_state()
  local current, next = resolve_config_current_next(item, state, config, lang)
  local title = i18n.t(item.key or "", lang)
  if lang == "ja" or lang == "jp" then
    return {
      title = title,
      lines = {
        "選択後の変化",
        "現在: " .. tostring(current),
        "次: " .. tostring(next),
      },
    }
  end
  return {
    title = title,
    lines = {
      "After Select",
      "Current: " .. tostring(current),
      "Next: " .. tostring(next),
    },
  }
end

-- 状態タブの選択行に対して、Enterで開く画面や反映内容を下部説明として返す。
local function build_status_enter_hint(item, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not item then
    if is_ja then
      return { "󰌑 Enterで実行する項目を選択してください。" }
    end
    return { "󰌑 Select a row to execute with Enter." }
  end
  local action_id = item.action_id
  if action_id then
    local action_title_ja = {
      equip = "装備変更画面を開きます。",
      stage = "ステージ選択画面を開きます。",
      purchase = "購入画面を開きます。",
      sell = "売却画面を開きます。",
      job = "ジョブ変更画面を開きます。",
      skills = "スキル設定画面を開きます。",
    }
    local action_title_en = {
      equip = "Open equipment menu.",
      stage = "Open stage select menu.",
      purchase = "Open purchase menu.",
      sell = "Open sell menu.",
      job = "Open job change menu.",
      skills = "Open skill settings menu.",
    }
    local title = is_ja and (action_title_ja[action_id] or "選択中の操作を実行します。")
      or (action_title_en[action_id] or "Execute selected action.")
    local hint = action_effect_hint(action_id, lang)
    if is_ja then
      return {
        "󰌑 Enter: " .. title,
        "󰇀 効果: " .. hint,
      }
    end
    return {
      "󰌑 Enter: " .. title,
      "󰇀 Effect: " .. hint,
    }
  end
  -- 実行行以外は詳細閲覧に統一し、表示専用メッセージを出さない。
  if type(item.detail_lines) == "table" and #item.detail_lines > 0 then
    if is_ja then
      return { "󰌑 Enter: 詳細画面を開きます。" }
    end
    return { "󰌑 Enter: Open detail view." }
  end
  if is_ja then
    return { "󰌑 Enter: 詳細画面を開きます。" }
  end
  return { "󰌑 Enter: Open detail view." }
end

-- 設定タブの選択行に対して、Enterで反映される内容を下部説明として返す。
local function build_config_enter_hint(item, get_state, config, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not item then
    if is_ja then
      return { "󰌑 Enterで変更する設定項目を選択してください。" }
    end
    return { "󰌑 Select a setting to change with Enter." }
  end
  local state = get_state()
  local effect = config_effect_hint(item, state, config, lang)
  if is_ja then
    return {
      "󰌑 Enter: " .. effect,
      "󰇀 設定はこの画面のまま反映されます。",
    }
  end
  return {
    "󰌑 Enter: " .. effect,
    "󰇀 This setting is applied without closing the menu.",
  }
end

-- 図鑑タブの選択行に対して、Enterで起きる操作を下部説明として返す。
local function build_dex_enter_hint(item, lang)
  local is_ja = lang == "ja" or lang == "jp"
  if not item then
    if is_ja then
      return { "󰌑 Enterで操作する行を選択してください。" }
    end
    return { "󰌑 Select a row to control with Enter." }
  end
  if item.id == "dex_entry" then
    if is_ja then
      return { "󰌑 Enter: 図鑑カードの詳細を開きます。" }
    end
    return { "󰌑 Enter: Open detail card." }
  end
  if item.id ~= "dex_control" then
    if is_ja then
      return { "󰇀 この行は表示専用です。操作はできません。" }
    end
    return { "󰇀 This row is display-only and cannot be executed." }
  end
  local action_ja = {
    cycle_mode = "表示モードを切り替えます。",
    toggle_controls = "詳細フィルタの表示を切り替えます。",
    cycle_sort = "並び順を切り替えます。",
    cycle_filter_element = "属性フィルタを切り替えます。",
    cycle_filter_keyword = "検索キーワードを切り替えます。",
    expand_enemy = "敵一覧を展開します。",
    collapse_enemy = "敵一覧を折りたたみます。",
    expand_item = "装備一覧を展開します。",
    collapse_item = "装備一覧を折りたたみます。",
  }
  local action_en = {
    cycle_mode = "Switch list mode.",
    toggle_controls = "Toggle filter controls.",
    cycle_sort = "Switch sort order.",
    cycle_filter_element = "Switch element filter.",
    cycle_filter_keyword = "Switch keyword filter.",
    expand_enemy = "Expand enemy entries.",
    collapse_enemy = "Collapse enemy entries.",
    expand_item = "Expand item entries.",
    collapse_item = "Collapse item entries.",
  }
  local message = is_ja and (action_ja[item.action] or "図鑑の表示を更新します。")
    or (action_en[item.action] or "Update dex view.")
  return { "󰌑 Enter: " .. message }
end

-- 状態に応じてラベルが変わる項目を整形する。
local function format_item_with_state(item, get_state, config, lang, index, total)
  local state = get_state()
  -- トグル系はボタン風の表示で状態が分かるように整形する。
  if item.id == "auto_start" then
    local label = with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), state.ui.auto_start ~= false, lang))
    return format_card_row(label, index, total, "config")
  end
  if item.id == "toggle_text" then
    local is_text = (state.ui and state.ui.render_mode) == "text"
    local label = with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), is_text, lang))
    return format_card_row(label, index, total, "config")
  end
  if item.id == "display_lines" then
    local lines = (state.ui and state.ui.display_lines) or 2
    local label = with_item_icon(item, menu_locale.display_lines_label(lines, lang))
    return format_card_row(label, index, total, "config")
  end
  if item.id == "game_speed" then
    local label = with_item_icon(item, menu_locale.game_speed_label(state, config, lang))
    return format_card_row(label, index, total, "config")
  end
  -- 戦闘時のHP分母表示はトグル表示で整形する。
  if item.id == "battle_hp_show_max" then
    local enabled = (state.ui and state.ui.battle_hp_show_max) or false
    local label = with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), enabled, lang))
    return format_card_row(label, index, total, "config")
  end
  local base = with_item_icon(item, i18n.t(item.key, lang))
  return format_card_row(base, index, total, "config")
end
local function handle_action_choice(action, get_state, set_state, config, lang, handlers)
  if not action then
    return
  end
  local action_id = action.action_id or action.id
  local on_cancel = nil
  if not (type(action) == "table" and action.keep_open == true) then
    on_cancel = function()
      open_status_root(get_state, set_state, config, handlers)
    end
  end
  local is_ja = lang == "ja" or lang == "jp"
  local action_logs_ja = {
    equip = "装備変更メニューを開く",
    stage = "ステージ選択メニューを開く",
    purchase = "購入メニューを開く",
    sell = "売却メニューを開く",
    job = "ジョブ変更メニューを開く",
    skills = "スキル設定メニューを開く",
  }
  local action_logs_en = {
    equip = "Open equipment menu",
    stage = "Open stage select menu",
    purchase = "Open purchase menu",
    sell = "Open sell menu",
    job = "Open job change menu",
    skills = "Open skill settings menu",
  }
  append_menu_log(
    get_state,
    set_state,
    is_ja and (action_logs_ja[action_id] or "状態タブ操作を実行")
      or (action_logs_en[action_id] or "Executed status action")
  )
  if action_id == "equip" then
    -- 装備メニューのキャンセル時に状態画面へ戻す。
    return actions.open_equip_menu(get_state, set_state, config, on_cancel)
  end
  if action_id == "stage" then
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_stage_menu(get_state, set_state, config, on_cancel)
  end
  if action_id == "purchase" then
    return shop.open_purchase_menu(get_state, set_state, lang, config, on_cancel)
  end
  if action_id == "sell" then
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return shop.open_sell_menu(get_state, set_state, lang, config, on_cancel)
  end
  if action_id == "job" then
    -- ジョブ変更メニューを開く。
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_job_menu(get_state, set_state, config, on_cancel)
  end
  if action_id == "skills" then
    -- スキル一覧と有効/無効切り替えを表示する。
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_skills_menu(get_state, set_state, config, on_cancel)
  end
end

local build_tabs

-- 状態タブの行から遷移可能なクイック操作を処理する。
local function handle_status_choice(item, get_state, set_state, config, lang, handlers)
  if not item then
    return
  end
  if not item.action_id then
    return
  end
  return handle_action_choice(item, get_state, set_state, config, lang, handlers)
end

local function handle_config_choice(action, get_state, set_state, config, handlers, lang)
  if not action then
    return
  end
  local effect_message = config_effect_hint(action, get_state(), config, lang)
  local applied = false
  if action.id == "toggle_text" then
    set_state(state_module.toggle_render_mode(get_state()))
    applied = true
  end
  if (not applied) and action.id == "auto_start" then
    settings.toggle_auto_start(get_state, set_state)
    applied = true
  end
  if (not applied) and action.id == "display_lines" then
    settings.toggle_display_lines(get_state, set_state, config)
    applied = true
  end
  if (not applied) and action.id == "game_speed" then
    settings.cycle_game_speed(get_state, set_state, config)
    applied = true
  end
  if (not applied) and action.id == "battle_hp_show_max" then
    settings.toggle_battle_hp_show_max(get_state, set_state, config)
    applied = true
  end
  if (not applied) and action.id == "reload_plugin" and handlers and type(handlers.on_reload) == "function" then
    handlers.on_reload()
    applied = true
  end
  if (not applied) and action.id == "language" then
    append_menu_log(
      get_state,
      set_state,
      (lang == "ja" or lang == "jp") and "言語設定メニューを開く" or "Open language settings"
    )
    return settings.open_language_menu(get_state, set_state, config)
  end
  if (not applied) and action.id == "reset" then
    -- 全データ初期化の確認画面を開く。
    append_menu_log(
      get_state,
      set_state,
      (lang == "ja" or lang == "jp") and "全データ初期化の確認画面を開く" or "Open reset confirmation"
    )
    return settings.open_reset_menu(get_state, set_state, config)
  end
  if applied then
    append_menu_log(
      get_state,
      set_state,
      (lang == "ja" or lang == "jp")
          and ("設定変更: " .. tostring(effect_message or ""))
        or ("Config changed: " .. tostring(effect_message or ""))
    )
    notify_config_applied(effect_message, lang)
  end
end
-- メニューの開閉状態を閉じる側へ更新する。
local function mark_closed()
  menu_open = false
  reset_view_state()
  if on_close_callback then
    on_close_callback()
  end
end

local function append_dex_action_log(action, get_state, set_state, lang)
  local is_ja = lang == "ja" or lang == "jp"
  local labels_ja = {
    cycle_mode = "図鑑表示モードを切り替え",
    toggle_controls = "図鑑フィルタ表示を切り替え",
    expand_enemy = "図鑑の敵一覧を展開",
    collapse_enemy = "図鑑の敵一覧を折りたたみ",
    expand_item = "図鑑の装備一覧を展開",
    collapse_item = "図鑑の装備一覧を折りたたみ",
    cycle_sort = "図鑑の並び順を切り替え",
    cycle_filter_element = "図鑑の属性フィルタを切り替え",
    cycle_filter_keyword = "図鑑のキーワードフィルタを切り替え",
  }
  local labels_en = {
    cycle_mode = "Dex view mode changed",
    toggle_controls = "Dex filter controls toggled",
    expand_enemy = "Dex enemy list expanded",
    collapse_enemy = "Dex enemy list collapsed",
    expand_item = "Dex item list expanded",
    collapse_item = "Dex item list collapsed",
    cycle_sort = "Dex sort order changed",
    cycle_filter_element = "Dex element filter changed",
    cycle_filter_keyword = "Dex keyword filter changed",
  }
  local key = action and action.action
  if not key then
    return
  end
  append_menu_log(
    get_state,
    set_state,
    is_ja and (labels_ja[key] or "図鑑操作を実行") or (labels_en[key] or "Executed dex action")
  )
end

local function handle_dex_choice(action, get_state, set_state, lang)
  if not action or action.id ~= "dex_control" then
    return
  end
  if action.action == "cycle_mode" then
    if view_state.dex.mode == "enemy" then
      view_state.dex.mode = "item"
    elseif view_state.dex.mode == "item" then
      view_state.dex.mode = "all"
    else
      view_state.dex.mode = "enemy"
    end
    -- 表示対象を切り替える際は展開状態を初期化して一覧の高さを抑える。
    view_state.dex.show_all_enemies = false
    view_state.dex.show_all_items = false
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "toggle_controls" then
    view_state.dex.show_controls = not (view_state.dex.show_controls == true)
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "expand_enemy" then
    view_state.dex.show_all_enemies = true
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "collapse_enemy" then
    view_state.dex.show_all_enemies = false
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "expand_item" then
    view_state.dex.show_all_items = true
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "collapse_item" then
    view_state.dex.show_all_items = false
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "cycle_sort" then
    if view_state.dex.sort_mode == "encounter" then
      view_state.dex.sort_mode = "count"
    elseif view_state.dex.sort_mode == "count" then
      view_state.dex.sort_mode = "rarity"
    else
      view_state.dex.sort_mode = "encounter"
    end
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "cycle_filter_element" then
    local current = view_state.dex.filter_element or "all"
    local order = { "all", "normal", "fire", "water", "grass", "light", "dark" }
    local next_value = "all"
    for index, value in ipairs(order) do
      if value == current then
        next_value = order[(index % #order) + 1]
        break
      end
    end
    view_state.dex.filter_element = next_value
    view_state.dex.show_all_enemies = false
    view_state.dex.show_all_items = false
    append_dex_action_log(action, get_state, set_state, lang)
    return
  end
  if action.action == "cycle_filter_keyword" then
    local current = tostring(view_state.dex.filter_keyword or "")
    local keywords = action.keywords or { "" }
    local next_value = keywords[1] or ""
    for index, token in ipairs(keywords) do
      if token == current then
        next_value = keywords[(index % #keywords) + 1] or ""
        break
      end
    end
    view_state.dex.filter_keyword = next_value
    view_state.dex.show_all_enemies = false
    view_state.dex.show_all_items = false
    append_dex_action_log(action, get_state, set_state, lang)
  end
end

build_tabs = function(get_state, set_state, config, handlers)
  local state = get_state()
  local lang = menu_locale.resolve_lang(state, config)
  return {
    {
      id = "status",
      label = i18n.t("menu_tab_status", lang),
      items = tabs_data.build_status_items(state, config, lang),
      format_item = function(item)
        return item.label
      end,
      detail_provider = function(item)
        return tabs_data.build_status_detail(item, get_state(), config, lang)
      end,
      enter_hint_provider = function(item)
        return build_status_enter_hint(item, lang)
      end,
      can_execute_on_enter = function(item)
        return type(item) == "table" and item.action_id ~= nil
      end,
      on_choice = function(item)
        return handle_status_choice(item, get_state, set_state, config, lang, handlers)
      end,
    },
    {
      id = "config",
      label = i18n.t("menu_tab_config", lang),
      items = tabs_data.build_config_items(),
      format_item = function(item, index, total)
        return format_item_with_state(item, get_state, config, lang, index, total)
      end,
      on_choice = function(action)
        return handle_config_choice(action, get_state, set_state, config, handlers, lang)
      end,
      detail_provider = function(item)
        return build_config_detail(item, get_state, config, lang)
      end,
      enter_hint_provider = function(item)
        return build_config_enter_hint(item, get_state, config, lang)
      end,
      can_execute_on_enter = function(item)
        return type(item) == "table" and item.id ~= nil
      end,
    },
    {
      id = "dex",
      label = i18n.t("menu_tab_dex", lang),
      items = tabs_data.build_dex_items(state, config, lang, view_state.dex),
      format_item = function(item)
        return item.label
      end,
      on_choice = function(action)
        return handle_dex_choice(action, get_state, set_state, lang)
      end,
      enter_hint_provider = function(item)
        return build_dex_enter_hint(item, lang)
      end,
      can_execute_on_enter = function(item)
        return type(item) == "table" and item.id == "dex_control"
      end,
    },
    {
      id = "log",
      label = i18n.t("menu_tab_log", lang),
      items = tabs_data.build_log_items(state, lang),
      format_item = function(item)
        return item.label
      end,
      can_execute_on_enter = function()
        return false
      end,
    },
    {
      id = "credits",
      label = i18n.t("menu_tab_credits", lang),
      items = tabs_data.build_credits_items(lang),
      format_item = function(item)
        return item.label
      end,
    },
  }
end
-- メニューの最初のページを再表示するための入口を用意する。
open_status_root = function(get_state, set_state, config, handlers)
  local lang = menu_locale.resolve_lang(get_state(), config)
  -- 全メニュー画面で共通のライブトラック情報を表示するため文脈を共有する。
  menu_view.set_context(get_state, config)
  tabs_view.set_context(get_state, config)
  local tabs = build_tabs(get_state, set_state, config, handlers)
  -- メニューの最初のページは状態詳細として表示する。
  tabs_view.select(tabs, {
    active = 1,
    on_close = mark_closed,
    title = i18n.t("menu_title", lang),
    footer_hints = menu_locale.menu_footer_hints(lang),
  }, config)
  menu_open = true
end
local function open(get_state, set_state, config, handlers)
  return open_status_root(get_state, set_state, config, handlers)
end

local function toggle_menu(get_state, set_state, config, handlers)
  local should_open = toggle.toggle_open(menu_open)
  if should_open then
    return open_status_root(get_state, set_state, config, handlers)
  end
  -- すでに開いている場合はメニュー表示を閉じる。
  M.close()
end

local function update_menu(get_state, set_state, config, handlers)
  if not menu_open then
    return
  end
  menu_view.set_context(get_state, config)
  tabs_view.set_context(get_state, config)
  -- 開いているメニュー表示を最新の状態に更新する。
  tabs_view.update(build_tabs(get_state, set_state, config, handlers))
end

M.open = open
M.toggle = toggle_menu
M.update = update_menu
M.close = function(options)
  local opts = options or {}
  local silent = opts.silent == true
  local saved_callback = nil
  if silent then
    -- 再読込時は画面更新コールバックを抑止して残像を防ぐ。
    saved_callback = on_close_callback
    on_close_callback = nil
  end
  -- 子メニューとタブメニューを順に閉じて表示を完全に解放する。
  menu_view.close()
  tabs_view.close(silent)
  menu_open = false
  reset_view_state()
  if silent then
    on_close_callback = saved_callback
  end
end
M.is_open = function()
  return menu_open
end
M.set_on_close = function(callback)
  on_close_callback = callback
end

return M
