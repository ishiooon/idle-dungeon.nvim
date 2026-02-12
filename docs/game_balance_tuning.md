<!-- この文書はゲームバランスの調整ポイントを最短で把握できるように整理したガイドです。 -->
# Idle Dungeon バランス調整ガイド

## 1. まず編集するファイル
- 基本は `lua/idle_dungeon/game/balance.lua` だけを編集します。
- 経験値、ゴールド、敵の強さ、レベル成長はこの1ファイルに集約しています。

## 2. どこを変えると何が変わるか

### 2.1 勇者レベル成長
- ファイル: `lua/idle_dungeon/game/balance.lua`
- 場所: `HERO_PROFILE`（7行目付近）

| 変更項目 | 変更するとどうなるか |
| --- | --- |
| `default_next_level` | 初期状態で次レベルに必要な経験値が変わります。 |
| `next_level_mul` | レベルが上がるほど必要経験値が増える速さが変わります。 |
| `next_level_add` | 毎レベルで固定的に上乗せされる必要経験値が変わります。 |
| `growth.hp/atk/def/speed` | レベルアップ時の基礎成長量が変わります。 |

### 2.2 敵の基礎成長
- ファイル: `lua/idle_dungeon/game/balance.lua`
- 場所: `ENEMY_PROFILE`（17行目付近）

| 変更項目 | 変更するとどうなるか |
| --- | --- |
| `growth_base` | 全ステージ共通で敵の最低強度が上下します。 |
| `growth_floor` | 同ステージ内で階層が進んだ時の伸びが変わります。 |
| `growth_stage` | ステージが進んだ時の伸びが変わります。 |
| `growth_boss_multiplier` | ボスだけ強くする倍率が変わります。 |
| `growth_hp/atk/def/speed` | 成長レベル1あたりの各能力の伸びが変わります。 |

### 2.3 ステージごとの敵強度と報酬
- ファイル: `lua/idle_dungeon/game/balance.lua`
- 場所: `STAGE_PROFILES`（35行目付近）

#### `enemy` の値
- `growth_mul`: そのステージだけ敵の成長レベルを倍率補正します。
- `hp_mul/atk_mul/def_mul/speed_mul`: 最終能力値への倍率補正です。
- `*_add`: 最終能力値への固定加算です。

#### `reward` の値
- `exp_mul`: そのステージの経験値倍率です。
- `exp_cap`: 1戦あたり経験値の上限です。序盤の急成長を抑える時に使います。
- `gold_mul`: ゴールド倍率です。
- `gold_add`: ゴールド固定加算です。

### 2.4 戦闘報酬の基礎値
- ファイル: `lua/idle_dungeon/game/balance.lua`
- 場所: `REWARD_PROFILE`（29行目付近）

| 変更項目 | 変更するとどうなるか |
| --- | --- |
| `base_exp` | 全体の経験値の土台が上下します。 |
| `base_gold` | 全体のゴールドの土台が上下します。 |

## 3. よくある調整パターン

### 序盤でレベルが上がりすぎる
1. `STAGE_PROFILES[1].reward.exp_mul` を下げる。
2. `STAGE_PROFILES[1].reward.exp_cap` を小さくする。
3. それでも早い場合は `HERO_PROFILE.default_next_level` を上げる。

### 6-1付近で急に詰まる
1. `STAGE_PROFILES[6].enemy.growth_mul` を少し下げる。
2. `STAGE_PROFILES[6].enemy.hp_mul` と `atk_mul` を小さくする。
3. 必要なら `ENEMY_PROFILE.growth_stage` も下げる。

### お金が足りなすぎる
1. `STAGE_PROFILES[1..3].reward.gold_mul` を少し上げる。
2. もしくは `REWARD_PROFILE.base_gold` を上げる。

## 4. 編集しないほうがよいファイル
- `lua/idle_dungeon/config/stages.lua`
  - ここは敵プールなどの構成情報だけを持つファイルです。
  - バランス数値は置かない方針です。

## 5. 反映確認の手順
1. `bash tests/run.sh --env=localdev`
2. 失敗したテスト名を見て、該当する倍率だけ再調整する。
3. とくに以下は毎回確認する。  
   `tests/test_stage1_exp_balance.lua`  
   `tests/test_stage_balance_curve.lua`

