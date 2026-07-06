# 如何快速搭一个可玩关卡

给不熟代码的关卡设计者（C）看的教程。所有东西都通过 Inspector 配置，不需要改脚本。设计权威是 `GDD.md`，本文件只讲"怎么用现有预制体拼出来"。

---

## 1. 一个可玩关卡最少需要什么

新建一个 `Node2D` 作为根节点（关卡的场景根），往下面拖这些东西：

| 必需程度 | 节点 | 说明 |
|---|---|---|
| 必需 | 若干 `Ground.tscn` 实例 | 至少要有能站的地面，玩家才不会一直下坠。 |
| 必需 | 1 个 `Player.tscn` 实例 | 摆在地面上方一点（别嵌进地面里）。 |
| 必需 | 1 个 `SacrificeInput.tscn` 实例 | 没有它，数字键切换牺牲不会响应。 |
| 强烈建议 | 1 个 `HUD.tscn` 实例 | 没有它玩家看不到槽位/图标状态（GDD §4.1 硬性要求）。 |
| 按需 | 若干 `Altar.tscn` 实例 | 关卡的谜题/进度都靠它触发。 |
| 按需 | 若干 `BlueObject.tscn`（或复制品）| 蓝墙、蓝平台之类的反应式机关。 |
| 按需 | 1 个 `RestartController.tscn` 实例 | **不放这个，该关卡按 R 键不会重开**。单场景项目里通常每个可运行的场景放一个。 |
| 按需（fourthwall 结局关） | 1 个 `EndingSequence.tscn` 实例 | 只有走到 `fourthwall` 祭坛的那个关卡/区域需要。 |

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

| `Action` | 效果 | 还要填什么 |
|---|---|---|
| `UNLOCK` | 解锁一个概念，让它能被数字键切换 | `Concept Id`（如 `"gravity"`）、`Message`（提示文案） |
| `SET_SLOTS` | 把槽位数改成 `Slot Count` | `Slot Count`（通常填 2）、`Message` |
| `PERMANENT_SACRIFICE` | 永久牺牲一个概念（不可逆） | `Concept Id`（如 `"jump"`）、`Message` |

- `One Shot` 默认打开：触发一次后这个祭坛不再显示提示、也不再响应。
- **双槽神龛怎么叠**：在同一个坐标摆两个 `Altar.tscn` 实例，一个设 `Action=SET_SLOTS`、`Slot Count=2`，另一个设 `Action=PERMANENT_SACRIFICE`、`Concept Id="jump"`。玩家站在范围内按一次 `interact`，两个祭坛会同时触发（它们各自独立监听同一次按键）。
- 提示文字（`Hint`）是祭坛自带的子节点，不用另外加，内容就是 `Message` 字段。

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

这就是一个最小闭环：地面 + 玩家 + 一个祭坛 + 一个机关。往上叠加更多祭坛/机关/`Ground` 拼区域，就是完整关卡的搭法——参考 `scenes/IntegrationLevel.tscn` 看一条完整的 R1→R6 关卡是怎么用同样的预制体拼起来的。
