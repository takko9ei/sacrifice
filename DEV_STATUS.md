# DEV_STATUS.md —《牺牲》当前开发状态快照

> **本文件记录的是"实际代码里现在是什么样"，不是 GDD 的理想设计。**
> 设计以 `GDD.md` 为准，协作铁律以 `CLAUDE.md` 为准，**开发进度以本文件为准**。
> 每次推进一步/做完一次改动，请更新本文件对应章节，让下一个接手的人（人类或 AI）不用翻代码就能知道现状。

## 0. 项目一句话简介 + 文档索引

《牺牲》是一个 Godot 4.x 的"减法银河城"：玩家通过永久或暂时牺牲抽象概念（重力、颜色"蓝"、跳跃、HUD、第四面墙……）来打通原本过不去的地方，越往后玩得到的东西越少，但能去的地方越多。

- **`GDD.md`** —— 唯一设计权威。讲"应该是什么"。
- **`DEV_PLAN_CORE.md`** —— 开发步骤划分（步骤一~六）。讲"按什么顺序做"。
- **`CLAUDE.md`** —— AI 协作铁律（禁止 git、禁止碰 Project Settings、架构铁律等）。讲"AI 能做什么、不能做什么"。
- **`DEV_STATUS.md`**（本文件）—— 讲"现在实际做到哪、实际长什么样、有什么坑"。
- **`scenes/HOW_TO_BUILD_A_LEVEL.md`** —— 给关卡设计者（C）的搭建教程，讲"怎么用现有预制体拼一个可玩关卡"。

---

## 1. 已完成的功能（对应 DEV_PLAN 步骤一 → 五，含步骤五后的一次追加改动）

### 步骤一 · 项目落地 + 手感打磨 —— ✅ 完成
- `Player.tscn`（CharacterBody2D + CollisionShape2D + AnimatedSprite2D 占位帧 + Camera2D）可复用预制体。
- 手感数值全部来自 `tuning/default.tres`（`PlayerConfig` 资源），无硬编码。**注意：`default.tres` 里 `jump_height` 被手动改成了 `74.0`，脚本默认值 `64.0` 只是兜底，实际手感以 74.0 为准。**
- 实际行为：左右移动带地面/空中加速度和摩擦力区分；分离重力跳跃（上升/下降重力不同）；土狼时间；跳跃缓冲；按住跳更高、松手提前截断（可变跳跃高度）；idle/run/jump/fall 四态动画按 `is_on_floor()` 和速度方向切换。

### 步骤二 · gravity + blue 可逆牺牲 —— ✅ 完成
- 按 1 切换 `gravity`：`Player.up_direction` 在 `Vector2.DOWN`/`Vector2.UP` 间翻转，精灵 `flip_v` 同步，天花板变"地板"，跳跃方向自动跟着翻转方向走（`_gravity_sign()` 统一处理，物理代码不区分正常/翻转）。
- 按 2 切换 `blue`：`BlueObject`（`StaticBody2D` + `blue_object.gd`）监听 `Sacrifice` 信号，被激活时碰撞禁用（`set_deferred`）+ 半透明；恢复时反之。
- 单槽约束：`Sacrifice.activate()` 在 `_active.size() >= max_slots` 时把最早激活的挤掉，`gravity`/`blue` 天然互斥（初始 `max_slots = 1`）。
- 切换反馈：`HUD.tscn` 的 `FlashOverlay`（白色半透明 ColorRect）每次切换闪一下（`hud.gd::_play_flash()`）。

### 步骤三 · 祭坛系统 + 解锁 + 双槽 + 永久牺牲 jump —— ✅ 完成
- 概念默认全部锁定（`Sacrifice._unlocked` 为空字典）；`sacrifice_input.gd` 只对 `Sacrifice.is_unlocked(id)` 为真的概念放行切换。
- `Altar.tscn`（`Area2D`，碰撞层 0 / mask 2，只与玩家层碰撞）三种 `Action`：`UNLOCK` / `SET_SLOTS` / `PERMANENT_SACRIFICE`，全部 Inspector 配置，无需改代码。
- **交互确认模型**（步骤三后半段追加的需求，非最初步骤三草案）：进入祭坛范围只显示提示（`Hint` Label），必须按 `interact`（E）才真正触发 `Sacrifice` 指令；`one_shot` 祭坛触发过一次后既不再显示提示也不再响应。两个祭坛可叠放在同一位置各自独立触发（双槽神龛用的就是这个：`AltarDoubleSlots`(`SET_SLOTS`=2) + `AltarSacrificeJump`(`PERMANENT_SACRIFICE jump`) 叠在同一坐标）。
- 永久牺牲 `jump` 后，`player.gd::_update_timers()` 里 `Input.is_action_just_pressed("jump") and not Sacrifice.is_permanently_sacrificed("jump")` 这个条件会让跳跃缓冲永远清零，跳跃键从此静默失效（不报错、不提示，符合"越拆越空"的调性）。

### 步骤四 · 两个 UI 牺牲（hud / fourthwall）—— ✅ 完成，其中 hud 的效果**中途改过设计**；`pause` 牺牲已整体删除
- **pause 现状（重要）**：`pause` 曾经是第三个 UI 牺牲（独立测试祭坛，牺牲后让 Escape 失效，但从未真正接入双槽升级），已被**整体删除**——`pause_controller.gd`/`PauseController.tscn` 已删文件，`TestRoom.tscn` 里的 `AltarPause`/`PauseController` 节点已移除，`GDD.md`/`DEV_PLAN_CORE.md` 里所有相关描述已同步删掉。现在项目里**没有任何暂停功能**，Escape 键不绑定任何逻辑。唯一残留：`project.godot` 的 Input Map 里 `pause`（Escape）这个动作定义还留着但无人监听，因为改 Project Settings 不在 AI 权限内（见第4节第6条）。
- **HUD**：`hud.gd`（挂在 `HUD.tscn`）从文字版换成图标版。`SlotsRow` 按 `Sacrifice.max_slots` 生成对应数量的槽位方块（填充色=已用，空色=未用）；`IconsRow` 每解锁一个概念加一个图标（灰=未激活，亮黄=激活中）；全部由 `concept_unlocked`/`concept_activated`/`concept_deactivated`/`slots_changed` 信号驱动，不查询之外的状态。
- **hud（界面坍塌）——⚠️ 设计中途改过，当前实现是"图标坠落变平台"，不是最初的"观测坍缩机关"**：
  - **旧设计（已完全退役、代码已删除）**：一种叫"观测坍缩机关"的门——牺牲 `hud` 前是实体挡路，牺牲后变可穿过。对应的 `scripts/observation_gate.gd` 和 `scenes/ObservationGate.tscn` 已被删除，所有场景引用已清空。
  - **新设计（当前实际实现）**：`hud_collapse_platforms.gd`（挂在 `HudCollapsePlatforms.tscn`，纯 `Node2D`）监听 `Sacrifice.concept_permanently_sacrificed`，收到 `id == "hud"` 时，遍历自己所有 `Marker2D` 子节点，在每个 Marker2D 的位置用代码现造一个 `StaticBody2D`（碰撞层 1，矩形碰撞体+同尺寸 `Polygon2D` 视觉），从 `目标位置 + Vector2(0, -drop_height)` 用 Tween（`TRANS_QUAD`/`EASE_IN`）坠落到目标位置——效果是"HUD 图标砸进关卡变成几块可踩的实体平台"。落点完全由在编辑器里加/挪 `Marker2D` 子节点配置，脚本里没有任何写死坐标。
    同时 `hud.gd::_on_permanently_sacrificed()` 在 `id == "hud"` 时用 Tween 把 `Layout`（图标+槽位那一整块 UI）淡出并隐藏——`FlashOverlay` 故意不受影响，因为 GDD §5.5 要求牺牲 hud 后玩家仍能靠"记忆+屏幕反馈（切换闪光）"操作。
  - 演示这个机制的关卡是 `IntegrationLevel.tscn`（R3 区域，`x≈800~820`）：一段 190px 高、单纯跳跃/翻转够不到的落差，旁边 `AltarHud`（`PERMANENT_SACRIFICE hud`）触发后，`HudCollapsePlatforms` 的两个 `Marker2D`（`Drop1`/`Drop2`）依次坠落生成台阶，配合已有的 `HudLedge` 组成一段可踩上去的三级台阶。`IntegrationLevel.tscn` 现在就是项目主场景，按 F5 可直接玩到。
- **fourthwall（结局）**：`ending_sequence.gd`（挂在 `EndingSequence.tscn`，`layer = 10`，`process_mode = Always`）监听 `concept_permanently_sacrificed`，`id == "fourthwall"` 时：`get_tree().paused = true` → 用一条 Tween 序列依次淡出 HUD（`hud_fade_target_path` 在场景里手动接到 `../HUD/Layout`）→ 黑色 `Overlay` 淡入到 `dissolve_alpha`（0.85，未全黑）→ 文字 `Label`（默认"Thank you for playing."）淡入 → 停留 → 文字淡出的同时 `Overlay` 继续淡到全黑（并行）。全程纯视觉，不碰 OS 窗口。触发后游戏树整体暂停，但 `RestartController`（`process_mode = Always`）仍能响应 R 键重开。

### 步骤五 · 房间模板 + 单场景整合关 —— ✅ 完成（无房间切换系统，用户明确选择单场景方案）
- **场景取舍决定（已执行完毕）**：`IntegrationLevel.tscn` 定为**唯一正式关卡**，以后要加内容一律在它上面加长/加区域（见 `DEV_PLAN_CORE.md` 步骤五的架构决定）。人工已把 `project.godot` 的 `run/main_scene` 改指向 `IntegrationLevel.tscn`（`uid://bkdctvarex6yi`），AI 随后删除了 `scenes/TestRoom.tscn` 并清理了代码里对它的注释引用（`restart_controller.gd`）。`TestRoom.tscn` 已不存在于项目中。
- `RoomTemplate.tscn` + 纯注释脚本 `room_template.gd`：给 C 的可复制样板，一个 `Ground`（`StaticBody2D`，层1）+ 一个 `ExampleAltar`（`Altar.tscn` 实例）+ 一个 `ExampleMechanism`（`BlueObject.tscn` 实例，纵向拉伸演示缩放用法）。脚本顶部注释写明"复制这个场景改坐标/改 concept_id 就是新房间，不要碰 sacrifice_manager.gd/altar.gd/blue_object.gd"。
- `IntegrationLevel.tscn`：单场景内用坐标区间划分 R1~R6，按 GDD §5.2 顺序串联：
  - **R1**（x≈-400~150）：`R1Ground` + `R1Ceiling`（间距 300px，超过跳跃高度，只能靠 `gravity` 翻转够到）+ `AltarGravity`。
  - **R2**（x≈150~450）：无地面层的竖直空当，`R2Ledge` 是一个悬空错位平台，逼玩家"翻转上升→走出平台边缘清空落脚点→继续上升→翻转回正常重力"这套操作；全场有一条 `SafetyFloor`（y=1000）兜底坠落。
  - **R3**（x≈450~900）：`R3Ground` + `AltarBlue` + `BlueWallR3`（纵向拉伸的蓝墙）；本区域内 x≈800~820 处新增 hud 演示 set-piece（见上文）。
  - **R4**（x≈900~1200）：`R4Ground` + 叠放的 `AltarDoubleSlots`（`SET_SLOTS 2`）+ `AltarSacrificeJump`（`PERMANENT_SACRIFICE jump`），双槽神龛。
  - **R5**（x≈1200~1350）：`LeftWallR5`/`RightWallR5` 围成竖井，三层 `BlueBarrier1/2/3` 横跨井道不同高度——单槽无法同时开 `gravity`+`blue`，必须先在 R4 拿到双槽才能同时开两者穿过。
  - **R6**：`R6Ground` 落脚平台 + `AltarFourthwall`（`PERMANENT_SACRIFICE fourthwall`）+ `EndingSequence` 实例。
  - 已人工逐房间走查确认：**R4 拿双槽之后，一路到 R6 全程不需要按跳跃键**（满足 GDD §5.4 硬约束）；R5 竖井内部地面高度没有实体地板，不翻转直接走进去只会掉进兜底安全网，不存在绕过谜题的路径。
  - **`IntegrationLevel.tscn` 有一些不是本次 AI 改动做的、后来被编辑器/人工调整过的痕迹**（本次核对时原样保留，未做任何还原）：所有节点补上了 `unique_id`；`SafetyFloor`/新增的 `SafetyFloor2`（在 R5/R6 上方 `y=-882` 处，同款兜底地板）；`LeftWallR5`/`RightWallR5` 的缩放比原计划略高（约 1.16 倍）；`AltarFourthwall` 的位置从原方案的 `y=-475` 挪到了 `y=-406`。这些都视为当前的真实/权威布局，不是待修的偏差。

### 步骤五后 · 预制体化整理 + 音频范围下线 + 文档一致性修正 —— ✅ 完成
- **音频彻底移出范围**：项目决定不做音频。移除了 `hud.gd` 里唯一的音频钩子 `_play_toggle_sfx_hook()`（此前是空函数占位，切换闪光效果本身不受影响）；`GDD.md`/`DEV_PLAN_CORE.md`/`DEV_STATUS.md` 里所有 AudioManager/BGM/音效/静音钩子相关的交付物、验收项、待办全部删除。**明确保留**：GDD `sound` 储备概念的设计文本（概念表格行、§7.6 扩展举例、附录索引）——那是"未来可能实现的静音玩法概念"的设计描述，不是音频实现，与本次范围变更无关。项目本身此前就没有任何 `AudioStreamPlayer` 节点或音频资源文件（已用 grep 全项目确认），所以这次改动几乎全是文档层面的清理。
- **三个新预制体，抽出此前内联在关卡里的对象**：
  - `Ground.tscn` + 新脚本 `ground.gd`（`@tool`，`StaticBody2D`）：地面/平台/天花板/墙通用预制体，`size`/`color` 两个导出属性驱动碰撞形状(`RectangleShape2D`)与可见多边形(`Polygon2D`)自动同步（`@tool` 使编辑器里改 `size` 立即看到效果；`_apply()` 每次都新建一个 `RectangleShape2D` 而不是复用共享的那份，避免多个实例互相污染碰撞尺寸）。`RoomTemplate.tscn` 和 `IntegrationLevel.tscn` 里原本 12 处手工维护的 `StaticBody2D`+`CollisionShape2D`+`Polygon2D` 三件套（`Ground`/`SafetyFloor`/`SafetyFloor2`/`R1Ground`/`R1Ceiling`/`R2Ledge`/`R3Ground`/`HudLedge`/`R4Ground`/`LeftWallR5`/`RightWallR5`/`R6Ground`）全部换成这个预制体的实例，尺寸/位置/缩放/颜色照抄原值，视觉与碰撞行为不变。`SafetyFloor`/`SafetyFloor2` 的 `Visual` 子节点原本带一个非对称的手工位置/缩放偏移（`position=(-40.999985,0)`、`scale=(1.337,1)`，人工在编辑器里调过，和碰撞形状不完全对齐但因为是屏幕外的兜底安全网从未被玩家看到），迁移时用子节点属性覆写原样保留了这个偏移，没有"顺手"抹平。
  - `SacrificeInput.tscn`：把此前只存在于 `IntegrationLevel.tscn` 内联的 `Node`+`sacrifice_input.gd` 抽成独立场景，`bindings` 字典导出不变。
  - `RestartController.tscn`：同样把内联的 `Node`+`restart_controller.gd`（`process_mode=Always`）抽成独立场景。
  - 三者都已在 `IntegrationLevel.tscn`/`RoomTemplate.tscn` 里换成实例引用；`room_template.gd` 顶部注释同步更新，不再描述"手工改 RectangleShape2D 和 Polygon2D"的旧流程。
  - `HudCollapsePlatforms.tscn` 经核对**已经满足**"可配置落点部件"的要求（落点靠关卡实例自己加的 `Marker2D` 子节点配置，`platform_size`/`color`/`drop_height`/`drop_duration` 已导出），本次未改动。
- **新增交接文档** `scenes/HOW_TO_BUILD_A_LEVEL.md`：面向不熟代码的关卡设计者，讲清楚一个可玩关卡最少需要什么、每个预制体怎么用、碰撞层设置、祭坛 interact 确认机制对摆放的影响、GDD §5.4/§7.7 两条硬约束，以及一个可以照抄的最小可玩关卡搭建示例。
- **GDD.md 章节重排**：删除 §7 音频整节后，原 §8~§11（技术架构/扩展接口/开发计划/内容素材清单）依次重编号为 §7~§10；同时补全了 §7.3 脚本清单表格里此前漏掉的 `ending_sequence.gd`/`restart_controller.gd`/`hud_collapse_platforms.gd`/`room_template.gd`（连同新增的 `ground.gd`），让架构权威表和实际实现对上。所有引用旧编号的地方（GDD 内部、`DEV_PLAN_CORE.md`、`DEV_STATUS.md`、`CLAUDE.md`、6 处脚本注释）已同步改号，逐一核对过没有遗漏。
- **清掉几处从未存在过的文件引用**：`DEV_PLAN_CORE.md` 曾引用 `PROJECT_SETUP.md`、`EXTENSION_GUIDE.md`、`Main.tscn`、`AI_CONTEXT.md` 四个名字，全项目搜索确认这些文件从未创建过——分别改成指向真实存在的文档或直接描述内容，不再点名不存在的文件。

（本条目记录的是步骤五完成之后、步骤六正式开始之前插入的一次范围变更+整理工作，不对应 DEV_PLAN 的某个具体步骤编号。）

---

## 2. 关键文件清单

### `scripts/`
| 文件 | 类型 | 职责 |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | 全局唯一牺牲状态与信号源。见下方"Sacrifice 公开接口"。 |
| `player_config.gd` | `Resource`，`class_name PlayerConfig` | 玩家手感数值容器（移动/跳跃/摩擦力/土狼/缓冲）。 |
| `player.gd` | `CharacterBody2D`，`class_name Player` | 移动+分离重力跳跃+`gravity` 牺牲响应（翻转 `up_direction`）+ 动画状态机。`class_name Player` 是特意加的，供 `altar.gd` 做 `body is Player` 判断。 |
| `blue_object.gd` | `StaticBody2D`（**无 class_name**，故意的，防止 B 复制改名时冲突） | 通用反应式物体样板：监听信号，按自己的 `concept_id` 切换碰撞禁用+透明度。`blue` 用它，B 加新概念也复制它改 `concept_id`。 |
| `sacrifice_input.gd` | `Node` | `@export var bindings: Dictionary` 把输入动作名映射到 concept_id，按键触发 `Sacrifice.toggle()`（仅对已解锁概念生效）。 |
| `altar.gd` | `Area2D`，`class_name Altar` | 通用祭坛：进入范围显示 `Hint` 提示，按 `interact`（E）才真正触发 `UNLOCK`/`SET_SLOTS`/`PERMANENT_SACRIFICE` 三种指令之一；`one_shot` 触发一次后不再显示/响应。 |
| `hud.gd` | `CanvasLayer` | 图标版状态显示（槽位+概念图标三态）+ 切换全屏闪光反馈 + 牺牲 `hud` 后的界面淡出解体。 |
| `ending_sequence.gd` | `CanvasLayer`，`process_mode = Always`，`layer = 10` | `fourthwall` 结局：HUD淡出→黑幕→文字→黑屏，纯视觉。 |
| `restart_controller.gd` | `Node`，`process_mode = Always` | 按 `restart`（R）：`Sacrifice.reset()` + 取消暂停 + 重载当前场景。 |
| `hud_collapse_platforms.gd` | `Node2D` | `hud` 永久牺牲后，按自己的 `Marker2D` 子节点位置各生成一个坠落的一次性实体平台。 |
| `ground.gd` | `StaticBody2D`，`@tool` | 可复用地面/平台几何块：`size`/`color` 两个导出属性驱动碰撞形状(`RectangleShape2D`)和可见多边形(`Polygon2D`)保持同步，编辑器里改 `size` 立即生效。挂在 `Ground.tscn` 上。 |
| `room_template.gd` | `Node2D`，纯注释无逻辑 | 给 C 的房间搭建说明文档，挂在 `RoomTemplate.tscn` 上。 |

### `scenes/`
| 场景 | 结构 | 备注 |
|---|---|---|
| `Player.tscn` | `CharacterBody2D`(player.gd) > `CollisionShape2D` + `AnimatedSprite2D`(占位帧) + `Camera2D` | `config` 指向 `tuning/default.tres`；`collision_layer = 2`。⚠️ `sprite_path` 在场景文件里被序列化成字面 `null`，见第 5 节。 |
| `Altar.tscn` | `Area2D`(层0/mask2, altar.gd) > `CollisionShape2D`(48×64矩形) + `Visual`(黄色Polygon2D) + `Hint`(Label，默认隐藏) | 三种 Action 都靠这一个场景，Inspector 配置。 |
| `BlueObject.tscn` | `StaticBody2D`(层1, blue_object.gd) > `CollisionShape2D`(32×32) + `Visual`(蓝色Polygon2D) | `concept_id` 默认 `"blue"`，改这个字段即可复用给别的概念。 |
| `HUD.tscn` | `CanvasLayer`(hud.gd) > `Layout`(VBox) > `SlotsRow`+`IconsRow`(HBox)；`FlashOverlay`(ColorRect，兄弟节点) | |
| `EndingSequence.tscn` | `CanvasLayer`(layer=10, process_mode=Always, ending_sequence.gd) > `Overlay`(黑ColorRect) + `Label` | 每个关卡实例里手动把 `hud_fade_target_path` 接到该关卡自己的 `HUD/Layout`。 |
| `HudCollapsePlatforms.tscn` | 裸 `Node2D`(hud_collapse_platforms.gd)，无默认子节点 | 每个关卡实例自己加 `Marker2D` 子节点定落点。 |
| `Ground.tscn` | `StaticBody2D`(层1, `ground.gd`) > `CollisionShape2D` + `Visual`(Polygon2D) | 通用地面/平台/天花板/墙预制体；`size`/`color` 导出，改 `size` 自动同步碰撞形状与可见多边形；用节点 `scale` 做整体拉伸。 |
| `SacrificeInput.tscn` | `Node`(sacrifice_input.gd) | 抽出的独立预制体，此前是各关卡内联的 `Node`+脚本；`bindings` 字典在 Inspector 可改。 |
| `RestartController.tscn` | `Node`(`process_mode=Always`, restart_controller.gd) | 抽出的独立预制体，此前是各关卡内联的 `Node`+脚本；无可调参数。 |
| `RoomTemplate.tscn` | `Node2D`(room_template.gd) > `Ground`(Ground.tscn 实例) + `ExampleAltar` + `ExampleMechanism` | 给 C 的复制起点。 |
| `IntegrationLevel.tscn` | 步骤五的 R1→R6 整合关，**当前项目实际的主场景**（见第 6 节"运行方式"） | 详见第 1 节步骤五描述。步骤一~四阶段曾用 `TestRoom.tscn` 作为手感/机制测试房，现已删除退役，测试与实际关卡都并入这一个场景。所有地面/平台/天花板/墙已改为 `Ground.tscn` 实例，`SacrificeInput`/`RestartController` 节点也已改为对应预制体实例（见第 1 节"预制体化整理"）。 |

### `Sacrifice` 单例公开接口（`scripts/sacrifice_manager.gd`，autoload 名必须精确是 `Sacrifice`）
```gdscript
# 信号
signal concept_activated(id: String)
signal concept_deactivated(id: String)
signal concept_unlocked(id: String)
signal slots_changed(new_slots: int)
signal concept_permanently_sacrificed(id: String)

# 状态（只读地对外暴露，写只能通过下面的函数）
var max_slots: int = 1

# 查询
func is_unlocked(id: String) -> bool
func is_active(id: String) -> bool
func is_permanently_sacrificed(id: String) -> bool
func get_active() -> Array[String]        # 返回副本
func get_unlocked() -> Array[String]

# 指令
func unlock(id: String) -> void                    # 幂等，重复调用不重复触发信号
func activate(id: String) -> void                  # 未解锁/已永久牺牲/已激活时静默忽略；超槽位时挤掉最早激活的
func deactivate(id: String) -> void
func toggle(id: String) -> void
func set_max_slots(n: int) -> void                  # 缩小槽位时挤掉多出来的（从最早激活开始）
func permanently_sacrifice(id: String) -> void      # 若当前激活先自动 deactivate，再标记永久
func reset() -> void                                # 清空所有状态、槽位复位为1，配合场景重载用
```

---

## 3. 当前架构约定 / 不变量（不能破坏）

1. 所有牺牲相关状态只存在 `Sacrifice` 单例（`sacrifice_manager.gd`）里；任何系统只通过它的信号/查询函数交互，**不建第二个全局状态**。
2. 玩家所有手感数值只来自 `PlayerConfig`（`tuning/default.tres`）；`player.gd` 里不许出现硬编码的移动/跳跃数字。
3. "会对牺牲做出反应的物体"统一模式：监听 `Sacrifice` 信号、过滤自己的 `concept_id`，参照 `blue_object.gd`；不要在 `Sacrifice` 单例里加针对具体物体的分支。`hud_collapse_platforms.gd` 是这个模式的第二个样板（响应方式是"生成几何"而非"切换几何"）。
4. 单槽/双槽/永久牺牲的规则只在 `Sacrifice` 单例内实现（`activate`/`set_max_slots`/`permanently_sacrifice`），别处不重写。
5. 碰撞层：世界实体（地形、`BlueObject`、hud 坍塌平台）= Layer 1；玩家 = Layer 2；`Altar` 是 `Area2D`，`collision_layer = 0` / `collision_mask = 2`（只检测玩家进入，不参与物理碰撞）。
6. autoload 名字必须精确是 `Sacrifice`（大写 S），当前 `project.godot` 里是 `Sacrifice="*uid://10vfev3uue5r"`，对应 `sacrifice_manager.gd`。
7. `Player` 有 `class_name Player`，专供 `altar.gd` 等做 `body is Player` 类型判断；反之 `blue_object.gd` 这类"物体侧"脚本故意不加 `class_name`，避免 B 复制粘贴改名时产生同名类冲突。
8. 需要在 `get_tree().paused = true` 期间仍然工作的节点（`EndingSequence`、`RestartController`），一律把 `process_mode` 设成 `3`（Always），这是全项目统一的"跨暂停存活"手法，别用其它方式（比如手动检测 paused 状态）绕过暂停系统。
9. 祭坛的落点/HUD坍塌平台落点等"关卡设计者需要摆放的位置"一律用 `Marker2D` 子节点或 Inspector 字段配置，脚本内不写死坐标（`hud_collapse_platforms.gd` 是这条约定的示范）。
10. AI 助手侧的铁律（来自 `CLAUDE.md`，重复强调）：禁止一切 git 操作；禁止修改 Project Settings（autoload/Input Map/主场景由人类手动配置）；只做当前 DEV_PLAN 步骤范围内的事。

---

## 4. 已知问题 / 临时处理 / 待办

1. **`sacrifice_input.gd` 的 UID 警告（低优先级，纯提示不影响功能）**：`SacrificeInput.tscn` 里对 `sacrifice_input.gd` 的 `ext_resource` 引用偶尔会被编辑器重新写回一个失效的 `uid=` 属性，导致控制台出现"invalid UID... using text path instead"警告。已排查过 `.uid` sidecar 文件和 `.godot/uid_cache.bin`，怀疑是编辑器进程内 `ResourceUID` 内存缓存的问题，"Reload Current Project"清不掉，理论上需要**完整退出并重启 Godot 编辑器**才能根治。游戏本身走文本路径 fallback 能正常加载，纯粹是控制台噪音。
2. **`Player.tscn` 里 `sprite_path` 被序列化成字面 `null`（未确认是否有实际影响）**：脚本里默认值是 `^"AnimatedSprite2D"`，但场景文件当前写的是 `sprite_path = null`（见 `Player.tscn` 第14行）。`player.gd::_ready()` 里 `_sprite = get_node(sprite_path) as AnimatedSprite2D`——如果这真的传入 null，`_sprite` 最终应该会是 `null`；后续 `_update_animation()` 已经有 `if _sprite == null: return` 的判空，动画部分调用点也都判空，所以**最坏情况是动画静默不播放，不会报错崩溃**。但从未针对这个具体字段专门做过验证，实际运行时是否受影响未知，建议下次打开编辑器时顺手在 Inspector 里确认一下 `Player.tscn` 的 `Sprite Path` 字段有没有正确指向 `AnimatedSprite2D`。
3. **祭坛的 `Hint` 提示没有强制置顶，可能被关卡里的前景物体遮挡**：`Hint` 是 `Altar.tscn` 里一个普通的 2D 场景树内 `Label`（悬浮在祭坛上方，`offset_top=-70`~`offset_bottom=-40`），不是 `CanvasLayer`，没有做 `z_index` 提升或独立 UI 层。如果某个房间设计恰好把别的前景物体叠在祭坛正上方同一屏幕位置，提示文字可能被视觉遮挡看不清。目前暂缓处理（Post-MVP 可考虑挪到 `CanvasLayer` 或加 `z_index`），关卡设计阶段（C 的工作）注意避开这种叠放即可绕开。
4. **（已解决）主场景已切到 `IntegrationLevel.tscn`，`TestRoom.tscn` 已退役删除**：不是待办，只是记录一下——人工已把 `project.godot` 的 `run/main_scene` 改为 `IntegrationLevel.tscn`（`uid://bkdctvarex6yi`），AI 随后删除了 `scenes/TestRoom.tscn` 并清理了代码注释里的引用（`restart_controller.gd`）。现在按 F5 直接跑的就是完整的 R1→R6 整合关，含 hud 演示，不再需要手动在编辑器打开单独运行。如果哪天又在项目里看到 `TestRoom.tscn` 或对它的引用，说明清理不完整，需要处理。
5. **`observation_gate.gd`/`ObservationGate.tscn`（旧的"观测坍缩机关"）已彻底删除**：不是待办，只是记录一下——这两个文件已被删除，`TestRoom.tscn`/`IntegrationLevel.tscn`/`room_template.gd` 里所有引用都已清空，已用 grep 确认项目内 0 处残留引用（`GDD.md`/`DEV_PLAN_CORE.md` 里的历史提法也已全部替换成新的"界面坍塌"描述）。如果哪天又在哪见到这两个名字，那是没清干净，需要处理。
6. **`pause` 牺牲玩法已整体删除，但 Input Map 里的 `pause`（Escape）动作定义还留着**：`pause_controller.gd`/`PauseController.tscn` 已删除，`TestRoom.tscn` 的 `AltarPause`/`PauseController` 节点也已移除，`GDD.md`/`DEV_PLAN_CORE.md` 里所有 `pause` 相关描述已同步删掉。但 `project.godot` 的 Input Map 仍定义着 `pause`（Escape）这个动作——按 `CLAUDE.md` 铁律，Project Settings 只能由人类在编辑器里手动改，AI 不能删。**这是一个预期内的、无害的孤立绑定：现在没有任何脚本监听它，按 Escape 不会有任何反应。** 如果人类想彻底清掉，需要自己去编辑器的 Input Map 面板删除这一行。

---

## 5. 下一步要做什么

**当前进度：步骤五（含步骤五后的 hud 机制重做）已完成，尚未开始步骤六。**

**步骤六（打磨 + 交接打包）待办内容**：
- 反馈打磨一遍：切换染色、结局解体这些已有的观感效果过一遍看是否需要微调。
- 整理交接文档包（见下）。

**交给 B（gimmick/机关，扩展新概念）需要准备好**：
- 两个可直接复制的反应式物体样板：`BlueObject.tscn`（切换碰撞+透明度型）和 `HudCollapsePlatforms.tscn`（牺牲时生成几何型）。
- 一段"如何加一个新概念"的说明：复制样板→改 `concept_id`→摆一个 `UNLOCK` 类型的 `Altar`→在 `SacrificeInput.bindings` 里加一行绑键。
- 明确储备概念（`friction`/`time`/`sound`）由 B 实现，可复用上面两个样板的模式。

**交给 C（地图/关卡设计）需要准备好**：
- `RoomTemplate.tscn` + `room_template.gd` 的用法说明，以及更完整的 `scenes/HOW_TO_BUILD_A_LEVEL.md` 搭建教程（已交付，见第 2 节场景清单）。
- `Ground.tscn`/`SacrificeInput.tscn`/`RestartController.tscn` 三个新抽出的预制体，用法见 `HOW_TO_BUILD_A_LEVEL.md`。
- `Altar.tscn` 三种 `Action` 的 Inspector 配置方法。
- 一条可参考的完整关卡：`IntegrationLevel.tscn`（现在就是项目主场景，按 F5 直接玩到）。
- 扩展关卡的方向：在 `IntegrationLevel.tscn` 这同一个场景里加长/加区域，而不是拆成多个用切换连接的独立场景——项目已正式放弃房间切换系统方案（见 `DEV_PLAN_CORE.md` 步骤五）。
- 两条必须遵守的硬约束：GDD §5.4（牺牲 `jump` 换双槽之后，到通关全程不能要求玩家按跳）和 GDD §7.7（不要设计"要在蓝墙内部恢复蓝"这种谜题）。

---

## 6. 输入映射与运行方式

### Input Map（`project.godot` 当前实际配置）
| 动作名 | 绑定键 |
|---|---|
| `move_left` | A |
| `move_right` | D |
| `jump` | Space |
| `sacrifice_gravity` | 1 |
| `sacrifice_blue` | 2 |
| `interact` | E |
| `restart` | R |

### 主场景
`project.godot` 的 `run/main_scene = "uid://bkdctvarex6yi"`，对应 **`scenes/IntegrationLevel.tscn`**。按 F5 实际跑的就是步骤五的完整 R1→R6 整合关，涵盖 gravity/blue/双槽神龛/永久牺牲jump/hud 图标坠落平台演示/fourthwall结局全部机制。`TestRoom.tscn`（步骤一~四阶段的手感/机制测试房）已退役删除。

### autoload
`Sacrifice = "*uid://10vfev3uue5r"`，对应 `scripts/sacrifice_manager.gd`。

### 按 R 重开
`restart_controller.gd`（`process_mode = Always`，通过 `RestartController.tscn` 实例挂在当前主场景 `IntegrationLevel.tscn` 里）监听 `restart` 动作：调用 `Sacrifice.reset()`（清空所有已解锁/激活/永久牺牲的概念，槽位复位为1）→ `get_tree().paused = false`（防止在结局黑屏状态下卡死）→ `get_tree().reload_current_scene()`。因为 `Sacrifice` 是 autoload、`paused` 是 SceneTree 级别标记，两者都不会随场景重载自动重置，所以这两步是必须的，不能省。结局播放中也能按 R 重开。
