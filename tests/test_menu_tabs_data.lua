-- このテストはメニュー表示のデータ生成が期待通りであることを確認する。
-- 状態タブは折りたたみを使わず、主要情報を常時表示する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local function assert_match(text, pattern, message)
  if not text:match(pattern) then
    error((message or "assert_match failed") .. ": " .. tostring(text) .. " !~ " .. pattern)
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local menu_data = require("idle_dungeon.menu.tabs_data")
local state_module = require("idle_dungeon.core.state")
local util = require("idle_dungeon.util")
local dex = require("idle_dungeon.game.dex")

local config = {
  stage_name = "dungeon1-1",
  stages = {
    { id = 1, name = "dungeon1-1", start = 0, length = 10 },
  },
  ui = { language = "en" },
}

local state = state_module.new_state(config)
state = util.merge_tables(state, {
  metrics = {
    chars = 120,
    saves = 2,
    time_sec = 60,
    filetypes = { lua = 100, python = 20 },
  },
})

local status_items = menu_data.build_status_items(state, config, "en")
assert_true(#status_items > 0, "状態タブの項目が生成される")

local found_status_action_equip = false
local found_status_action_stage = false
local found_status_action_purchase = false
local found_status_action_sell = false
local found_status_action_skills = false
local found_status_action_job = false
local found_status_action_stage_keep_open = false
local found_status_action_purchase_keep_open = false
local found_status_action_sell_keep_open = false
local found_status_action_job_keep_open = false
local found_status_action_equip_keep_open = false
local found_status_action_skills_keep_open = false
local found_status_next_reward = false
local found_status_stage_name_redundant = false
local found_status_equipment_row = false
local found_status_skill_row = false
local found_status_step_count_label = false
local found_status_next_enemy_line = false
local found_status_danger_reason_detail = false
local found_status_control = false
local found_metrics_detail_flag = false
local found_metrics_detail_id = false
local found_section_situation = false
local found_section_power = false
local found_section_loadout = false
local found_section_progress = false
local found_section_metrics = false

local function is_equipment_detail_row(label)
  local text = tostring(label or "")
  local has_slot = text:match("Weapon") or text:match("Armor") or text:match("Accessory")
  local has_split = text:match("|")
  return has_slot and has_split
end

local function is_skill_detail_row(label)
  local text = tostring(label or "")
  if text:match("Passive") then
    return true
  end
  if text:match("Skill%s") and not text:match("Setup") then
    return true
  end
  return false
end

for _, item in ipairs(status_items) do
  local label = tostring(item.label or "")
  if item.id == "header" and label:match("Situation") then
    found_section_situation = true
  end
  if item.id == "header" and label:match("Power") then
    found_section_power = true
  end
  if item.id == "header" and label:match("Loadout & Skills") then
    found_section_loadout = true
  end
  if item.id == "header" and label:match("Progress") then
    found_section_progress = true
  end
  if item.id == "header" and label:match("Input Metrics") then
    found_section_metrics = true
  end

  if label:match("%d+ step%(s%) to enemy") or label:match("Move %d+ step%(s%)") then
    found_status_step_count_label = true
  end

  local detail_joined = table.concat(item.detail_lines or {}, "\n")
  if detail_joined:match("Next Enemy:") or detail_joined:match("次の敵:") then
    found_status_next_enemy_line = true
  end
  if detail_joined:match("Threat Scan:") then
    found_status_danger_reason_detail = true
  end

  if item.action_id == "equip" then
    found_status_action_equip = true
    if item.keep_open == true then
      found_status_action_equip_keep_open = true
    end
  end
  if item.action_id == "stage" then
    found_status_action_stage = true
    if item.keep_open == true then
      found_status_action_stage_keep_open = true
    end
    if label:match("dungeon1%-1") then
      found_status_stage_name_redundant = true
    end
  end
  if item.action_id == "purchase" then
    found_status_action_purchase = true
    if item.keep_open == true then
      found_status_action_purchase_keep_open = true
    end
  end
  if item.action_id == "sell" then
    found_status_action_sell = true
    if item.keep_open == true then
      found_status_action_sell_keep_open = true
    end
  end
  if item.action_id == "skills" then
    found_status_action_skills = true
    if item.keep_open == true then
      found_status_action_skills_keep_open = true
    end
  end
  if item.action_id == "job" then
    found_status_action_job = true
    if item.keep_open == true then
      found_status_action_job_keep_open = true
    end
  end

  if label:match("Next Reward") then
    found_status_next_reward = true
  end
  if item.id == "status_control" then
    found_status_control = true
  end
  if item.id == "metrics_detail" then
    found_metrics_detail_id = true
  end
  if item.open_detail_on_enter == true and item.keep_open == true then
    found_metrics_detail_flag = true
  end
  if is_equipment_detail_row(label) then
    found_status_equipment_row = true
  end
  if is_skill_detail_row(label) then
    found_status_skill_row = true
  end
end

assert_true(found_status_action_equip, "状態タブから装備変更へ遷移する項目が含まれる")
assert_true(found_status_action_stage, "状態タブから開始ステージ変更へ遷移する項目が含まれる")
assert_true(found_status_action_purchase, "状態タブから購入へ遷移する項目が含まれる")
assert_true(found_status_action_sell, "状態タブから売却へ遷移する項目が含まれる")
assert_true(found_status_action_skills, "状態タブからスキル設定へ遷移する項目が含まれる")
assert_true(found_status_action_job, "状態タブからジョブ変更へ遷移する項目が含まれる")
assert_true(found_status_action_stage_keep_open, "状態タブのステージ遷移はメインメニューを維持する")
assert_true(found_status_action_purchase_keep_open, "状態タブの購入遷移はメインメニューを維持する")
assert_true(found_status_action_sell_keep_open, "状態タブの売却遷移はメインメニューを維持する")
assert_true(found_status_action_job_keep_open, "状態タブのジョブ遷移はメインメニューを維持する")
assert_true(found_status_action_equip_keep_open, "状態タブの装備遷移はメインメニューを維持する")
assert_true(found_status_action_skills_keep_open, "状態タブのスキル遷移はメインメニューを維持する")
assert_true(found_status_next_reward, "状態タブに次の報酬行が含まれる")
assert_true(not found_status_stage_name_redundant, "状態タブでステージ名を重複表示しない")
assert_true(not found_status_step_count_label, "状態タブで敵まで残り歩数を表示しない")
assert_true(not found_status_next_enemy_line, "状態タブの詳細に次の敵の行を表示しない")
assert_true(found_status_danger_reason_detail, "状態タブの詳細に危険度判断の理由を表示する")
assert_true(not found_status_control, "状態タブに折りたたみトグルを表示しない")
assert_true(found_status_equipment_row, "状態タブに装備情報の行を常時表示する")
assert_true(found_status_skill_row, "状態タブにジョブスキル情報の行を常時表示する")
assert_true(found_metrics_detail_flag, "状態タブに入力統計の詳細導線が含まれる")
assert_true(not found_metrics_detail_id, "状態タブに重複した入力統計行を含めない")
assert_true(found_section_situation, "状態タブに状況セクションが含まれる")
assert_true(found_section_power, "状態タブに強さセクションが含まれる")
assert_true(found_section_loadout, "状態タブに装備と技能セクションが含まれる")
assert_true(found_section_progress, "状態タブに進行セクションが含まれる")
assert_true(found_section_metrics, "状態タブに入力統計セクションが含まれる")

-- 進行後半の敵能力は戦闘生成式で大きく伸びるため、基礎値だけで危険度を判定しないことを確認する。
local scaled_enemy_state = util.merge_tables(state, {
  actor = util.merge_tables(state.actor or {}, {
    hp = 30,
    max_hp = 30,
    atk = 5,
    def = 2,
    speed = 2,
  }),
  progress = util.merge_tables(state.progress or {}, {
    distance = 95,
    stage_start = 0,
    stage_id = 1,
    floor_enemies = {
      { id = "dust_slime", element = "normal", position = 10, defeated = false },
    },
  }),
})
local scaled_enemy_items = menu_data.build_status_items(scaled_enemy_state, config, "en")
local found_scaled_enemy_high_risk = false
local found_scaled_enemy_timing_reason = false
for _, item in ipairs(scaled_enemy_items) do
  local detail_joined = table.concat(item.detail_lines or {}, "\n")
  if detail_joined:match("Risk:%s*High") then
    found_scaled_enemy_high_risk = true
  end
  if detail_joined:match("Enemy can defeat you in about") and detail_joined:match("before your estimated win time") then
    found_scaled_enemy_timing_reason = true
  end
end
assert_true(found_scaled_enemy_high_risk, "進行後半では基礎値ではなく成長後の敵能力で危険度を判定する")
assert_true(found_scaled_enemy_timing_reason, "危険度理由に撃破見込み時間の比較を表示する")

local status_items_ja = menu_data.build_status_items(state, config, "ja")
local status_ja_joined = {}
local found_status_danger_reason_detail_ja = false
local found_status_next_equipment_unlock_ja = false
for _, item in ipairs(status_items_ja) do
  if item and item.label then
    table.insert(status_ja_joined, item.label)
    -- 次の解放の対象が装備であることを日本語表示で明示する。
    if tostring(item.label):match("次の装備解放") then
      found_status_next_equipment_unlock_ja = true
    end
  end
  local detail_joined = table.concat(item.detail_lines or {}, "\n")
  if detail_joined:match("脅威診断:") then
    found_status_danger_reason_detail_ja = true
  end
end
local status_ja_text = table.concat(status_ja_joined, "\n")
assert_true(not status_ja_text:match("Risk"), "日本語表示にRiskが混在しない")
assert_true(not status_ja_text:match("Breakthrough"), "日本語表示にBreakthroughが混在しない")
assert_true(not status_ja_text:match("Stability"), "日本語表示にStabilityが混在しない")
assert_true(not status_ja_text:match("Weapon/Armor/Accessory"), "日本語表示に英語の装備カテゴリを混在させない")
assert_true(not status_ja_text:match("敵まで%d+歩"), "日本語表示で敵まで残り歩数を表示しない")
assert_true(not status_ja_text:match("接近中"), "日本語表示で接敵文言を表示しない")
assert_true(found_status_danger_reason_detail_ja, "日本語表示の詳細に危険度判断の理由を表示する")
assert_true(found_status_next_equipment_unlock_ja, "日本語表示で次の装備解放の文言を明示する")

local action_items = menu_data.build_action_items()
assert_true(#action_items >= 5, "操作タブの項目が生成される")
assert_match(action_items[1].id or "", "equip", "操作項目に装備変更が含まれる")

local config_items = menu_data.build_config_items()
assert_true(#config_items >= 3, "設定タブの項目が生成される")
assert_match(config_items[1].id or "", "toggle_text", "設定項目にモード切り替えが含まれる")
local found_language = false
local found_display_lines = false
local found_battle_hp = false
local found_game_speed = false
local found_reload_plugin = false
for _, item in ipairs(config_items) do
  if item.id == "language" then
    found_language = true
    assert_true(item.keep_open == true, "言語設定はメニューを閉じずに開ける")
  end
  if item.id == "display_lines" then
    found_display_lines = true
    assert_true(item.keep_open == true, "表示行数の設定はメニューを閉じずに開ける")
  end
  if item.id == "game_speed" then
    found_game_speed = true
    assert_true(item.keep_open == true, "ゲーム速度の設定はメニューを閉じずに開ける")
  end
  if item.id == "reload_plugin" then
    found_reload_plugin = true
    assert_true(item.keep_open == true, "再読み込みはメニューを閉じずに実行できる")
  end
  -- 戦闘時のHP分母表示を切り替える項目が含まれることを確認する。
  if item.id == "battle_hp_show_max" then
    found_battle_hp = true
    assert_true(item.keep_open == true, "戦闘HP表示の設定はメニューを閉じずに開ける")
  end
end
assert_true(found_language, "言語設定の項目が含まれる")
assert_true(found_display_lines, "表示行数の項目が含まれる")
assert_true(found_game_speed, "ゲーム速度の項目が含まれる")
assert_true(found_battle_hp, "戦闘HP表示の項目が含まれる")
assert_true(found_reload_plugin, "再読み込みの項目が含まれる")
assert_true((config_items[#config_items] or {}).id == "reload_plugin", "再読み込みの項目は設定メニューの最下段にある")

local credits_items = menu_data.build_credits_items("en")
assert_true(#credits_items > 0, "クレジットタブの項目が生成される")
-- クレジットの表記は IdleDungeon に統一する。
assert_match(credits_items[1].label or "", "IdleDungeon", "クレジットのアスキーアートが含まれる")
local found_creator = false
for _, item in ipairs(credits_items) do
  if tostring(item.label or ""):match("ishiooon") then
    found_creator = true
    break
  end
end
assert_true(found_creator, "クレジットに作成者ishiooonの表記が含まれる")

-- 図鑑のアイコン色付けはアイコン部分だけに適用するため情報を保持する。
local dex_state = util.merge_tables(state, {
  dex = dex.record_enemy(dex.new_dex(), "dust_slime", "normal", 10),
})
local dex_items = menu_data.build_dex_items(dex_state, config, "en", {
  show_controls = true,
})
local highlighted = nil
local found_dex_summary = false
local found_dex_toggle = false
local found_dex_hint = false
local found_mastery_badge = false
local found_mastery_legend = false
local found_sort_control = false
local found_element_control = false
local found_keyword_control = false
local found_danger_detail = false
local found_drop_band_detail = false
for _, item in ipairs(dex_items) do
  if item.id == "header" and (item.label or ""):match("Enemies") and (item.label or ""):match("Items") and (item.label or ""):match("%[") then
    found_dex_summary = true
  end
  if item.id == "header" and (item.label or ""):match("NEW=") then
    found_mastery_legend = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Expand") then
    found_dex_toggle = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Sort:") then
    found_sort_control = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Element:") then
    found_element_control = true
  end
  if item.id == "dex_control" and (item.label or ""):match("Search:") then
    found_keyword_control = true
  end
  if item.id == "header" and (item.label or ""):match("Enter:") then
    found_dex_hint = true
  end
  if item.id == "dex_entry" and item.highlight_key then
    highlighted = item
    if (item.label or ""):match("NEW") or (item.label or ""):match("★") then
      found_mastery_badge = true
    end
    local detail_joined = table.concat(item.detail_lines or {}, " ")
    if detail_joined:match("Danger:") then
      found_danger_detail = true
    end
    if detail_joined:match("Drop Band:") then
      found_drop_band_detail = true
    end
  end
end
assert_true(found_dex_summary, "図鑑の概要行に進捗メーターが含まれる")
assert_true(found_mastery_legend, "図鑑の達成バッジ説明が含まれる")
assert_true(found_dex_toggle, "図鑑の展開トグルが含まれる")
assert_true(found_sort_control, "図鑑の並び替えトグルが含まれる")
assert_true(found_element_control, "図鑑の属性フィルタが含まれる")
assert_true(found_keyword_control, "図鑑の検索フィルタが含まれる")
assert_true(found_dex_hint, "図鑑の操作ヒント行が含まれる")
assert_true(highlighted ~= nil, "図鑑の敵エントリが見つかる")
assert_true(found_mastery_badge, "図鑑のエントリに達成バッジが表示される")
assert_true(found_danger_detail, "図鑑の敵詳細に危険度が表示される")
assert_true(found_drop_band_detail, "図鑑の敵詳細にドロップ帯が表示される")
assert_match(highlighted.highlight_icon or "", "%S", "図鑑の敵アイコンが保持される")

print("OK")
