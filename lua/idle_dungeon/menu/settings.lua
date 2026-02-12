-- このモジュールはメニューの設定系操作をまとめる。
-- 設定操作の参照先はmenuとcore配下へ整理する。
local i18n = require("idle_dungeon.i18n")
local game_speed = require("idle_dungeon.core.game_speed")
local menu_locale = require("idle_dungeon.menu.locale")
local menu_view = require("idle_dungeon.menu.view")
local state_module = require("idle_dungeon.core.state")

local M = {}

local function open_language_menu(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local languages = (config.ui or {}).languages or { "en", "ja" }
  -- 言語選択のメニューを表示する。
  menu_view.select(languages, {
    prompt = i18n.t("prompt_language", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    -- 言語を選んでも閉じず、連続操作できるようにする。
    keep_open = true,
    format_item = function(item)
      return i18n.language_label(item, lang)
    end,
    detail_provider = function(item)
      local current = menu_locale.resolve_lang(get_state(), config)
      if lang == "ja" or lang == "jp" then
        return {
          title = i18n.language_label(item, lang),
          lines = {
            "選択すると表示言語を即時反映します。",
            "現在: " .. i18n.language_label(current, lang),
            "次: " .. i18n.language_label(item, lang),
          },
        }
      end
      return {
        title = i18n.language_label(item, lang),
        lines = {
          "Apply language immediately after select.",
          "Current: " .. i18n.language_label(current, lang),
          "Next: " .. i18n.language_label(item, lang),
        },
      }
    end,
  }, function(choice)
    if not choice then
      return
    end
    -- 表示言語を更新して保存する。
    local next_state = state_module.set_language(get_state(), choice)
    set_state(next_state)
  end, config)
end

local function open_status_menu(get_state, config)
  local state = get_state()
  local lang = menu_locale.resolve_lang(state, config)
  -- 詳細な状態情報をメニューに表示する。
  local lines = menu_locale.status_lines(state, lang, config)
  -- 現在の状態を確認するためのメニューを表示する。
  menu_view.select(lines, {
    prompt = i18n.t("prompt_status", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    format_item = function(item)
      return item
    end,
  }, function(_) end, config)
end

local function toggle_auto_start(get_state, set_state)
  local state = get_state()
  -- 自動開始の設定を反転して保存する。
  local current = state.ui.auto_start ~= false
  local next_state = state_module.set_auto_start(state, not current)
  set_state(next_state)
end

local function toggle_display_lines(get_state, set_state, config)
  local state = get_state()
  local current = (state.ui and state.ui.display_lines) or (config.ui or {}).height or 2
  local next_lines = 2
  if current >= 2 then
    next_lines = 1
  elseif current == 1 then
    next_lines = 0
  else
    next_lines = 2
  end
  -- 表示行数を0〜2行で切り替えて保存する。
  local next_state = state_module.set_display_lines(state, next_lines)
  set_state(next_state)
end

local function cycle_game_speed(get_state, set_state, config)
  local state = get_state()
  local current = (state.ui and state.ui.game_speed) or nil
  local next_speed = game_speed.cycle_game_speed_id(current, config)
  -- ゲーム進行速度のみを循環切り替えして保存する。
  local next_state = state_module.set_game_speed(state, next_speed)
  set_state(next_state)
end
local function toggle_battle_hp_show_max(get_state, set_state, config)
  local state = get_state()
  local current = (state.ui and state.ui.battle_hp_show_max) or (config.ui or {}).battle_hp_show_max or false
  -- 戦闘時のHP分母表示を反転して保存する。
  local next_state = state_module.set_battle_hp_show_max(state, not current)
  set_state(next_state)
end

local function build_reset_choices(lang)
  return {
    { id = "no", label = i18n.t("choice_no", lang) },
    { id = "yes", label = i18n.t("choice_yes", lang) },
  }
end

local function open_reset_menu(get_state, set_state, config)
  local lang = menu_locale.resolve_lang(get_state(), config)
  local choices = build_reset_choices(lang)
  -- すべてのデータを初期化する確認メニューを表示する。
  menu_view.select(choices, {
    prompt = i18n.t("prompt_reset_confirm", lang),
    lang = lang,
    footer_hints = menu_locale.submenu_footer_hints(lang),
    keep_open = true,
    format_item = function(item)
      return item.label
    end,
    detail_provider = function(item)
      if lang == "ja" or lang == "jp" then
        if item and item.id == "yes" then
          return {
            title = item.label,
            lines = {
              "全ての進行データと設定を初期化します。",
              "この操作は取り消せません。",
            },
          }
        end
        return {
          title = item and item.label or "",
          lines = {
            "初期化を実行せず設定画面へ戻ります。",
          },
        }
      end
      if item and item.id == "yes" then
        return {
          title = item.label,
          lines = {
            "Reset all progress and settings.",
            "This action cannot be undone.",
          },
        }
      end
      return {
        title = item and item.label or "",
        lines = {
          "Cancel reset and return to settings.",
        },
      }
    end,
  }, function(choice)
    if not choice or choice.id ~= "yes" then
      return
    end
    -- 進行状況と設定を初期化して保存する。
    local next_state = state_module.reset_state(config)
    set_state(next_state)
  end, config)
end

M.open_language_menu = open_language_menu
M.open_status_menu = open_status_menu
M.toggle_auto_start = toggle_auto_start
M.toggle_display_lines = toggle_display_lines
M.cycle_game_speed = cycle_game_speed
M.toggle_battle_hp_show_max = toggle_battle_hp_show_max
M.open_reset_menu = open_reset_menu

return M
