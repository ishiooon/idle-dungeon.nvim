-- このモジュールはステージ開始時の簡単な物語文を定義する。

local M = {}

M.intros = {
  {
    id = "stage_intro_1",
    stage_id = 1,
    title = { en = "Glacier Command", ja = "初手の氷回廊" },
    message = {
      en = "The ice answers every step with a clean chime. Tuxes glide ahead, and a green mantis trims the path like a rite.",
      ja = "氷が一歩ごとに澄んだ音を返す。タックスが滑り、緑のマンティスが道を儀式のように刈り取る。",
    },
  },
  {
    id = "stage_intro_2",
    stage_id = 2,
    title = { en = "Whale Dock", ja = "温路の鯨湾" },
    message = {
      en = "A harbor of warm circuits opens. Whales ferry silent cargo while hounds and gophers keep the corridor awake.",
      ja = "温かな回路の港が開く。ホエールが静かな荷を運び、ハウンドとゴーファーが通路を目覚めさせる。",
    },
  },
  {
    id = "stage_intro_3",
    stage_id = 3,
    title = { en = "Dataflow Dam", ja = "流路のビーバー堤" },
    message = {
      en = "Beavers carve a living channel, dolphins leap with polished light, and a scarlet shell watches in silence.",
      ja = "ビーバーが生きた流路を刻み、ドルフィンが磨いた光を跳ね、紅い殻が沈黙のまま見守る。",
    },
  },
  {
    id = "stage_intro_4",
    stage_id = 4,
    title = { en = "Script Coil", ja = "スクリプトの蛇環" },
    message = {
      en = "A serpent winds around the lamps. Swift hunters dash between shadows, and every loop tightens.",
      ja = "蛇が灯りに絡みつく。俊敏な狩人たちが影を駆け、輪は少しずつ締まる。",
    },
  },
  {
    id = "stage_intro_5",
    stage_id = 5,
    title = { en = "Rust Oath Forge", ja = "錆誓の鍛冶炉" },
    message = {
      en = "Iron claws spark and old oaths echo. Even the stone carries heat here.",
      ja = "鉄の鋏が火花を散らし、古い誓いが反響する。ここでは石さえ熱を帯びる。",
    },
  },
  {
    id = "stage_intro_6",
    stage_id = 6,
    title = { en = "Twin Compiler Citadel", ja = "双コンパイラの城砦" },
    message = {
      en = "Twin sentinels guard the gate while colossi loom behind them. Commands are short and sharp.",
      ja = "双つのセンチネルが門を守り、背後に巨像が立つ。命令は短く鋭い。",
    },
  },
  {
    id = "stage_intro_7",
    stage_id = 7,
    title = { en = "Ancestral Stampede", ja = "祖霊の踏圧" },
    message = {
      en = "Ancient hooves shake the ground. The air fills with a creed older than the walls.",
      ja = "祖霊の蹄が地を揺らす。壁より古い信条が空気を満たす。",
    },
  },
  {
    id = "stage_intro_8",
    stage_id = 8,
    title = { en = "Null Horizon", ja = "終端ヌルホライゾン" },
    message = {
      en = "An endless corridor opens. Light and shadow blur, and the horizon keeps calling rightward.",
      ja = "果てのない回廊が開き、光と影が滲む。地平は右へ進めと呼び続ける。",
    },
  },
}

return M
