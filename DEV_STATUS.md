# DEV_STATUS.md — Current Development Status Snapshot for 《Sacrifice》

> **This file records "what the code actually looks like right now," not the GDD's ideal design.**
> Design follows `GDD.md`; collaboration hard rules follow `CLAUDE.md`; **development progress follows this file.**
> Every time a change is completed, update the corresponding section of this file so the next person who picks this up (human or AI, with no memory of prior sessions) can know the current state without digging through the code.

## 0. Project Status: **Development Complete**

All of `DEV_PLAN_CORE.md`'s Steps 1–6 are done, plus several rounds of post-plan additions (title screen, a three-level chained structure, `red`/`green` concepts, audio, a redundant-code cleanup pass — all described below). There is no active "next step" — this file now documents a finished shipped state, not work in progress. If new work starts later (new concepts, new levels, art/audio passes), treat Section 6 ("Known Gaps / Possible Future Work") as the starting point, and keep updating this file as that work happens.

---

## 1. One-Sentence Project Summary + Doc Index

《Sacrifice》 is a Godot 4.x "subtractive Metroidvania": the player permanently or temporarily sacrifices abstract concepts (gravity, colors, jump, the HUD, the fourth wall…) to get through places that were otherwise impassable — the further you play, the less you have, but the more places you can reach.

- **`GDD.md`** — the sole design authority. Describes "what it should be." Runs §0–§10 plus Appendices A/B, no gaps (renumbered after the original audio-exclusion section was removed).
- **`DEV_PLAN_CORE.md`** — the original breakdown of build steps (Steps 1–6). Describes "what order things were built in" — a historical record; some of its architectural decisions (notably Step 5's single-scene plan) were later revisited, see Section 2.
- **`CLAUDE.md`** — AI collaboration hard rules (no git, no touching Project Settings, architectural hard rules, etc.).
- **`DEV_STATUS.md`** (this file) — describes "how far things have actually gotten, what it actually looks like, and what the gotchas are."
- **`scenes/HOW_TO_BUILD_A_LEVEL.md`** — a build tutorial for extending the game with new levels/concepts (Chinese/English/Japanese).
- **`scenes/change_point.md`** — a running changelog of feature-level changes, in the same trilingual format.

**Rule of thumb: design follows `GDD.md`; actual behavior follows this file.** Where the two disagree, this file wins for "what currently exists."

---

## 2. Architecture: Title Screen → Three Chained Levels → Title Screen

**This is the single biggest architectural fact to know before touching anything.** The project does **not** use one continuous single scene the way `DEV_PLAN_CORE.md`'s Step 5 originally decided (that decision is now superseded — see the note in that file). Instead, the shipped game is **four separate scenes connected by `get_tree().change_scene_to_file()`**, forming a loop:

```
TitleScreen.tscn --(interact)--> Level1.tscn --(fourthwall altar)--> Level2.tscn --(fourthwall altar)--> Level3.tscn --(fourthwall altar)--> TitleScreen.tscn
```

- `project.godot`'s `run/main_scene` is `TitleScreen.tscn` (confirmed this session, resolves via `uid://c2l1q3xpsacrf`).
- Each of `Level1.tscn`/`Level2.tscn`/`Level3.tscn` is a **fully self-contained playable scene**: its own `Player`, `HUD`, `SacrificeInput`, `RestartController`, and `EndingSequence` instances, plus its own set of `Altar`/`Ground`/reactive-object content. None of them share a camera or scene tree with each other.
- The mechanism that chains them: every `EndingSequence` instance has an `@export_file("*.tscn") var next_scene_path` and an `@export var skip_sequence: bool` (see `ending_sequence.gd`, Section 4). When the level's `"fourthwall"` altar is triggered:
  - `Level1.tscn`'s `EndingSequence` has `skip_sequence = true`, `next_scene_path` pointing at `Level2.tscn` — pressing the altar skips the fade/text entirely and jumps straight to `Level2.tscn`.
  - `Level2.tscn`'s `EndingSequence` likewise has `skip_sequence = true`, `next_scene_path` pointing at `Level3.tscn`.
  - `Level3.tscn`'s `EndingSequence` has **no override** — it uses the script default (`skip_sequence = false`, `next_scene_path = "res://scenes/TitleScreen.tscn"`), so reaching the end of `Level3` plays the **real** ending (HUD fade → black dissolve → "Thank you for playing." → hold → fade to black), then automatically returns to `TitleScreen.tscn`.
  - `Sacrifice.reset()` is called every time `_to_next_scene()` runs (regardless of `skip_sequence`), so every level starts with a clean slate — concepts unlocked/active/permanently-sacrificed in one level do **not** carry over to the next.
- `TitleScreen.tscn` also calls `Sacrifice.reset()` in its own `_ready()`, so landing back on the title screen (whether via the real ending or a manual `restart`) is always guaranteed clean.
- Each level's altar that triggers this chain uses `concept_id = "fourthwall"` — the **same id** is reused in all three levels to mean "advance to the next scene," and only in `Level3` does it coincide with the GDD's literal "the game's true ending." This works correctly (thanks to the per-scene `Sacrifice.reset()`), but is a deliberate, known overload of one concept id across three different meanings — not a bug, just worth knowing before grepping for `"fourthwall"` and assuming every hit is "the ending."

### Why this exists despite `DEV_PLAN_CORE.md` Step 5 saying "no room-switching, one continuous scene"
That decision was the plan at the time Step 5 was executed, and the resulting single level (originally `IntegrationLevel.tscn`) is still exactly what `Level1.tscn` is today. Later, the project was extended by chaining two more full levels onto the end of it (`Level2.tscn`, originally the copyable `RoomTemplate.tscn`, repurposed into real content; `Level3.tscn`, originally `ColorLevel.tscn`, a large standalone level built separately and wired in afterward) using scene transitions — i.e., exactly the "room-switching" approach Step 5's decision explicitly ruled out. `DEV_PLAN_CORE.md` itself hasn't been rewritten (it's a historical build-order record, now annotated as superseded), but treat its single-scene framing as replaced by what's described in this section.

---

## 3. Each Level's Content

All three levels reuse the exact same prefabs (`Ground.tscn`, `Altar.tscn`, `BlueObject.tscn`/`RedObject.tscn`/`GreenObject.tscn`, `HudCollapsePlatforms.tscn`, `SacrificeInput.tscn`, `RestartController.tscn`, `HUD.tscn`, `EndingSequence.tscn`, `Player.tscn`) — nothing level-specific was hardcoded outside `Inspector`-configured instances. The following is a structural summary from reading each scene file directly (not a manual playthrough — if the exact puzzle sequencing matters, open the scene in the editor).

### `Level1.tscn` (the original Step 5 integration level; root has `integration_intro.gd` attached)
- Divides content into R1–R6 by coordinate ranges (node names still say `R1Ground`, `R2Ledge`, etc.).
- Concepts introduced: `gravity` (R1) → `blue` (R3) → `hud` permanently sacrificed (R3, drops `HudCollapsePlatforms` steps) → double slot + `jump` permanently sacrificed at the shrine (R4) → a blue vertical shaft requiring `gravity`+`blue` together (R5) → `fourthwall` altar (R6). This altar's hint text ("Press E to Sacrifice the Fourth Wall (Ends the game, unreversible)") describes the level's *original*, pre-chain behavior rather than what it does now (advances to `Level2`) — reviewed this session and intentionally left as-is by project decision.
- Root node's `integration_intro.gd`: the player starts frozen, shown as the title-screen "stand" pose; pressing `interact` shatters that pose into 4 sprite-quadrant shards and hands control to the normal `Player`. See Section 4 for how this sources its `SpriteFrames`.
- Bounded by a 3000×3000 square of `SafetyFloor`/`SafetyFloor2`/`SafetyFloorLeft`/`SafetyFloorRight` (the left/right walls are the same `Ground.tscn` prefab rotated 90°).
- No `red`/`green` content anywhere in this level.

### `Level2.tscn` (originally `RoomTemplate.tscn`; root now has **no script** — see Section 4)
- A full altar chain in its own right: `fourthwall` (advance to `Level3`) → `blue` → `gravity` → `red` (`RedAltar`/`RedObject`) → `green` (`GreenAltar`/`GreenObject`) → `hud` (permanently sacrificed, drops one `HudCollapsePlatforms` platform) → a `SET_SLOTS` altar (`Altar4`) → `jump` permanently sacrificed (`Altar6`). Eleven `Ground`/`Ground2`…`Ground11` instances plus two `BlueObject`/`BlueObject2` instances make up the terrain.
- This is the level formerly known as `RoomTemplate.tscn` — it used to be a non-gameplay copy-source template for level design, and the `room_template.gd` script that documented that role has been removed (it no longer applies; see Section 4). There is currently **no reusable "room template" scene anywhere in the project** — that deliverable was consumed when this scene was repurposed into real content. If a fresh copyable template is wanted later, it would need to be built from scratch (a plain `Node2D` + one `Ground` + one `Altar` + one `BlueObject`, per the pattern `HOW_TO_BUILD_A_LEVEL.md` already documents from scratch).

### `Level3.tscn` (originally `ColorLevel.tscn`; root has no script)
- The largest of the three: a full altar chain under an `Altar` group node (`AltarGravity`/`AltarRed`/`AltarGreen`/`AltarSlots`/`AltarJump`/`AltarHud`/`AltarSlot2`/`AltarFourthwall`/`AltarBlue` — note `AltarSlots` and `AltarSlot2` are two separate `SET_SLOTS` altars, both `action = 1`; this is the scene's existing structure, not something changed this session), a large amount of grouped terrain (`Ground`/`safety`), and three color-grouped reactive-object clusters (`Blue`, `Red`, `Green`, each with a dozen-plus wall/platform instances).
- This is the level whose `EndingSequence` plays the real, full ending sequence and returns to `TitleScreen.tscn` — see Section 2.

---

## 4. Key File Inventory

### `scripts/`
| File | Type | Responsibility |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | The single global source of sacrifice state and signals. See the public interface below. |
| `player_config.gd` | `Resource`, `class_name PlayerConfig` | Container for the player's feel values (movement/jump/friction/coyote/buffer). |
| `player.gd` | `CharacterBody2D`, `class_name Player` | Movement + split-gravity jump + `gravity` sacrifice response + animation state machine + jump SFX. `jump_sound_path: NodePath` (default `^"JumpSound"`) resolved via `get_node_or_null()` into a typed, null-guarded `_jump_sound: AudioStreamPlayer2D` — the only audio anywhere in the project. |
| `blue_object.gd` | `StaticBody2D` (no `class_name`) | Generic reactive-object template: listens to the signal, toggles collision-disable + transparency based on its own `concept_id`. `blue`/`red`/`green` all use this same script with a different `concept_id`. |
| `sacrifice_input.gd` | `Node` | `@export var bindings: Dictionary` maps input actions to concept_ids; currently `1→gravity, 2→blue, 3→red, 4→green`. |
| `altar.gd` | `Area2D`, `class_name Altar` | Generic altar: shows a `Hint` prompt on entering range, triggers one of `UNLOCK`/`SET_SLOTS`/`PERMANENT_SACRIFICE` on `interact`; `one_shot` altars stop responding after one trigger. |
| `hud.gd` | `CanvasLayer` | Icon-based status display (slots + concept icons, three states) + toggle-flash feedback + UI fade-out after `hud` is sacrificed. |
| `ending_sequence.gd` | `CanvasLayer`, `process_mode = Always`, `layer = 10` | The `fourthwall` handler: HUD fade-out → black overlay → text → black screen (unless `skip_sequence`) → `Sacrifice.reset()` → `change_scene_to_file(next_scene_path)`. **Field names**: `next_scene_path` (was `title_scene_path`) and `_to_next_scene()` (was `_return_to_title()`) — renamed to reflect that this is now a generic "go to the next configured scene" mechanism used for level-to-level chaining, not literally always "return to the title." |
| `restart_controller.gd` | `Node`, `process_mode = Always` | On `restart` (R): `Sacrifice.reset()` + unpause + reload the current scene. |
| `hud_collapse_platforms.gd` | `Node2D` | After `hud` is permanently sacrificed, spawns one falling, one-time solid platform at each of its own `Marker2D` child positions. |
| `ground.gd` | `StaticBody2D`, `@tool` | Reusable floor/platform/wall prefab; `size`/`color` exports keep the collision shape and visible polygon in sync. |
| `title_screen.gd` | `Node2D` | Title screen: shows the title character in the "stand" pose over a non-interactive `Level1.tscn` preview; `interact` plays a shatter-tween then loads `next_scene_path` (default `Level1.tscn`). Calls `Sacrifice.reset()` on `_ready()`. |
| `integration_intro.gd` | `Node`, attached to `Level1.tscn`'s root | Intro-unlock gate: freezes `Player`, shows the "stand" pose, `interact` shatters it into gameplay. |

**`scripts/room_template.gd` has been deleted** (along with its `.uid` sidecar) — it was a comment-only script whose entire content was "this scene is a copy-source template, don't add real gameplay to it," which became actively wrong once `Level2.tscn` (its one and only attachment point) was repurposed into a real level. See Section 3's `Level2.tscn` entry.

**Stand-frame construction has been de-duplicated**: `title_screen.gd` and `integration_intro.gd` used to each independently rebuild an identical 4-frame "stand" `SpriteFrames` animation at runtime from raw PNGs (`_build_stand_frames()`, plus `stand_frame_paths`/`stand_animation_speed` exports, byte-for-byte duplicated in both scripts). A pre-baked resource with the exact same content, `assets/player/title_stand_frames.tres`, already existed and was already wired into both scenes but was being silently overridden/bypassed by the runtime-built version. The runtime-building code has been deleted from both scripts; `title_stand_frames.tres` (via `TitleScreen.tscn`'s `Character.sprite_frames` and `Level1.tscn`'s `locked_frames` export) is now the actual, sole source — no behavior change, just removed duplication and made the `.tres` non-dead.

**Confirmed absent** (known "resurrecting files" from early sessions — if any reappear, delete them, cause unknown, suspected editor caching): `scripts/observation_gate.gd`, `scripts/pause_controller.gd`, `scenes/TestRoom.tscn`, `scenes/ObservationGate.tscn`. Also confirmed absent as of this session: any remaining reference anywhere in code to the old scene names `IntegrationLevel.tscn`/`RoomTemplate.tscn`/`ColorLevel.tscn` (fully renamed to `Level1`/`Level2`/`Level3`).

### `scenes/`
| Scene | Notes |
|---|---|
| `Player.tscn` | `CharacterBody2D`(player.gd) + `CollisionShape2D` + `AnimatedSprite2D` + `Camera2D` + `JumpSound`(`AudioStreamPlayer2D`, plays `assets/audio/jump.wav`). `sprite_path` isn't serialized in the scene (uses the script default `^"AnimatedSprite2D"`, which matches). |
| `Altar.tscn` | `Area2D`(layer 0/mask 2) + `CollisionShape2D`(48×64) + `Visual` + `Hint`(Label). |
| `BlueObject.tscn` / `RedObject.tscn` / `GreenObject.tscn` | All three are the same structure running `blue_object.gd`, differing only in `concept_id` (`"blue"`/`"red"`/`"green"`) and visual color. |
| `HUD.tscn` | `CanvasLayer`(hud.gd) — icon rows + slot rows + a full-screen `FlashOverlay`. |
| `EndingSequence.tscn` | `CanvasLayer`(layer=10, process_mode=Always, ending_sequence.gd) — see Section 2 for the chaining mechanism. |
| `HudCollapsePlatforms.tscn` | Bare `Node2D`; landing spots are `Marker2D` children added per level. |
| `Ground.tscn` | Generic floor/platform/wall prefab. |
| `SacrificeInput.tscn` / `RestartController.tscn` | Standalone input-handling prefabs, one instance per level. |
| `TitleScreen.tscn` | The current `run/main_scene`. Contains a non-interactive `Level1.tscn` instance as a backdrop preview. |
| `Level1.tscn` / `Level2.tscn` / `Level3.tscn` | The three chained levels — see Section 3. |

---

## 5. `Sacrifice` Singleton Public Interface (`scripts/sacrifice_manager.gd`; autoload name must be exactly `Sacrifice`)
```gdscript
# Signals
signal concept_activated(id: String)
signal concept_deactivated(id: String)
signal concept_unlocked(id: String)
signal slots_changed(new_slots: int)
signal concept_permanently_sacrificed(id: String)

# State
var max_slots: int = 1

# Queries
func is_unlocked(id: String) -> bool
func is_active(id: String) -> bool
func is_permanently_sacrificed(id: String) -> bool
func get_active() -> Array[String]
func get_unlocked() -> Array[String]

# Commands
func unlock(id: String) -> void
func activate(id: String) -> void
func deactivate(id: String) -> void
func toggle(id: String) -> void
func set_max_slots(n: int) -> void
func permanently_sacrifice(id: String) -> void
func reset() -> void
```

**Concept ids with a real listener:**

| id | Action | Listener |
|---|---|---|
| `"gravity"` | `UNLOCK` | Hardcoded in `player.gd` |
| `"blue"` | `UNLOCK` | `BlueObject.tscn` / `blue_object.gd` |
| `"red"` | `UNLOCK` | `RedObject.tscn` / `blue_object.gd`; placed in `Level2` and `Level3` (not `Level1`) |
| `"green"` | `UNLOCK` | `GreenObject.tscn` / `blue_object.gd`; placed in `Level2` and `Level3` (not `Level1`) |
| `"jump"` | `PERMANENT_SACRIFICE` | Hardcoded in `player.gd` |
| `"hud"` | `PERMANENT_SACRIFICE` | `hud.gd` + `hud_collapse_platforms.gd`; present in all three levels |
| `"fourthwall"` | `PERMANENT_SACRIFICE` | `ending_sequence.gd`; present in all three levels, means "advance to next scene" in `Level1`/`Level2` and "real ending" only in `Level3` (see Section 2) |

---

## 6. Known Gaps / Possible Future Work

These are not bugs blocking anything — the game is complete and playable start to finish. They're just open items that would need attention if work resumes:

1. **No reusable "room template" scene exists anymore** (Section 3's `Level2.tscn` note) — building a 4th level or reworking an existing one currently means copying node structure by hand rather than from a dedicated template.
2. **`Level1`'s `fourthwall` altar hint text is stale** ("Ends the game, unreversible") relative to its actual behavior (advances to `Level2`) — reviewed and intentionally left as-is by project decision.
3. **`Altar.triggered` signal is declared and emitted but has no listeners anywhere** — harmless dead code.
4. **`Level2`'s `EndingSequence` instance doesn't set `hud_fade_target_path`** (unlike `Level1`/`Level3`, which both wire it to `../HUD/Layout`) — invisible today since `skip_sequence = true` skips that step entirely; would silently no-op the HUD fade if `skip_sequence` were ever turned off there without also adding this.
5. **`project.godot`'s Input Map still has an unused `pause` (Escape) action** — nothing listens to it; harmless; can only be removed by a human in the editor (Project Settings are off-limits to the AI per `CLAUDE.md`).
6. **`tuning/default.tres`'s `jump_height` (currently `150.0`) has drifted before** — always re-read the file directly rather than trusting a cached number.
7. **The altar `Hint` label isn't a `CanvasLayer`** and can in principle be occluded by foreground level geometry stacked at the same screen position — avoid that kind of stacking when placing altars.

---

## 7. Input Mapping & How to Run It

| Action | Key |
|---|---|
| `move_left` / `move_right` | A / D |
| `jump` | Space |
| `sacrifice_gravity` | 1 |
| `sacrifice_blue` | 2 |
| `sacrifice_red` | 3 |
| `sacrifice_green` | 4 |
| `interact` | E |
| `restart` | R |
| *(`pause` exists in the Input Map but nothing listens to it)* | Escape |

**Running the game**: F5 boots `TitleScreen.tscn` (`run/main_scene`, `uid://c2l1q3xpsacrf`). `interact` (E) at the title enters `Level1.tscn`; another `interact` breaks the intro-gate pose into normal gameplay. Reaching each level's `fourthwall` altar and pressing `interact` advances to the next level; `Level3`'s ending plays in full and returns to the title screen. `R` resets and reloads the current level at any point, including mid-ending.

**Autoload**: `Sacrifice = "*uid://10vfev3uue5r"` → `scripts/sacrifice_manager.gd`.
