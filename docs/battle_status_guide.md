<!-- この文書は戦闘の流れとステータス算出ルールを実装準拠で理解しやすく整理するためのコメントです。 -->
# Idle Dungeon 戦闘手順とステータス決定ガイド

## 1. まず全体像
- 自動移動中に敵とのエンカウント条件を満たすと、状態が `move` から `battle` に切り替わる。
- 戦闘はターン制で進む。
- 勝利時は `reward` に遷移し、経験値・ゴールド・ドロップ反映後に `move` に戻る。
- 敗北時は `defeat` に遷移し、ステージ開始位置へ戻して `move` に戻る。

## 2. エンカウントから戦闘開始まで
- 各フロアに敵位置が先に生成される。
- 実際の戦闘開始距離は「敵位置そのもの」ではなく、`encounter_gap` を使って手前に補正される。
- 初回フロアの先頭敵は `dust_slime` に固定される。

## 3. 戦闘の1サイクルで行うこと
1. ゲーム速度から現在のティック秒を解決する。
2. 戦闘ティックの蓄積値 `battle_tick_buffer` を更新する。
3. ティック到達前なら戦闘処理は進めない。
4. 攻撃演出中なら演出フレームだけ減らす。
5. 勝敗確定後の待機中なら `outcome_wait` を減らす。
6. `turn_wait` が残っていれば減らして終了する。
7. 行動側のターンを処理する。

## 4. ターン順と速度の扱い
- 行動順は交互固定ではなく、勇者と敵それぞれの待機カウンタで決まる。
- 1戦闘ティックごとに、勇者側と敵側の待機カウンタを同時に 1 減らす。
- 待機カウンタが 0 以下になった側が行動できる。
- 両方が同時に行動可能なら、直前の行動者と反対側を優先して決める。
- 行動した側は、自分の待機カウンタを `speed` に戻す。
- そのため `speed` が小さい側ほど行動間隔が短くなり、相手より行動回数が増える。

## 5. 勇者ターンの処理順
1. パッシブスキル倍率を取得する。
2. アクティブスキル抽選を1回行う。
3. 命中判定とダメージ計算を行う。
4. 敵HPを減らす。
5. 敵が生存している場合、保持中ペットが順番に追撃する。
6. 敵HPが 0 以下なら勝利処理に入る。

## 6. 敵ターンの処理順
1. 敵のパッシブ倍率を取得する。
2. 敵アクティブスキル抽選を1回行う。
3. 敵が攻撃対象を選ぶ。
  - ペットがいる場合は `pet_target_rate` でペット狙い抽選。
  - 外れた場合は勇者を攻撃。
4. 命中判定とダメージ計算を行う。
5. 勇者または対象ペットのHPを減らす。
6. 勇者HPが 0 以下なら敗北処理に入る。

## 7. スキル発動ルール
### アクティブスキル
- 1ターンで発動できるアクティブは最大1つ。
- まず全体発動率で抽選し、当たった場合のみ個別スキルの重み `rate` で1つ選ぶ。
- 発動しなければ通常攻撃になる。
- 攻撃計算では主に `power` と `accuracy` が反映される。

### パッシブスキル
- 習得済みかつ有効なものをすべて適用する。
- 効果は乗算ではなく加算で重ねる。
- 対象は `atk` / `def` / `accuracy`。
- 猛獣使いの `pet_slots` はペット保持上限に加算される。

## 8. ダメージ計算の決まり
1. 命中判定: `1..100` の乱数が `accuracy` 以下なら命中。
2. 基礎ダメージ: `max(1, atk - def)`。
3. 属性相性倍率を掛ける。
4. 最終ダメージ: `max(1, floor(base_damage * multiplier + 0.5))`。

### 属性倍率
- 強点: `1.25`
- 弱点: `0.75`
- 等倍: `1.0`

### 既定の相性
- 炎 -> 草に強い、水に弱い。
- 水 -> 炎に強い、草に弱い。
- 草 -> 水に強い、炎に弱い。
- 光 -> 闇に強い。
- 闇 -> 光に強い。
- ノーマルは特別な有利不利なし。

## 9. 報酬の決まり
### 経験値
- 基本式: `floor(base_reward_exp * enemy.exp_multiplier + 0.5)`。
- `base_reward_exp` は設定値。
- `exp_multiplier` は敵ごとの定義値。

### ゴールド
- 基本ゴールド: `reward_gold`。
- 追加ゴールド: 敵ごとの `drops.gold` 範囲で乱数抽選。
- 最終獲得: `reward_gold + bonus_gold`。

### アイテムドロップ
- `drop_rates` に従って `pet -> rare -> common` の順で判定する。
- 実際の候補は敵定義の `drops.common/rare/pet` を優先する。
- ボスは `boss_bonus` によりドロップ率が上乗せされる。

## 10. 勇者ステータスの決まり
## 10.1 初期値
- 既定ジョブの `base` を使用する。
- 初期レベルは勇者 `Lv1`、ジョブ `Lv1`。

## 10.2 レベル成長
- 勇者レベル成長は全ジョブ共通の成長値を使う。
  - `HERO_GROWTH = { hp=1, atk=1, def=1, speed=0 }`
- ジョブレベル成長はジョブの `growth` を使う。

基礎ステータス式:
- `hp = job.base.hp + (hero_level-1)*1 + (job_level-1)*job.growth.hp`
- `atk = job.base.atk + (hero_level-1)*1 + (job_level-1)*job.growth.atk`
- `def = job.base.def + (hero_level-1)*1 + (job_level-1)*job.growth.def`
- `speed = max(1, job.base.speed + (hero_level-1)*0 + (job_level-1)*job.growth.speed)`

## 10.3 装備補正
- 装備中アイテムの `hp/atk/def/speed` を基礎値に加算する。
- 最終的に `speed >= 1` を保証する。
- `hp` は `max_hp` を超えないように丸める。

## 10.4 ジョブレベルの上がり方
- 現在ジョブのレベルは、勇者レベルが上がった分だけ同時に上がる。
- 独立したジョブ経験値で上げる方式ではない。

## 11. 敵ステータスの決まり
## 11.1 敵の選出
- ステージ情報の `enemy_pool` があればそれを優先する。
- なければ `content/enemies.lua` の出現条件と重みで選ぶ。

## 11.2 成長レベル
- `growth = growth_base + stage_floor*growth_floor + (stage_index-1)*growth_stage`
- ボスは `growth = floor(growth * growth_boss_multiplier + 0.5)`

## 11.3 最終ステータス
- `hp = base_hp + floor(growth * growth_hp)`
- `atk = base_atk + floor(growth * growth_atk)`
- `def = base_def + floor(growth * growth_def)`
- `speed = max(1, base_speed - floor((growth-1) * growth_speed))`
- 命中は敵定義の `stats.accuracy` を使う。

## 12. ペットの戦闘ルール
- 基本保持上限は1匹。
- 新規獲得時は後勝ちで古いペットから押し出される。
- 戦闘中は勇者ターン後に追撃する。
- 敵に狙われてHP0になったペットは即時離脱する。
- パッシブ `pet_slots` で保持上限を増やせる。

## 13. 実装を変更する時に見るファイル
- 戦闘遷移: `lua/idle_dungeon/core/transition/battle.lua`
- 戦闘開始条件: `lua/idle_dungeon/core/transition.lua`
- ダメージ・敵生成: `lua/idle_dungeon/game/battle.lua`
- 属性相性: `lua/idle_dungeon/game/element.lua`
- 勇者成長・装備反映: `lua/idle_dungeon/game/player.lua`
- スキル: `lua/idle_dungeon/game/skills.lua`
- ペット: `lua/idle_dungeon/game/pets.lua`
- ドロップ: `lua/idle_dungeon/game/loot.lua`
- 敵定義: `lua/idle_dungeon/content/enemies.lua`
- ジョブ定義: `lua/idle_dungeon/content/jobs.lua`
- 装備定義: `lua/idle_dungeon/content/items.lua`
- 既定パラメータ: `lua/idle_dungeon/config.lua`

## 14. 迷った時の確認順
1. まず `core/transition/battle.lua` の分岐順を確認する。
2. 次に `game/battle.lua` の式を確認する。
3. それでも差があれば `skills.lua` と `pets.lua` の倍率と追撃を確認する。
4. 最後に `config.lua` と `content/*.lua` の値を確認する。
