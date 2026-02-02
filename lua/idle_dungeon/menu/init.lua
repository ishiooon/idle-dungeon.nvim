-- このモジュールはメニューの入口とアクション選択を提供する。
-- メニュー関連の参照先はmenu配下へ揃える。
local actions = require("idle_dungeon.menu.actions")
local i18n = require("idle_dungeon.i18n")
local menu_locale = require("idle_dungeon.menu.locale")
local settings = require("idle_dungeon.menu.settings")
local shop = require("idle_dungeon.menu.shop")
local tabs_data = require("idle_dungeon.menu.tabs_data")
local toggle = require("idle_dungeon.menu.toggle")
local state_module = require("idle_dungeon.core.state")
local tabs_view = require("idle_dungeon.menu.tabs_view")
local M = {}
local menu_open = false
-- 状態に応じてラベルが変わる項目を整形する。
local function format_item_with_state(item, get_state, lang)
  local state = get_state()
  -- トグル系はボタン風の表示で状態が分かるように整形する。
  if item.id == "auto_start" then
    return menu_locale.toggle_label(i18n.t(item.key, lang), state.ui.auto_start ~= false, lang)
  end
  if item.id == "toggle_text" then
    local is_text = (state.ui and state.ui.render_mode) == "text"
    return menu_locale.toggle_label(i18n.t(item.key, lang), is_text, lang)
  end
  return i18n.t(item.key, lang)
end
local function handle_action_choice(action, get_state, set_state, config, lang)
  if not action then
    return
  end
  if action.id == "equip" then
    return actions.open_equip_menu(get_state, set_state, config)
  end
  if action.id == "stage" then
    return actions.open_stage_menu(get_state, set_state, config)
  end
  if action.id == "purchase" then
    return shop.open_purchase_menu(get_state, set_state, lang, config)
  end
  if action.id == "sell" then
    return shop.open_sell_menu(get_state, set_state, lang, config)
  end
  if action.id == "character" then
    return actions.open_character_menu(get_state, set_state, config)
  end
end
local function handle_config_choice(action, get_state, set_state, config)
  if not action then
    return
  end
  if action.id == "toggle_text" then
    return set_state(state_module.toggle_render_mode(get_state()))
  end
  if action.id == "auto_start" then
    return settings.toggle_auto_start(get_state, set_state)
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
end

local function build_tabs(get_state, set_state, config)
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
    },
    {
      id = "actions",
      label = i18n.t("menu_tab_actions", lang),
      items = tabs_data.build_action_items(),
      format_item = function(item)
        return i18n.t(item.key, lang)
      end,
      on_choice = function(action)
        return handle_action_choice(action, get_state, set_state, config, lang)
      end,
    },
    {
      id = "config",
      label = i18n.t("menu_tab_config", lang),
      items = tabs_data.build_config_items(),
      format_item = function(item)
        return format_item_with_state(item, get_state, lang)
      end,
      on_choice = function(action)
        return handle_config_choice(action, get_state, set_state, config)
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
local function open_status_root(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local tabs = build_tabs(get_state, set_state, config)
  -- メニューの最初のページは状態詳細として表示する。
  tabs_view.select(tabs, {
    active = 1,
    on_close = mark_closed,
    title = i18n.t("menu_title", lang),
    footer_hints = menu_locale.menu_footer_hints(lang),
  }, config)
  menu_open = true
end
local function open(get_state, set_state, config)
  return open_status_root(get_state, set_state, config)
end

local function toggle_menu(get_state, set_state, config)
  local should_open = toggle.toggle_open(menu_open)
  if should_open then
    return open_status_root(get_state, set_state, config)
  end
  -- すでに開いている場合はメニュー表示を閉じる。
  tabs_view.close()
  menu_open = false
end

local function update_menu(get_state, set_state, config)
  if not menu_open then
    return
  end
  -- 開いているメニュー表示を最新の状態に更新する。
  tabs_view.update(build_tabs(get_state, set_state, config))
end

M.open = open
M.toggle = toggle_menu
M.update = update_menu

return M
