> [中文](#lang-zh) | [English](#lang-en) | [日本語](#lang-ja)

---

<a id="lang-zh"></a>

# 如何快速搭一个可玩关卡

给不熟代码的关卡设计者（C）看的教程。所有东西都通过 Inspector 配置，不需要改脚本。设计权威是 `GDD.md`，本文件只讲"怎么用现有预制体拼出来"。

---

## 1. 一个可玩关卡最少需要什么

新建一个 `Node2D` 作为根节点（关卡的场景根），往下面拖这些东西：

| 必需程度                  | 节点                               | 说明                                                                          |
| ------------------------- | ---------------------------------- | ----------------------------------------------------------------------------- |
| 必需                      | 若干 `Ground.tscn` 实例            | 至少要有能站的地面，玩家才不会一直下坠。                                      |
| 必需                      | 1 个 `Player.tscn` 实例            | 摆在地面上方一点（别嵌进地面里）。                                            |
| 必需                      | 1 个 `SacrificeInput.tscn` 实例    | 没有它，数字键切换牺牲不会响应。                                              |
| 强烈建议                  | 1 个 `HUD.tscn` 实例               | 没有它玩家看不到槽位/图标状态（GDD §4.1 硬性要求）。                          |
| 按需                      | 若干 `Altar.tscn` 实例             | 关卡的谜题/进度都靠它触发。                                                   |
| 按需                      | 若干 `BlueObject.tscn`（或复制品） | 蓝墙、蓝平台之类的反应式机关。                                                |
| 按需                      | 1 个 `RestartController.tscn` 实例 | **不放这个，该关卡按 R 键不会重开**。单场景项目里通常每个可运行的场景放一个。 |
| 按需（fourthwall 结局关） | 1 个 `EndingSequence.tscn` 实例    | 只有走到 `fourthwall` 祭坛的那个关卡/区域需要。                               |

其余都是可选的机关/装饰。

---

## 2. 各预制体怎么用

### `Ground.tscn` —— 地面/平台/天花板/墙通用

- 拖一个实例进场景，在 Inspector 改两个字段：`size`（宽高，像素）、`color`。
- 碰撞形状和可见的多边形会自动跟着 `size` 同步（改了立刻在编辑器里看到），不需要手动编辑 `CollisionShape2D` 或 `Polygon2D`。
- 想做窄墙/长墙这种拉伸效果，用节点自带的 `Scale`（而不是改 `size`）——两种效果都行，`size` 改的是"基础尺寸"，`Scale` 是在此基础上整体拉伸。
- 默认 `collision_layer = 1`（世界层），不要改。

### `Player.tscn` —— 玩家

- 每个关卡放一个，摆在起点位置，Y 坐标别让它一开始就卡进地面。
- `collision_layer = 2`（玩家层）是固定的，不要改，否则祭坛/地面检测不到玩家。
- 手感数值来自 `tuning/default.tres`，这个关卡本身不用管。

### `Altar.tscn` —— 祭坛

进入范围只显示提示文字，玩家必须按 `interact`（默认 E）才真正触发。Inspector 里三个关键字段：

| `Action`              | 效果                             | 还要填什么                                                                                                        |
| --------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `UNLOCK`              | 解锁一个概念，让它能被数字键切换 | `Concept Id`（如 `"gravity"`）、`Message`（提示文案）                                                             |
| `SET_SLOTS`           | 把槽位数改成 `Slot Count`        | `Slot Count`（通常填 2）、`Message`。**`Concept Id` 这一档完全不会被读取（见 `altar.gd::_trigger()`），留空即可** |
| `PERMANENT_SACRIFICE` | 永久牺牲一个概念（不可逆）       | `Concept Id`（如 `"jump"`）、`Message`                                                                            |

- `One Shot` 默认打开：触发一次后这个祭坛不再显示提示、也不再响应。
- **双槽神龛怎么叠**：在同一个坐标摆两个 `Altar.tscn` 实例，一个设 `Action=SET_SLOTS`、`Slot Count=2`，另一个设 `Action=PERMANENT_SACRIFICE`、`Concept Id="jump"`。玩家站在范围内按一次 `interact`，两个祭坛会同时触发（它们各自独立监听同一次按键）。
- 提示文字（`Hint`）是祭坛自带的子节点，不用另外加，内容就是 `Message` 字段。

#### `Concept Id` 具体能填什么

`Concept Id` 在代码里就是一个普通字符串字段（`@export var concept_id: String`），Inspector 只给你一个文本框，**不会有下拉菜单，也不会校验拼写**——填错字不会报错，只会"什么都不发生"，是这里最容易踩的坑。

`Sacrifice` 单例本身对字符串没有任何白名单，任何 id 都能正常 unlock/activate/permanently_sacrifice。但**要让这个 id 真正产生游戏效果，必须有别的物体在监听它**。当前项目里只有下面 5 个 id 有对应的监听者：

| id             | 该配哪种 `Action`     | 效果实现在哪                                                                         |
| -------------- | --------------------- | ------------------------------------------------------------------------------------ |
| `"gravity"`    | `UNLOCK`              | `player.gd` 里写死判断 `if id != "gravity": return`，翻转重力/`up_direction`         |
| `"blue"`       | `UNLOCK`              | `BlueObject.tscn`（`blue_object.gd`），其 `concept_id` 字段默认就是 `"blue"`         |
| `"jump"`       | `PERMANENT_SACRIFICE` | `player.gd` 里写死判断 `Sacrifice.is_permanently_sacrificed("jump")`，让跳跃缓冲失效 |
| `"hud"`        | `PERMANENT_SACRIFICE` | `hud.gd`（界面淡出）+ `hud_collapse_platforms.gd`（坠落平台）                        |
| `"fourthwall"` | `PERMANENT_SACRIFICE` | `ending_sequence.gd`（结局序列）                                                     |

`"gravity"`/`"blue"` 只能配 `UNLOCK`（且要在 `SacrificeInput.tscn` 的 `Bindings` 里配好对应按键，见下方 `SacrificeInput.tscn` 一节）；`"jump"`/`"hud"`/`"fourthwall"` 只能配 `PERMANENT_SACRIFICE`——填到别的 `Action` 上没有任何监听者响应，等于白填。

**其他任何字符串**（比如 GDD 储备概念 `"friction"`/`"time"`/`"sound"`，或全新的自定义 id）技术上都能正常触发、正常记录状态，但只要没有配套的监听者，就没有任何可见效果。要让新 id 生效，必须先有人（通常是 B）复制 `blue_object.gd` 或 `hud_collapse_platforms.gd` 改 `concept_id` 加一个监听者——这属于 GDD §7.6"扩展模式"的范围，需要改脚本，不是纯 Inspector 能搞定的。

**三处字符串必须逐字符一致**（区分大小写，Godot 不会做任何校验），是另一个常见坑：

1. `Altar.tscn` 的 `Concept Id`
2. 反应物体（`BlueObject.tscn` 等）的 `concept_id`
3. 如果是可逆概念，还要加 `SacrificeInput.tscn` 的 `Bindings` 字典里对应的**值**

三处只要有一处拼错，效果就会悄悄失效且不报错，务必复制粘贴而不是手打。

### `BlueObject.tscn` —— 蓝墙/蓝平台

- 直接当蓝墙/蓝平台用：默认 `concept_id = "blue"`，牺牲 `blue` 时会禁用碰撞+半透明，恢复时反之。
- 用节点的 `Scale` 拉伸大小（碰撞和视觉会一起缩放）。
- 要复用给别的颜色/概念：复制这个场景，改 `concept_id` 和 `Visual` 的颜色即可，不用碰脚本。

### `SacrificeInput.tscn` —— 输入映射

- 一关放一个就够。
- 新增按键映射：在 Inspector 展开 `Bindings` 字典，加一行 `"输入动作名": "concept_id"`（输入动作要先在 Project Settings 的 Input Map 里存在——这一步得找程序/人类做，AI 不能碰 Project Settings）。

### `HUD.tscn` —— 状态显示

- 一关放一个就够，不用配置什么，全靠 `Sacrifice` 单例的信号自动更新槽位和图标。

### `HudCollapsePlatforms.tscn` —— hud 牺牲的坠落平台 set-piece

- 摆在需要"牺牲 hud 后多出踏脚点"的缺口/高台附近。
- 在它下面加若干 `Marker2D` 子节点，每个 Marker2D 的位置就是一块平台最终落地的位置。
- Inspector 可调：`Platform Size`、`Platform Color`、`Drop Height`（掉落起始高度）、`Drop Duration`（掉落耗时）。
- 只有旁边配一个 `Altar.tscn`（`Action=PERMANENT_SACRIFICE`，`Concept Id="hud"`）触发后，这些平台才会生成——两者要配对摆放。

### `RestartController.tscn` —— 按 R 重开

- 每个可独立运行/测试的场景放一个即可，没有可调参数。
- 作用：按 `restart` 键时清空所有牺牲状态并重载当前场景。

### `EndingSequence.tscn` —— fourthwall 结局

- 只在包含最终祭坛（`PERMANENT_SACRIFICE fourthwall`）的关卡里放一个。
- 放好之后必须手动把它的 `Hud Fade Target Path` 字段接到本关卡自己的 `HUD` 节点下的 `Layout`（例如 `../HUD/Layout`），否则结局播放时 HUD 不会正确淡出。

---

## 3. 碰撞层设置（新手最容易忘）

- **Layer 1 = 世界实体**（地面、墙、蓝墙这类机关）。`Ground.tscn`/`BlueObject.tscn` 默认已经是 1，不要改。
- **Layer 2 = 玩家**。`Player.tscn` 默认已经是 2，不要改。
- 祭坛（`Altar.tscn`）是 `Area2D`，`collision_layer=0`（自己不参与物理碰撞）、`collision_mask=2`（只检测玩家）——这两个也是预制体自带的默认值，正常摆放不用改。
- **常见错误**：手滑把某个地面/机关的 `collision_layer` 改成了 2（玩家层），会导致它和玩家"融合"、碰撞检测异常；或者把 `Player` 的层改掉，会导致祭坛检测不到玩家进入范围、地面也可能穿模。摆放之后如果祭坛提示文字不出现、或者玩家穿过了本该实体的地面，先检查这两个字段有没有被误改。

---

## 4. 祭坛的 interact 确认机制对摆放的影响

- 祭坛的 `CollisionShape2D`（默认 48×64）决定了"玩家站在哪里能看到提示、按键才有效"。摆放时要确保玩家能整个身位走进这个范围，不要把祭坛塞进一个玩家够不到中心点的窄缝里。
- 叠放多个祭坛（双槽神龛那种用法）时，要让所有叠放的祭坛的碰撞范围都能同时覆盖到玩家站的那个点——最简单的做法就是把它们摆在完全相同的坐标，用默认的 48×64 范围即可，不需要额外对齐。
- 提示文字（`Hint`）目前不是 `CanvasLayer`，会被摆在同一屏幕位置的前景物体遮挡（已知问题，见 `DEV_STATUS.md` 第4节第3条）。设计关卡时注意别把别的前景机关叠在祭坛正上方。

---

## 5. 两条硬约束（必须遵守）

1. **GDD §5.4**：如果关卡用"永久牺牲 `jump` 换双槽"这套方案（默认方案），那么从双槽神龛往后，到通关为止，全程不能有任何"必须按跳跃键才能过"的地方（改用重力翻转覆盖所有垂直移动）。验证方法：牺牲 `jump` 之后自己重走一遍确认能通关。
2. **GDD §7.7**：不要设计"必须在人物嵌在蓝色物体内部时把蓝恢复成实体"的谜题——这会把玩家卡进墙里。自然的关卡走法基本不会撞到这个边界，只要不刻意设计"卡在蓝墙里再按2"这种解法就没问题。

---

## 6. 最小可玩关卡搭建示例

从零开始，照着做一遍就能跑起来：

1. 新建一个场景，根节点用 `Node2D`，命名随意（比如 `MyRoom`）。
2. 拖一个 `Ground.tscn` 实例进来当地面，摆在 `position = (0, 300)` 左右，`size` 设成 `(600, 40)`。
3. 拖一个 `Player.tscn` 实例，摆在地面正上方一点，比如 `position = (-200, 260)`。
4. 拖一个 `SacrificeInput.tscn` 实例（位置无所谓，它不显示任何东西）。
5. 拖一个 `HUD.tscn` 实例。
6. 拖一个 `RestartController.tscn` 实例。
7. 拖一个 `Altar.tscn` 实例，摆在地面上、玩家能走到的位置，`Action` 设成 `UNLOCK`，`Concept Id` 填 `"blue"`，`Message` 填一句提示，比如 `"Press E to Sacrifice Blue"`。
8. 拖一个 `BlueObject.tscn` 实例，摆在祭坛前方挡住继续前进的路，`Scale` 拉高一点当一堵墙。
9. 按 F5（或"运行当前场景"）：应该能左右移动、跳跃；走到祭坛按 `interact` 解锁 `blue`；按 2 切换后蓝墙变半透明能穿过去；按 R 能重开。

这就是一个最小闭环：地面 + 玩家 + 一个祭坛 + 一个机关。往上叠加更多祭坛/机关/`Ground` 拼区域，就是完整关卡的搭法——参考 `scenes/Level1.tscn` 看一条完整的 R1→R6 关卡是怎么用同样的预制体拼起来的。

---

<a id="lang-en"></a>

# How to Quickly Build a Playable Level

Tutorial for level designers (C) who aren't comfortable with code. Everything is configured through the Inspector — no scripts need to be touched. `GDD.md` is the design authority; this file only explains "how to assemble a level from the existing prefabs."

---

## 1. What a Playable Level Needs at Minimum

Create a `Node2D` as the root node (the level's scene root), then drag these under it:

| Requirement                         | Node                                                | Notes                                                                                                                |
| ----------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Required                            | One or more `Ground.tscn` instances                 | You need at least a floor to stand on, or the player will keep falling.                                              |
| Required                            | One `Player.tscn` instance                          | Place it just above the ground (don't embed it inside the floor).                                                    |
| Required                            | One `SacrificeInput.tscn` instance                  | Without it, the number keys won't toggle any sacrifice.                                                              |
| Strongly recommended                | One `HUD.tscn` instance                             | Without it the player can't see slot/icon state (GDD §4.1 hard requirement).                                         |
| As needed                           | One or more `Altar.tscn` instances                  | The level's puzzles/progression are all triggered through these.                                                     |
| As needed                           | One or more `BlueObject.tscn` instances (or copies) | Reactive gimmicks such as blue walls/blue platforms.                                                                 |
| As needed                           | One `RestartController.tscn` instance               | **Without this, pressing R won't restart the level.** In this single-scene project, put one in every runnable scene. |
| As needed (fourthwall ending level) | One `EndingSequence.tscn` instance                  | Only needed for the level/area that leads to the `fourthwall` altar.                                                 |

Everything else is optional gimmicks/decoration.

---

## 2. How to Use Each Prefab

### `Ground.tscn` — Generic floor/platform/ceiling/wall

- Drag an instance into the scene, then edit two Inspector fields: `size` (width/height in pixels) and `color`.
- The collision shape and the visible polygon stay in sync with `size` automatically (visible instantly in the editor) — no need to hand-edit `CollisionShape2D` or `Polygon2D`.
- To stretch it into a narrow/long wall, use the node's built-in `Scale` (instead of changing `size`) — both work, but `size` changes the "base dimensions" while `Scale` stretches on top of that.
- Defaults to `collision_layer = 1` (world layer) — don't change it.

### `Player.tscn` — The player

- Place one per level, at the starting position; make sure its Y coordinate doesn't start it embedded in the floor.
- `collision_layer = 2` (player layer) is fixed — don't change it, or altars/floors won't detect the player.
- Feel values come from `tuning/default.tres`; this is not something the level itself needs to manage.

### `Altar.tscn` — Altar

Entering its range only shows the hint text; the player must press `interact` (default E) to actually trigger it. Three key Inspector fields:

| `Action`              | Effect                                                   | What else to fill in                                                                                                                   |
| --------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `UNLOCK`              | Unlocks a concept so it can be toggled with a number key | `Concept Id` (e.g. `"gravity"`), `Message` (hint text)                                                                                 |
| `SET_SLOTS`           | Changes the slot count to `Slot Count`                   | `Slot Count` (usually 2), `Message`. **`Concept Id` is not read at all for this action (see `altar.gd::_trigger()`) — leave it blank** |
| `PERMANENT_SACRIFICE` | Permanently sacrifices a concept (irreversible)          | `Concept Id` (e.g. `"jump"`), `Message`                                                                                                |

- `One Shot` is on by default: once triggered, this altar stops showing its hint and stops responding.
- **How to stack the double-slot shrine**: place two `Altar.tscn` instances at the same spot — one with `Action=SET_SLOTS`, `Slot Count=2`, the other with `Action=PERMANENT_SACRIFICE`, `Concept Id="jump"`. While standing in range, one press of `interact` triggers both altars at once (each listens to the same key press independently).
- The hint text (`Hint`) is the altar's own built-in child node — no need to add anything else; its content is just the `Message` field.

#### What exactly can go in `Concept Id`

In code, `Concept Id` is just a plain string field (`@export var concept_id: String`). The Inspector only gives you a text box — **no dropdown, and no spelling validation**. A typo won't throw an error; it will just silently do nothing, which is the easiest trap to fall into here.

The `Sacrifice` singleton itself has no whitelist for strings — any id can be unlocked/activated/permanently sacrificed without error. But **for an id to actually produce a gameplay effect, some other object must be listening for it**. Currently only these 5 ids have a matching listener in the project:

| id             | Which `Action` it belongs with | Where the effect is implemented                                                                  |
| -------------- | ------------------------------ | ------------------------------------------------------------------------------------------------ |
| `"gravity"`    | `UNLOCK`                       | Hardcoded in `player.gd`: `if id != "gravity": return`, flips gravity/`up_direction`             |
| `"blue"`       | `UNLOCK`                       | `BlueObject.tscn` (`blue_object.gd`), whose `concept_id` field defaults to `"blue"`              |
| `"jump"`       | `PERMANENT_SACRIFICE`          | Hardcoded in `player.gd`: `Sacrifice.is_permanently_sacrificed("jump")` disables the jump buffer |
| `"hud"`        | `PERMANENT_SACRIFICE`          | `hud.gd` (UI fade-out) + `hud_collapse_platforms.gd` (falling platforms)                         |
| `"fourthwall"` | `PERMANENT_SACRIFICE`          | `ending_sequence.gd` (ending sequence)                                                           |

`"gravity"`/`"blue"` only make sense with `UNLOCK` (and need a matching key binding in `SacrificeInput.tscn`'s `Bindings`, see the `SacrificeInput.tscn` section below); `"jump"`/`"hud"`/`"fourthwall"` only make sense with `PERMANENT_SACRIFICE` — putting them on any other `Action` has no listener responding, i.e. it's a no-op.

**Any other string** (e.g. the GDD's reserved concepts `"friction"`/`"time"`/`"sound"`, or a brand-new custom id) will technically trigger and record state without error, but produces no visible effect unless a matching listener exists. To make a new id do something, someone (typically B) first needs to copy `blue_object.gd` or `hud_collapse_platforms.gd`, change `concept_id`, and add a listener — this falls under GDD §7.6 "extension pattern" and requires a script change; it can't be done from the Inspector alone.

**Three places must match character-for-character** (case-sensitive, Godot performs no validation) — another common trap:

1. `Altar.tscn`'s `Concept Id`
2. The reactive object's (`BlueObject.tscn`, etc.) `concept_id`
3. For a reversible concept, also the corresponding **value** in `SacrificeInput.tscn`'s `Bindings` dictionary

A typo in any one of the three silently breaks the effect without an error — always copy-paste, don't retype by hand.

### `BlueObject.tscn` — Blue wall/blue platform

- Use it directly as a blue wall/platform: `concept_id = "blue"` by default; sacrificing `blue` disables its collision and makes it translucent, and restores it when un-sacrificed.
- Use the node's `Scale` to stretch its size (collision and visuals scale together).
- To reuse it for a different color/concept: duplicate this scene, change `concept_id` and the `Visual` node's color — no scripting needed.

### `SacrificeInput.tscn` — Input mapping

- One per level is enough.
- To add a new key binding: expand the `Bindings` dictionary in the Inspector and add a line `"input_action_name": "concept_id"` (the input action must already exist in Project Settings' Input Map — that step needs a programmer/human; AI is not allowed to touch Project Settings).

### `HUD.tscn` — Status display

- One per level is enough; nothing needs to be configured. It updates slots and icons automatically purely through the `Sacrifice` singleton's signals.

### `HudCollapsePlatforms.tscn` — The falling-platform set-piece for the `hud` sacrifice

- Place it near the gap/ledge that needs "extra footholds after sacrificing hud."
- Add one or more `Marker2D` children underneath it — each Marker2D's position is where one platform will land.
- Adjustable in the Inspector: `Platform Size`, `Platform Color`, `Drop Height` (starting drop height), `Drop Duration` (fall duration).
- The platforms only spawn once a nearby `Altar.tscn` (`Action=PERMANENT_SACRIFICE`, `Concept Id="hud"`) is triggered — the two must be placed as a pair.

### `RestartController.tscn` — Press R to restart

- Place one in every independently runnable/testable scene; no adjustable parameters.
- Effect: pressing the `restart` key clears all sacrifice state and reloads the current scene.

### `EndingSequence.tscn` — The fourthwall ending

- Only place one in the level containing the final altar (`PERMANENT_SACRIFICE fourthwall`).
- After placing it, you must manually wire its `Hud Fade Target Path` field to this level's own `HUD` node's `Layout` (e.g. `../HUD/Layout`), or the HUD won't fade out correctly during the ending.

---

## 3. Collision Layer Setup (the thing beginners forget most)

- **Layer 1 = world entities** (floors, walls, blue-wall type gimmicks). `Ground.tscn`/`BlueObject.tscn` already default to 1 — don't change it.
- **Layer 2 = player**. `Player.tscn` already defaults to 2 — don't change it.
- The altar (`Altar.tscn`) is an `Area2D` with `collision_layer=0` (doesn't participate in physics collision itself) and `collision_mask=2` (only detects the player) — these are also the prefab's built-in defaults; normal placement doesn't require changing them.
- **Common mistake**: accidentally changing some floor/gimmick's `collision_layer` to 2 (the player layer) causes it to "merge" with the player and produces odd collision behavior; or changing `Player`'s layer causes altars to stop detecting the player entering their range, and floors may become walkable-through. If an altar's hint text doesn't appear, or the player passes through what should be solid ground, check whether these two fields were accidentally changed first.

---

## 4. How the Altar's Interact-Confirm Mechanic Affects Placement

- The altar's `CollisionShape2D` (48×64 by default) determines "where the player must stand to see the hint and have the key press take effect." Make sure the player can fully walk into this range when placing it — don't wedge an altar into a gap so narrow the player can't reach its center point.
- When stacking multiple altars (as with the double-slot shrine), make sure every stacked altar's collision range covers the point where the player stands — the simplest approach is to place them at the exact same coordinates using the default 48×64 range; no extra alignment needed.
- The hint text (`Hint`) is currently not a `CanvasLayer`, so it can be occluded by any foreground object placed at the same screen position (known issue, see `DEV_STATUS.md` section 4, item 3). When designing a level, avoid stacking other foreground gimmicks directly above an altar.

---

## 5. Two Hard Constraints (Must Be Followed)

1. **GDD §5.4**: If the level uses the "permanently sacrifice `jump` for the double slot" scheme (the default), then from the double-slot shrine onward, all the way to the end of the level, there must be no place that "requires pressing jump to pass" (use gravity flipping to cover all vertical movement instead). Verification method: after sacrificing `jump`, walk through the level again yourself to confirm it's still completable.
2. **GDD §7.7**: Don't design a puzzle that "requires restoring blue while the character is embedded inside a blue object" — this traps the player inside a wall. Natural level traversal essentially never hits this edge case; just don't deliberately design a solution like "get stuck in the blue wall, then press 2."

---

## 6. Minimal Playable Level Walkthrough

Starting from scratch, follow these steps and it will run:

1. Create a new scene with a `Node2D` root, named whatever you like (e.g. `MyRoom`).
2. Drag a `Ground.tscn` instance in to serve as the floor, place it around `position = (0, 300)`, set `size` to `(600, 40)`.
3. Drag a `Player.tscn` instance in, place it just above the floor, e.g. `position = (-200, 260)`.
4. Drag a `SacrificeInput.tscn` instance in (position doesn't matter — it doesn't display anything).
5. Drag a `HUD.tscn` instance in.
6. Drag a `RestartController.tscn` instance in.
7. Drag an `Altar.tscn` instance in, place it on the ground where the player can reach it, set `Action` to `UNLOCK`, `Concept Id` to `"blue"`, `Message` to a hint sentence such as `"Press E to Sacrifice Blue"`.
8. Drag a `BlueObject.tscn` instance in, place it in front of the altar blocking further progress, stretch its `Scale` taller to act as a wall.
9. Press F5 (or "Run Current Scene"): you should be able to move left/right and jump; walking to the altar and pressing `interact` should unlock `blue`; pressing 2 should toggle it, making the blue wall translucent and passable; pressing R should restart.

That's the minimal loop: floor + player + one altar + one gimmick. Stack more altars/gimmicks/`Ground` on top of this to build out full areas — see `scenes/Level1.tscn` for a complete R1→R6 level built from the same prefabs.

---

<a id="lang-ja"></a>

# プレイ可能なレベルを手早く作る方法

コードに詳しくないレベルデザイナー（C）向けのチュートリアル。すべて Inspector で設定でき、スクリプトを変更する必要はない。設計の権威は `GDD.md` であり、本ファイルは「既存のプレハブでレベルをどう組み立てるか」だけを説明する。

---

## 1. プレイ可能なレベルに最低限必要なもの

`Node2D` をルートノード（レベルのシーンルート）として新規作成し、その下に以下をドラッグする：

| 必要度                                          | ノード                                         | 説明                                                                                                                                         |
| ----------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 必須                                            | `Ground.tscn` のインスタンス（1つ以上）        | 立てる床が最低限必要。なければプレイヤーは落ち続ける。                                                                                       |
| 必須                                            | `Player.tscn` のインスタンス（1つ）            | 地面の少し上に配置する（地面にめり込ませない）。                                                                                             |
| 必須                                            | `SacrificeInput.tscn` のインスタンス（1つ）    | これがないと数字キーでの犠牲切り替えが反応しない。                                                                                           |
| 強く推奨                                        | `HUD.tscn` のインスタンス（1つ）               | なければプレイヤーはスロット/アイコンの状態が見えない（GDD §4.1 の必須要件）。                                                               |
| 必要に応じて                                    | `Altar.tscn` のインスタンス（複数可）          | レベルのパズル/進行はすべてこれで発火する。                                                                                                  |
| 必要に応じて                                    | `BlueObject.tscn`（またはその複製、複数可）    | 青い壁/青い足場のような反応式ギミック。                                                                                                      |
| 必要に応じて                                    | `RestartController.tscn` のインスタンス（1つ） | **これを置かないと、そのレベルは R キーでリスタートできない**。単一シーン構成のこのプロジェクトでは、実行可能なシーンごとに1つ置くのが基本。 |
| 必要に応じて（fourthwall エンディングのレベル） | `EndingSequence.tscn` のインスタンス（1つ）    | `fourthwall` の祭壇に到達するレベル/エリアにのみ必要。                                                                                       |

それ以外はすべて任意のギミック/装飾。

---

## 2. 各プレハブの使い方

### `Ground.tscn` —— 床/足場/天井/壁 汎用

- インスタンスをシーンにドラッグし、Inspector で `size`（幅と高さ、ピクセル）と `color` の2フィールドを変更する。
- 当たり判定形状と可視ポリゴンは `size` に自動追従する（変更するとエディタ上で即座に反映される）ので、`CollisionShape2D` や `Polygon2D` を手動で編集する必要はない。
- 細い壁/長い壁のように引き伸ばしたい場合は、ノード自体が持つ `Scale` を使う（`size` を変えるのではなく）——どちらの方法でも良いが、`size` は「基本サイズ」を変え、`Scale` はそれを土台に全体を拡大縮小する。
- デフォルトは `collision_layer = 1`（ワールド層）——変更しないこと。

### `Player.tscn` —— プレイヤー

- レベルごとに1つ配置し、スタート地点に置く。Y座標を地面にめり込んだ状態で開始しないよう注意する。
- `collision_layer = 2`（プレイヤー層）は固定値——変更しないこと。変更すると祭壇や地面がプレイヤーを検知できなくなる。
- 操作感の数値は `tuning/default.tres` 由来であり、レベル側で気にする必要はない。

### `Altar.tscn` —— 祭壇

範囲に入るとヒントテキストが表示されるだけで、プレイヤーが `interact`（デフォルトは E）を押して初めて実際に発火する。Inspector 上の重要な3フィールド：

| `Action`              | 効果                                                 | 他に入力すべき項目                                                                                                                       |
| --------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `UNLOCK`              | ある概念を解禁し、数字キーで切り替えられるようにする | `Concept Id`（例：`"gravity"`）、`Message`（ヒント文言）                                                                                 |
| `SET_SLOTS`           | スロット数を `Slot Count` に変更する                 | `Slot Count`（通常は2）、`Message`。**`Concept Id` はこのアクションでは一切読み取られない（`altar.gd::_trigger()` 参照）ので空欄でよい** |
| `PERMANENT_SACRIFICE` | ある概念を永久に犠牲にする（不可逆）                 | `Concept Id`（例：`"jump"`）、`Message`                                                                                                  |

- `One Shot` はデフォルトでオン：一度発火するとその祭壇はヒントを表示しなくなり、反応もしなくなる。
- **二重スロットの祭壇（double-slot shrine）の重ね方**：同じ座標に `Altar.tscn` のインスタンスを2つ置く。一方は `Action=SET_SLOTS`、`Slot Count=2`、もう一方は `Action=PERMANENT_SACRIFICE`、`Concept Id="jump"` に設定する。範囲内に立って `interact` を1回押すだけで、両方の祭壇が同時に発火する（それぞれが独立して同じキー入力を監視しているため）。
- ヒントテキスト（`Hint`）は祭壇が最初から持つ子ノードなので、別途追加する必要はなく、内容は `Message` フィールドそのものである。

#### `Concept Id` に具体的に何を入力できるか

コード上、`Concept Id` はただの文字列フィールド（`@export var concept_id: String`）である。Inspector はテキストボックスを表示するだけで、**ドロップダウンもスペルチェックもない**——入力ミスをしてもエラーにはならず、ただ「何も起きない」だけになる。これが最も陥りやすい罠である。

`Sacrifice` シングルトン自体は文字列に対して一切のホワイトリストを持たない——どんな id でも unlock/activate/permanently_sacrifice できてしまう。しかし**その id が実際にゲーム上の効果を生むには、それを監視している別のオブジェクトが必要**である。現在のプロジェクトで対応するリスナーがあるのは、次の5つの id だけである：

| id             | どの `Action` に対応するか | 効果の実装箇所                                                                                                        |
| -------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `"gravity"`    | `UNLOCK`                   | `player.gd` にハードコードされた判定 `if id != "gravity": return` により重力/`up_direction` を反転させる              |
| `"blue"`       | `UNLOCK`                   | `BlueObject.tscn`（`blue_object.gd`）。その `concept_id` フィールドはデフォルトで `"blue"`                            |
| `"jump"`       | `PERMANENT_SACRIFICE`      | `player.gd` にハードコードされた判定 `Sacrifice.is_permanently_sacrificed("jump")` によりジャンプバッファを無効化する |
| `"hud"`        | `PERMANENT_SACRIFICE`      | `hud.gd`（UI のフェードアウト）+ `hud_collapse_platforms.gd`（落下する足場）                                          |
| `"fourthwall"` | `PERMANENT_SACRIFICE`      | `ending_sequence.gd`（エンディング演出）                                                                              |

`"gravity"`/`"blue"` は `UNLOCK` としてのみ意味を持つ（また `SacrificeInput.tscn` の `Bindings` に対応するキー割り当てが必要。下記の `SacrificeInput.tscn` の節を参照）。`"jump"`/`"hud"`/`"fourthwall"` は `PERMANENT_SACRIFICE` としてのみ意味を持つ——それ以外の `Action` に入れても、反応するリスナーが存在しないため何も起きない。

**それ以外の任意の文字列**（例えば GDD の予備概念 `"friction"`/`"time"`/`"sound"`、あるいは完全に新規の独自 id）は、技術的には正常に発火し状態も正常に記録されるが、対応するリスナーがなければ目に見える効果は一切ない。新しい id を機能させるには、まず誰か（通常は B）が `blue_object.gd` か `hud_collapse_platforms.gd` を複製して `concept_id` を変更し、リスナーを追加する必要がある——これは GDD §7.6「拡張パターン」の範囲であり、スクリプトの変更を伴うため、Inspector だけでは完結しない。

**3箇所の文字列は一字一句完全に一致していなければならない**（大文字小文字を区別し、Godot は一切の検証を行わない）。これも陥りやすい罠のひとつ：

1. `Altar.tscn` の `Concept Id`
2. 反応オブジェクト（`BlueObject.tscn` など）の `concept_id`
3. 可逆的な概念の場合は、さらに `SacrificeInput.tscn` の `Bindings` 辞書に対応する**値**

この3箇所のいずれか1つでも打ち間違えると、エラーも出ずに効果だけが静かに失われる。手入力せず必ずコピー&ペーストすること。

### `BlueObject.tscn` —— 青い壁/青い足場

- そのまま青い壁/足場として使う：デフォルトで `concept_id = "blue"`。`blue` を犠牲にすると当たり判定が無効化され半透明になり、元に戻すと復元される。
- ノードの `Scale` でサイズを引き伸ばす（当たり判定と見た目が一緒に拡大縮小する）。
- 別の色/概念用に再利用する場合：このシーンを複製し、`concept_id` と `Visual` の色を変更するだけでよい。スクリプトに触れる必要はない。

### `SacrificeInput.tscn` —— 入力マッピング

- レベルごとに1つで十分。
- 新しいキー割り当てを追加する場合：Inspector で `Bindings` 辞書を展開し、`"入力アクション名": "concept_id"` の行を追加する（その入力アクションは事前に Project Settings の Input Map に存在している必要がある——この手順はプログラマー/人間が行う必要があり、AI は Project Settings に触れてはならない）。

### `HUD.tscn` —— ステータス表示

- レベルごとに1つで十分。設定は何も要らず、`Sacrifice` シングルトンのシグナルだけでスロットとアイコンが自動更新される。

### `HudCollapsePlatforms.tscn` —— `hud` 犠牲時の落下足場セットピース

- 「`hud` を犠牲にした後に足場が増える」ことを想定した隙間/高台の近くに配置する。
- その子として `Marker2D` を1つ以上追加する。各 `Marker2D` の位置が、足場が最終的に着地する位置になる。
- Inspector で調整可能：`Platform Size`、`Platform Color`、`Drop Height`（落下開始の高さ）、`Drop Duration`（落下にかかる時間）。
- 近くに配置した `Altar.tscn`（`Action=PERMANENT_SACRIFICE`、`Concept Id="hud"`）が発火して初めてこれらの足場が生成される——両者はペアで配置する必要がある。

### `RestartController.tscn` —— R キーでのリスタート

- 独立して実行/テストできるシーンごとに1つ置けばよく、調整可能なパラメータはない。
- 効果：`restart` キーを押すと、すべての犠牲状態をクリアし現在のシーンをリロードする。

### `EndingSequence.tscn` —— fourthwall エンディング

- 最終祭壇（`PERMANENT_SACRIFICE fourthwall`）を含むレベルにのみ1つ配置する。
- 配置後は、`Hud Fade Target Path` フィールドを手動でそのレベル自身の `HUD` ノード配下の `Layout`（例：`../HUD/Layout`）に接続する必要がある。接続しないと、エンディング再生時に HUD が正しくフェードアウトしない。

---

## 3. 当たり判定レイヤーの設定（初心者が最も忘れやすい点）

- **Layer 1 = ワールド実体**（地面、壁、青い壁のようなギミック）。`Ground.tscn`/`BlueObject.tscn` はデフォルトですでに 1 になっている——変更しないこと。
- **Layer 2 = プレイヤー**。`Player.tscn` はデフォルトですでに 2 になっている——変更しないこと。
- 祭壇（`Altar.tscn`）は `Area2D` であり、`collision_layer=0`（自身は物理衝突に関与しない）、`collision_mask=2`（プレイヤーのみを検知）——これらもプレハブ標準のデフォルト値であり、通常の配置では変更不要。
- **よくあるミス**：誤って地面/ギミックの `collision_layer` を 2（プレイヤー層）に変更してしまうと、プレイヤーと「融合」してしまい当たり判定がおかしくなる。あるいは `Player` の層を変えてしまうと、祭壇がプレイヤーの侵入を検知できなくなったり、地面をすり抜けてしまったりすることがある。配置後に祭壇のヒントが出なかったり、本来実体であるはずの地面をプレイヤーがすり抜けたりした場合は、まずこの2つのフィールドが誤って変更されていないか確認すること。

---

## 4. 祭壇の interact 確認方式が配置に与える影響

- 祭壇の `CollisionShape2D`（デフォルトは 48×64）が「プレイヤーがどこに立てばヒントが見えてキー入力が有効になるか」を決める。配置する際はプレイヤーが全身でこの範囲に入れることを確認し、中心点に届かないような狭い隙間に祭壇を押し込まないこと。
- 複数の祭壇を重ねる場合（二重スロットの祭壇のような使い方）、重ねたすべての祭壇の当たり判定範囲がプレイヤーの立つ地点を同時にカバーしている必要がある——最も簡単なのは、まったく同じ座標に配置し、デフォルトの 48×64 の範囲をそのまま使うことで、追加の調整は不要である。
- ヒントテキスト（`Hint`）は現状 `CanvasLayer` ではないため、同じ画面位置に配置された前景オブジェクトに隠れてしまうことがある（既知の問題、`DEV_STATUS.md` 第4節第3項を参照）。レベル設計時は、祭壇の真上に別の前景ギミックを重ねないよう注意すること。

---

## 5. 守るべき2つのハード制約

1. **GDD §5.4**：レベルが「`jump` を永久犠牲にして二重スロットと交換する」という方式（デフォルトの方式）を採用している場合、二重スロットの祭壇より先、クリアに至るまでの全区間で「ジャンプキーを押さなければ通れない」箇所があってはならない（重力反転を使ってすべての垂直移動をカバーする）。検証方法：`jump` を犠牲にした後、自分で最初から歩き直してクリアできることを確認する。
2. **GDD §7.7**：「キャラクターが青いオブジェクトの内部に埋まった状態で青を実体に戻さなければならない」パズルを設計しないこと——プレイヤーが壁の中に閉じ込められてしまう。自然なレベルの進み方ではこの境界にほぼ遭遇しない。「青い壁の中に入り込んでから2を押す」というような解法をわざと設計しなければ問題ない。

---

## 6. 最小限のプレイ可能なレベルの組み立て例

ゼロから始めて、この手順どおりに進めれば動くようになる：

1. 新しいシーンを作成し、ルートノードを `Node2D` にする。名前は何でもよい（例：`MyRoom`）。
2. `Ground.tscn` のインスタンスを地面としてドラッグし、`position = (0, 300)` あたりに配置し、`size` を `(600, 40)` に設定する。
3. `Player.tscn` のインスタンスをドラッグし、地面のすぐ上、例えば `position = (-200, 260)` に配置する。
4. `SacrificeInput.tscn` のインスタンスをドラッグする（位置はどこでもよい。何も表示されない）。
5. `HUD.tscn` のインスタンスをドラッグする。
6. `RestartController.tscn` のインスタンスをドラッグする。
7. `Altar.tscn` のインスタンスをドラッグし、地面の上、プレイヤーが歩いて行ける位置に配置する。`Action` を `UNLOCK` に、`Concept Id` を `"blue"` に、`Message` にはヒント文、例えば `"Press E to Sacrifice Blue"` を入力する。
8. `BlueObject.tscn` のインスタンスをドラッグし、祭壇の前方に置いて先へ進めないようにふさぐ。`Scale` を縦に伸ばして壁のようにする。
9. F5（または「現在のシーンを実行」）を押す：左右移動とジャンプができるはず。祭壇まで歩いて `interact` を押すと `blue` が解禁される。2 を押すと切り替わり、青い壁が半透明になって通り抜けられるようになる。R を押すとリスタートできる。

これが最小のループである：地面 + プレイヤー + 祭壇1つ + ギミック1つ。この上にさらに祭壇/ギミック/`Ground` を積み重ねてエリアを組み立てれば、それが完全なレベルの作り方になる——同じプレハブを使って組み立てられた完全な R1→R6 のレベルについては `scenes/Level1.tscn` を参照。
