-- このモジュールはステージ開始時の簡単な物語文と演出用アートを定義する。

local M = {}

M.intros = {
  {
    id = "stage_intro_1",
    stage_id = 1,
    title = { en = "Glacier Command", ja = "初手の氷回廊" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|              GLACIER COMMAND           |",
        "|   *  *  *  CRYSTAL ICE AWAKENS  *  *   |",
        "|        /\\    /\\    /\\    /\\            |",
        "|       /  \\__/  \\__/  \\__/  \\           |",
        "|       Frost chimes answer each step.    |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|               初手の氷回廊              |",
        "|   *  *  *  霜の鈴が足音に応える  *  *   |",
        "|        /\\    /\\    /\\    /\\            |",
        "|       /  \\__/  \\__/  \\__/  \\           |",
        "|          氷の回廊が静かに目覚める        |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "The ice answers every step with a clean chime. Tuxes glide ahead, and a green mantis trims the path like a rite.",
      ja = "氷が一歩ごとに澄んだ音を返す。タックスが滑り、緑のマンティスが道を儀式のように刈り取る。",
    },
  },
  {
    id = "stage_intro_2",
    stage_id = 2,
    title = { en = "Whale Dock", ja = "温路の鯨湾" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|                WHALE DOCK              |",
        "|     ~  ~  ~  WARM CIRCUIT HARBOR  ~    |",
        "|        __      __      __             |",
        "|    ___/  \\____/  \\____/  \\___         |",
        "|     The tide carries silent cargo.     |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|                温路の鯨湾               |",
        "|     ~  ~  ~  温かな回路の港  ~  ~      |",
        "|        __      __      __             |",
        "|    ___/  \\____/  \\____/  \\___         |",
        "|        潮が静かな荷を運んでいく          |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "A harbor of warm circuits opens. Whales ferry silent cargo while hounds and gophers keep the corridor awake.",
      ja = "温かな回路の港が開く。ホエールが静かな荷を運び、ハウンドとゴーファーが通路を目覚めさせる。",
    },
  },
  {
    id = "stage_intro_3",
    stage_id = 3,
    title = { en = "Dataflow Dam", ja = "流路のビーバー堤" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|               DATAFLOW DAM             |",
        "|      ||||||  CHANNELS CARVED ALIVE     |",
        "|   ====    ====    ====    ====         |",
        "|     ||      ||      ||      ||         |",
        "|     The stream obeys steady craft.      |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|              流路のビーバー堤            |",
        "|      ||||||  生きた流路が刻まれる       |",
        "|   ====    ====    ====    ====         |",
        "|     ||      ||      ||      ||         |",
        "|         流れは堤の意志に従う             |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "Beavers carve a living channel, dolphins leap with polished light, and a scarlet shell watches in silence.",
      ja = "ビーバーが生きた流路を刻み、ドルフィンが磨いた光を跳ね、紅い殻が沈黙のまま見守る。",
    },
  },
  {
    id = "stage_intro_4",
    stage_id = 4,
    title = { en = "Script Coil", ja = "スクリプトの蛇環" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|               SCRIPT COIL              |",
        "|     ~>~>~>  LAMPS WRAPPED IN LOOPS      |",
        "|       ()--()--()--()--()               |",
        "|        \\__/\\__/\\__/\\__/                |",
        "|       The corridor tightens its ring.   |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|              スクリプトの蛇環           |",
        "|     ~>~>~>  灯りに絡む蛇の輪           |",
        "|       ()--()--()--()--()               |",
        "|        \\__/\\__/\\__/\\__/                |",
        "|        通路は環を静かに締めていく        |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "A serpent winds around the lamps. Swift hunters dash between shadows, and every loop tightens.",
      ja = "蛇が灯りに絡みつく。俊敏な狩人たちが影を駆け、輪は少しずつ締まる。",
    },
  },
  {
    id = "stage_intro_5",
    stage_id = 5,
    title = { en = "Rust Oath Forge", ja = "錆誓の鍛冶炉" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|             RUST OATH FORGE            |",
        "|    >>>  HEAT AND OATHS IN THE ANVIL  >>>|",
        "|       []==[]==[]==[]==[]               |",
        "|        /\\  /\\  /\\  /\\                  |",
        "|       Sparks write the old vow.         |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|               錆誓の鍛冶炉              |",
        "|    >>>  炉の熱と誓いが交差する  >>>     |",
        "|       []==[]==[]==[]==[]               |",
        "|        /\\  /\\  /\\  /\\                  |",
        "|         火花が古い誓いを刻む             |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "Iron claws spark and old oaths echo. Even the stone carries heat here.",
      ja = "鉄の鋏が火花を散らし、古い誓いが反響する。ここでは石さえ熱を帯びる。",
    },
  },
  {
    id = "stage_intro_6",
    stage_id = 6,
    title = { en = "Twin Compiler Citadel", ja = "双コンパイラの城砦" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|         TWIN COMPILER CITADEL          |",
        "|      ||      GATES OF PARALLEL IRON    |",
        "|     ||||     ||||     ||||             |",
        "|     ||||     ||||     ||||             |",
        "|        Commands sharpen at the gate.    |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|          双コンパイラの城砦             |",
        "|      ||      並列の鉄門がそびえる       |",
        "|     ||||     ||||     ||||             |",
        "|     ||||     ||||     ||||             |",
        "|          命令は門で鋭さを増す            |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "Twin sentinels guard the gate while colossi loom behind them. Commands are short and sharp.",
      ja = "双つのセンチネルが門を守り、背後に巨像が立つ。命令は短く鋭い。",
    },
  },
  {
    id = "stage_intro_7",
    stage_id = 7,
    title = { en = "Ancestral Stampede", ja = "祖霊の踏圧" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|           ANCESTRAL STAMPEDE           |",
        "|     ////  HOOFBEATS SHAKE THE STONE    |",
        "|     v  v    v  v    v  v    v  v       |",
        "|      \\_/     \\_/     \\_/     \\_/       |",
        "|        The ground remembers the creed. |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|               祖霊の踏圧               |",
        "|     ////  蹄音が石を揺らす             |",
        "|     v  v    v  v    v  v    v  v       |",
        "|      \\_/     \\_/     \\_/     \\_/       |",
        "|         大地が古い信条を覚えている      |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "Ancient hooves shake the ground. The air fills with a creed older than the walls.",
      ja = "祖霊の蹄が地を揺らす。壁より古い信条が空気を満たす。",
    },
  },
  {
    id = "stage_intro_8",
    stage_id = 8,
    title = { en = "Null Horizon", ja = "終端ヌルホライゾン" },
    art = {
      en = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|              NULL HORIZON              |",
        "|      ....  THE CORRIDOR WITHOUT END    |",
        "|      |  |  |  |  |  |  |  |  |  |       |",
        "|      |  |  |  |  |  |  |  |  |  |       |",
        "|        The horizon keeps calling right. |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
      ja = {
        ".-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.",
        "|             終端ヌルホライゾン          |",
        "|      ....  果てのない回廊             |",
        "|      |  |  |  |  |  |  |  |  |  |       |",
        "|      |  |  |  |  |  |  |  |  |  |       |",
        "|            地平は右へと呼び続ける       |",
        "'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'",
      },
    },
    message = {
      en = "An endless corridor opens. Light and shadow blur, and the horizon keeps calling rightward.",
      ja = "果てのない回廊が開き、光と影が滲む。地平は右へ進めと呼び続ける。",
    },
  },
}

return M
