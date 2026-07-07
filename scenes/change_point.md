> [中文](#lang-zh) | [English](#lang-en) | [日本語](#lang-ja)

---

<a id="lang-zh"></a>

## 1. 标题画面

- 新增 `scenes/TitleScreen.tscn`，游戏现在从标题画面开始。
- 标题为 `The price of sacrifice`。
- 标题画面上显示 `assets/player-stand/player-stand-1.png` 到 `player-stand-4.png` 的角色动画。
- 提示文字为 `Press E to sacrifice the title screen!`。
- 按 `E` 后，标题画面会破裂，角色会缩小并移动到玩家位置，然后进入 `IntegrationLevel.tscn`。
- 标题画面背后显示 `IntegrationLevel` 的地图预览，而不是黑色背景。
- 预览中的玩家和开始提示在标题画面期间被隐藏，避免与标题角色重叠。

## 2. IntegrationLevel 开始演出

- 新增 `scripts/integration_intro.gd`。
- 进入 `IntegrationLevel` 后，玩家一开始显示为 `player-stand` 动画并且不能移动。
- 提示文字为 `Press E to sacrifice the player graphic!`。
- 按 `E` 后，`player-stand` 图像会破裂成碎片并消失。
- 破裂演出后，玩家切换为通常的 `Player` 外观，并恢复正常操作。

## 3. IntegrationLevel 的边界与流程

- `SafetyFloor` 系列被整理为一个边长 3000 的正方形边界。
- `SafetyFloor` 是下边，`SafetyFloor2` 是上边。
- `SafetyFloorLeft` 和 `SafetyFloorRight` 旋转 90 度作为左右墙。
- `IntegrationLevel` 的最终目标触发后，不显示 `Thank you for playing.`，直接进入 `RoomTemplate.tscn`。

## 4. 结束序列

- `scripts/ending_sequence.gd` 新增 `skip_sequence` 选项。
- 当 `skip_sequence = true` 时，会跳过文字和淡出动画，直接切换到指定场景。
- `IntegrationLevel` 中的 `EndingSequence` 使用该选项跳转到 `RoomTemplate.tscn`。

## 5. 红色与绿色机关

- 新增 `scenes/RedObject.tscn`。
- 新增 `scenes/GreenObject.tscn`。
- 这两个对象复用与 `BlueObject` 相同的机制：对应概念被 sacrifice 时，碰撞关闭并变为半透明。
- 新增输入：
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- `scripts/sacrifice_input.gd` 中追加了 `red` 和 `green` 的切换绑定。
- `RoomTemplate.tscn` 中放置了一个红色祭坛、一个红色对象、一个绿色祭坛、一个绿色对象。
- 红色与绿色祭坛不是独立场景，而是现有 `Altar.tscn` 的实例。

---

<a id="lang-en"></a>

## 1. Title Screen

- Added `scenes/TitleScreen.tscn`; the game now starts from the title screen.
- The title is `The price of sacrifice`.
- The title character uses an animation made from `assets/player-stand/player-stand-1.png` through `player-stand-4.png`.
- The prompt is `Press E to sacrifice the title screen!`.
- Pressing `E` breaks the title screen, shrinks the character into the player position, then loads `IntegrationLevel.tscn`.
- The background behind the title is now an `IntegrationLevel` map preview instead of a black screen.
- The preview player and intro prompt are hidden during the title screen so they do not overlap the title character.

## 2. IntegrationLevel Intro

- Added `scripts/integration_intro.gd`.
- At the start of `IntegrationLevel`, the player appears as the `player-stand` animation and cannot move.
- The prompt is `Press E to sacrifice the player graphic!`.
- Pressing `E` shatters the `player-stand` graphic into pieces.
- After the shatter animation, the player switches back to the normal `Player` look and normal controls are enabled.

## 3. IntegrationLevel Bounds And Flow

- The `SafetyFloor` objects were arranged into a square boundary with side length 3000.
- `SafetyFloor` is the bottom edge, and `SafetyFloor2` is the top edge.
- `SafetyFloorLeft` and `SafetyFloorRight` are rotated 90 degrees and used as side walls.
- After reaching the final goal in `IntegrationLevel`, the game goes directly to `RoomTemplate.tscn` without showing `Thank you for playing.`.

## 4. Ending Sequence

- Added a `skip_sequence` option to `scripts/ending_sequence.gd`.
- When `skip_sequence = true`, the text and fade animation are skipped and the scene changes immediately.
- The `EndingSequence` instance in `IntegrationLevel` uses this option to move to `RoomTemplate.tscn`.

## 5. Red And Green Objects

- Added `scenes/RedObject.tscn`.
- Added `scenes/GreenObject.tscn`.
- Both reuse the same behavior as `BlueObject`: when their concept is sacrificed, collision is disabled and the object becomes translucent.
- Added input actions:
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- Added `red` and `green` bindings to `scripts/sacrifice_input.gd`.
- `RoomTemplate.tscn` now contains one red altar, one red object, one green altar, and one green object.
- The red and green altars are not separate scenes; they are instances of the existing `Altar.tscn`.

---

<a id="lang-ja"></a>
## 1. タイトル画面

- `scenes/TitleScreen.tscn` を追加し、ゲームがタイトル画面から始まるようにした。
- タイトルは `The price of sacrifice`。
- タイトル画面のキャラクターは `assets/player-stand/player-stand-1.png` から `player-stand-4.png` のアニメーションを使用する。
- 表示文は `Press E to sacrifice the title screen!`。
- `E` を押すとタイトル画面が割れ、キャラクターが小さくなってプレイヤー位置に重なり、その後 `IntegrationLevel.tscn` に進む。
- タイトル画面の背後は黒背景ではなく、`IntegrationLevel` のマッププレビューを表示する。
- タイトル中はプレビュー側のプレイヤーと開始プロンプトを透明にし、タイトルキャラクターと重ならないようにした。

## 2. IntegrationLevel 開始演出

- `scripts/integration_intro.gd` を追加した。
- `IntegrationLevel` 開始時、プレイヤーは `player-stand` の見た目で表示され、まだ動けない。
- 表示文は `Press E to sacrifice the player graphic!`。
- `E` を押すと `player-stand` の見た目が破片になって割れる。
- 割れる演出の後、通常の `Player` の見た目に変わり、通常操作が可能になる。

## 3. IntegrationLevel の外枠と遷移

- `SafetyFloor` 系のノードを一辺 3000 の正方形の外枠として整理した。
- `SafetyFloor` は下辺、`SafetyFloor2` は上辺。
- `SafetyFloorLeft` と `SafetyFloorRight` は 90 度回転させて左右の壁にした。
- `IntegrationLevel` のゴール後は `Thank you for playing.` を表示せず、そのまま `RoomTemplate.tscn` に遷移する。

## 4. エンディング処理

- `scripts/ending_sequence.gd` に `skip_sequence` オプションを追加した。
- `skip_sequence = true` の場合、文字表示やフェード演出を省略し、指定シーンへ直接遷移する。
- `IntegrationLevel` の `EndingSequence` はこの設定で `RoomTemplate.tscn` へ遷移する。

## 5. 赤・緑のオブジェクト

- `scenes/RedObject.tscn` を追加した。
- `scenes/GreenObject.tscn` を追加した。
- どちらも `BlueObject` と同じ仕組みを使い、対応する概念が sacrifice されると当たり判定が消えて半透明になる。
- 入力を追加した。
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- `scripts/sacrifice_input.gd` に `red` と `green` の切り替え設定を追加した。
- `RoomTemplate.tscn` に赤の祭壇、赤のオブジェクト、緑の祭壇、緑のオブジェクトを1つずつ配置した。
- 赤と緑の祭壇は専用シーンではなく、既存の `Altar.tscn` のインスタンスとして再現している。
