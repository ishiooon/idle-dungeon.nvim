-- このモジュールはメニューの入口とアクション選択を提供する。
-- メニュー関連の参照先はmenu配下へ揃える。
local actions = require("idle_dungeon.menu.actions")
local i18n = require("idle_dungeon.i18n")
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

local function with_item_icon(item, text)
  if not item or not item.icon or item.icon == "" then
    return text
  end
  return string.format("%s %s", item.icon, text)
end

-- 状態に応じてラベルが変わる項目を整形する。
local function format_item_with_state(item, get_state, config, lang)
  local state = get_state()
  -- トグル系はボタン風の表示で状態が分かるように整形する。
  if item.id == "auto_start" then
    return with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), state.ui.auto_start ~= false, lang))
  end
  if item.id == "toggle_text" then
    local is_text = (state.ui and state.ui.render_mode) == "text"
    return with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), is_text, lang))
  end
  if item.id == "display_lines" then
    local lines = (state.ui and state.ui.display_lines) or 2
    return with_item_icon(item, menu_locale.display_lines_label(lines, lang))
  end
  if item.id == "game_speed" then
    return with_item_icon(item, menu_locale.game_speed_label(state, config, lang))
  end
  -- 戦闘時のHP分母表示はトグル表示で整形する。
  if item.id == "battle_hp_show_max" then
    local enabled = (state.ui and state.ui.battle_hp_show_max) or false
    return with_item_icon(item, menu_locale.toggle_label(i18n.t(item.key, lang), enabled, lang))
  end
  return with_item_icon(item, i18n.t(item.key, lang))
end
local function handle_action_choice(action, get_state, set_state, config, lang, handlers)
  if not action then
    return
  end
  if action.id == "equip" then
    -- 装備メニューのキャンセル時に状態画面へ戻す。
    return actions.open_equip_menu(get_state, set_state, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "stage" then
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_stage_menu(get_state, set_state, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "purchase" then
    return shop.open_purchase_menu(get_state, set_state, lang, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "sell" then
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return shop.open_sell_menu(get_state, set_state, lang, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "job" then
    -- ジョブ変更メニューを開く。
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_job_menu(get_state, set_state, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "skills" then
    -- スキル一覧と有効/無効切り替えを表示する。
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_skills_menu(get_state, set_state, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
  if action.id == "job_levels" then
    -- サブメニューのキャンセル時は状態画面へ戻す。
    return actions.open_job_levels_menu(get_state, set_state, config, function()
      open_status_root(get_state, set_state, config, handlers)
    end)
  end
end
local function handle_config_choice(action, get_state, set_state, config, handlers)
  if not action then
    return
  end
  if action.id == "toggle_text" then
    return set_state(state_module.toggle_render_mode(get_state()))
  end
  if action.id == "auto_start" then
    return settings.toggle_auto_start(get_state, set_state)
  end
  if action.id == "display_lines" then
    return settings.toggle_display_lines(get_state, set_state, config)
  end
  if action.id == "game_speed" then
    return settings.cycle_game_speed(get_state, set_state, config)
  end
  if action.id == "battle_hp_show_max" then
    return settings.toggle_battle_hp_show_max(get_state, set_state, config)
  end
  if action.id == "reload_plugin" and handlers and type(handlers.on_reload) == "function" then
    return handlers.on_reload()
  end
  if action.id == "language" then
    return settings.open_language_menu(get_state, set_state, config)
  end
  if action.id == "reset" then
    -- 全データ初期化の確認画面を開く。
    return settings.open_reset_menu(get_state, set_state, config)
  end
end
-- メニューの開閉状態を閉じる側へ更新する。
local function mark_closed()
  menu_open = false
  if on_close_callback then
    on_close_callback()
  end
end

local function build_tabs(get_state, set_state, config, handlers)
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
    },
    {
      id = "actions",
      label = i18n.t("menu_tab_actions", lang),
      items = tabs_data.build_action_items(),
      format_item = function(item)
        return with_item_icon(item, i18n.t(item.key, lang))
      end,
      on_choice = function(action)
        return handle_action_choice(action, get_state, set_state, config, lang, handlers)
      end,
    },
    {
      id = "config",
      label = i18n.t("menu_tab_config", lang),
      items = tabs_data.build_config_items(),
      format_item = function(item)
        return format_item_with_state(item, get_state, config, lang)
      end,
      on_choice = function(action)
        return handle_config_choice(action, get_state, set_state, config, handlers)
      end,
    },
    {
      id = "dex",
      label = i18n.t("menu_tab_dex", lang),
      items = tabs_data.build_dex_items(state, config, lang),
      format_item = function(item)
        return item.label
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
  tabs_view.close()
  menu_open = false
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
M.is_open = function()
  return menu_open
end
M.set_on_close = function(callback)
  on_close_callback = callback
end

return M
