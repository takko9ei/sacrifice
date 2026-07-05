# DEV_STATUS.md —《牺牲》当前开发状态快照

> **本文件记录的是"实际代码里现在是什么样"，不是 GDD 的理想设计。**
> 设计以 `GDD.md` 为准，协作铁律以 `CLAUDE.md` 为准，**开发进度以本文件为准**。
> 每次推进一步/做完一次改动，请更新本文件对应章节，让下一个接手的人（人类或 AI）不用翻代码就能知道现状。

## 0. 项目一句话简介 + 文档索引

《牺牲》是一个 Godot 4.x 的"减法银河城"：玩家通过永久或暂时牺牲抽象概念（重力、颜色"蓝"、跳跃、HUD、暂停、第四面墙……）来打通原本过不去的地方，越往后玩得到的东西越少，但能去的地方越多。

- **`GDD.md`** —— 唯一设计权威。讲"应该是什么"。
- **`DEV_PLAN_CORE.md`** —— 开发步骤划分（步骤一~六）。讲"按什么顺序做"。
- **`CLAUDE.md`** —— AI 协作铁律（禁止 git、禁止碰 Project Settings、架构铁律等）。讲"AI 能做什么、不能做什么"。
- **`DEV_STATUS.md`**（本文件）—— 讲"现在实际做到哪、实际长什么样、有什么坑"。

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
- 切换反馈：`HUD.tscn` 的 `FlashOverlay`（白色半透明 ColorRect）每次切换闪一下（`hud.gd::_play_flash()`），并留了 `_play_toggle_sfx_hook()` 空函数等步骤六接音效。

### 步骤三 · 祭坛系统 + 解锁 + 双槽 + 永久牺牲 jump —— ✅ 完成
- 概念默认全部锁定（`Sacrifice._unlocked` 为空字典）；`sacrifice_input.gd` 只对 `Sacrifice.is_unlocked(id)` 为真的概念放行切换。
- `Altar.tscn`（`Area2D`，碰撞层 0 / mask 2，只与玩家层碰撞）三种 `Action`：`UNLOCK` / `SET_SLOTS` / `PERMANENT_SACRIFICE`，全部 Inspector 配置，无需改代码。
- **交互确认模型**（步骤三后半段追加的需求，非最初步骤三草案）：进入祭坛范围只显示提示（`Hint` Label），必须按 `interact`（E）才真正触发 `Sacrifice` 指令；`one_shot` 祭坛触发过一次后既不再显示提示也不再响应。两个祭坛可叠放在同一位置各自独立触发（双槽神龛用的就是这个：`AltarDoubleSlots`(`SET_SLOTS`=2) + `AltarSacrificeJump`(`PERMANENT_SACRIFICE jump`) 叠在同一坐标）。
- 永久牺牲 `jump` 后，`player.gd::_update_timers()` 里 `Input.is_action_just_pressed("jump") and not Sacrifice.is_permanently_sacrificed("jump")` 这个条件会让跳跃缓冲永远清零，跳跃键从此静默失效（不报错、不提示，符合"越拆越空"的调性）。

### 步骤四 · 三个 UI 牺牲（hud / pause / fourthwall）—— ✅ 完成，其中 hud 的效果**中途改过设计**
- **HUD**：`hud.gd`（挂在 `HUD.tscn`）从文字版换成图标版。`SlotsRow` 按 `Sacrifice.max_slots` 生成对应数量的槽位方块（填充色=已用，空色=未用）；`IconsRow` 每解锁一个概念加一个图标（灰=未激活，亮黄=激活中）；全部由 `concept_unlocked`/`concept_activated`/`concept_deactivated`/`slots_changed` 信号驱动，不查询之外的状态。
- **pause**：`pause_controller.gd`（挂在 `PauseController.tscn`，`process_mode = Always`）按 `pause`（Escape）真正暂停/恢复 `get_tree().paused`，暂停时显示"PAUSED"文字。永久牺牲 `pause` 后，暂停键只能"恢复"不能再次"暂停"（`_unhandled_input` 里 `elif not Sacrifice.is_permanently_sacrificed("pause")` 那一分支被跳过）。
  **实际现状 vs 设计意图的落差（未解决，见第 5 节）**：GDD §2.6 设计 `pause` 是双槽升级的"备选价格"（和永久牺牲 `jump` 二选一），但代码里 `AltarPause` 是一个完全独立的测试祭坛，牺牲后**没有任何游戏内收益**，也没有和 `Sacrifice.set_max_slots()` 挂钩——`jump` 目前是全项目唯一真正生效的双槽代价。
- **hud（界面坍塌）——⚠️ 设计中途改过，当前实现是"图标坠落变平台"，不是最初的"观测坍缩机关"**：
  - **旧设计（已完全退役、代码已删除）**：一种叫"观测坍缩机关"的门——牺牲 `hud` 前是实体挡路，牺牲后变可穿过。对应的 `scripts/observation_gate.gd` 和 `scenes/ObservationGate.tscn` 已被删除，所有场景引用已清空。
  - **新设计（当前实际实现）**：`hud_collapse_platforms.gd`（挂在 `HudCollapsePlatforms.tscn`，纯 `Node2D`）监听 `Sacrifice.concept_permanently_sacrificed`，收到 `id == "hud"` 时，遍历自己所有 `Marker2D` 子节点，在每个 Marker2D 的位置用代码现造一个 `StaticBody2D`（碰撞层 1，矩形碰撞体+同尺寸 `Polygon2D` 视觉），从 `目标位置 + Vector2(0, -drop_height)` 用 Tween（`TRANS_QUAD`/`EASE_IN`）坠落到目标位置——效果是"HUD 图标砸进关卡变成几块可踩的实体平台"。落点完全由在编辑器里加/挪 `Marker2D` 子节点配置，脚本里没有任何写死坐标。
    同时 `hud.gd::_on_permanently_sacrificed()` 在 `id == "hud"` 时用 Tween 把 `Layout`（图标+槽位那一整块 UI）淡出并隐藏——`FlashOverlay` 故意不受影响，因为 GDD §5.5 要求牺牲 hud 后玩家仍能靠"记忆+屏幕反馈（切换闪光）"操作。
  - 目前**唯一**演示这个机制的关卡是 `IntegrationLevel.tscn`（R3 区域，`x≈800~820`）：一段 190px 高、单纯跳跃/翻转够不到的落差，旁边 `AltarHud`（`PERMANENT_SACRIFICE hud`）触发后，`HudCollapsePlatforms` 的两个 `Marker2D`（`Drop1`/`Drop2`）依次坠落生成台阶，配合已有的 `HudLedge` 组成一段可踩上去的三级台阶。**`TestRoom.tscn`（当前实际主场景，见第 7 节）完全没有这个演示**，只在 `IntegrationLevel.tscn` 里能玩到。
- **fourthwall（结局）**：`ending_sequence.gd`（挂在 `EndingSequence.tscn`，`layer = 10`，`process_mode = Always`）监听 `concept_permanently_sacrificed`，`id == "fourthwall"` 时：`get_tree().paused = true` → 用一条 Tween 序列依次淡出 HUD（`hud_fade_target_path` 在场景里手动接到 `../HUD/Layout`）→ 黑色 `Overlay` 淡入到 `dissolve_alpha`（0.85，未全黑）→ 文字 `Label`（默认"Thank you for playing."）淡入 → 停留 → 文字淡出的同时 `Overlay` 继续淡到全黑（并行）。全程纯视觉，不碰 OS 窗口。触发后游戏树整体暂停，但 `RestartController`（`process_mode = Always`）仍能响应 R 键重开。

### 步骤五 · 房间模板 + 单场景整合关 —— ✅ 完成（无房间切换系统，用户明确选择单场景方案）
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
| `pause_controller.gd` | `CanvasLayer`，`process_mode = Always` | 真暂停（`get_tree().paused`）+ `pause` 永久牺牲后暂停键失效。 |
| `ending_sequence.gd` | `CanvasLayer`，`process_mode = Always`，`layer = 10` | `fourthwall` 结局：HUD淡出→黑幕→文字→黑屏，纯视觉。 |
| `restart_controller.gd` | `Node`，`process_mode = Always` | 按 `restart`（R）：`Sacrifice.reset()` + 取消暂停 + 重载当前场景。 |
| `hud_collapse_platforms.gd` | `Node2D` | `hud` 永久牺牲后，按自己的 `Marker2D` 子节点位置各生成一个坠落的一次性实体平台。 |
| `room_template.gd` | `Node2D`，纯注释无逻辑 | 给 C 的房间搭建说明文档，挂在 `RoomTemplate.tscn` 上。 |

### `scenes/`
| 场景 | 结构 | 备注 |
|---|---|---|
| `Player.tscn` | `CharacterBody2D`(player.gd) > `CollisionShape2D` + `AnimatedSprite2D`(占位帧) + `Camera2D` | `config` 指向 `tuning/default.tres`；`collision_layer = 2`。⚠️ `sprite_path` 在场景文件里被序列化成字面 `null`，见第 5 节。 |
| `Altar.tscn` | `Area2D`(层0/mask2, altar.gd) > `CollisionShape2D`(48×64矩形) + `Visual`(黄色Polygon2D) + `Hint`(Label，默认隐藏) | 三种 Action 都靠这一个场景，Inspector 配置。 |
| `BlueObject.tscn` | `StaticBody2D`(层1, blue_object.gd) > `CollisionShape2D`(32×32) + `Visual`(蓝色Polygon2D) | `concept_id` 默认 `"blue"`，改这个字段即可复用给别的概念。 |
| `HUD.tscn` | `CanvasLayer`(hud.gd) > `Layout`(VBox) > `SlotsRow`+`IconsRow`(HBox)；`FlashOverlay`(ColorRect，兄弟节点) | |
| `PauseController.tscn` | `CanvasLayer`(process_mode=Always, pause_controller.gd) > `Label`("PAUSED"，默认隐藏) | |
| `EndingSequence.tscn` | `CanvasLayer`(layer=10, process_mode=Always, ending_sequence.gd) > `Overlay`(黑ColorRect) + `Label` | 每个关卡实例里手动把 `hud_fade_target_path` 接到该关卡自己的 `HUD/Layout`。 |
| `HudCollapsePlatforms.tscn` | 裸 `Node2D`(hud_collapse_platforms.gd)，无默认子节点 | 每个关卡实例自己加 `Marker2D` 子节点定落点。 |
| `RoomTemplate.tscn` | `Node2D`(room_template.gd) > `Ground` + `ExampleAltar` + `ExampleMechanism` | 给 C 的复制起点。 |
| `TestRoom.tscn` | 见下文"运行方式"，**当前项目实际的主场景** | 步骤一~四搭建的手感/机制测试房：`Ground`/`Ceiling`/`GroundExt`/`CeilingExt`/4个占位平台/`BlueWallMid`/2个`BluePlatform`/`AltarGravity`/`AltarBlue`/双槽神龛(`AltarDoubleSlots`+`AltarSacrificeJump`叠放)/`AltarPause`(独立测试祭坛，无实际收益)/`AltarFourthwall`/`SacrificeInput`/`RestartController`/`PauseController`/`HUD`/`EndingSequence`/`Player`。**不包含 hud 图标坠落平台演示。** |
| `IntegrationLevel.tscn` | 步骤五的 R1→R6 整合关，**当前不是主场景**，需手动在编辑器里打开运行 | 详见第 1 节步骤五描述。 |

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
8. 需要在 `get_tree().paused = true` 期间仍然工作的节点（`PauseController`、`EndingSequence`、`RestartController`），一律把 `process_mode` 设成 `3`（Always），这是全项目统一的"跨暂停存活"手法，别用其它方式（比如手动检测 paused 状态）绕过暂停系统。
9. 祭坛的落点/HUD坍塌平台落点等"关卡设计者需要摆放的位置"一律用 `Marker2D` 子节点或 Inspector 字段配置，脚本内不写死坐标（`hud_collapse_platforms.gd` 是这条约定的示范）。
10. AI 助手侧的铁律（来自 `CLAUDE.md`，重复强调）：禁止一切 git 操作；禁止修改 Project Settings（autoload/Input Map/主场景由人类手动配置）；只做当前 DEV_PLAN 步骤范围内的事。

---

## 4. 已知问题 / 临时处理 / 待办

1. **`sacrifice_input.gd` 的 UID 警告（低优先级，纯提示不影响功能）**：`TestRoom.tscn` 里对 `sacrifice_input.gd` 的 `ext_resource` 引用偶尔会被编辑器重新写回一个失效的 `uid=` 属性，导致控制台出现"invalid UID... using text path instead"警告。已排查过 `.uid` sidecar 文件和 `.godot/uid_cache.bin`，怀疑是编辑器进程内 `ResourceUID` 内存缓存的问题，"Reload Current Project"清不掉，理论上需要**完整退出并重启 Godot 编辑器**才能根治。游戏本身走文本路径 fallback 能正常加载，纯粹是控制台噪音。
2. **`Player.tscn` 里 `sprite_path` 被序列化成字面 `null`（未确认是否有实际影响）**：脚本里默认值是 `^"AnimatedSprite2D"`，但场景文件当前写的是 `sprite_path = null`（见 `Player.tscn` 第14行）。`player.gd::_ready()` 里 `_sprite = get_node(sprite_path) as AnimatedSprite2D`——如果这真的传入 null，`_sprite` 最终应该会是 `null`；后续 `_update_animation()` 已经有 `if _sprite == null: return` 的判空，动画部分调用点也都判空，所以**最坏情况是动画静默不播放，不会报错崩溃**。但从未针对这个具体字段专门做过验证，实际运行时是否受影响未知，建议下次打开编辑器时顺手在 Inspector 里确认一下 `Player.tscn` 的 `Sprite Path` 字段有没有正确指向 `AnimatedSprite2D`。
3. **祭坛的 `Hint` 提示没有强制置顶，可能被关卡里的前景物体遮挡**：`Hint` 是 `Altar.tscn` 里一个普通的 2D 场景树内 `Label`（悬浮在祭坛上方，`offset_top=-70`~`offset_bottom=-40`），不是 `CanvasLayer`，没有做 `z_index` 提升或独立 UI 层。如果某个房间设计恰好把别的前景物体叠在祭坛正上方同一屏幕位置，提示文字可能被视觉遮挡看不清。目前暂缓处理（Post-MVP 可考虑挪到 `CanvasLayer` 或加 `z_index`），关卡设计阶段（C 的工作）注意避开这种叠放即可绕开。
4. **`pause` 牺牲的设计意图与实际实现不一致，已两次提请用户决策，均未回复**：`GDD.md` §2.6（第116行）和 `DEV_PLAN_CORE.md` 步骤四（第123行）都写着 `pause` 应该是双槽升级的"备选价格"（与永久牺牲 `jump` 二选一，不能对同一次升级收两份价）。但 `TestRoom.tscn`/`IntegrationLevel.tscn` 里的 `AltarPause` 都是完全独立的测试祭坛，牺牲后只是让暂停键失效，**没有接入 `Sacrifice.set_max_slots()`，没有给任何双槽收益**——`jump` 是目前唯一真正生效的双槽代价。三个可选方向（改文档描述现实 / 真正把 pause 接成双槽的备选代价（需要写代码）/ 显式标成 TODO 留着）都还没有得到用户的选择，**在此之前不要擅自改动这部分代码或文档**。
5. **"进入祭坛先看提示、按 E 确认才触发"这个交互确认机制，`GDD.md` 完全没有记录**：`GDD.md` §3.1 的控制方案表里没有 `interact` 这一行，也没有任何地方描述这个"靠近显示提示→按键确认→才真正触发"的两段式交互（现在 `altar.gd` 的实际行为）；`DEV_PLAN_CORE.md` 步骤三的完成判定也只写了"靠近祭坛能看到操作提示文字"，没提确认按键这一步。这个问题在此前已经提请用户决策（是否要把 `interact`/`pause` 键位补进 GDD §3.1 控制表），**用户尚未回复，在收到回复前不要自行改 GDD.md**。
6. **`IntegrationLevel.tscn` 目前不是项目主场景**：`project.godot` 的 `run/main_scene` 仍指向 `TestRoom.tscn`（`uid://bvdur1gdqu4xr`），步骤五原计划是把主场景切到 `IntegrationLevel.tscn`，但按 `CLAUDE.md` 铁律这类 Project Settings 改动只能由人类在编辑器里手动做，AI 没有替用户做这一步。**现状是按 F5 跑的是 `TestRoom.tscn`，要玩步骤五的完整 R1→R6 关卡（含 hud 演示）得在编辑器里手动打开 `IntegrationLevel.tscn` 再单独运行（F6/"运行当前场景"）。**
7. **`observation_gate.gd`/`ObservationGate.tscn`（旧的"观测坍缩机关"）已彻底删除**：不是待办，只是记录一下——这两个文件已被删除，`TestRoom.tscn`/`IntegrationLevel.tscn`/`room_template.gd` 里所有引用都已清空，已用 grep 确认项目内 0 处残留引用（`GDD.md`/`DEV_PLAN_CORE.md` 里的历史提法也已全部替换成新的"界面坍塌"描述）。如果哪天又在哪见到这两个名字，那是没清干净，需要处理。

---

## 5. 下一步要做什么

**当前进度：步骤五（含步骤五后的 hud 机制重做）已完成，尚未开始步骤六。**

**步骤六（音频钩子 + 打磨 + 交接打包）待办内容**：
- 一个简单的 `AudioManager`：牺牲切换音、落地音、祭坛触发音、一首 BGM。
- 预留 `sound` 概念以后要用的"全局静音"钩子（给 B 接，本项目目前完全没有音频代码，`hud.gd::_play_toggle_sfx_hook()` 是目前唯一一个空音效钩子）。
- 反馈打磨一遍：切换染色、结局解体这些已有的观感效果过一遍看是否需要微调。
- 整理交接文档包（见下）。

**开始步骤六之前，建议先解决第 4 节里第 4、5 两条悬而未决的问题**（pause 定价方式、interact 机制要不要补进 GDD），因为交接文档要如实描述这些机制，模糊状态会让 B/C 接手时更困惑。

**交给 B（gimmick/机关，扩展新概念）需要准备好**：
- 两个可直接复制的反应式物体样板：`BlueObject.tscn`（切换碰撞+透明度型）和 `HudCollapsePlatforms.tscn`（牺牲时生成几何型）。
- 一段"如何加一个新概念"的说明：复制样板→改 `concept_id`→摆一个 `UNLOCK` 类型的 `Altar`→在 `SacrificeInput.bindings` 里加一行绑键。
- 明确储备概念（`friction`/`time`/`sound`）由 B 实现，可复用上面两个样板的模式。
- 预留的 `sound` 全局静音钩子位置（步骤六才会真正建好，目前只有 `hud.gd` 里一个空函数占位）。

**交给 C（地图/关卡设计）需要准备好**：
- `RoomTemplate.tscn` + `room_template.gd` 的用法说明（已经写好在脚本注释里）。
- `Altar.tscn` 三种 `Action` 的 Inspector 配置方法。
- 一条可参考的完整关卡：`IntegrationLevel.tscn`（注意：目前需要手动在编辑器打开运行，不是按 F5 就能玩到）。
- 两条必须遵守的硬约束：GDD §5.4（牺牲 `jump` 换双槽之后，到通关全程不能要求玩家按跳）和 GDD §8.7（不要设计"要在蓝墙内部恢复蓝"这种谜题）。

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
| `pause` | Escape |
| `restart` | R |

### 主场景
`project.godot` 的 `run/main_scene = "uid://bvdur1gdqu4xr"`，对应 **`scenes/TestRoom.tscn`**（不是 `IntegrationLevel.tscn`，见第4节第6条）。按 F5 实际跑的是这个步骤一~四搭建的测试房，能体验 gravity/blue/双槽神龛/永久牺牲jump/pause独立测试/fourthwall结局，**不包含 hud 图标坠落平台的演示**。要玩步骤五的 R1→R6 整合关（含 hud 演示），需要在编辑器里手动打开 `IntegrationLevel.tscn` 并单独运行。

### autoload
`Sacrifice = "*uid://10vfev3uue5r"`，对应 `scripts/sacrifice_manager.gd`。

### 按 R 重开
`restart_controller.gd`（`process_mode = Always`，两个场景里都有实例）监听 `restart` 动作：调用 `Sacrifice.reset()`（清空所有已解锁/激活/永久牺牲的概念，槽位复位为1）→ `get_tree().paused = false`（防止在暂停或结局黑屏状态下卡死）→ `get_tree().reload_current_scene()`。因为 `Sacrifice` 是 autoload、`paused` 是 SceneTree 级别标记，两者都不会随场景重载自动重置，所以这两步是必须的，不能省。暂停中、结局播放中都能按 R 重开。
