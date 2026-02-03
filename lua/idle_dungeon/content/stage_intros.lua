-- このモジュールはステージ開始時の簡単な物語文と演出用アートを定義する。
-- messageの後に濃いストーリー文を保持して世界観の背景を補足する。

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
    -- storyは長文の世界観補足として、章の動機と余韻を描く。
    story = {
      en = "He wakes to a ceiling of frost and a plain of ice, the kind of white that erases distance and swallows sound. The corridor is already pulling him rightward, as if the world itself expects a journey. He is from a small ice village where children learn to count cracks and listen to the wind; when the sky went pale and the seas stilled, the elders said the cold was the only law left. The village was small and the lamps were few, so promises became the warmest thing they could keep, and every winter festival ended with a vow to meet again in spring. His mentor left to find a path that still held spring and never returned, leaving a tiny charm and a short line of words: keep walking until the answer speaks. Now he wakes here with that charm in his fist, unable to remember how he arrived. Penguins patrol the rim like old neighbors, and mantises shave the frost so the path remains thin but open, and the chime beneath his boots is beautiful and brittle at once. Each step carries a quiet threat of collapse, and the silence makes his loss sound louder than the wind. He does not yet know why the world froze, only that the ice is older than his memory and the corridor is older than his village. A secret from the old stories says the ice is not a punishment but a cover, a lid laid over something sleeping, and that the rightward road was made to keep a heartbeat awake. If that is true, then his grief is not only his own, and the answer he seeks might be the reason the world still moves at all. He takes the first step, young and stubborn, carrying hope and ache in the same small chest, and the ice answers with a sound like a bell. He recalls the day the sun dimmed and the river stopped; the elders said the sky split and cold poured through. Since then, spring has been only a word, and every child in the village grew up under a long winter. Nights grew quieter as lamps vanished and people left without returning. If the corridor is a heartbeat, then the ice might be a bandage, and he is walking along the seam that keeps it together. He fears that home may be unreachable now, yet he keeps the memory of his mother's hands and a friend's laugh to steady his steps, refusing to let the cold reach his heart.",
      ja = "目を開けると、白い天と地の境がぼやけ、息の白さだけが生きている証だった。氷は古く、世界は長い冬のまま止まっている。少年は氷の村の出で、子どもたちは氷の割れる音を数え、風の向きで明日を占った。空が裂け、海が止まり、冷気が降り続いた日から、春は物語の中の言葉になった。村は小さく灯りも少なく、だからこそ人の声と約束が一番温かかった。祭りでは互いの名を掌に書き、春にまた会うと誓ったが、約束は少しずつ欠けていった。師は春の名残を探すと言って旅立ち、戻らないまま護符と短い言葉だけを残した。気が付けば少年はその護符を握り、この氷の回廊で目覚めていた。どうしてここにいるのかは思い出せないが、足元の氷の下で細い光が脈のように走るのを見た。ペンギンが道の縁を巡回し、蟷螂が霜を払い、通路はかろうじて保たれている。澄んだ鈴のような音は美しいが、同時に崩れる前触れにも聞こえる。師がいないという事実は冷気より痛く、静けさがその痛みを増幅した。古い伝承には、氷は世界を閉じる蓋ではなく、眠りを守る覆いだとある。もし回廊が誰かの鼓動を支える道なら、歩みを止めることは眠りを止めることになる。少年はまだ幼さを残した胸で、その重さを受け取った。帰る場所があるかは分からないが、母の手の温かさと友の笑い声だけは失いたくない。だから彼は旅に出る。寒さに慣れても心まで凍らせないと誓い、右へ進むたびに小さな火を守るように息を吐く。右へ進むことは逃げではなく、眠る世界に火を渡す行為だと信じ始める。氷の音が鈴のように鳴るたび、師の声が遠くから返ってくる気がして、足が自然と前に出た。彼は村の記録帳に残った空白のページを思い出す。書くべき名前が書けなかった夜が続いた。だからこそ、今は自分の歩幅を記録の代わりにする。氷の下に眠る何かが目覚めるなら、その瞬間に自分の足音が届いてほしい。旅はここで始まり、彼の名前もまた、回廊の記憶の一つになろうとしていた。村の井戸の縁で聞いた笑い声を思い出し、胸が痛む。痛みは彼を少年に留めるが、同時に前へ押す。誰かのために歩く旅だと自分に言い聞かせ、右へ進む。旅の始まりは壮大ではない。小さな一歩と息づかいだけが真実だった。少年は氷に耳を澄ませ、足元の鈴の音を道しるべに変える。誰かの眠りを守るために歩くという意志が、彼の背中を少しだけ大人にした。師は春を取り戻すために回廊へ向かい、その理由を少年に託した。少年は師の足跡を追い、春を取り戻す旅へ踏み出す。",
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
    story = {
      en = "When the cold loosens, warm air finally breathes, and the boy feels his fingers again. Whale Dock is a harbor cut into the corridor, where slow giants ferry silent cargo and tunnel crews keep the lights awake. He shares a bowl of thin soup with a girl who laughs as if the ice never ruled, and for a moment he believes the journey could end here. But the harbor is built on borrowed heat, a pulse that fades if you linger, and the quiet faces around the lamps tell him that staying too long turns warmth into regret. Old boards on the dock carry names of those who stopped, and many names end with a line that says, we waited and the corridor moved on. He leaves a ribbon from his village on a post so that someone else can remember, and the rightward pull returns like a tide. The harbor teaches him a childlike lesson that hurts: comfort can be real and still not be the place you belong. He bows his head to the warm lights, promises to come back, and knows that his promise is really a way to say farewell. Behind the harbor a small market trades stories instead of goods. He is surprised that elders still remember the scent of spring, while he knows it only as a word. A child on the pier says tomorrow will come, and he realizes it is more prayer than certainty. He writes a short line in the dock ledger, asking anyone who meets his mentor to tell him he kept walking. Warmth is real and still temporary, so he chooses to carry it forward rather than cling to it. The smell of the sea stays with him as a quiet promise.",
      ja = "冷たさが緩み、温かな空気が息を吹き返したとき、少年の指先はようやく血を取り戻した。温路の鯨湾は回廊の途中に開いた港で、ゆったりとした鯨が静かな荷を運び、掘り手たちが灯りを守っている。薄いスープを分けてくれた少女は氷など最初から無かったように笑い、少年は一瞬だけ旅が終わる幻想を見る。だがこの港の温もりは借り火で、長く留まれば熱はすぐに消える。灯りの周りに座る人々の静かな顔が、それを言葉より強く教える。桟橋の板には残された名前が刻まれ、いくつもの名の横に待ったが回廊は進んだとだけ書かれている。港の裏手では小さな市場が開き、人々は手に入った物ではなく失った物の話をする。春を知らない自分より年上の人々が春の匂いを覚えていることに、少年は驚く。桟橋には帰りを待つ子どもがいて、その姿が氷より重く見えた。少年も待ちたいと思うが、回廊は立ち止まる者から時間を奪うと知っている。彼は港の帳面に短い言葉を残し、師に会った者がいたら歩き続けていると伝えてほしいと書く。温かさは現実で、それでも永遠ではない。だからこそ彼は温もりに甘えず、温もりを持ったまま進む。老夫婦が肩を寄せ合って波を見ている姿に、未来と別れが同時に映る。別れの痛みは消えないが、その痛みがあるから人を大切にできると知り、少年は海の匂いを胸に刻む。港の灯りが小さくなるにつれ、胸の奥で何かが静かに閉じるのを感じた。それでも閉じたものの中に温もりをしまい、旅の途中で誰かに渡せる日を願う。港で交わした小さな挨拶を思い出し、言葉が火種になると知る。彼は火種を抱えたまま、潮の匂いが消えるまで歩き続けた。港で見た笑顔は短くても確かで、その確かさが旅の灯になる。少年は別れを繰り返しながらも、別れの中に希望を残す方法を覚える。温もりを失わずに進むことが、ここでの冒険の条件だった。港で交わした視線の数だけ、彼の胸には小さな責任が増えた。責任は重いが、重いからこそ旅は意味を持つ。彼は温もりを守るために戦うのではなく、温もりを渡すために歩くと決める。あの港が彼の心の帰り道になると信じて。彼は港の灯りを背に、もう一度だけ小さく頭を下げた。港で見た灯りを忘れないと、彼は心の中で静かに誓った。港の温もりは春の兆しに見え、彼は春を取り戻す決意をさらに深くする。",
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
    story = {
      en = "At the dam, water is the only thing that truly moves, and it decides how the corridor breathes. Beavers stack the flow into precise channels, dolphins polish the current into mirrors, and a red shell keeps count of every overflow like a quiet judge. The boy remembers the thin streams he used to carve in the snow outside his village, rivers that vanished by morning, and he feels how different this living current is. A worker asks him to hold a gate for a breath, and his arms tremble under the pressure, yet he learns that steady hands can change a whole path. The mirror of the stream shows him a face that looks older than he expects, and for a heartbeat he thinks he sees his mentor standing just behind him. It is only his own reflection, sharpened by the water, but the thought stays. He learns that strength without control shatters the road, and that slowing down can be a kind of courage, a way to keep going without breaking. A keeper of the dam tells him that water never forgets the shapes it touched; it only chooses when to show them again. The boy thinks of the friend he left by the frozen well and wonders if his own footsteps will ever return as a ripple. He practices patience by matching his breath to the gates, learning that slowing down is sometimes the only way not to break. Time is a river too, and he cannot step into the same moment twice. The workers speak little, but their quiet pride seeps into him, and he begins to believe even his small steps can matter. The sky in the water is distorted, yet it is still the sky, and that thought comforts him.",
      ja = "この堤では水だけが本当に動いていて、その流れが通路の呼吸を決めている。ビーバーが流れを精密な水路に積み上げ、ドルフィンが水面を磨き、紅い殻が氾濫の数を数える。少年は村の外で雪を掘り、朝には消えてしまう小さな川を作った日々を思い出す。ここにある流れは生きていて、触れるだけで力と責任が伝わってくる。堤の係に一息だけ扉を支えてくれと頼まれ、腕が震えるほどの重みを受けながら、通路を変える感覚を知る。水面の鏡には自分の顔が映るが、その眼差しは想像より大人びていて、一瞬だけ師の背中が見えた気がした。もちろんそれは錯覚だが、錯覚ほど心に残るものもない。勢いだけでは道が砕けることを悟り、歩幅と呼吸を合わせることが強さだと学ぶ。堤の番人は水は触れた形を忘れない、いつ現れるかを選ぶだけだと教えてくれる。少年は凍った井戸のそばに残した友のことを思い、自分の足跡もいつか波として戻るのだろうかと考える。急ぎすぎれば壊れると知り、壊れないための速度を覚える。時間もまた川であり、同じ瞬間には戻れないという事実が心を少し落ち着かせる。悲しみは消えずに形を変える、それなら自分も形を変えながら歩けばいいと理解する。堤の影で働く人々は口数が少ないが、誰もが流れを守る誇りを持っている。その誇りが少年の胸にも移り、弱い自分でも役割を持てるのではと感じる。水面に映る空は歪んでいるが、それでも確かに空だ。歪んだままでも真実になれると知り、彼は自分の歪みも受け入れ始める。水の流れは道を守り、道は人を守る。その連なりを知ったとき、少年は自分の歩みも誰かを守る鎖の一つになれると気づく。旅の中で手に入れたのは力だけではなく、慎重に進む知恵だった。堤の静かな仕事は派手ではないが、世界を支えている。少年は自分の冒険も同じだと思う。小さな一歩でも、誰かの暮らしを守れると信じられた。堤の仕事は静かで、静かさの中に強さがあると知る。少年は派手な勝利よりも、折れずに続けることの価値を学ぶ。流れのように続く旅は、いつか誰かの岸辺に届くと信じるようになった。堤の水音は、歩幅を乱さないための拍子に聞こえた。その拍子が、彼の旅の脈になる。その脈が途切れないよう、彼は足を止めない。流れが戻る感覚は春の手触りに近く、春を取り戻す鍵はここにあると感じた。",
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
    story = {
      en = "The corridor coils like a sleeping serpent, and every lamp is wrapped in loops of dim light. Hunters dart across the shadows, closing the gaps you thought were safe, and the air feels tight around each breath. The boy remembers playing hide and seek in the ice village, how laughter used to spill out of the snowdrifts, and he feels the difference between playful darkness and this watchful dark. Here, hesitation is answered by a tightening ring, and every pause sounds like the silence that swallowed his mentor. He forces himself to read the pattern, to listen for the rhythm of the coils, and to move before the ring closes. Fear becomes a map, not a wall, and he begins to understand that courage is not the absence of doubt, but the choice to step forward while doubt still bites at his heels. He whispers his mentor's name once, and the coils loosen just enough for him to slip through. He notices the coils feel like repeated mistakes, a script that replays until someone dares to change a line. He thinks of the nights he wished his mentor had stayed and realizes he cannot rewrite that past. Still, he can choose a different step now, even if his hands shake. A faint warmth lingers after a dream of his mentor, and he uses that memory as a guide. The corridor seems to reward the small, quiet kind of bravery.",
      ja = "通路は眠る蛇のように身をくねらせ、灯りは輪の中に絡みついて淡く揺れる。狩人たちは影を裂き、逃げ場と思った隙間を容赦なく塞ぎ、息をするだけで空気が締まるように感じる。少年は氷の村で隠れんぼをした日のことを思い出す。雪の山から笑い声がこぼれ、暗がりが遊びだった頃の記憶が、ここでは重く別物になる。迷いの瞬間に輪は締まり、静けさは師が消えた夜の沈黙と重なる。彼は歯を食いしばり、輪のリズムを読み、閉じる前に一歩を出す。恐怖は壁ではなく地図だと自分に言い聞かせ、疑いを抱えたまま進むことが勇気だと覚え始める。輪の動きは繰り返される失敗のようで、誰かが一行を書き換えない限り同じ結末に戻る脚本にも見える。師が残ってくれたらと願った過去は書き換えられないが、今の一歩は選び直せる。正しさよりも誠実さで動いたとき、灯りが少し明るくなり、輪はわずかに緩む。回廊は大きな勝利より静かな勇気を見ているようだった。影の中に聞こえる囁きは誰かの悪意というより、自分の心が作る幻だと気づく。幻を追い払うには足音を確かめ、今ここにいる自分を何度も確かめるしかない。夜、彼は眠りの中で師に会うが、言葉は聞こえず、背中の温度だけが残る。目を覚ましたとき、その温度が指先に残っていて、それを道標にする。蛇の輪は焦りを試し、焦りは影に吸い込まれる。少年は自分の焦りが最も危うい敵だと気づき、慎重に一歩ずつ進む。恐れに名前を与えることで歩けるようになった彼は、旅の中で初めて自分の弱さと肩を並べた。蛇の輪が迫るたび、彼は息を数え、足を置く場所だけを見る。恐れを持ったまま進むことが、今の自分にできる最善だと理解する。旅は試練を重ねるほど、心のかたちを試す。影の中で見つけた小さな光は、すぐに消えるほど弱い。それでも彼は光を追わず、光のそばに留まる。怖さと並んで歩くことで、怖さが少しだけ薄くなると知った。旅の試練は心の癖を映し、癖を知るほど人は強くなる。迷いを隠すより、迷いを抱えたまま進む方が誠実だと分かる。誠実さだけが輪をほどく鍵になる。輪が締まるほど、彼の決意は硬くなる。迷いが薄くならなくても、歩みは強くなる。彼の視線は短く、息は長く、足音は確かになった。春を取り戻す旅は恐れを避けられず、恐れを抱えたまま進むことが試練になる。",
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
    story = {
      en = "Rust is not decay here, it is a vow remembered by metal. The forge stamps every weapon with a promise of use, and the heat punishes those who swing without purpose. The boy hears the bellows like a distant heartbeat, the kind he feared would stop when his mentor disappeared, and he remembers the village smith who taught him to hold a blade without anger. Sparks fall like a brief rain, and each one seems to ask whether he is still walking for the right reason. He tempers his resolve in the furnace, shaping it into something that can survive both heat and doubt, and he learns that discipline can be a kinder companion than fury. The soot on his cheeks and the sweat on his hands feel like proof that he is still alive, and the vow pinned under his coat feels heavier, but steadier. He leaves with blistered palms and a quieter heart, knowing the fire did not burn his grief away, but taught him how to carry it without dropping his blade. He finds a bent tool that reminds him of his mentor and feels a sting of loss. The old smith says strength is a promise to protect, not a license to harm. Even if he cannot become a great hero, he can choose to guard one person well. The forge does not burn grief away, but it shapes how he carries it, and he leaves with a heavier weapon and a lighter rage.",
      ja = "ここでの錆は朽ちではなく、金属が覚えた誓いだ。鍛冶炉は武器に用途の約束を刻み、目的のない一振りには熱が罰を与える。炉の呼気は遠い心臓の鼓動に似ていて、師が消えた夜に聞いた沈黙がふと重なる。少年は村の鍛冶屋に教わった怒りではなく目的で振れという言葉を思い出し、火花の中で自分の決意を鍛える。火の粉は短い雨のように落ち、どの粒もなぜ進むのかと問いかける。熱と迷いの両方に耐えられる形へと整えていくうちに、力よりも節度が長い旅の友になると悟る。炉の隅で師が使っていたような工具の欠片を見つけ、胸が締め付けられる。無くしたものほど重く、残ったものほど小さい。だが小さな欠片でも手の中に収まれば、また歩ける。老いた鍛冶師は刃には二つの役目がある、切るためと踏みとどまるためだと教える。少年は誓いの言葉を布に書き、柄に結びつける。守りたい顔を思い浮かべると、それは遠い誰かではなく村の人々の顔だった。鍛冶師の手には古い火傷の跡があり、その跡がこの場所の時間の長さを語っていた。少年は火傷を恐れながらも、火傷の意味を知りたいと思う。痛みは避けられないが、痛みの先に守るべきものがあるなら耐えられると理解する。彼は刃の重さを確かめながら、自分が守るべきものの重さも確かめた。旅の中で得た熱を、怒りではなく誓いとして胸にしまう。炉の音は戦いの音ではなく、誓いを刻む音だと知る。少年はこの冒険の先で守るべきものを見つけるために、いまは守る心を鍛える。熱は痛いが、痛みがあるからこそ言葉は本物になる。鍛冶師は火を扱う者は必ず誓いを持てと言った。誓いがなければ刃はただの重い鉄になる。少年は自分の誓いを言葉にし、言葉を刃に重ねる。重ねた言葉が、これからの冒険の守りになると信じた。刃を磨くたびに心も磨かれる気がした。磨いた分だけ迷いが薄くなるとは限らないが、進む意志は濃くなる。鍛冶師は最後に、刃は使う人の心で強さが決まると告げた。少年はその言葉を胸に刻み、刃より心を先に磨くと誓う。火の前で笑うことは少ないが、彼は笑いの価値を失わない。その価値を守るために、彼は刃を持つ手を慎重に選ぶ。その慎重さが、彼の旅を支える。その支えが、彼の背中を押す。春を守る誓いを胸に刻み、刃よりも心を先に鍛えると決める。",
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
    story = {
      en = "Two gates face each other like twins, each guarding a different kind of truth. One favors speed, one favors safety, and both open only to a clear command spoken without shaking. The boy stands between them and realizes that no choice is painless; a path left unpicked is also a loss that will haunt him later. He remembers the village elders who argued about which road to close when winter deepened, and how even a good decision left someone crying. He speaks a simple command, not because he is certain, but because he chooses to carry the weight. He learns that decision is a kind of courage, and that the hollow feeling after choosing is not failure but proof that the choice mattered. The gate does not promise a better world, only a direction, and that is enough for him to step through. At night he sleeps between the gates and dreams of two futures, one fast and bright, one slow and kind. Both futures hold someone crying, and he wakes with a tight chest. He writes a short note to the friend he left behind, though he has no way to send it, and the act alone steadies him. The walls are carved with brief lines from travelers who hesitated, and one reads keep going even while afraid. He touches the words and steps through, knowing the weight of choice will follow.",
      ja = "二つの門が双子のように向かい合い、それぞれ速度と安全という異なる真実を守っている。どちらも震えのない命令にしか開かず、背後の巨像は迷いの代償を示す。少年は門の間に立ち、どんな選択にも痛みが残ることを悟る。選ばなかった道もまた失うものだ。村の長老たちが冬の深まりとともに道を閉じるとき、正しい判断でさえ誰かの涙を残したことを思い出す。夜、門の間で眠ると速さだけの未来と慎重さだけの未来が夢に現れる。どちらも光に満ちているのに、どちらにも誰かが泣いている。少年は選ぶことが誰かを置いていくことだと知り、胸が痛む。それでも短い命令を口にする。確信ではなく引き受ける覚悟として一歩を踏み出す。決断のあとに残る空虚さも抱えたまま進むことが、ここでの強さだと知る。門の壁には過去の旅人が残した短い言葉が刻まれており、迷ったままでも進めと読める文字があった。彼はその文字を指でなぞり、恐れを抱えたまま足を踏み出す。門の向こうで何が待つか分からないが、決めた方向へ進むことでしか答えは見えない。だから彼は迷いを抱えたままでも歩みを止めない。選択は終わりではなく始まりであり、始まりは必ず不安を連れてくる。少年は不安と共に歩く術を覚え、揺れる心を自分で支えるようになる。旅はここで折り返すのではなく、より深くなる。選択は孤独だが、孤独の中で選んだ道には責任が宿る。少年は責任を抱えたまま進む覚悟を固める。ここからの旅は、答えを探す旅ではなく、答えを作る旅になる。選択は一度きりに見えても、実際は毎歩が選択の連続だと気づく。だからこそ彼は、迷いの中でも丁寧に歩くことを選ぶ。門を越えることは終わりではなく、覚悟を持つ練習だった。彼は選択の重さを誰かに渡すのではなく、自分の足で支えることを選ぶ。支える覚悟が、次の扉を開く鍵になる。選ぶたびに失うものがあると知り、その失い方を丁寧にしたいと願う。丁寧さが旅の礼儀だと理解する。迷いを抱えたままでも、人は道を選べると知った。選んだ道で出会う人々に、選択の意味を渡せるようになりたい。丁寧さは遅さではなく、迷いを受け止める速さだ。迷いを受け止めるほど、歩みは強くなる。それで十分だ。どちらの門も春へ続く可能性があると信じ、選択の重みを春のために引き受ける。",
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
    story = {
      en = "The stampede is not anger but memory. Each hoofbeat repeats a creed that once held this place together, and the ground tests whether you can match its rhythm. The boy feels the weight of many lives in the thundering steps, a reminder that journeys end and still must be honored. He does not outrun the stampede; he learns to run beside it, carrying a quiet grief that does not stop him. In the roar he hears names he has never met and names he has lost, and he understands that the corridor remembers everyone who moved to the right. The lesson is harsh and strangely gentle: keep pace with the past, or be swallowed by it. He tightens his grip on the charm, not to silence the thunder, but to promise that he will carry those names forward. In the roar he thinks he sees his father's back, but it is only a shadow moving at the same pace. He cannot catch it, so he runs beside it. The ground remembers old footsteps and carries new ones forward. He imagines his own name being whispered one day and feels both fear and comfort. Grief does not fade, but it can move with him, and the stampede teaches him to honor that motion.",
      ja = "踏圧は怒りではなく記憶だ。蹄音はこの場所を結び留めた信条を繰り返し、大地はそのリズムに合わせられるかを試す。轟く歩みの中で、少年は多くの旅が終わった重みを感じる。終わりは避けられないと知りながら、前へ進むことを選ぶ。轟きの中で、彼は父の背中の幻を見た気がする。追いかけても追いつけず、ただ同じリズムで走るしかない。大地は過去の足音を覚えていて、今の足音を未来に渡そうとしている。少年は自分の名もまたいつか誰かに唱えられるのだろうと想像し、怖さと救いの両方を抱く。悲しみは消えないが、悲しみを抱えたまま前へ進むことが誰かの灯りになると信じる。踏圧の風は冷たく、息を吸うたび胸が痛むが、それでも足を止めない。倒れたならここで消えた名の一つになるだけだという現実が、逆に歩みを強くする。足音は祈りであり、祈りは誰かのために続くものだと知る。踏圧の後に残る土は柔らかく、そこに自分の足跡が刻まれる。列の終わりが見えなくても、今の一歩だけは自分のものだと信じる。踏圧の終わりで膝をつき、土に手を当てて感謝を伝える。祈りは声にならなくても確かに残る。その残り火が次の歩みを照らし、旅は最奥へ向かう。踏圧の列に加わることは終わりではなく、長い物語の一節になることだと知る。少年はその一節を恥じないように歩く。旅の終盤で得た静けさが、最終章への力になる。踏圧の列に加わることは、過去と未来の間に立つことだと知る。少年はその立場が怖いが、怖さを抱えたまま進むと決める。旅の終盤で得た静けさが、次の一歩の支えになる。祈りは形にならないが、形にならないからこそ長く残ると信じる。彼はその祈りを胸に、最後の坂へ向かう。踏圧の列の中で、彼は見えない仲間を感じる。恐れは残るが、恐れと共に歩くことがこの章の答えだった。その答えが彼の背中を支え、終わりの気配にも折れない。祖霊の列に小さな誓いを立て、恐れを言葉に変える。言葉にした恐れは、歩みを止めるものではなく、歩みを支える柱になる。彼はその柱を抱え、最後まで折れないと誓う。背中の誓いは軽くならないが、重さが歩みを止めない。それでも進む。重さを背負っても、足は止まらない。それが彼の答えだった。祖霊たちも春を待ち望んだと知り、春を取り戻す歩みを止めないと誓う。",
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
    -- 師の役割が比喩で曖昧にならないよう、回廊を動かす役目として明記する。
    story = {
      en = "Null Horizon is the corridor that never finishes compiling. Every step to the right rewrites the path behind you, and light and shadow trade places without warning. The boy understands now why his mentor never returned; the horizon eats certainty and leaves only motion. Yet he also feels a strange peace: if the corridor has no end, then his promise can live as long as he walks. He steps into the endless corridor with a young heart that has learned to carry both hope and ache. A final surprise waits in the hush: the charm he has carried opens not a door but a memory. The corridor is a vast vessel built to keep a fading world alive. It moves so the sleeping can keep breathing, and it asks for keepers who will not stop. His mentor did not vanish; he accepted the keeper's duty to keep the corridor moving and stayed behind as part of its work. The boy does not call this a happy ending, but he accepts the weight of it and keeps moving, because the rightward path is now a promise to everyone who sleeps beneath the ice.",
      ja = "終端ヌルホライゾンは完成しない回廊だ。右へ進むたびに背後の道が書き換わり、光と影が静かに入れ替わる。少年はここで、師が帰れなかった理由の片鱗を理解する。地平は確かな答えを飲み込み、残るのは歩き続ける意志だけだ。それでも不思議と心は静かで、終わりがないなら誓いもまた歩き続けられると知る。実は彼が握り続けた護符は扉ではなく記憶を開く鍵だった。回廊は凍った世界を眠らせ続けるための巨大な器で、止まれば眠りも途切れる。師は消えたのではなく、回廊を動かし続ける役目を引き受け、守り手として残った。師の役目は歩みを止めないこと、その一点に集約されていた。だからこそ彼は戻らず、回廊の奥で静かに働き続けたのだと分かる。少年は幸福とは呼べない真実を受け入れ、それでも右へ進む。回廊が永遠に続くという事実は残酷でもあり、同時に誰かを守るための唯一の方法でもある。彼の歩みは眠り続ける世界の呼吸を支え、誰かの明日を辛うじてつなぐ。彼は師の代わりに歩くのではなく、師の役目を理解した上で自分の役目を選ぶのだ。回廊の壁には過去の旅人の痕があり、それが道を支える柱になっていると知る。いつか自分の名もその痕になり、次の旅人の背中を押すだろうと想像する。その想像が怖くても、彼は歩くことだけはやめないと決める。旅の意味は勝利ではなく支えであり、支えがある限り誰かの朝は守られる。守り手の役目は重いが、重いからこそ意味がある。少年は自分が守る側に立つ未来を受け入れ、いまは歩き続けることに集中する。歩くことが世界の呼吸を支えるなら、その歩みこそが彼の冒険の答えだった。回廊の真実を知ったあとも、彼は歩くことをやめない。歩き続けることが、師が残した役目を尊重する唯一の方法だと理解したからだ。彼の歩みは孤独だが、孤独の中に世界の呼吸がある。呼吸を守ることが、彼にとっての冒険の結末だった。世界が静かに息をする音を想像し、その音に歩幅を合わせる。歩き続けることが、彼の小さな英雄譚になる。師の残した道は重いが、重さがあるからこそ道は折れない。彼はその重さを抱え、静かに前へ進む。静かな歩幅が、回廊の奥に新しい約束を刻んだ。約束は消えない。回廊が動き続ける限り春が戻る可能性は残る。だから彼は歩みを止めず、春を取り戻すための役目を受け入れる。",
    },
  },
}

return M
