-- このモジュールは固定文言の多言語対応を提供する。

local M = {}

local translations = {
  menu_title = { en = "Idle Dungeon Menu", jp = "Idle Dungeon メニュー" },
  -- タブ表示の文言を定義する。
  menu_tab_status = { en = "Status", jp = "状態" },
  menu_tab_actions = { en = "Actions", jp = "操作" },
  menu_tab_config = { en = "Config", jp = "設定" },
  menu_tab_dex = { en = "Dex", jp = "図鑑" },
  menu_tab_credits = { en = "Credits", jp = "クレジット" },
  menu_action_equip = { en = "Change Equipment", jp = "装備変更" },
  menu_action_stage = { en = "Select Starting Dungeon", jp = "開始ダンジョン設定" },
  menu_action_purchase = { en = "Buy Weapons or Armor", jp = "武器や防具の購入" },
  menu_action_sell = { en = "Sell Equipment", jp = "装備の販売" },
  -- ジョブ変更メニューの文言を追加する。
  menu_action_job = { en = "Change Job", jp = "ジョブ変更" },
  menu_action_skills = { en = "Skills", jp = "スキル一覧" },
  menu_action_job_levels = { en = "Job Levels", jp = "ジョブレベル一覧" },
  menu_action_toggle_text = { en = "Toggle Text Mode", jp = "テキストモード切り替え" },
  menu_action_auto_start = { en = "Auto Start", jp = "自動開始" },
  menu_action_display_lines = { en = "Display Lines", jp = "表示行数" },
  -- 戦闘時のHP分母表示を切り替える文言を追加する。
  menu_action_battle_hp_show_max = { en = "Battle HP Max", jp = "戦闘HP分母表示" },
  menu_action_language = { en = "Language", jp = "言語設定" },
  menu_action_status = { en = "Status", jp = "状態確認" },
  menu_status_metrics = { en = "Input Metrics (Detail)", jp = "入力統計(詳細)" },
  -- メニュー下部の案内文を定義する。
  menu_hint_tabs = { en = "Tabs: Click / <- -> / Tab", jp = "タブ: クリック / <- -> / Tab" },
  menu_hint_toggle = { en = "Toggle: Enter switches", jp = "切り替え: Enterで変更" },
  menu_hint_select = { en = "Select: Enter", jp = "選択: Enter" },
  menu_hint_back = { en = "Back: b / <- / Esc", jp = "戻る: b / <- / Esc" },
  menu_hint_close = { en = "Close: q / Esc", jp = "閉じる: q / Esc" },
  -- 状態詳細メニューの文言を定義する。
  menu_action_open_actions = { en = "Open Actions", jp = "操作メニューへ" },
  menu_action_close = { en = "Close Menu", jp = "閉じる" },
  -- 全データ初期化の表示文言をまとめる。
  menu_action_reset = { en = "Reset All Data", jp = "全データ初期化" },
  prompt_job = { en = "Select a job", jp = "ジョブを選択してください" },
  prompt_skills = { en = "Select a skill to toggle", jp = "切り替えるスキルを選択してください" },
  menu_job_levels_title = { en = "Job Levels", jp = "ジョブレベル一覧" },
  menu_job_levels_empty = { en = "No job data yet.", jp = "ジョブ情報がまだありません。" },
  prompt_stage = { en = "Select a starting dungeon", jp = "開始ダンジョンを選択してください" },
  prompt_slot = { en = "Select an equipment slot", jp = "装備枠を選択してください" },
  prompt_equipment = { en = "Select equipment", jp = "装備を選択してください" },
  prompt_purchase = { en = "Select equipment to buy", jp = "購入する装備を選択してください" },
  prompt_sell = { en = "Select equipment to sell", jp = "売却する装備を選択してください" },
  prompt_language = { en = "Select a language", jp = "言語を選択してください" },
  prompt_status = { en = "Status", jp = "現在の状態" },
  -- 状態詳細の見出しを定義する。
  menu_status_title = { en = "Current Status", jp = "現在の状態(詳細)" },
  credits_title = { en = "Credits", jp = "クレジット" },
  -- クレジット内の表記は IdleDungeon に統一する。
  credits_line_created = { en = "Created by the IdleDungeon team", jp = "IdleDungeon 開発チーム" },
  credits_line_ui = { en = "UI concept: gisketch/triforce.nvim", jp = "UI参考: gisketch/triforce.nvim" },
  -- 画像スプライトの参照表記は廃止した。
  credits_line_thanks = { en = "Thanks for playing!", jp = "遊んでくれてありがとう！" },
  dex_title_enemies = { en = "Enemies", jp = "出会った敵" },
  dex_title_items = { en = "Items", jp = "入手した装備" },
  dex_empty_enemies = { en = "No enemies recorded yet.", jp = "まだ敵を記録していません。" },
  dex_empty_items = { en = "No items recorded yet.", jp = "まだ装備を記録していません。" },
  -- 図鑑の未発見表示とドロップ表記を定義する。
  dex_unknown = { en = "???", jp = "???" },
  dex_label_drops = { en = "Drops", jp = "ドロップ" },
  dex_detail_name = { en = "Name:", jp = "名前:" },
  dex_detail_type = { en = "Type:", jp = "種別:" },
  dex_detail_kind_enemy = { en = "Enemy", jp = "敵" },
  dex_detail_kind_item = { en = "Item", jp = "装備" },
  dex_detail_count = { en = "Count:", jp = "遭遇/取得回数:" },
  dex_detail_element = { en = "Element:", jp = "属性:" },
  dex_detail_flavor = { en = "Flavor:", jp = "説明:" },
  dex_detail_slot = { en = "Slot:", jp = "装備枠:" },
  dex_detail_rarity = { en = "Rarity:", jp = "レアリティ:" },
  dex_rarity_common = { en = "Common", jp = "コモン" },
  dex_rarity_rare = { en = "Rare", jp = "レア" },
  dex_rarity_pet = { en = "Pet", jp = "ペット" },
  -- 初期化確認の文言と選択肢を定義する。
  prompt_reset_confirm = { en = "Reset all data?", jp = "全データを初期化しますか" },
  choice_yes = { en = "Yes", jp = "はい" },
  choice_no = { en = "No", jp = "いいえ" },
  -- 選択イベントの自動決定表示を定義する。
  choice_auto = { en = "Auto:", jp = "自動:" },
  slot_weapon = { en = "Weapon", jp = "武器" },
  slot_armor = { en = "Armor", jp = "防具" },
  slot_accessory = { en = "Accessory", jp = "装身具" },
  slot_companion = { en = "Companion", jp = "仲間" },
  status_unlocked = { en = "Unlocked", jp = "解放済み" },
  status_locked = { en = "Locked", jp = "未解放" },
  status_owned = { en = "Owned:", jp = "所持:" },
  status_price = { en = "Price:", jp = "価格:" },
  status_affordable = { en = "Affordable", jp = "購入可" },
  status_unaffordable = { en = "Too Expensive", jp = "購入不可" },
  -- 装備解放条件の表示文言を追加する。
  unlock_title = { en = "Unlock Requirements", jp = "解放条件" },
  unlock_chars = { en = "Typed Characters", jp = "入力文字数" },
  unlock_saves = { en = "File Saves", jp = "保存回数" },
  unlock_time = { en = "Active Time", jp = "稼働時間" },
  unlock_filetype = { en = "Typed (%s)", jp = "%s の入力文字数" },
  unlock_unknown = { en = "Unknown Requirement", jp = "不明な条件" },
  unlock_none = { en = "No unlock requirements registered.", jp = "解放条件が未登録です。" },
  status_on = { en = "On", jp = "有効" },
  status_off = { en = "Off", jp = "無効" },
  label_stage = { en = "Stage:", jp = "ステージ:" },
  label_distance = { en = "Distance:", jp = "距離:" },
  -- 階層表示のラベルを追加する。
  label_floor = { en = "Current Floor:", jp = "現在の階層:" },
  label_floor_step = { en = "Floor Step:", jp = "階層内の進行:" },
  label_level = { en = "Level:", jp = "レベル:" },
  -- ジョブ表示とスキル表示の追加文言をまとめる。
  label_job = { en = "Job:", jp = "ジョブ:" },
  label_job_level = { en = "Job Level:", jp = "ジョブLv:" },
  label_job_exp = { en = "Job Exp:", jp = "ジョブ経験:" },
  label_job_growth = { en = "Growth:", jp = "成長:" },
  label_job_skills = { en = "Skills:", jp = "習得スキル:" },
  skill_kind_active = { en = "Active", jp = "アクティブ" },
  skill_kind_passive = { en = "Passive", jp = "パッシブ" },
  label_skill_rate = { en = "Rate:", jp = "発動率:" },
  label_skill_power = { en = "Power:", jp = "威力:" },
  label_skill_accuracy = { en = "Accuracy:", jp = "命中補正:" },
  label_skill_bonus = { en = "Bonus:", jp = "補正:" },
  label_hp = { en = "HP:", jp = "体力:" },
  label_gold = { en = "Gold:", jp = "所持金:" },
  label_mode = { en = "Mode:", jp = "状態:" },
  label_progress = { en = "Stage Progress:", jp = "ステージ進行:" },
  label_exp = { en = "Exp:", jp = "経験値:" },
  label_atk = { en = "ATK:", jp = "攻撃力:" },
  label_def = { en = "DEF:", jp = "防御力:" },
  label_render = { en = "Render:", jp = "表示:" },
  label_auto_start = { en = "Auto Start:", jp = "自動開始:" },
  label_chars = { en = "Typed:", jp = "入力文字数:" },
  label_saves = { en = "Saves:", jp = "保存回数:" },
  label_time = { en = "Active Time:", jp = "稼働時間:" },
  label_filetypes = { en = "Filetypes:", jp = "入力内訳:" },
  metrics_detail_title = { en = "Input Metrics", jp = "入力統計" },
  metrics_detail_empty = { en = "No filetype data yet.", jp = "ファイル種別の入力はまだありません。" },
  notify_read_only = { en = "Idle Dungeon is running in another Neovim. Read-only mode is active.", jp = "Idle Dungeonは他のNeovimで稼働中のため閲覧専用です。" },
  language_en = { en = "English", jp = "English" },
  language_ja = { en = "日本語", jp = "日本語" },
}

local function normalize_lang(lang)
  if lang == "jp" then
    return "jp"
  end
  if lang == "ja" then
    return "ja"
  end
  return "en"
end

local function t(key, lang)
  local resolved = normalize_lang(lang)
  local entry = translations[key]
  if type(entry) ~= "table" then
    return entry or key
  end
  return entry[resolved] or entry.jp or entry.en or key
end

local function language_label(lang, current_lang)
  local resolved = normalize_lang(lang)
  local label_key = (resolved == "ja" or resolved == "jp") and "language_ja" or "language_en"
  local label = t(label_key, current_lang)
  return string.format("%s (%s)", label, resolved)
end

M.t = t
M.language_label = language_label

return M
