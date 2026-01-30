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

return M
