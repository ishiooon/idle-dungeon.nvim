-- このモジュールはイベント定義を提供する。

local M = {}

M.events = {
  -- 敵コンテンツと文体の一貫性を保つため、短く芯のあるトーンで記述する。
  -- ステージ1の物語イベントを定義する。
  {
    id = "start",
    stage_id = 1,
    distance = 1,
    title = "スタートの灯り",
    message = { en = "A small lantern swings; the first lane stays calm.", ja = "小さなランタンが揺れ、最初のレーンは静かに始まる。" },
  },
  {
    id = "right_oath",
    stage_id = 1,
    distance = 10,
    title = "ライトラインの誓い",
    message = { en = "You set one rule: keep pushing to the right.", ja = "ルールはひとつ。右方向へテンポよく進み続ける。" },
  },
  {
    id = "wind_gate",
    stage_id = 1,
    distance = 25,
    title = "ウィンドゲート",
    message = { en = "A wind gate checks whether your pace is stable.", ja = "ウィンドゲートが、こちらの歩調が安定しているか試してくる。" },
  },
  {
    id = "rust_sign",
    stage_id = 1,
    distance = 40,
    title = "ラストサイン",
    message = { en = "A rusted sign hints that heavier enemies wait ahead.", ja = "錆びたサインが、前方に重い敵がいると告げている。" },
  },
  {
    id = "rest_pave",
    stage_id = 1,
    distance = 60,
    title = "ブレスポイント",
    message = { en = "Warm paving stones let your breathing return to rhythm.", ja = "温かい石畳で呼吸を整え、リズムを立て直せる。" },
  },
  {
    id = "quiet_market",
    stage_id = 1,
    distance = 80,
    title = "クワイエットマーケット",
    message = { en = "A quiet market opens, ready with practical gear.", ja = "静かなマーケットが開き、実用的な装備が並ぶ。" },
  },
  {
    id = "far_steps",
    stage_id = 1,
    distance = 120,
    title = "エコーステップ",
    message = { en = "Distant steps echo closer and tighten the air.", ja = "遠い足音が反響しながら近づき、空気が引き締まる。" },
  },
  {
    id = "shadow_path",
    stage_id = 1,
    distance = 160,
    title = "シャドウパス",
    message = { en = "Long shadows stretch across the lane and sharpen your focus.", ja = "長い影がレーンを覆い、集中が一段階シャープになる。" },
  },
  {
    id = "edge_tower",
    stage_id = 1,
    distance = 220,
    title = "エッジタワー",
    message = { en = "A tower on the edge marks the handoff to the next stage.", ja = "右端のタワーが、次のステージへの切り替え地点を示す。" },
  },
  {
    id = "start_again",
    stage_id = 1,
    distance = 240,
    title = "リスタートステップ",
    message = { en = "You reset your stance and step forward again.", ja = "姿勢を整え直し、もう一度前へ踏み出す。" },
  },
  -- ステージ2の物語イベントを定義する。
  {
    id = "blue_river",
    stage_id = 2,
    distance = 30,
    title = "ブルーリバー",
    message = { en = "A blue river hums along the route with cold pressure.", ja = "蒼い川がルートの脇で低く唸り、冷たい圧を放つ。" },
  },
  {
    id = "echo_bridge",
    stage_id = 2,
    distance = 70,
    title = "エコーブリッジ",
    message = { en = "On a long bridge, each footstep returns as a clear echo.", ja = "長い橋では一歩ごとに足音が返り、間合いが読みづらくなる。" },
  },
  {
    id = "silver_moss",
    stage_id = 2,
    distance = 130,
    title = "シルバーモス",
    message = { en = "Silver moss glows underfoot, lighting subtle movement lines.", ja = "銀色の苔が足元で光り、細い移動ラインを浮かび上がらせる。" },
  },
  {
    id = "mirror_gate",
    stage_id = 2,
    distance = 190,
    title = "ミラーゲート",
    message = { en = "A mirror gate returns your stance and asks if you can hold it.", ja = "ミラーゲートがこちらの構えを映し、その精度を問うてくる。" },
  },
  {
    id = "dusk_lantern",
    stage_id = 2,
    distance = 260,
    title = "ダスクランタン",
    message = { en = "A dusk lantern points onward to the deeper lanes.", ja = "夕暮れ色のランタンが、さらに深いレーンの先を照らしている。" },
  },
}

-- 隠しイベントの一覧を定義する。
-- 数フロアに一度だけ出現し、目視できない効果として扱う。
M.hidden_events = {
  {
    id = "hidden_oasis",
    title = { en = "Oasis Break", ja = "オアシスブレイク" },
    message = { en = "A hidden spring lets you recover cleanly before the next push.", ja = "隠れた泉で呼吸を整え、次の押し込みへ向けて立て直せる。" },
    effect = { kind = "heal", amount = 4 },
    appear = { min = 1, max = 4 },
    weight = 3,
  },
  {
    id = "hidden_clockwork_breeze",
    title = { en = "Clockwork Wind", ja = "クロックワークウィンド" },
    message = { en = "A rhythmic wind syncs with your step and boosts your tempo.", ja = "規則的な風が歩調と同期し、行動テンポを一段引き上げる。" },
    effect = { kind = "speed", tick_seconds = 0.1, duration_ticks = 6 },
    appear = { min = 1, max = 8 },
    weight = 2,
  },
  {
    id = "hidden_shadow_spike",
    title = { en = "Shadow Spike", ja = "シャドウスパイク" },
    message = { en = "A hidden spike catches you from a blind angle.", ja = "死角から伸びたスパイクがかすめ、体勢を崩してくる。" },
    effect = { kind = "damage", amount = 3 },
    appear = { min = 2, max = 8 },
    weight = 3,
  },
  {
    id = "hidden_lost_satchel",
    title = { en = "Lost Satchel", ja = "ロストサッチェル" },
    message = { en = "You recover a travel satchel and pull useful gear from inside.", ja = "旅用のサッチェルを見つけ、中から実用的な装備を取り出す。" },
    effect = { kind = "item", item_id = "swift_ring" },
    appear = { min = 1, max = 6 },
    weight = 2,
  },
  {
    id = "hidden_silver_cache",
    title = { en = "Silver Cache", ja = "シルバーキャッシュ" },
    message = { en = "A silver cache opens with a soft click and rewards careful eyes.", ja = "銀のキャッシュが小さく鳴って開き、観察力に応えてくれる。" },
    effect = { kind = "item", item_id = "record_ring" },
    appear = { min = 2, max = 8 },
    weight = 2,
  },
  {
    id = "hidden_pet_crossing",
    title = { en = "Curious Companion", ja = "キュリアスコンパニオン" },
    message = { en = "A curious little companion syncs with your route and follows along.", ja = "好奇心の強い小さな相棒が、こちらのルートに合わせてついてくる。" },
    effect = { kind = "pet", item_id = "dust_slime" },
    appear = { min = 3, max = 8 },
    weight = 1,
  },
  {
    id = "hidden_whisper_note",
    title = { en = "Whisper Note", ja = "ウィスパーノート" },
    message = {
      en = "A folded note reads: keep your cadence stable and the route will open.",
      ja = "折りたたまれたメモに「ケイデンスを保てばルートは開く」と記されていた。",
    },
    effect = { kind = "flavor" },
    appear = { min = 1, max = 8 },
    weight = 4,
  },
  -- 選択式の宝箱イベントを追加する。
  {
    id = "hidden_sealed_chest",
    title = { en = "Sealed Chest", ja = "シールドチェスト" },
    message = { en = "A sealed chest blocks the lane. Do you open it?", ja = "封印されたチェストが道をふさぐ。開けるかどうか選ぶ？" },
    choice_seconds = 10,
    choices = {
      {
        id = "open",
        label = { en = "Open", ja = "開ける" },
        results = {
          {
            id = "chest_good",
            weight = 3,
            message = { en = "A warm glow restores you, and a useful trinket drops into your hand.", ja = "温かな光で体勢が戻り、実用的なトリンケットが手に収まる。" },
            effects = {
              { kind = "heal", amount = 4 },
              { kind = "item", item_id = "record_ring" },
            },
          },
          {
            id = "chest_bad",
            weight = 2,
            message = { en = "A trap snaps and metal fangs strike from inside the lid.", ja = "トラップが作動し、ふたの内側からメタルの牙が跳ね上がる。" },
            effect = { kind = "damage", amount = 4 },
          },
          {
            id = "chest_neutral",
            weight = 2,
            message = { en = "Only dust and stale air spill out. The chest is empty.", ja = "埃と古い空気だけが流れ出る。チェストの中身は空だった。" },
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
            message = { en = "You pass the chest and keep your route stable.", ja = "チェストには触れず、ルートの安定を優先して通り過ぎる。" },
          },
        },
      },
    },
    appear = { min = 2, max = 8 },
    weight = 2,
  },
}

return M
