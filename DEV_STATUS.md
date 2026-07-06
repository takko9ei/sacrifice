# DEV_STATUS.md — Current Development Status Snapshot for 《Sacrifice》

> **This file records "what the code actually looks like right now," not the GDD's ideal design.**
> Design follows `GDD.md`; collaboration hard rules follow `CLAUDE.md`; **development progress follows this file.**
> Every time a step is advanced or a change is completed, update the corresponding section of this file so the next person who picks this up (human or AI) can know the current state without digging through the code.

## 1. One-Sentence Project Summary + Doc Index

《Sacrifice》 is a Godot 4.x "subtractive Metroidvania": the player permanently or temporarily sacrifices abstract concepts (gravity, the color "blue," jump, the HUD, the fourth wall…) to get through places that were otherwise impassable — the further you play, the less you have, but the more places you can reach.

- **`GDD.md`** — the sole design authority. Describes "what it should be."
- **`DEV_PLAN_CORE.md`** — the breakdown of development steps (Steps 1–6). Describes "what order to build things in."
- **`CLAUDE.md`** — AI collaboration hard rules (no git, no touching Project Settings, architectural hard rules, etc.). Describes "what the AI can and can't do."
- **`DEV_STATUS.md`** (this file) — describes "how far things have actually gotten, what it actually looks like, and what the gotchas are."
- **`scenes/HOW_TO_BUILD_A_LEVEL.md`** — a build tutorial for the level designer (C), explaining "how to assemble a playable level from the existing prefabs."

---

## 2. Completed Features (corresponding to DEV_PLAN Steps 1 → 5, including one addendum change after Step 5)

### Step 1 · Project Bootstrap + Feel Polish — ✅ Done
- `Player.tscn` (CharacterBody2D + CollisionShape2D + AnimatedSprite2D placeholder frames + Camera2D) is a reusable prefab.
- All feel values come from `tuning/default.tres` (a `PlayerConfig` resource), no hardcoding. **Note: `jump_height` in `default.tres` was manually changed to `74.0`; the script's default value of `64.0` is only a fallback — the actual feel is based on 74.0.**
- Actual behavior: left/right movement with distinct ground/air acceleration and friction; split-gravity jump (different gravity for rise/fall); coyote time; jump buffering; holding jump for a higher jump, releasing early cuts it short (variable jump height); idle/run/jump/fall four-state animation switching based on `is_on_floor()` and velocity direction.

### Step 2 · gravity + blue Reversible Sacrifices — ✅ Done
- Pressing 1 toggles `gravity`: `Player.up_direction` flips between `Vector2.DOWN`/`Vector2.UP`, sprite `flip_v` syncs, the ceiling becomes "the floor," and jump direction automatically follows the flip direction (`_gravity_sign()` handles this uniformly — the physics code doesn't distinguish normal vs. flipped).
- Pressing 2 toggles `blue`: `BlueObject` (`StaticBody2D` + `blue_object.gd`) listens to `Sacrifice` signals; when activated, collision is disabled (`set_deferred`) + it turns translucent; restoring reverses this.
- Single-slot constraint: `Sacrifice.activate()` evicts the earliest-activated concept when `_active.size() >= max_slots`, so `gravity`/`blue` are naturally mutually exclusive (initial `max_slots = 1`).
- Toggle feedback: `HUD.tscn`'s `FlashOverlay` (a white translucent ColorRect) flashes once per toggle (`hud.gd::_play_flash()`). The project has decided against audio, so this feedback is purely visual with no accompanying sound effect (see "After Step 5" in Section 2).

### Step 3 · Altar System + Unlocking + Double Slot + Permanent Sacrifice of jump — ✅ Done
- All concepts are locked by default (`Sacrifice._unlocked` is an empty dictionary); `sacrifice_input.gd` only allows toggling concepts for which `Sacrifice.is_unlocked(id)` is true.
- `Altar.tscn` (`Area2D`, collision layer 0 / mask 2, only collides with the player layer) has three `Action`s: `UNLOCK` / `SET_SLOTS` / `PERMANENT_SACRIFICE`, all configurable in the Inspector, no code changes needed.
- **Interact-confirm model** (a requirement added partway through Step 3, not in the original Step 3 draft): entering an altar's range only shows a hint (the `Hint` Label); the `Sacrifice` command only actually triggers after pressing `interact` (E); a `one_shot` altar stops showing its hint and stops responding after triggering once. Two altars can be stacked at the same spot and trigger independently (this is exactly how the double-slot shrine works: `AltarDoubleSlots` (`SET_SLOTS`=2) + `AltarSacrificeJump` (`PERMANENT_SACRIFICE jump`) stacked at the same coordinates).
- After permanently sacrificing `jump`, the condition `Input.is_action_just_pressed("jump") and not Sacrifice.is_permanently_sacrificed("jump")` in `player.gd::_update_timers()` permanently zeroes out the jump buffer, so the jump key silently stops working from then on (no error, no prompt, in keeping with the "increasingly empty" tone).

### Step 4 · Both UI Sacrifices (hud / fourthwall) — ✅ Done; hud's effect **had its design changed partway through**; the `pause` sacrifice has been removed entirely

**Currently the project has only two UI sacrifices: `hud` and `fourthwall`. `pause` is not a third UI sacrifice — it has been completely removed and does not exist in the current implementation.**

- **Current state of `pause` (important — easy to be misled by stale memory or stale docs)**: `pause` used to be a third UI sacrifice (a standalone test altar that disabled Escape once sacrificed, but was never actually wired into the double-slot upgrade), and has been **removed entirely** — the two files `pause_controller.gd`/`PauseController.tscn` have been deleted; the main scene that used to hold the `AltarPause`/`PauseController` nodes (`TestRoom.tscn`) was also later deleted entirely as part of the Step 5 scene consolidation (see "Step 5" below); all related descriptions in `GDD.md`/`DEV_PLAN_CORE.md` have been removed to match. There is currently **no pause functionality whatsoever** in the project, and the Escape key is bound to no game logic. The only remnant: `project.godot`'s Input Map still has the `pause` (Escape) action defined but nothing listens to it, since modifying Project Settings is outside AI's permissions (see Section 5, item 6).
- **HUD**: `hud.gd` (attached to `HUD.tscn`) switched from the text version to an icon version. `SlotsRow` generates the corresponding number of slot squares based on `Sacrifice.max_slots` (filled color = in use, empty color = unused); `IconsRow` adds one icon per unlocked concept (gray = inactive, bright yellow = active); everything is driven by the `concept_unlocked`/`concept_activated`/`concept_deactivated`/`slots_changed` signals, with no querying of any state beyond that.
- **Current state of `hud` (UI collapse) — ⚠️ the design changed partway through; the current implementation is "icons fall and become platforms," not the original "observation-collapse mechanism"**:
  - **Old design (fully retired, script deleted, but its scene file has repeatedly resurrected on disk — see Section 5, item 5)**: a gate called the "observation-collapse mechanism" — solid and blocking before `hud` was sacrificed, passable afterward. The corresponding script `scripts/observation_gate.gd` has been deleted, and at the game-logic level **nothing** anywhere references or instantiates `ObservationGate.tscn`.
  - **New design (the implementation that's actually in effect now)**: `hud_collapse_platforms.gd` (attached to `HudCollapsePlatforms.tscn`, a plain `Node2D`) listens to `Sacrifice.concept_permanently_sacrificed`; when it receives `id == "hud"`, it iterates over all of its own `Marker2D` child nodes and, at each Marker2D's position, constructs a `StaticBody2D` in code (collision layer 1, a rectangular collision shape + a same-sized `Polygon2D` visual), dropping it from `target_position + Vector2(0, -drop_height)` to the target position via a Tween (`TRANS_QUAD`/`EASE_IN`) — the effect being "HUD icons crash into the level and turn into a few steppable solid platforms." Landing spots are configured entirely by adding/moving `Marker2D` child nodes in the editor; there are no hardcoded coordinates in the script.
    At the same time, `hud.gd::_on_permanently_sacrificed()` uses a Tween to fade out and hide `Layout` (the whole icons + slots UI block) when `id == "hud"` — `FlashOverlay` is deliberately left unaffected, because GDD §5.5 requires that after sacrificing hud, the player can still operate by "memory + on-screen feedback (the toggle flash)."
  - The level demonstrating this mechanic is `IntegrationLevel.tscn` (the R3 area, `x≈800~820`): a 190px drop that's simply unreachable by jumping/flipping alone; once the nearby `AltarHud` (`PERMANENT_SACRIFICE hud`) triggers, `HudCollapsePlatforms`'s two `Marker2D`s (`Drop1`/`Drop2`) fall in sequence to form steps, which combine with the existing `HudLedge` to form a three-tier stepped climb. `IntegrationLevel.tscn` is now the project's main scene, playable directly via F5.
- **Current state of `fourthwall` (ending)**: `ending_sequence.gd` (attached to `EndingSequence.tscn`, `layer = 10`, `process_mode = Always`) listens to `concept_permanently_sacrificed`; when `id == "fourthwall"`: `get_tree().paused = true` → a Tween sequence fades out the HUD in order (`hud_fade_target_path` is manually wired in the scene to `../HUD/Layout`) → the black `Overlay` fades in to `dissolve_alpha` (0.85, not fully black) → the text `Label` (default "Thank you for playing.") fades in → holds → the text fades out while `Overlay` continues fading to fully black (in parallel). Entirely visual throughout, never touching the OS window. After triggering, the whole game tree pauses, but `RestartController` (`process_mode = Always`) can still respond to the R key to restart.

### Step 5 · Room Template + Single-Scene Integration Level — ✅ Done (no room-switching system; the user explicitly chose the single-scene approach)
- **Scene decision (fully executed)**: `IntegrationLevel.tscn` is designated as the **single official level**; any future content additions should extend/add areas on top of it (see the architectural decision for Step 5 in `DEV_PLAN_CORE.md`). The human has manually changed `project.godot`'s `run/main_scene` to point at `IntegrationLevel.tscn` (`uid://bkdctvarex6yi`), and the AI subsequently deleted `scenes/TestRoom.tscn` and cleaned up the comment reference to it in the code (`restart_controller.gd`). **By design, `TestRoom.tscn` should no longer exist in the project** — but see Section 5, item 4: this file has strangely reappeared once after being deleted, and whoever picks this up should keep an eye out for it.
- `RoomTemplate.tscn` + the comment-only script `room_template.gd`: a copyable template for C, consisting of one `Ground` (a `Ground.tscn` instance, layer 1) + one `ExampleAltar` (an `Altar.tscn` instance) + one `ExampleMechanism` (a `BlueObject.tscn` instance, stretched vertically to demonstrate scaling usage). A comment at the top of the script states: "Copy this scene, change the coordinates/`concept_id`, and that's a new room — don't touch sacrifice_manager.gd/altar.gd/blue_object.gd."
- `IntegrationLevel.tscn`: within a single scene, divides R1~R6 by coordinate ranges, chained in GDD §5.2 order:
  - **R1** (x≈-400~150): `R1Ground` + `R1Ceiling` (300px apart, beyond jump height, reachable only via `gravity` flip) + `AltarGravity`.
  - **R2** (x≈150~450): a vertical gap with no floor layer; `R2Ledge` is a floating, offset platform that forces the player through the sequence "flip to rise → walk off the platform edge to clear the foothold → keep rising → flip back to normal gravity"; the whole area has a `SafetyFloor` (y=1000) as a fall-back safety net.
  - **R3** (x≈450~900): `R3Ground` + `AltarBlue` + `BlueWallR3` (a vertically stretched blue wall); within this area, at x≈800~820, the hud demonstration set-piece has been added (see above).
  - **R4** (x≈900~1200): `R4Ground` + the stacked `AltarDoubleSlots` (`SET_SLOTS 2`) + `AltarSacrificeJump` (`PERMANENT_SACRIFICE jump`), the double-slot shrine.
  - **R5** (x≈1200~1350): `LeftWallR5`/`RightWallR5` form a vertical shaft, with three tiers of `BlueBarrier1/2/3` spanning the shaft at different heights — with a single slot it's impossible to have `gravity`+`blue` on at the same time, so the player must first get the double slot in R4 to have both on and pass through.
  - **R6**: the `R6Ground` landing platform + `AltarFourthwall` (`PERMANENT_SACRIFICE fourthwall`) + an `EndingSequence` instance.
  - Manually walked through room by room and confirmed: **once the double slot is obtained in R4, the jump key is never needed all the way to R6** (satisfying the GDD §5.4 hard constraint); the floor level inside the R5 shaft has no solid floor — walking straight in without flipping only drops you into the fall-back safety net, so there is no path that bypasses the puzzle.
  - **`IntegrationLevel.tscn` has some traces that weren't made by this round of AI changes, but were later adjusted by the editor/a human** (preserved as-is during this review, with no reverting done): every node has had a `unique_id` added; `SafetyFloor`/the newly added `SafetyFloor2` (the same kind of fall-back floor, positioned above R5/R6 at `y=-882`); `LeftWallR5`/`RightWallR5`'s scale is slightly higher than originally planned (about 1.16×); `AltarFourthwall`'s position has moved from the original plan's `y=-475` to `y=-406`. All of these are treated as the current real/authoritative layout, not deviations to be fixed.

### After Step 5 · Prefab-ification Cleanup + Audio Scope Removal + Documentation Consistency Fixes — ✅ Done
- **Audio removed from scope entirely**: the project has decided against audio. Removed `hud.gd`'s only audio hook, `_play_toggle_sfx_hook()` (previously an empty placeholder function; the toggle flash effect itself is unaffected); all AudioManager/BGM/SFX/mute-hook-related deliverables, acceptance items, and TODOs in `GDD.md`/`DEV_PLAN_CORE.md`/`DEV_STATUS.md` have been removed. **Explicitly kept**: the GDD's design text for the `sound` reserved concept (the concept table row, the §7.6 extension example, and the appendix index) — that's design text for a "possible future silent-gameplay concept," not an audio implementation, and is unrelated to this scope change. The project itself never had any `AudioStreamPlayer` node or audio resource files to begin with (confirmed via a project-wide grep), so this change was almost entirely documentation-level cleanup.
- **Three new prefabs, extracted from objects that were previously inlined in levels**:
  - `Ground.tscn` + the new script `ground.gd` (`@tool`, `StaticBody2D`): a generic floor/platform/ceiling/wall prefab; two exported properties, `size`/`color`, drive the collision shape (`RectangleShape2D`) and the visible polygon (`Polygon2D`) to auto-sync (`@tool` makes changes to `size` show up instantly in the editor; `_apply()` creates a fresh `RectangleShape2D` every time instead of reusing a shared one, to avoid multiple instances polluting each other's collision size). The 12 previously hand-maintained `StaticBody2D`+`CollisionShape2D`+`Polygon2D` triples in `RoomTemplate.tscn` and `IntegrationLevel.tscn` (`Ground`/`SafetyFloor`/`SafetyFloor2`/`R1Ground`/`R1Ceiling`/`R2Ledge`/`R3Ground`/`HudLedge`/`R4Ground`/`LeftWallR5`/`RightWallR5`/`R6Ground`) have all been replaced with instances of this prefab, with size/position/scale/color copied from the original values exactly — visual and collision behavior are unchanged. `SafetyFloor`/`SafetyFloor2`'s `Visual` child node originally had an asymmetric manual position/scale offset (`position=(-40.999985,0)`, `scale=(1.337,1)`, tuned by a human in the editor; it doesn't perfectly align with the collision shape, but since it's an offscreen fall-back safety net it was never seen by the player) — the migration preserved this offset as-is via a child-node property override, without "conveniently" smoothing it out.
  - `SacrificeInput.tscn`: extracted the `Node`+`sacrifice_input.gd` that previously only existed inline in `IntegrationLevel.tscn` into a standalone scene; the `bindings` dictionary export is unchanged.
  - `RestartController.tscn`: likewise extracted the inline `Node`+`restart_controller.gd` (`process_mode=Always`) into a standalone scene.
  - All three have been swapped for instance references in `IntegrationLevel.tscn`/`RoomTemplate.tscn`; the top-of-file comment in `room_template.gd` has been updated to match, and no longer describes the old workflow of "manually editing RectangleShape2D and Polygon2D."
  - `HudCollapsePlatforms.tscn` was checked and **already satisfies** the "configurable landing-spot component" requirement (landing spots are configured via `Marker2D` child nodes added by each level instance itself; `platform_size`/`color`/`drop_height`/`drop_duration` are already exported) — unchanged this round.
- **New handoff document** `scenes/HOW_TO_BUILD_A_LEVEL.md`: aimed at level designers unfamiliar with the code, clearly explaining what a playable level needs at minimum, how to use each prefab, collision layer setup, how the altar's interact-confirm mechanic affects placement, the two GDD §5.4/§7.7 hard constraints, and a copyable minimal playable level build example.
- **GDD.md section renumbering**: after deleting the entire §7 audio section, the original §8~§11 (technical architecture / extension interfaces / development plan / content and asset checklist) were renumbered in sequence to §7~§10; also filled in the previously missing `ending_sequence.gd`/`restart_controller.gd`/`hud_collapse_platforms.gd`/`room_template.gd` (along with the newly added `ground.gd`) in the §7.3 script list table, so the authoritative architecture table matches the actual implementation. Every place that referenced the old numbering (inside the GDD itself, `DEV_PLAN_CORE.md`, `DEV_STATUS.md`, `CLAUDE.md`, and 6 script comments) has been updated to match, checked one by one with nothing missed.
- **Cleared out a few references to files that never existed**: `DEV_PLAN_CORE.md` used to reference four names — `PROJECT_SETUP.md`, `EXTENSION_GUIDE.md`, `Main.tscn`, `AI_CONTEXT.md` — a project-wide search confirmed these files were never created; they've been changed to point at documents that actually exist, or to describe the content directly, instead of naming nonexistent files.

(This entry records a scope change + cleanup pass inserted after Step 5 completed and before Step 6 formally began; it doesn't correspond to a specific numbered DEV_PLAN step.)

---

## 3. Key File Inventory

### `scripts/`
| File | Type | Responsibility |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | The single global source of sacrifice state and signals. See the "Sacrifice public interface" below. |
| `player_config.gd` | `Resource`, `class_name PlayerConfig` | Container for the player's feel values (movement/jump/friction/coyote/buffer). |
| `player.gd` | `CharacterBody2D`, `class_name Player` | Movement + split-gravity jump + `gravity` sacrifice response (flipping `up_direction`) + animation state machine. `class_name Player` was added deliberately, for `altar.gd` to do `body is Player` checks. |
| `blue_object.gd` | `StaticBody2D` (**no class_name**, deliberately, to prevent naming collisions when B copies/renames it) | Generic reactive-object template: listens to the signal, toggles collision-disable + transparency based on its own `concept_id`. `blue` uses it, and B copies it and changes `concept_id` when adding new concepts. |
| `sacrifice_input.gd` | `Node` | `@export var bindings: Dictionary` maps input action names to concept_ids; a key press triggers `Sacrifice.toggle()` (only takes effect for already-unlocked concepts). Attached to `SacrificeInput.tscn`. |
| `altar.gd` | `Area2D`, `class_name Altar` | Generic altar: shows the `Hint` prompt on entering its range, and only actually triggers one of the three commands `UNLOCK`/`SET_SLOTS`/`PERMANENT_SACRIFICE` when `interact` (E) is pressed; a `one_shot` altar stops showing/responding after triggering once. |
| `hud.gd` | `CanvasLayer` | Icon-based status display (slots + concept icons, three states) + the full-screen toggle-flash feedback + the UI fade-out/disintegration after sacrificing `hud`. |
| `ending_sequence.gd` | `CanvasLayer`, `process_mode = Always`, `layer = 10` | The `fourthwall` ending: HUD fade-out → black overlay → text → black screen, purely visual. |
| `restart_controller.gd` | `Node`, `process_mode = Always` | On `restart` (R): `Sacrifice.reset()` + unpause + reload the current scene. Attached to `RestartController.tscn`. |
| `hud_collapse_platforms.gd` | `Node2D` | After `hud` is permanently sacrificed, spawns one falling, one-time solid platform at each of its own `Marker2D` child node positions. |
| `ground.gd` | `StaticBody2D`, `@tool` | Reusable floor/platform geometry block: two exported properties, `size`/`color`, drive the collision shape (`RectangleShape2D`) and the visible polygon (`Polygon2D`) to stay in sync, with `size` changes taking effect instantly in the editor. Attached to `Ground.tscn`. |
| `room_template.gd` | `Node2D`, comment-only, no logic | Room-building instructions for C, attached to `RoomTemplate.tscn`. |

**Script that shouldn't exist but needs watching for**: `observation_gate.gd` — deleted; if it reappears, the cleanup was incomplete (historically its companion scene `ObservationGate.tscn` has resurfaced — see Section 5, item 5).

### `scenes/`
| Scene | Structure | Notes |
|---|---|---|
| `Player.tscn` | `CharacterBody2D`(player.gd) > `CollisionShape2D` + `AnimatedSprite2D`(placeholder frames) + `Camera2D` | `config` points to `tuning/default.tres`; `collision_layer = 2`. ⚠️ `sprite_path` is serialized as literal `null` in the scene file — see Known Issue item 2 in Section 5. |
| `Altar.tscn` | `Area2D`(layer 0/mask 2, altar.gd) > `CollisionShape2D`(48×64 rectangle) + `Visual`(yellow Polygon2D) + `Hint`(Label, hidden by default) | All three Actions rely on this one scene, configured via the Inspector. |
| `BlueObject.tscn` | `StaticBody2D`(layer 1, blue_object.gd) > `CollisionShape2D`(32×32) + `Visual`(blue Polygon2D) | `concept_id` defaults to `"blue"`; change this field to reuse it for another concept. |
| `HUD.tscn` | `CanvasLayer`(hud.gd) > `Layout`(VBox) > `SlotsRow`+`IconsRow`(HBox); `FlashOverlay`(ColorRect, a sibling node) | |
| `EndingSequence.tscn` | `CanvasLayer`(layer=10, process_mode=Always, ending_sequence.gd) > `Overlay`(black ColorRect) + `Label` | Each level instance manually wires `hud_fade_target_path` to that level's own `HUD/Layout`. |
| `HudCollapsePlatforms.tscn` | bare `Node2D`(hud_collapse_platforms.gd), no default children | Each level instance adds its own `Marker2D` child nodes to set the landing spots. |
| `Ground.tscn` | `StaticBody2D`(layer 1, `ground.gd`) > `CollisionShape2D` + `Visual`(Polygon2D) | Generic floor/platform/ceiling/wall prefab; `size`/`color` exported — changing `size` auto-syncs the collision shape and visible polygon; use the node's `scale` for an overall stretch. |
| `SacrificeInput.tscn` | `Node`(sacrifice_input.gd) | Extracted standalone prefab, previously inline per-level; the `bindings` dictionary is editable in the Inspector. |
| `RestartController.tscn` | `Node`(`process_mode=Always`, restart_controller.gd) | Extracted standalone prefab, previously inline per-level; no adjustable parameters. |
| `RoomTemplate.tscn` | `Node2D`(room_template.gd) > `Ground`(a Ground.tscn instance) + `ExampleAltar` + `ExampleMechanism` | The copy starting point for C. |
| `IntegrationLevel.tscn` | Step 5's R1→R6 integration level, **the project's current actual main scene** (see "How to Run It" in Section 7) | See the Step 5 description in Section 2 for details. During Steps 1–4, `TestRoom.tscn` served as the feel/mechanics test room; it has been retired and deleted by design, and both testing and the real level have merged into this one scene. All floors/platforms/ceilings/walls have been switched to `Ground.tscn` instances, and the `SacrificeInput`/`RestartController` nodes have also been switched to instances of the corresponding prefabs (see "Prefab-ification Cleanup" in Section 2). |

**Scenes that shouldn't exist but need watching for**: `TestRoom.tscn` (see Section 5, item 4), `ObservationGate.tscn` (see Section 5, item 5) — both have resurfaced on disk before and are currently confirmed deleted; if either is found alive again when picking this up, just delete it.

### `Sacrifice` Singleton Public Interface (`scripts/sacrifice_manager.gd`; the autoload name must be exactly `Sacrifice`)
```gdscript
# Signals
signal concept_activated(id: String)
signal concept_deactivated(id: String)
signal concept_unlocked(id: String)
signal slots_changed(new_slots: int)
signal concept_permanently_sacrificed(id: String)

# State (exposed read-only externally; writes only through the functions below)
var max_slots: int = 1

# Queries
func is_unlocked(id: String) -> bool
func is_active(id: String) -> bool
func is_permanently_sacrificed(id: String) -> bool
func get_active() -> Array[String]        # returns a copy
func get_unlocked() -> Array[String]

# Commands
func unlock(id: String) -> void                    # idempotent, repeated calls don't re-fire the signal
func activate(id: String) -> void                  # silently ignored if not unlocked / already permanently sacrificed / already active; evicts the earliest-activated one when over the slot limit
func deactivate(id: String) -> void
func toggle(id: String) -> void
func set_max_slots(n: int) -> void                  # evicts the excess (starting from the earliest-activated) when shrinking the slot count
func permanently_sacrifice(id: String) -> void      # auto-deactivates first if currently active, then marks as permanent
func reset() -> void                                # clears all state, resets slots to 1, meant to pair with a scene reload
```

---

## 4. Current Architectural Conventions / Invariants (must not be broken)

1. All sacrifice-related state lives only in the `Sacrifice` singleton (`sacrifice_manager.gd`); any other system interacts with it only through its signals/query functions — **never build a second global state holder**.
2. All of the player's feel values come only from `PlayerConfig` (`tuning/default.tres`); `player.gd` must never contain a hardcoded movement/jump number.
3. Unified pattern for "objects that react to a sacrifice": listen to the `Sacrifice` signal, filter by its own `concept_id`, following `blue_object.gd`; never add object-specific branches inside the `Sacrifice` singleton. `hud_collapse_platforms.gd` is the second template for this pattern (its response style is "spawning geometry" rather than "toggling geometry").
4. The single-slot / double-slot / permanent-sacrifice rules are implemented only inside the `Sacrifice` singleton (`activate`/`set_max_slots`/`permanently_sacrifice`) — never reimplemented elsewhere.
5. Collision layers: world entities (terrain, `Ground`, `BlueObject`, the hud collapse platforms) = Layer 1; the player = Layer 2; `Altar` is an `Area2D` with `collision_layer = 0` / `collision_mask = 2` (only detects the player entering, doesn't participate in physics collision).
6. The autoload name must be exactly `Sacrifice` (capital S); currently in `project.godot` it's `Sacrifice="*uid://10vfev3uue5r"`, corresponding to `sacrifice_manager.gd`.
7. `Player` has `class_name Player`, dedicated to letting `altar.gd` and similar scripts do `body is Player` type checks; conversely, "object-side" scripts like `blue_object.gd` deliberately don't have a `class_name`, to avoid name collisions when B copy-pastes and renames them.
8. Nodes that need to keep working while `get_tree().paused = true` (`EndingSequence`, `RestartController`) always set `process_mode` to `3` (Always) — this is the project-wide, unified technique for "surviving across pause"; don't use any other method (e.g. manually checking the paused state) to work around the pause system.
9. "Positions the level designer needs to place," such as altar landing spots or HUD collapse platform landing spots, are always configured via `Marker2D` child nodes or Inspector fields — never hardcode coordinates in a script (`hud_collapse_platforms.gd` is the demonstration of this convention).
10. Floors/platforms/ceilings/walls always use `Ground.tscn` instances (`size`/`color` exported) — don't hand-write the `StaticBody2D`+`CollisionShape2D`+`Polygon2D` triple anymore. This is a convention added after Step 5; `ground.gd` is the sole place responsible for keeping the collision shape and visible polygon in sync.
11. The project does no audio. Don't add an `AudioStreamPlayer`, SFX-playback logic, or any "reserved audio hook" placeholder code — this is an already-settled scope change, not a temporary omission.
12. The AI assistant's hard rules (from `CLAUDE.md`, reiterated here): no git operations of any kind; no modifying Project Settings (autoload/Input Map/main scene are configured manually by a human); only work within the scope of the current DEV_PLAN step.

---

## 5. Known Issues / Workarounds / TODOs

1. **`sacrifice_input.gd`'s UID warning (low priority, purely a console notice, doesn't affect functionality)**: the `ext_resource` reference to `sacrifice_input.gd` in `SacrificeInput.tscn` occasionally gets its `uid=` attribute rewritten back to a stale value by the editor, causing an "invalid UID... using text path instead" warning in the console. The `.uid` sidecar file and `.godot/uid_cache.bin` have been checked; this is suspected to be an in-memory `ResourceUID` cache issue inside the editor process. "Reload Current Project" doesn't clear it — a **full quit and restart of the Godot editor** is theoretically needed to fix it for good. The game itself loads fine via the text-path fallback; this is purely console noise.
2. **`Player.tscn`'s `sprite_path` is serialized as literal `null` (unconfirmed whether this has any real impact)**: the script's default value is `^"AnimatedSprite2D"`, but the scene file currently has `sprite_path = null` (see line 14 of `Player.tscn`). In `player.gd::_ready()`, `_sprite = get_node(sprite_path) as AnimatedSprite2D` — if `null` really is being passed in, `_sprite` should end up `null`; the subsequent `_update_animation()` already has a `if _sprite == null: return` null-check, and the animation call sites are all null-checked too, so **the worst case is animation silently not playing, with no error or crash**. However this specific field has never been verified in isolation, and whether it's actually affected at runtime is unknown — recommend confirming in the Inspector next time the editor is open whether `Player.tscn`'s `Sprite Path` field correctly points at `AnimatedSprite2D`.
3. **The altar's `Hint` prompt isn't forced to the top layer and may be occluded by foreground objects in the level**: `Hint` is a plain `Label` inside the 2D scene tree in `Altar.tscn` (floating above the altar, `offset_top=-70`~`offset_bottom=-40`), not a `CanvasLayer`, with no `z_index` bump or dedicated UI layer. If a room design happens to stack another foreground object at the same screen position directly above an altar, the hint text may be visually occluded and unreadable. Currently deferred (post-MVP could consider moving it to a `CanvasLayer` or adding a `z_index`); during level design (C's work), just avoid this kind of stacking to sidestep the issue.
4. **(Resolved, but watch for the same phenomenon as item 5) the main scene has switched to `IntegrationLevel.tscn`, and `TestRoom.tscn` should have been retired/deleted**: the human has manually changed `project.godot`'s `run/main_scene` to `IntegrationLevel.tscn` (`uid://bkdctvarex6yi`), and the AI subsequently deleted `scenes/TestRoom.tscn` and cleaned up the reference in the code comments (`restart_controller.gd`). Pressing F5 should now run the full R1→R6 integration level directly, including the hud demo, with no need to manually open a separate scene in the editor. **However, after being deleted, this file reappeared on disk once following some unknown operation, and was deleted again at that time** — the cause is unknown, suspected to be related to some caching/auto-writeback behavior in the local Godot editor, and was not manually restored by a human. If `scenes/TestRoom.tscn` is found to exist again when picking this up, just delete it (and confirm `project.godot`'s main scene still points at `IntegrationLevel.tscn`) — this doesn't mean this document's record is wrong.
5. **(Resolved) `ObservationGate.tscn` had resurfaced on disk; deleted in this session**: the old "observation-collapse mechanism" design (a gate that blocks before `hud` is sacrificed and becomes passable afterward) was long ago replaced by "icons fall and become platforms" (`hud_collapse_platforms.gd`); the corresponding script `scripts/observation_gate.gd` is confirmed deleted. During the previous snapshot review, the scene file `scenes/ObservationGate.tscn` itself was found to have reappeared on disk — it references the script `res://scripts/observation_gate.gd`, which doesn't exist, making it an orphaned/broken scene file pointing at a missing script. This session re-grepped the entire project (`.gd`/`.tscn`/`.tres`/`.godot`) to confirm no scene/script references or instantiates it, then deleted it. This is the same type of "a deleted file reappearing" phenomenon as item 4's `TestRoom.tscn`, cause likewise unknown (suspected to be a local Godot editor caching behavior); if `scenes/ObservationGate.tscn` is found to exist again when picking this up, just delete it.
6. **The `pause` sacrifice gameplay has been removed entirely, but the `pause` (Escape) action definition in the Input Map is still there**: `pause_controller.gd`/`PauseController.tscn` have been deleted, and the main scene that used to hold the `AltarPause`/`PauseController` nodes (`TestRoom.tscn`) was itself later deleted entirely as well; all `pause`-related descriptions in `GDD.md`/`DEV_PLAN_CORE.md` have been removed to match. But `project.godot`'s Input Map still defines the `pause` (Escape) action — per the `CLAUDE.md` hard rules, Project Settings can only be changed manually by a human in the editor, and the AI can't delete it. **This is an expected, harmless orphaned binding: no script currently listens to it, and pressing Escape does nothing.** If a human wants to clean it up entirely, they need to go delete this row in the editor's Input Map panel themselves.

---

## 6. What's Next

**Current progress: Step 5 (including the hud mechanism rework after Step 5, and the prefab-ification + audio removal + documentation consistency fixes added after Step 5) is complete; Step 6 has not yet begun.**

**Cleanup complete**: the two "resurrected" leftover files mentioned in Section 5, items 4 and 5 — `scenes/TestRoom.tscn`, `scenes/ObservationGate.tscn` — are both now confirmed deleted (`ObservationGate.tscn` was deleted in this session, after re-grepping the entire project beforehand to confirm no references). No longer an urgent TODO; can proceed directly to Step 6.

**Step 6 (polish + handoff packaging) TODO items**:
- Give the existing feedback effects — toggle tint, ending disintegration — a pass to see if they need tweaking.
- Assemble the handoff documentation bundle (see below).

**What needs to be ready to hand to B (gimmicks/mechanisms, extending new concepts)**:
- Two directly copyable reactive-object templates: `BlueObject.tscn` (the toggle-collision + transparency type) and `HudCollapsePlatforms.tscn` (the spawn-geometry-on-sacrifice type).
- A write-up on "how to add a new concept": copy the template → change `concept_id` → place a `UNLOCK`-type `Altar` → add a line to `SacrificeInput.bindings` for the key binding (GDD §7.6 "extension pattern").
- Make clear that the reserved concepts (`friction`/`time`/`sound`) are to be implemented by B, reusing the pattern of the two templates above.

**What needs to be ready to hand to C (map/level design)**:
- Usage notes for `RoomTemplate.tscn` + `room_template.gd`, and the more complete `scenes/HOW_TO_BUILD_A_LEVEL.md` build tutorial (already delivered, see the scene inventory in Section 3).
- The three newly extracted prefabs `Ground.tscn`/`SacrificeInput.tscn`/`RestartController.tscn` — usage is covered in `HOW_TO_BUILD_A_LEVEL.md`.
- How to configure `Altar.tscn`'s three `Action`s in the Inspector.
- One reference full level: `IntegrationLevel.tscn` (now the project's main scene, playable directly via F5).
- Direction for extending the level: lengthen/add areas within this same `IntegrationLevel.tscn` scene, rather than splitting into multiple independent scenes connected by transitions — the project has formally abandoned the room-switching-system approach (see Step 5 in `DEV_PLAN_CORE.md`).
- Two hard constraints that must be followed: GDD §5.4 (after sacrificing `jump` for the double slot, the player must never be required to press jump all the way to the end) and GDD §7.7 (don't design a puzzle that requires "restoring blue while inside a blue wall").

---

## 7. Input Mapping & How to Run It

### Input Map (`project.godot`'s current actual configuration)
| Action name | Bound key |
|---|---|
| `move_left` | A |
| `move_right` | D |
| `jump` | Space |
| `sacrifice_gravity` | 1 |
| `sacrifice_blue` | 2 |
| `interact` | E |
| `restart` | R |

(The Input Map also still has a `pause` (Escape) action defined, but no script listens to it — see Section 5, item 6.)

### Main Scene
`project.godot`'s `run/main_scene = "uid://bkdctvarex6yi"`, corresponding to **`scenes/IntegrationLevel.tscn`**. Pressing F5 actually runs Step 5's full R1→R6 integration level, covering every mechanic: gravity/blue, the double-slot shrine, the permanent sacrifice of jump, the hud icon-falling-platform demo, and the fourthwall ending. `TestRoom.tscn` (the feel/mechanics test room from Steps 1–4) has by design been retired and deleted (but see the resurrection phenomenon in Section 5, item 4).

### autoload
`Sacrifice = "*uid://10vfev3uue5r"`, corresponding to `scripts/sacrifice_manager.gd`.

### Restarting with R
`restart_controller.gd` (`process_mode = Always`, attached via a `RestartController.tscn` instance in the current main scene `IntegrationLevel.tscn`) listens for the `restart` action: it calls `Sacrifice.reset()` (clears all unlocked/active/permanently-sacrificed concepts, resets slots to 1) → `get_tree().paused = false` (prevents getting stuck in the ending's black-screen paused state) → `get_tree().reload_current_scene()`. Because `Sacrifice` is an autoload and `paused` is a SceneTree-level flag, neither resets automatically on scene reload, so these two steps are mandatory and can't be skipped. R can also be pressed to restart while the ending is playing.
