# DEV_STATUS.md — Current Development Status Snapshot for 《Sacrifice》

> **This file records "what the code actually looks like right now," not the GDD's ideal design.**
> Design follows `GDD.md`; collaboration hard rules follow `CLAUDE.md`; **development progress follows this file.**
> Every time a step is advanced or a change is completed, update the corresponding section of this file so the next person who picks this up (human or AI, with no memory of prior sessions) can know the current state without digging through the code.

## 1. One-Sentence Project Summary + Doc Index

《Sacrifice》 is a Godot 4.x "subtractive Metroidvania": the player permanently or temporarily sacrifices abstract concepts (gravity, the color "blue," jump, the HUD, the fourth wall…) to get through places that were otherwise impassable — the further you play, the less you have, but the more places you can reach.

- **`GDD.md`** — the sole design authority. Describes "what it should be."
- **`DEV_PLAN_CORE.md`** — the breakdown of development steps (Steps 1–6). Describes "what order to build things in."
- **`CLAUDE.md`** — AI collaboration hard rules (no git, no touching Project Settings, architectural hard rules, etc.). Describes "what the AI can and can't do."
- **`DEV_STATUS.md`** (this file) — describes "how far things have actually gotten, what it actually looks like, and what the gotchas are."
- **`scenes/HOW_TO_BUILD_A_LEVEL.md`** — a build tutorial for the level designer (C), explaining "how to assemble a playable level from the existing prefabs" (available in Chinese/English/Japanese).

**Rule of thumb for a cold-start session: design follows `GDD.md`; actual progress and behavior follow this file.** Where the two disagree, this file wins for "what currently exists," and the disagreement itself should be treated as a TODO to reconcile, not silently ignored.

---

## 2. Completed Features (Step 1 → Step 5, including one addendum change after Step 5)

### Step 1 · Project Bootstrap + Feel Polish — ✅ Done
- `Player.tscn` (CharacterBody2D + CollisionShape2D + AnimatedSprite2D placeholder frames + Camera2D) is a reusable prefab.
- All feel values come from `tuning/default.tres` (a `PlayerConfig` resource), no hardcoding. **`jump_height` in `default.tres` is currently `150.0`** (the script default in `player_config.gd` is `64.0`, used only as a fallback if a `PlayerConfig` field is ever missing — the resource value is the one that governs actual feel). **This value has already drifted once before (it was previously `74.0`) — don't trust any single number from a doc long-term; re-read `tuning/default.tres` directly if the exact current feel value matters.**
- Actual behavior: left/right movement with distinct ground/air acceleration and friction; split-gravity jump (different gravity for rise/fall); coyote time; jump buffering; holding jump for a higher jump, releasing early cuts it short (variable jump height); idle/run/jump/fall four-state animation switching based on `is_on_floor()` and velocity direction.

### Step 2 · gravity + blue Reversible Sacrifices — ✅ Done
- Pressing 1 toggles `gravity`: `Player.up_direction` flips between `Vector2.DOWN`/`Vector2.UP`, sprite `flip_v` syncs, the ceiling becomes "the floor," and jump direction automatically follows the flip direction (`_gravity_sign()` handles this uniformly — the physics code doesn't distinguish normal vs. flipped).
- Pressing 2 toggles `blue`: `BlueObject` (`StaticBody2D` + `blue_object.gd`) listens to `Sacrifice` signals; when activated, collision is disabled (`set_deferred`) + it turns translucent; restoring reverses this.
- Single-slot constraint: `Sacrifice.activate()` evicts the earliest-activated concept when `_active.size() >= max_slots`, so `gravity`/`blue` are naturally mutually exclusive (initial `max_slots = 1`).
- Toggle feedback: `HUD.tscn`'s `FlashOverlay` (a white translucent ColorRect) flashes once per toggle (`hud.gd::_play_flash()`). The project has decided against audio entirely (see the "After Step 5" entry below) — this feedback is purely visual with no accompanying sound effect, and there is no reserved/placeholder audio hook anywhere in the code.

### Step 3 · Altar System + Unlocking + Double Slot + Permanent Sacrifice of jump — ✅ Done
- All concepts are locked by default (`Sacrifice._unlocked` is an empty dictionary); `sacrifice_input.gd` only allows toggling concepts for which `Sacrifice.is_unlocked(id)` is true.
- `Altar.tscn` (`Area2D`, collision layer 0 / mask 2, only collides with the player layer) has three `Action`s: `UNLOCK` / `SET_SLOTS` / `PERMANENT_SACRIFICE`, all configurable in the Inspector, no code changes needed.
- **Interact-confirm model**: entering an altar's range only shows a hint (the `Hint` Label); the `Sacrifice` command only actually triggers after pressing `interact` (E); a `one_shot` altar stops showing its hint and stops responding after triggering once. Two altars can be stacked at the same spot and trigger independently (this is exactly how the double-slot shrine works: `AltarDoubleSlots` (`SET_SLOTS`=2) + `AltarSacrificeJump` (`PERMANENT_SACRIFICE jump`) stacked at the same coordinates).
- After permanently sacrificing `jump`, the condition `Input.is_action_just_pressed("jump") and not Sacrifice.is_permanently_sacrificed("jump")` in `player.gd::_update_timers()` permanently zeroes out the jump buffer, so the jump key silently stops working from then on (no error, no prompt, in keeping with the "increasingly empty" tone).

### Step 4 · Both UI Sacrifices (hud / fourthwall) — ✅ Done; hud's effect **had its design changed partway through**; the `pause` sacrifice has been removed entirely

**Currently the project has only two UI sacrifices: `hud` and `fourthwall`. `pause` is not a third UI sacrifice — it has been completely removed and does not exist in the current implementation.** (Confirmed again this session via a project-wide grep for `pause_controller`/`PauseController` — zero hits in `scripts/`, `scenes/`, or `project.godot`.)

- **Current state of `pause`**: `pause` used to be a third UI sacrifice (a standalone test altar that disabled Escape once sacrificed, but was never actually wired into the double-slot upgrade), and has been **removed entirely** — the two files `pause_controller.gd`/`PauseController.tscn` have been deleted; the main scene that used to hold the `AltarPause`/`PauseController` nodes (`TestRoom.tscn`) was also later deleted entirely as part of the Step 5 scene consolidation (see "Step 5" below); all related descriptions in `GDD.md`/`DEV_PLAN_CORE.md` have been removed to match. There is currently **no pause functionality whatsoever** in the project, and the Escape key is bound to no game logic. The only remnant: `project.godot`'s Input Map still has the `pause` (Escape) action defined but nothing listens to it, since modifying Project Settings is outside AI's permissions (see Section 5, item 6).
- **HUD**: `hud.gd` (attached to `HUD.tscn`) is the icon version (not text). `SlotsRow` generates the corresponding number of slot squares based on `Sacrifice.max_slots` (filled color = in use, empty color = unused); `IconsRow` adds one icon per unlocked concept (gray = inactive, bright yellow = active); everything is driven by the `concept_unlocked`/`concept_activated`/`concept_deactivated`/`slots_changed` signals, with no querying of any state beyond that.
- **Current state of `hud` (UI collapse) — the current, only implementation is "icons fall and become platforms"; the earlier "observation-collapse mechanism" design has been retired and deleted**:
  - **Old design (fully retired, script deleted)**: a gate called the "observation-collapse mechanism" — solid and blocking before `hud` was sacrificed, passable afterward. The corresponding script `scripts/observation_gate.gd` has been deleted, and at the game-logic level **nothing** anywhere references or instantiates `ObservationGate.tscn`. The orphaned scene file `scenes/ObservationGate.tscn` itself had resurfaced on disk twice in past sessions (cause unknown — suspected local Godot editor caching/write-back behavior) and has been re-deleted each time; a fresh grep this session confirms it does **not** currently exist. If it turns up again, just delete it — it is a broken scene referencing a nonexistent script and nothing instantiates it.
  - **Current implementation**: `hud_collapse_platforms.gd` (attached to `HudCollapsePlatforms.tscn`, a plain `Node2D`) listens to `Sacrifice.concept_permanently_sacrificed`; when it receives `id == "hud"`, it iterates over all of its own `Marker2D` child nodes and, at each Marker2D's position, constructs a `StaticBody2D` in code (collision layer 1, a rectangular collision shape + a same-sized `Polygon2D` visual), dropping it from `target_position + Vector2(0, -drop_height)` to the target position via a Tween (`TRANS_QUAD`/`EASE_IN`) — the effect being "HUD icons crash into the level and turn into a few steppable solid platforms." Landing spots are configured entirely by adding/moving `Marker2D` child nodes in the editor; there are no hardcoded coordinates in the script.
    At the same time, `hud.gd::_on_permanently_sacrificed()` (calling `_dismantle()`) uses a Tween to fade out and hide `Layout` (the whole icons + slots UI block) when `id == "hud"` — `FlashOverlay` is deliberately left unaffected, because GDD §5.5 requires that after sacrificing hud, the player can still operate by "memory + on-screen feedback (the toggle flash)."
  - The level demonstrating this mechanic is `IntegrationLevel.tscn` (the R3 area, around x≈800~820): a drop that's simply unreachable by jumping/flipping alone; once the nearby `AltarHud` (`position≈(800,248)`, `action=PERMANENT_SACRIFICE`, `concept_id="hud"`) triggers, `HudCollapsePlatforms`'s two `Marker2D` children (`Drop1`/`Drop2`) fall in sequence to form steps, which combine with the existing `HudLedge` to form a stepped climb.
- **Current state of `fourthwall` (ending)**: `ending_sequence.gd` (attached to `EndingSequence.tscn`, `layer = 10`, `process_mode = Always`) listens to `concept_permanently_sacrificed`; when `id == "fourthwall"`: `get_tree().paused = true` → a Tween sequence fades out the HUD in order (`hud_fade_target_path` is manually wired in the scene to `../HUD/Layout`) → the black `Overlay` fades in to `dissolve_alpha` (0.85, not fully black) → the text `Label` (default "Thank you for playing.") fades in → holds → the text fades out while `Overlay` continues fading to fully black (in parallel). Entirely visual throughout, never touching the OS window. After triggering, the whole game tree pauses, but `RestartController` (`process_mode = Always`) can still respond to the R key to restart. `AltarFourthwall` is at `position = (1275, -406)` in `IntegrationLevel.tscn`.

### Step 5 · Room Template + Single-Scene Integration Level — ✅ Done (no room-switching system; the user explicitly chose the single-scene approach)
- **Scene decision**: `IntegrationLevel.tscn` is designated as the **single official level**; any future content additions should extend/add areas on top of it. `scenes/TestRoom.tscn` (the old feel/mechanics test room) has been deleted and confirmed absent from disk this session (fresh grep, zero hits). It has resurfaced unexpectedly on disk more than once in the past for unknown reasons (suspected editor caching behavior) — if it's ever found present again, just delete it.
- **⚠️ Known discrepancy found this session — read before pressing F5**: `project.godot`'s `run/main_scene` currently resolves to `uid://cvxqb1ysmem20`, which is **`scenes/RoomTemplate.tscn`** (the bare example room template), **not** `scenes/IntegrationLevel.tscn` (`uid://bkdctvarex6yi`, the actual full R1→R6 level). This means **pressing F5 right now boots the minimal room template, not the full playable demo.** `RoomTemplate.tscn` itself is unchanged and works fine as a template — this is purely a main-scene pointer issue. Per `CLAUDE.md`, Project Settings (including `run/main_scene`) can only be changed by a human in the editor — the AI cannot fix this. **A human needs to re-point `run/main_scene` back to `IntegrationLevel.tscn` in Project Settings > Application > Run** before F5 will demo the real level again. Cause unknown — possibly changed while testing the room template in the editor and never switched back.
- `RoomTemplate.tscn` + the comment-only script `room_template.gd`: a copyable template for C, consisting of one `Ground` (a `Ground.tscn` instance, layer 1) + one `ExampleAltar` (an `Altar.tscn` instance) + one `ExampleMechanism` (a `BlueObject.tscn` instance, stretched vertically to demonstrate scaling usage). A comment at the top of the script states: "Copy this scene, change the coordinates/`concept_id`, and that's a new room — don't touch sacrifice_manager.gd/altar.gd/blue_object.gd."
- `IntegrationLevel.tscn`: within a single scene, divides R1~R6 by coordinate ranges, chained in GDD §5.2 order (node names/positions confirmed against the actual scene file this session):
  - **R1**: `R1Ground` + `R1Ceiling` + `AltarGravity` (position ≈(x,?) — gravity altar; unlocks `gravity`).
  - **R2**: `R2Ledge`, a floating offset platform with no ground layer, forcing "flip up → walk off the edge → keep rising → flip back."
  - **R3**: `R3Ground` + `AltarBlue` (unlocks `blue`) + `BlueWallR3` (position `(750, 244)`, `scale (1, 4)` — a vertically stretched blue wall). Within this area, the hud demo set-piece sits around x≈800~820: `AltarHud` + `HudCollapsePlatforms` (children `Drop1`/`Drop2`) + `HudLedge`.
  - **R4**: `R4Ground` + the stacked `AltarDoubleSlots` (`SET_SLOTS 2`) + `AltarSacrificeJump` (`PERMANENT_SACRIFICE jump`) — the double-slot shrine.
  - **R5**: `LeftWallR5`/`RightWallR5` (both `scale ≈ (1, 1.16)`, slightly taller than the original plan) form a vertical shaft; three tiers `BlueBarrier1/2/3` (all `scale (5, 1)`, at y = 150 / -50 / -250) span the shaft at different heights — with a single slot it's impossible to have `gravity`+`blue` on at once, so the player must first get the double slot in R4.
  - **R6**: `R6Ground` + `AltarFourthwall` (`position (1275, -406)`, `PERMANENT_SACRIFICE fourthwall`) + an `EndingSequence` instance.
  - Manually walked through room by room and confirmed (as of the last full walkthrough): **once the double slot is obtained in R4, the jump key is never needed all the way to R6** (satisfying the GDD §5.4 hard constraint); the R5 shaft has no solid floor inside it, so walking straight in without flipping only drops the player into the fall-back safety net (`SafetyFloor` at y=1000, plus `SafetyFloor2` at `position (500, -882)`, size `(2000, 40)`, covering the R5/R6 area) — there is no path that bypasses the puzzle.
  - All node positions/scales above were re-verified directly against `scenes/IntegrationLevel.tscn` this session and are the current real/authoritative layout, not values copied from an older doc.

### After Step 5 · Prefab-ification Cleanup + Audio Scope Removal + Documentation Consistency Fixes — ✅ Done
- **Audio removed from scope entirely, and this is final, not a placeholder gap**: the project has decided against audio. There is no `_play_toggle_sfx_hook()` or any other audio hook anywhere in the code (confirmed this session via `grep -n "sfx\|Audio" scripts/*.gd` — zero hits); there is no `AudioStreamPlayer` node or audio resource file anywhere in the project. **Do not add audio hooks in Step 6 or anywhere else — this is a settled scope decision, not deferred work.** (`GDD.md`/`DEV_PLAN_CORE.md`/this file all reflect this; the `sound` reserved-concept design text in the GDD is a description of a possible future silent-gameplay mechanic, unrelated to audio playback, and is intentionally kept.)
- **Three prefabs extracted from what used to be inlined per-level objects**:
  - `Ground.tscn` + `ground.gd` (`@tool`, `StaticBody2D`): a generic floor/platform/ceiling/wall prefab; `size`/`color` exports drive the collision shape (`RectangleShape2D`) and visible polygon (`Polygon2D`) to auto-sync, with a fresh `RectangleShape2D` created per instance (never a shared/mutated one) to avoid cross-instance collision-size pollution. All floors/platforms/walls in `RoomTemplate.tscn` and `IntegrationLevel.tscn` are instances of this prefab.
  - `SacrificeInput.tscn`: the `Node`+`sacrifice_input.gd` combo, extracted into a standalone, reusable scene (`bindings` dictionary still exported).
  - `RestartController.tscn`: the `Node`+`restart_controller.gd` (`process_mode=Always`) combo, likewise extracted into a standalone scene.
  - `HudCollapsePlatforms.tscn` was checked and already satisfies the "configurable landing-spot component" requirement (landing spots via level-added `Marker2D` children; `platform_size`/`color`/`drop_height`/`drop_duration` exported).
- **Handoff document** `scenes/HOW_TO_BUILD_A_LEVEL.md` exists, aimed at level designers unfamiliar with the code: what a playable level needs at minimum, how to use each prefab, collision layer setup, how the altar's interact-confirm mechanic affects placement, the GDD §5.4/§7.7 hard constraints, a copyable minimal-level build example, and (added in a later pass) a worked explanation of exactly which `Concept Id` strings currently have a listener and which `Action` each pairs with. **This file is intentionally trilingual (Chinese/English/Japanese, each a full standalone copy in one file with a language-switcher at the top) — it is the one exception to "the rest of the project's docs are English-only."**
- **GDD.md section numbering**: after the audio section was removed, sections were renumbered so the GDD now runs §0–§10 plus Appendices A/B, with no gaps and no leftover §11. All cross-references in `CLAUDE.md`/`DEV_PLAN_CORE.md`/this file use this current numbering.
- **All four core docs (`GDD.md`, `DEV_PLAN_CORE.md`, `DEV_STATUS.md`, `CLAUDE.md`) were fully translated from Chinese to English** in a later pass, preserving every code identifier, file name, and GDD section number exactly. `scenes/HOW_TO_BUILD_A_LEVEL.md` was deliberately left trilingual rather than English-only (see above).

(This entry records a scope change + cleanup pass inserted after Step 5 completed and before Step 6 formally began; it doesn't correspond to a specific numbered DEV_PLAN step.)

---

## 3. Key File Inventory

### `scripts/`
| File | Type | Responsibility |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | The single global source of sacrifice state and signals. See the public interface below. |
| `player_config.gd` | `Resource`, `class_name PlayerConfig` | Container for the player's feel values (movement/jump/friction/coyote/buffer). |
| `player.gd` | `CharacterBody2D`, `class_name Player` | Movement + split-gravity jump + `gravity` sacrifice response (flipping `up_direction`) + animation state machine. `class_name Player` lets `altar.gd` do `body is Player` checks. |
| `blue_object.gd` | `StaticBody2D` (no `class_name`, deliberately, to avoid name collisions when copied/renamed) | Generic reactive-object template: listens to the signal, toggles collision-disable + transparency based on its own `concept_id`. `blue` uses it as-is; new concepts copy it and change `concept_id`. |
| `sacrifice_input.gd` | `Node` | `@export var bindings: Dictionary` maps input action names to concept_ids; a key press triggers `Sacrifice.toggle()` (only for already-unlocked concepts). Attached to `SacrificeInput.tscn`. |
| `altar.gd` | `Area2D`, `class_name Altar` | Generic altar: shows the `Hint` prompt on entering its range, and only actually triggers one of `UNLOCK`/`SET_SLOTS`/`PERMANENT_SACRIFICE` when `interact` (E) is pressed; a `one_shot` altar stops showing/responding after triggering once. |
| `hud.gd` | `CanvasLayer` | Icon-based status display (slots + concept icons, three states) + full-screen toggle-flash feedback + the UI fade-out/disintegration after sacrificing `hud` (`_dismantle()`). |
| `ending_sequence.gd` | `CanvasLayer`, `process_mode = Always`, `layer = 10` | The `fourthwall` ending: HUD fade-out → black overlay → text → black screen, purely visual. |
| `restart_controller.gd` | `Node`, `process_mode = Always` | On `restart` (R): `Sacrifice.reset()` + unpause + reload the current scene. Attached to `RestartController.tscn`. |
| `hud_collapse_platforms.gd` | `Node2D` | After `hud` is permanently sacrificed, spawns one falling, one-time solid platform at each of its own `Marker2D` child node positions. |
| `ground.gd` | `StaticBody2D`, `@tool` | Reusable floor/platform geometry block: `size`/`color` exports drive the collision shape (`RectangleShape2D`) and visible polygon (`Polygon2D`) to stay in sync, live in the editor. Attached to `Ground.tscn`. |
| `room_template.gd` | `Node2D`, comment-only, no logic | Room-building instructions for the level designer, attached to `RoomTemplate.tscn`. |

**Confirmed absent this session** (should stay absent — if either reappears, delete it, it's a known "resurrecting file" phenomenon of unknown cause): `scripts/observation_gate.gd`, `scripts/pause_controller.gd`.

### `scenes/`
| Scene | Structure | Notes |
|---|---|---|
| `Player.tscn` | `CharacterBody2D`(player.gd) > `CollisionShape2D` + `AnimatedSprite2D`(placeholder frames) + `Camera2D` | `config` points to `tuning/default.tres`; `collision_layer = 2`. ⚠️ `sprite_path` is serialized as literal `null` in the scene file (confirmed still the case this session — see Known Issue item 2 in Section 5). |
| `Altar.tscn` | `Area2D`(layer 0/mask 2, altar.gd) > `CollisionShape2D`(48×64 rectangle) + `Visual`(yellow Polygon2D) + `Hint`(Label, hidden by default) | All three Actions rely on this one scene, configured via the Inspector. |
| `BlueObject.tscn` | `StaticBody2D`(layer 1, blue_object.gd) > `CollisionShape2D`(32×32) + `Visual`(blue Polygon2D) | `concept_id` defaults to `"blue"`; change this field to reuse it for another concept. |
| `HUD.tscn` | `CanvasLayer`(hud.gd) > `Layout`(VBox) > `SlotsRow`+`IconsRow`(HBox); `FlashOverlay`(ColorRect, a sibling node) | |
| `EndingSequence.tscn` | `CanvasLayer`(layer=10, process_mode=Always, ending_sequence.gd) > `Overlay`(black ColorRect) + `Label` | Each level instance manually wires `hud_fade_target_path` to that level's own `HUD/Layout`. |
| `HudCollapsePlatforms.tscn` | bare `Node2D`(hud_collapse_platforms.gd), no default children | Each level instance adds its own `Marker2D` child nodes to set the landing spots. |
| `Ground.tscn` | `StaticBody2D`(layer 1, `ground.gd`) > `CollisionShape2D` + `Visual`(Polygon2D) | Generic floor/platform/ceiling/wall prefab; `size`/`color` exported; use the node's `scale` for an overall stretch. |
| `SacrificeInput.tscn` | `Node`(sacrifice_input.gd) | Standalone prefab; `bindings` dictionary editable in the Inspector. |
| `RestartController.tscn` | `Node`(`process_mode=Always`, restart_controller.gd) | Standalone prefab; no adjustable parameters. |
| `RoomTemplate.tscn` | `Node2D`(room_template.gd) > `Ground`(a Ground.tscn instance) + `ExampleAltar` + `ExampleMechanism` | The copy starting point for level design. **`project.godot`'s `run/main_scene` currently points here — see the Section 2/Step 5 discrepancy note and Section 5, item 7.** |
| `IntegrationLevel.tscn` | Step 5's R1→R6 integration level; **intended to be the project's main scene, but currently is NOT the one `run/main_scene` points to** (see above) | See Section 2's Step 5 entry for the full room-by-room layout. All floors/platforms/ceilings/walls are `Ground.tscn` instances; `SacrificeInput`/`RestartController` nodes are instances of the corresponding prefabs. |

**Confirmed absent this session** (known "resurrecting files" — if either is found present again, just delete it): `scenes/TestRoom.tscn`, `scenes/ObservationGate.tscn`.

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

**Currently meaningful concept ids and which listens for each** (any other string id can technically be unlock/activate/permanently_sacrifice'd through the API without error, but nothing will visibly react unless a listener like the ones below exists for it):

| id | Action it's used with | Listener |
|---|---|---|
| `"gravity"` | `UNLOCK` | Hardcoded in `player.gd` (`if id != "gravity": return`) |
| `"blue"` | `UNLOCK` | `BlueObject.tscn` / `blue_object.gd` (default `concept_id`) |
| `"jump"` | `PERMANENT_SACRIFICE` | Hardcoded in `player.gd` (`Sacrifice.is_permanently_sacrificed("jump")`) |
| `"hud"` | `PERMANENT_SACRIFICE` | `hud.gd` + `hud_collapse_platforms.gd` |
| `"fourthwall"` | `PERMANENT_SACRIFICE` | `ending_sequence.gd` |

---

## 4. Current Architectural Conventions / Invariants (must not be broken)

1. All sacrifice-related state lives only in the `Sacrifice` singleton (`sacrifice_manager.gd`); any other system interacts with it only through its signals/query functions — **never build a second global state holder**.
2. All of the player's feel values come only from `PlayerConfig` (`tuning/default.tres`); `player.gd` must never contain a hardcoded movement/jump number.
3. Unified pattern for "objects that react to a sacrifice": listen to the `Sacrifice` signal, filter by its own `concept_id`, following `blue_object.gd`; never add object-specific branches inside the `Sacrifice` singleton. `hud_collapse_platforms.gd` is the second template for this pattern (its response style is "spawning geometry" rather than "toggling geometry").
4. The single-slot / double-slot / permanent-sacrifice rules are implemented only inside the `Sacrifice` singleton (`activate`/`set_max_slots`/`permanently_sacrifice`) — never reimplemented elsewhere.
5. Collision layers: world entities (terrain, `Ground`, `BlueObject`, the hud collapse platforms) = Layer 1; the player = Layer 2; `Altar` is an `Area2D` with `collision_layer = 0` / `collision_mask = 2` (only detects the player entering, doesn't participate in physics collision).
6. The autoload name must be exactly `Sacrifice` (capital S); currently in `project.godot` it's `Sacrifice="*uid://10vfev3uue5r"`, corresponding to `sacrifice_manager.gd` (confirmed this session).
7. `Player` has `class_name Player`, dedicated to letting `altar.gd` and similar scripts do `body is Player` type checks; conversely, "object-side" scripts like `blue_object.gd` deliberately don't have a `class_name`, to avoid name collisions when copy-pasted and renamed.
8. Nodes that need to keep working while `get_tree().paused = true` (`EndingSequence`, `RestartController`) always set `process_mode` to `3` (Always) — the project-wide, unified technique for "surviving across pause"; don't use any other method (e.g. manually checking the paused state) to work around the pause system.
9. "Positions the level designer needs to place," such as altar landing spots or HUD collapse platform landing spots, are always configured via `Marker2D` child nodes or Inspector fields — never hardcode coordinates in a script (`hud_collapse_platforms.gd` is the demonstration of this convention).
10. Floors/platforms/ceilings/walls always use `Ground.tscn` instances (`size`/`color` exported) — don't hand-write the `StaticBody2D`+`CollisionShape2D`+`Polygon2D` triple anymore; `ground.gd` is the sole place responsible for keeping the collision shape and visible polygon in sync.
11. The project does no audio, full stop. Don't add an `AudioStreamPlayer`, SFX-playback logic, or any "reserved audio hook" placeholder code — this is an already-settled scope change, not a temporary omission, and not something to pick back up in Step 6.
12. AI assistant hard rules (from `CLAUDE.md`, reiterated here): no git operations of any kind; no modifying Project Settings (autoload/Input Map/main scene are configured manually by a human — this is exactly why the Section 2/Step 5 main-scene discrepancy below has to be fixed by a human, not by the AI); only work within the scope of the current DEV_PLAN step.

---

## 5. Known Issues / Workarounds / TODOs

1. **`project.godot`'s `run/main_scene` currently points to `RoomTemplate.tscn`, not `IntegrationLevel.tscn` (found this session, needs a human to fix)**: see the detailed note in Section 2's Step 5 entry. `run/main_scene = "uid://cvxqb1ysmem20"` resolves to `scenes/RoomTemplate.tscn`; the actual full R1→R6 demo level `scenes/IntegrationLevel.tscn` has uid `uid://bkdctvarex6yi`. Until a human repoints this in the editor (Project Settings > Application > Run > Main Scene), **pressing F5 boots the bare room template, not the playable demo** — this is very likely to confuse whoever picks this project up next if it isn't fixed first. The AI cannot fix it (Project Settings are off-limits per `CLAUDE.md`).
2. **`sacrifice_input.gd`'s UID warning (low priority, purely a console notice, doesn't affect functionality)**: the `ext_resource` reference to `sacrifice_input.gd` in `SacrificeInput.tscn` occasionally gets its `uid=` attribute rewritten back to a stale value by the editor, causing an "invalid UID... using text path instead" warning in the console. Suspected to be an in-memory `ResourceUID` cache issue inside the editor process; "Reload Current Project" doesn't clear it — a full quit and restart of the Godot editor is theoretically needed. The game itself loads fine via the text-path fallback; this is purely console noise.
3. **`Player.tscn`'s `sprite_path` is serialized as literal `null` (unconfirmed whether this has any real impact)**: the script's default value is `^"AnimatedSprite2D"`, but the scene file currently has `sprite_path = null` (confirmed still present this session, line 15 of `Player.tscn`). In `player.gd::_ready()`, `_sprite = get_node(sprite_path) as AnimatedSprite2D` — if `null` really is being passed in, `_sprite` should end up `null`; `_update_animation()` already null-checks `_sprite`, so **the worst case is animation silently not playing, with no error or crash**. Never verified in isolation whether this actually manifests at runtime — worth confirming in the Inspector whether `Player.tscn`'s `Sprite Path` field correctly points at `AnimatedSprite2D` next time the editor is open.
4. **The altar's `Hint` prompt isn't forced to the top layer and may be occluded by foreground objects in the level**: `Hint` is a plain `Label` inside the 2D scene tree in `Altar.tscn` (floating above the altar), not a `CanvasLayer`, with no `z_index` bump or dedicated UI layer. If a room design stacks another foreground object at the same screen position directly above an altar, the hint text may be visually occluded. Deferred (post-MVP could move it to a `CanvasLayer` or add a `z_index`); during level design, just avoid this kind of stacking to sidestep it.
5. **`tuning/default.tres`'s `jump_height` has already changed once outside of a documented dev step (currently `150.0`)**: this isn't necessarily a bug — feel tuning is expected to move — but it means **this file's numbers for tunable values can silently go stale**; always re-read `tuning/default.tres` directly rather than trusting a cached number if the exact current feel matters for a task.
6. **The `pause` sacrifice gameplay has been removed entirely, but the `pause` (Escape) action definition in the Input Map is still there**: per the `CLAUDE.md` hard rules, Project Settings can only be changed manually by a human in the editor, so the AI can't delete this stray binding. **This is expected and harmless: no script currently listens to it, and pressing Escape does nothing.** If a human wants to clean it up, they need to delete this row in the editor's Input Map panel themselves.
7. **Two files have a history of unexplained resurrection on disk**: `scenes/TestRoom.tscn` and `scenes/ObservationGate.tscn` have each, on separate past occasions, reappeared on disk after being deleted, for reasons never identified (suspected local Godot editor caching/auto-write-back behavior, not manual human restoration). Both are confirmed absent as of this session's grep. If either turns up again: `TestRoom.tscn` should not exist now that `IntegrationLevel.tscn` is the intended single level, and `ObservationGate.tscn` references a script that no longer exists and is instantiated nowhere — in both cases, just delete the file.

---

## 6. What's Next

**Current progress: Step 5 (including the hud mechanism rework and the prefab-ification/audio-removal/doc-consistency cleanup done after Step 5) is complete. Step 6 has not yet begun.**

**Before Step 6 work starts, flag/fix item 1 in Section 5** (the `run/main_scene` pointing at `RoomTemplate.tscn` instead of `IntegrationLevel.tscn`) — this needs a human to change in the editor; the AI cannot do it. Everything else previously blocking Step 6 (the `TestRoom.tscn`/`ObservationGate.tscn` resurrected-file cleanup) is done as of this session.

**Step 6 (polish + handoff packaging) — per `DEV_PLAN_CORE.md`, this step is polish and packaging only. There is no audio work in Step 6 or anywhere else in the plan — audio is fully out of scope (see Section 4, item 11).** TODO items:
- Give the existing feedback effects — toggle tint, ending disintegration — a pass to see if they need tweaking.
- Assemble the handoff documentation bundle (see below).

**What needs to be ready to hand to B (gimmicks/mechanisms, extending new concepts)**:
- Two directly copyable reactive-object templates: `BlueObject.tscn` (the toggle-collision + transparency type) and `HudCollapsePlatforms.tscn` (the spawn-geometry-on-sacrifice type).
- A write-up on "how to add a new concept": copy the template → change `concept_id` → place a `UNLOCK`-type `Altar` → add a line to `SacrificeInput.bindings` for the key binding (GDD §7.6 "extension pattern").
- Make clear that the reserved concepts (`friction`/`time`/`sound`) are to be implemented by B, reusing the pattern of the two templates above.

**What needs to be ready to hand to C (map/level design)**:
- Usage notes for `RoomTemplate.tscn` + `room_template.gd`, and `scenes/HOW_TO_BUILD_A_LEVEL.md` (already delivered, trilingual — see Section 2's "After Step 5" entry).
- The prefabs `Ground.tscn`/`SacrificeInput.tscn`/`RestartController.tscn` — usage is covered in `HOW_TO_BUILD_A_LEVEL.md`.
- How to configure `Altar.tscn`'s three `Action`s in the Inspector, and specifically which `Concept Id` strings currently do something (see the table in Section 3).
- One reference full level: `IntegrationLevel.tscn` (currently NOT wired as the main scene — see Section 5, item 1 — but playable by opening it directly in the editor and running that scene).
- Direction for extending the level: lengthen/add areas within this same `IntegrationLevel.tscn` scene, rather than splitting into multiple independent scenes connected by transitions — the project has formally abandoned the room-switching-system approach.
- Two hard constraints that must be followed: GDD §5.4 (after sacrificing `jump` for the double slot, the player must never be required to press jump all the way to the end) and GDD §7.7 (don't design a puzzle that requires "restoring blue while inside a blue wall").

---

## 7. Input Mapping & How to Run It

### Input Map (`project.godot`'s current actual configuration, re-verified this session)
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

### Main Scene — ⚠️ currently misconfigured, see Section 5 item 1
`project.godot`'s `run/main_scene` is currently `"uid://cvxqb1ysmem20"`, which is **`scenes/RoomTemplate.tscn`**, not the intended `scenes/IntegrationLevel.tscn` (`uid://bkdctvarex6yi`). **As things stand, pressing F5 does not run the full R1→R6 demo** — it opens the bare room template. To actually play/test the full game (gravity/blue, the double-slot shrine, permanent sacrifice of jump, the hud icon-falling-platform demo, the fourthwall ending), open `scenes/IntegrationLevel.tscn` in the editor and use "Run Current Scene" instead of F5, until a human repoints the project's main scene setting.

### autoload
`Sacrifice = "*uid://10vfev3uue5r"`, corresponding to `scripts/sacrifice_manager.gd`.

### Restarting with R
`restart_controller.gd` (`process_mode = Always`, attached via a `RestartController.tscn` instance in `IntegrationLevel.tscn`) listens for the `restart` action: it calls `Sacrifice.reset()` (clears all unlocked/active/permanently-sacrificed concepts, resets slots to 1) → `get_tree().paused = false` (prevents getting stuck in the ending's black-screen paused state) → `get_tree().reload_current_scene()`. Because `Sacrifice` is an autoload and `paused` is a SceneTree-level flag, neither resets automatically on scene reload, so these two steps are mandatory and can't be skipped. R can also be pressed to restart while the ending is playing.
