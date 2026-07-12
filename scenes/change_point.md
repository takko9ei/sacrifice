> [中文](#lang-zh) | [English](#lang-en) | [日本語](#lang-ja)

---

<a id="lang-zh"></a>

## 1. 标题画面

- 新增 `scenes/TitleScreen.tscn`，游戏现在从标题画面开始。
- 标题为 `The price of sacrifice`。
- 标题画面上显示 `assets/player-stand/player-stand-1.png` 到 `player-stand-4.png` 的角色动画。
- 提示文字为 `Press E to sacrifice the title screen!`。
- 按 `E` 后，标题画面会破裂，角色会缩小并移动到玩家位置，然后进入 `Level1.tscn`。
- 标题画面背后显示 `Level1` 的地图预览，而不是黑色背景。
- 预览中的玩家和开始提示在标题画面期间被隐藏，避免与标题角色重叠。

## 2. Level1 开始演出

- 新增 `scripts/integration_intro.gd`。
- 进入 `Level1` 后，玩家一开始显示为 `player-stand` 动画并且不能移动。
- 提示文字为 `Press E to sacrifice the player graphic!`。
- 按 `E` 后，`player-stand` 图像会破裂成碎片并消失。
- 破裂演出后，玩家切换为通常的 `Player` 外观，并恢复正常操作。

## 3. Level1 的边界与流程

- `SafetyFloor` 系列被整理为一个边长 3000 的正方形边界。
- `SafetyFloor` 是下边，`SafetyFloor2` 是上边。
- `SafetyFloorLeft` 和 `SafetyFloorRight` 旋转 90 度作为左右墙。
- `Level1` 的最终目标触发后，不显示 `Thank you for playing.`，直接进入 `Level2.tscn`。

## 4. 结束序列

- `scripts/ending_sequence.gd` 新增 `skip_sequence` 选项。
- 当 `skip_sequence = true` 时，会跳过文字和淡出动画，直接切换到指定场景。
- `Level1` 中的 `EndingSequence` 使用该选项跳转到 `Level2.tscn`。

## 5. 红色与绿色机关

- 新增 `scenes/RedObject.tscn`。
- 新增 `scenes/GreenObject.tscn`。
- 这两个对象复用与 `BlueObject` 相同的机制：对应概念被 sacrifice 时，碰撞关闭并变为半透明。
- 新增输入：
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- `scripts/sacrifice_input.gd` 中追加了 `red` 和 `green` 的切换绑定。
- `Level2.tscn` 中放置了一个红色祭坛、一个红色对象、一个绿色祭坛、一个绿色对象。
- 红色与绿色祭坛不是独立场景，而是现有 `Altar.tscn` 的实例。

## 6. 场景重命名 + 关卡串联收尾 + 代码清理

- 场景改名：`IntegrationLevel.tscn` → `Level1.tscn`，`RoomTemplate.tscn` → `Level2.tscn`，`ColorLevel.tscn` → `Level3.tscn`。
- 三关正式串成一条线：`TitleScreen.tscn` → `Level1.tscn` → `Level2.tscn` → `Level3.tscn` → 回到 `TitleScreen.tscn`。串联方式是给每一关的 `fourthwall` 祭坛配一个 `EndingSequence`，`Level1`/`Level2` 把 `Skip Sequence` 设成 `true`、`Next Scene Path` 指向下一关；只有 `Level3` 保留默认值，播放真正的结局演出后回到标题画面。
- `ending_sequence.gd` 的字段改名：`title_scene_path` → `next_scene_path`，`_return_to_title()` → `_to_next_scene()`，反映它现在是"去下一个配置好的场景"而不总是"回标题"。
- `title_screen.gd`/`integration_intro.gd` 里各自重复实现的运行时拼帧函数 `_build_stand_frames()`（以及配套的 `stand_frame_paths`/`stand_animation_speed` 两个导出字段）已删除，统一改用早就存在但一直被覆盖掉的预烘焙资源 `assets/player/title_stand_frames.tres`。
- `Level2.tscn`（原 `RoomTemplate.tscn`）根节点上的 `room_template.gd` 已摘除并删除该脚本文件——这个场景已经变成正式关卡，不再是给关卡设计者复制用的模板，脚本里"这是模板，别塞真机关"的说明已经不适用。
- 开发状态：所有计划内容已完成，项目进入"开发完成"状态，详见 `DEV_STATUS.md`。

---

<a id="lang-en"></a>

## 1. Title Screen

- Added `scenes/TitleScreen.tscn`; the game now starts from the title screen.
- The title is `The price of sacrifice`.
- The title character uses an animation made from `assets/player-stand/player-stand-1.png` through `player-stand-4.png`.
- The prompt is `Press E to sacrifice the title screen!`.
- Pressing `E` breaks the title screen, shrinks the character into the player position, then loads `Level1.tscn`.
- The background behind the title is now an `Level1` map preview instead of a black screen.
- The preview player and intro prompt are hidden during the title screen so they do not overlap the title character.

## 2. Level1 Intro

- Added `scripts/integration_intro.gd`.
- At the start of `Level1`, the player appears as the `player-stand` animation and cannot move.
- The prompt is `Press E to sacrifice the player graphic!`.
- Pressing `E` shatters the `player-stand` graphic into pieces.
- After the shatter animation, the player switches back to the normal `Player` look and normal controls are enabled.

## 3. Level1 Bounds And Flow

- The `SafetyFloor` objects were arranged into a square boundary with side length 3000.
- `SafetyFloor` is the bottom edge, and `SafetyFloor2` is the top edge.
- `SafetyFloorLeft` and `SafetyFloorRight` are rotated 90 degrees and used as side walls.
- After reaching the final goal in `Level1`, the game goes directly to `Level2.tscn` without showing `Thank you for playing.`.

## 4. Ending Sequence

- Added a `skip_sequence` option to `scripts/ending_sequence.gd`.
- When `skip_sequence = true`, the text and fade animation are skipped and the scene changes immediately.
- The `EndingSequence` instance in `Level1` uses this option to move to `Level2.tscn`.

## 5. Red And Green Objects

- Added `scenes/RedObject.tscn`.
- Added `scenes/GreenObject.tscn`.
- Both reuse the same behavior as `BlueObject`: when their concept is sacrificed, collision is disabled and the object becomes translucent.
- Added input actions:
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- Added `red` and `green` bindings to `scripts/sacrifice_input.gd`.
- `Level2.tscn` now contains one red altar, one red object, one green altar, and one green object.
- The red and green altars are not separate scenes; they are instances of the existing `Altar.tscn`.

## 6. Scene Rename + Final Level Chaining + Code Cleanup

- Scenes renamed: `IntegrationLevel.tscn` → `Level1.tscn`, `RoomTemplate.tscn` → `Level2.tscn`, `ColorLevel.tscn` → `Level3.tscn`.
- The three levels are now formally chained into one loop: `TitleScreen.tscn` → `Level1.tscn` → `Level2.tscn` → `Level3.tscn` → back to `TitleScreen.tscn`. Chaining works by giving each level's `fourthwall` altar an `EndingSequence`; `Level1`/`Level2` set `Skip Sequence = true` with `Next Scene Path` pointing at the next level, while only `Level3` keeps the defaults, so it plays the real ending sequence and returns to the title screen.
- `ending_sequence.gd`'s fields were renamed: `title_scene_path` → `next_scene_path`, `_return_to_title()` → `_to_next_scene()`, reflecting that it now means "go to whichever scene is configured next," not always "return to the title."
- The duplicated runtime frame-building function `_build_stand_frames()` (and its `stand_frame_paths`/`stand_animation_speed` exports), independently implemented in both `title_screen.gd` and `integration_intro.gd`, has been removed. Both now use the pre-baked `assets/player/title_stand_frames.tres` resource that already existed but was being silently overridden.
- `room_template.gd` has been detached from `Level2.tscn`'s root node (originally `RoomTemplate.tscn`) and deleted — that scene is now a real, played level rather than a copy-source template, so the script's "this is a template, don't add real gameplay" comment no longer applied.
- Development status: all planned content is complete; the project is now in a "development complete" state — see `DEV_STATUS.md`.

---

<a id="lang-ja"></a>

## 1. タイトル画面

- `scenes/TitleScreen.tscn` を追加し、ゲームがタイトル画面から始まるようにした。
- タイトルは `The price of sacrifice`。
- タイトル画面のキャラクターは `assets/player-stand/player-stand-1.png` から `player-stand-4.png` のアニメーションを使用する。
- 表示文は `Press E to sacrifice the title screen!`。
- `E` を押すとタイトル画面が割れ、キャラクターが小さくなってプレイヤー位置に重なり、その後 `Level1.tscn` に進む。
- タイトル画面の背後は黒背景ではなく、`Level1` のマッププレビューを表示する。
- タイトル中はプレビュー側のプレイヤーと開始プロンプトを透明にし、タイトルキャラクターと重ならないようにした。

## 2. Level1 開始演出

- `scripts/integration_intro.gd` を追加した。
- `Level1` 開始時、プレイヤーは `player-stand` の見た目で表示され、まだ動けない。
- 表示文は `Press E to sacrifice the player graphic!`。
- `E` を押すと `player-stand` の見た目が破片になって割れる。
- 割れる演出の後、通常の `Player` の見た目に変わり、通常操作が可能になる。

## 3. Level1 の外枠と遷移

- `SafetyFloor` 系のノードを一辺 3000 の正方形の外枠として整理した。
- `SafetyFloor` は下辺、`SafetyFloor2` は上辺。
- `SafetyFloorLeft` と `SafetyFloorRight` は 90 度回転させて左右の壁にした。
- `Level1` のゴール後は `Thank you for playing.` を表示せず、そのまま `Level2.tscn` に遷移する。

## 4. エンディング処理

- `scripts/ending_sequence.gd` に `skip_sequence` オプションを追加した。
- `skip_sequence = true` の場合、文字表示やフェード演出を省略し、指定シーンへ直接遷移する。
- `Level1` の `EndingSequence` はこの設定で `Level2.tscn` へ遷移する。

## 5. 赤・緑のオブジェクト

- `scenes/RedObject.tscn` を追加した。
- `scenes/GreenObject.tscn` を追加した。
- どちらも `BlueObject` と同じ仕組みを使い、対応する概念が sacrifice されると当たり判定が消えて半透明になる。
- 入力を追加した。
  - `3` = `sacrifice_red`
  - `4` = `sacrifice_green`
- `scripts/sacrifice_input.gd` に `red` と `green` の切り替え設定を追加した。
- `Level2.tscn` に赤の祭壇、赤のオブジェクト、緑の祭壇、緑のオブジェクトを1つずつ配置した。
- 赤と緑の祭壇は専用シーンではなく、既存の `Altar.tscn` のインスタンスとして再現している。

## 6. シーンのリネーム + レベル連結の完成 + コードの整理

- シーン名を変更：`IntegrationLevel.tscn` → `Level1.tscn`、`RoomTemplate.tscn` → `Level2.tscn`、`ColorLevel.tscn` → `Level3.tscn`。
- 3つのレベルが正式に1つのループとして連結された：`TitleScreen.tscn` → `Level1.tscn` → `Level2.tscn` → `Level3.tscn` → `TitleScreen.tscn` に戻る。連結の仕組みは各レベルの `fourthwall` 祭壇に `EndingSequence` を設定すること——`Level1`/`Level2` は `Skip Sequence = true` にして `Next Scene Path` を次のレベルへ向け、`Level3` だけはデフォルトのままにして本当のエンディング演出を最後まで再生し、タイトル画面へ戻る。
- `ending_sequence.gd` のフィールド名を変更：`title_scene_path` → `next_scene_path`、`_return_to_title()` → `_to_next_scene()`。常に「タイトルに戻る」わけではなく「設定された次のシーンへ行く」ことを表すようにした。
- `title_screen.gd` と `integration_intro.gd` にそれぞれ重複して実装されていた、実行時にフレームを組み立てる関数 `_build_stand_frames()`（および付随する `stand_frame_paths`/`stand_animation_speed` の2つのエクスポートフィールド）を削除した。両スクリプトとも、以前から存在していたが常に上書きされていた事前ビルド済みリソース `assets/player/title_stand_frames.tres` を使うように統一した。
- `Level2.tscn`（元 `RoomTemplate.tscn`）のルートノードから `room_template.gd` を外し、スクリプト自体も削除した——このシーンはすでにコピー用テンプレートではなく実際にプレイされる本編レベルになっており、「これはテンプレートなので本物のギミックを入れないこと」というスクリプトの説明はもはや当てはまらない。
- 開発状況：計画されていた内容はすべて完了し、プロジェクトは「開発完了」の状態に入った。詳細は `DEV_STATUS.md` を参照。
