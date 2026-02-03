-- このモジュールはイベント定義を提供する。

local M = {}

M.events = {
  -- ステージ1の物語イベントを定義する。
  {
    id = "start",
    stage_id = 1,
    distance = 1,
    title = "旅立ちの挨拶",
    message = { en = "A lantern flickers; the path is quiet.", ja = "ランプが揺れて、道は静かだ。" },
  },
  {
    id = "right_oath",
    stage_id = 1,
    distance = 10,
    title = "右へ進む誓い",
    message = { en = "You promise to keep moving right.", ja = "右へ進み続けると誓う。" },
  },
  {
    id = "wind_gate",
    stage_id = 1,
    distance = 25,
    title = "風の門",
    message = { en = "A wind gate tests your steps.", ja = "風の門が歩調を試す。" },
  },
  {
    id = "rust_sign",
    stage_id = 1,
    distance = 40,
    title = "錆びた看板",
    message = { en = "A rusty sign warns of stronger foes.", ja = "錆びた看板が強敵を告げる。" },
  },
  {
    id = "rest_pave",
    stage_id = 1,
    distance = 60,
    title = "ひと休みの石畳",
    message = { en = "Warm stones let you catch your breath.", ja = "温かな石畳で息を整える。" },
  },
  {
    id = "quiet_market",
    stage_id = 1,
    distance = 80,
    title = "静かな市場",
    message = { en = "A quiet market opens its stalls.", ja = "静かな市場が扉を開く。" },
  },
  {
    id = "far_steps",
    stage_id = 1,
    distance = 120,
    title = "遠い足音",
    message = { en = "Distant footsteps draw near.", ja = "遠い足音が近づく。" },
  },
  {
    id = "shadow_path",
    stage_id = 1,
    distance = 160,
    title = "影の通路",
    message = { en = "Shadows stretch; your focus sharpens.", ja = "影が伸び、集中が研ぎ澄まされる。" },
  },
  {
    id = "edge_tower",
    stage_id = 1,
    distance = 220,
    title = "右端の塔",
    message = { en = "A tower marks the next stage.", ja = "右端の塔が次の道を示す。" },
  },
  {
    id = "start_again",
    stage_id = 1,
    distance = 240,
    title = "再び歩き出す",
    message = { en = "You step forward once more.", ja = "再び歩き出す。" },
  },
  -- ステージ2の物語イベントを定義する。
  {
    id = "blue_river",
    stage_id = 2,
    distance = 30,
    title = "蒼い川",
    message = { en = "A blue river hums beside the trail.", ja = "蒼い川が道の脇で唸る。" },
  },
  {
    id = "echo_bridge",
    stage_id = 2,
    distance = 70,
    title = "反響の橋",
    message = { en = "Your steps echo across a long bridge.", ja = "長い橋に足音が反響する。" },
  },
  {
    id = "silver_moss",
    stage_id = 2,
    distance = 130,
    title = "銀の苔",
    message = { en = "Silver moss glows faintly underfoot.", ja = "銀の苔が淡く光る。" },
  },
  {
    id = "mirror_gate",
    stage_id = 2,
    distance = 190,
    title = "鏡の門",
    message = { en = "A mirror gate reflects your resolve.", ja = "鏡の門が決意を映す。" },
  },
  {
    id = "dusk_lantern",
    stage_id = 2,
    distance = 260,
    title = "夕暮れのランプ",
    message = { en = "A lantern in dusk points onward.", ja = "夕暮れのランプが先を照らす。" },
  },
}

-- 隠しイベントの一覧を定義する。
-- 数フロアに一度だけ出現し、目視できない効果として扱う。
M.hidden_events = {
  {
    id = "hidden_oasis",
    title = { en = "Oasis Sip", ja = "オアシスの一口" },
    message = { en = "You find a hidden spring and recover your breath.", ja = "隠れた泉で喉を潤し、息を整える。" },
    effect = { kind = "heal", amount = 4 },
    appear = { min = 1, max = 4 },
    weight = 3,
  },
  {
    id = "hidden_clockwork_breeze",
    title = { en = "Clockwork Breeze", ja = "歯車の風" },
    message = { en = "A rhythmic wind pushes you forward.", ja = "規則的な風が背中を押す。" },
    effect = { kind = "speed", tick_seconds = 0.5, duration_ticks = 6 },
    appear = { min = 1, max = 8 },
    weight = 2,
  },
  {
    id = "hidden_shadow_spike",
    title = { en = "Shadow Spike", ja = "影の棘" },
    message = { en = "A hidden spike grazes you in the dark.", ja = "闇の棘がかすめ、痛みが走る。" },
    effect = { kind = "damage", amount = 3 },
    appear = { min = 2, max = 8 },
    weight = 3,
  },
  {
    id = "hidden_lost_satchel",
    title = { en = "Lost Satchel", ja = "忘れられた小袋" },
    message = { en = "You recover a traveler’s satchel with gear inside.", ja = "旅人の小袋を見つけ、装備が入っていた。" },
    effect = { kind = "item", item_id = "swift_ring" },
    appear = { min = 1, max = 6 },
    weight = 2,
  },
  {
    id = "hidden_silver_cache",
    title = { en = "Silver Cache", ja = "銀の隠し箱" },
    message = { en = "A silver cache opens with a soft click.", ja = "銀の隠し箱が静かに開く。" },
    effect = { kind = "item", item_id = "record_ring" },
    appear = { min = 2, max = 8 },
    weight = 2,
  },
  {
    id = "hidden_pet_crossing",
    title = { en = "Curious Companion", ja = "好奇心の相棒" },
    message = { en = "A small companion decides to follow you.", ja = "小さな相棒があなたについてくる。" },
    effect = { kind = "pet", item_id = "wind_bird" },
    appear = { min = 3, max = 8 },
    weight = 1,
  },
  {
    id = "hidden_whisper_note",
    title = { en = "Whisper Note", ja = "ささやきのメモ" },
    -- 目に見えないイベントでも状況が伝わる短文に整える。
    message = {
      en = "A folded note says: keep a steady cadence and the path will open.",
      ja = "折りたたまれたメモに「歩調を整えれば道はひらける」と書かれていた。",
    },
    effect = { kind = "flavor" },
    appear = { min = 1, max = 8 },
    weight = 4,
  },
  -- 選択式の宝箱イベントを追加する。
  {
    id = "hidden_sealed_chest",
    title = { en = "Sealed Chest", ja = "封印された宝箱" },
    message = { en = "A sealed chest waits. Open it?", ja = "封印された宝箱がある。開けますか？" },
    choice_seconds = 10,
    choices = {
      {
        id = "open",
        label = { en = "Open", ja = "開ける" },
        results = {
          {
            id = "chest_good",
            weight = 3,
            message = { en = "A warm glow restores you and a trinket slips into your hand.", ja = "温かな光が体を癒やし、装身具が手に滑り込む。" },
            effects = {
              { kind = "heal", amount = 4 },
              { kind = "item", item_id = "record_ring" },
            },
          },
          {
            id = "chest_bad",
            weight = 2,
            message = { en = "A trap snaps shut and the metal bites back.", ja = "罠が弾け、金属の牙が襲いかかる。" },
            effect = { kind = "damage", amount = 4 },
          },
          {
            id = "chest_neutral",
            weight = 2,
            message = { en = "Dust and old air spill out. Nothing else.", ja = "埃と古い空気が溢れ出す。中身は空だった。" },
          },
        },
      },
      {
        id = "leave",
        label = { en = "Leave", ja = "立ち去る" },
        results = {
          {
            id = "chest_leave",
            weight = 1,
            message = { en = "You leave the chest untouched and move on.", ja = "触れずに通り過ぎる。" },
          },
        },
      },
    },
    appear = { min = 2, max = 8 },
    weight = 2,
  },
}

return M
