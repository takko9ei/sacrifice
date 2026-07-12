# 《Sacrifice》 Game Design Document (GDD)

> Status: Development baseline v1.0
> Engine: Godot 4.2+ (GDScript)
> Positioning: Game Jam deliverable demo; architecture reserved for long-term extension

---

## 0. About This Document

This file is the **sole authority** for the official development of 《Sacrifice》. All level, art, and programming work follows this document; any verbal agreement that conflicts with it is superseded by this document — revise this document first if a change is needed.

Suggested reading order: programmers read §2, §3, §7 first; level designers read §2, §5, §8.1; artists read §4, §6, §8.2; the feel-tuning lead reads §3, §8.3.

**Glossary**:
- **Concept**: an abstract object that can be sacrificed, identified by a string id (e.g. `gravity`, `blue`, `hud`).
- **Sacrifice**: making a concept's effect take hold. Comes in two kinds: "reversible" and "permanent."
- **Slot**: the maximum number of concepts that can be active at the same time. Starts at 1; becomes 2 after the "double slot" upgrade.
- **Altar**: a trigger that changes sacrifice state.
- **Signal bus**: the set of signals emitted by the `Sacrifice` singleton — the sole channel of communication between all systems.

---

## 1. Game Overview

### 1.1 One-Line Positioning
A "subtractive" Metroidvania: instead of gaining abilities, the player gets through places that were otherwise impassable by **sacrificing an abstract concept**.

### 1.2 Core Concept
Conventional Metroidvanias do addition (defeat the boss → gain the double jump → new area unlocked). This game does subtraction: the player keeps deleting concepts from the world. The key is that **every sacrifice cuts both ways** — closing off one thing while opening up another path. This lets it still fit into the Metroidvania's basic loop of "couldn't get through before, can now."

### 1.3 Core Design Pillars
The following three pillars take top priority in any tradeoff; when they conflict, the one listed first wins:

1. **Every sacrifice must cut both ways**: any sacrifice that is "all cost, no traversal payoff" is unacceptable and must be cut or redesigned.
2. **Readability first**: at any second, the player must be able to tell "what have I sacrificed right now, how many slots do I have left, which things are currently solid/ghosted."
3. **The sense of losing control that comes from subtraction is the theme**: the world grows emptier and stranger as the game progresses; clearing it means having stripped the world down to just the exit.

### 1.4 Platform & Scope
- Platform: PC (keyboard).
- Engine: Godot 4.2+, GDScript.
- Scope: a 5-minute-clearable demo containing one complete Metroidvania loop. **Scope discipline is covered in §9.1 — anything not on the MVP list does not get built during the jam.**

### 1.5 Tone
Altars and the world treat "sacrifice" in a transactional, unemotional way. The tone is conveyed through **details within the world** (an altar's reaction, extremely short text, the UI disintegrating), not through exposition or narration. Implementation principle: **restraint over volume — let the player stumble onto it themselves, don't spell it out.**

---

## 2. Core Mechanic: The Sacrifice System

### 2.1 Overall Principle
Every sacrifice produces two results at once: losing a concept's original function + gaining a new way to get through. Both sides must be spelled out explicitly whenever designing any sacrifice.

### 2.2 Two-Layer Structure
Sacrifices are split into two layers — this is the key to keeping the mechanic both playable and achievable within the jam's timeframe.

**Layer one — reversible tools (the player's movement system).** A handful of concepts act as always-on-hand tools that can be toggled **for free, instantly**, at any moment (number keys). Because toggling is free, the player is never soft-locked, and can toggle back even mid-air. In the demo these are `gravity` and `blue`.

**Layer two — permanent sacrifices (the world's spine).** A small number of irreversible sacrifices that change something globally or advance the main thread, triggered via altars. These carry the emotional weight and the progression of "the world is getting stripped bare." In the demo these are `jump` (the price of the double slot), `hud` (UI collapse), and the ending's fourth wall.

### 2.3 The Single-Slot Constraint
Core rule: **only `max_slots` concepts can be active at the same time** (initially 1). When toggling on a new concept while already at the slot limit, the **earliest-activated** one is automatically turned off.

This rule alone is a free puzzle generator: if a stretch "needs both A and B," it's impassable under a single slot, and the player must realize on their own that "I need both open at once" — that's the moment a Metroidvania "door" is erected.

### 2.4 The Double-Slot Upgrade
Partway through, the player gets the "double slot" upgrade via an altar (`max_slots` 1→2), allowing two concepts to be active at once. This is the game's "double jump" — getting it lets the player go back to places that were previously impassable due to the single slot and clear them in one go, completing the loop. The double slot itself is paid for with one permanent sacrifice (see §2.6's `jump`).

### 2.5 Concept Library — Master Table

| id | Type | Lose | Gain | Corresponding gate | Cost | Inclusion status |
|---|---|---|---|---|---|---|
| `gravity` | Reversible | Falling; instead "falls" upward | Walk on ceilings, go up through vertical shafts | A shaft with no footholds | Standing ground below loses meaning; can't actively go down | **MVP** |
| `blue` | Reversible | The solidity of blue objects | Pass through blue walls/doors | A blue barrier | Can't stand on blue platforms, can't press blue switches | **MVP** |
| `red` | Reversible | The solidity of red objects | Pass through red walls/doors | A red barrier | Can't stand on red platforms, can't press red switches | **Shipped** (post-MVP; §2.6's `blue` extension pattern, "red/yellow/etc." realized as red) |
| `green` | Reversible | The solidity of green objects | Pass through green walls/doors | A green barrier | Can't stand on green platforms, can't press green switches | **Shipped** (post-MVP; same extension pattern) |
| `jump` | Permanent | The ability to jump | Trades for the "double slot" upgrade | — (acts as the upgrade's price) | Loses the normal means of vertical movement | **MVP** |
| `hud` | Permanent | The ability to see your own sacrifice state | At the moment of sacrifice, the HUD icons fall into the level and crash into fixed solid platforms, steppable to reach places previously out of reach | A high ledge/gap that's out of reach | Must rely on memory and screen feedback to judge current state | **MVP** |
| `fourthwall` | Permanent | The integrity of the game as a "game" | "Getting out" (the ending) | — (the final exit) | The game ends | **MVP (ending)** |
| `friction` | Reversible | Friction (the whole world becomes ice) | Rush down slopes, slide across long drop-offs, squeeze through narrow gaps | A long slope/a continuous narrow gap | Precise platforming becomes harder, easy to overshoot | Reserved for extension |
| `time` | Reversible | Things that operate on a timer stop | Use frozen bullets/enemies as footholds | A bullet-hell room | Moving platforms you need also stop | Reserved for extension |
| `sound` | Reversible | The whole scene goes silent | Disables enemies that perceive via sound | A sound-based/sound-perceiving enemy area | Sound-triggered mechanisms can't be triggered | Reserved for extension |

> "Reserved for extension" = the mechanic works in principle but isn't implemented in this Demo — kept as a pool of future content.

### 2.6 Detailed Spec Per Concept

**`gravity` (gravity) — reversible, MVP**
- Effect: gravity direction flips; the player accelerates upward until landing on the ceiling; the character sprite flips vertically to indicate "now standing on the new surface."
- `up_direction` flips accordingly, so `is_on_floor()` and sticking to the ceiling work exactly as before.
- Cuts both ways: can now reach the ceiling, go up through shafts; but the ground below becomes useless, and there's no way to actively go down.
- Air control is unaffected, and it can be toggled back at any time.

**`blue` (blue solidity) — reversible, MVP**
- Effect: all collision bodies marked as blue lose their collision (become passable) and simultaneously turn translucent as a readability cue.
- Cuts both ways: can pass through blue walls; but can't stand on blue platforms or press blue switches. Restoring reverts everything — fully reversible.
- Can be extended into red/yellow/etc. multi-color-gate sets (reusing the same template script, changing only the id).

**`jump` (jump) — permanent, MVP**
- Trigger point: the double-slot shrine, as the price of the "double slot" upgrade.
- Effect: permanently disables the jump input. Irreversible once triggered.
- Design constraint: see §5.4 — everything from this trigger point to the end of the game must be completable without jumping.

**`hud` (the sacrifice-status indicator UI) — permanent, MVP**
- Effect: at the moment of sacrifice, the HUD icons in the corner of the screen fall into the game world and crash into several one-time static solid platforms at preset locations. The status UI is gone for good after this.
- What the two-sided trade gains: these "UI wreckage" platforms let the player step up to reach places that were otherwise unreachable (adding geometry out of thin air — the exact opposite of blue's "removing geometry").
- Cost: permanently losing the status display; from then on, the player can only judge what's currently active by memory.
- Scope of use: implemented as a single one-time set-piece, with the platform positions preset by the level designer — not built as a reusable system.

**`fourthwall` (the fourth wall / the game itself) — permanent, MVP (ending)**
- Trigger point: the final sacrifice at the final exit.
- Effect: hands over the fact that "this is a game," in exchange for "getting out." Represented as the interface disintegrating piece by piece (the HUD falling away, scene elements dissolving, ending in a black screen).
- Implementation constraint: **purely visual**, never actually manipulates the operating-system window. Producing the impression that "the interface is disintegrating" is enough.

---

## 3. Player & Controls Feel

### 3.1 Control Scheme
| Action | Input action name | Default key |
|---|---|---|
| Move left/right | `move_left` / `move_right` | A/D or ←/→ |
| Jump | `jump` | Space |
| Sacrifice gravity | `sacrifice_gravity` | 1 |
| Sacrifice blue | `sacrifice_blue` | 2 |
| Confirm altar action | `interact` | E |
| Restart (demo) | `restart` | R |

Key bindings can be freely changed without affecting feel. When adding a new concept, add a line to `SacrificeInput.bindings` and bind a key.

### 3.2 Movement Model
Uses a split-gravity model for good feel: given jump height h, rise time t_up, and fall time t_down, rise gravity = 2h/t_up², fall gravity = 2h/t_down², and launch speed = 2h/t_up. When t_down is smaller than t_up, the fall feels snappier. "Rise/fall" is judged relative to the current gravity direction, so the feel stays consistent after a flip.

### 3.3 PlayerConfig Parameter Table (Complete)
All feel values live in the `PlayerConfig` resource (.tres); the code has zero hardcoding, and changes take effect immediately at runtime.

| Parameter | Default | Meaning | Adjustment direction |
|---|---|---|---|
| `move_speed` | 180 | Max horizontal speed (px/s) | Higher = faster |
| `ground_acceleration` | 1800 | Ground acceleration to top speed | Higher = snappier |
| `ground_friction` | 2200 | Ground stopping | Higher = harder stop |
| `air_acceleration` | 1200 | Air turning force | Higher = more air control |
| `air_friction` | 400 | Air drag | Lower = floatier |
| `jump_height` | 64 | Peak jump height (px) | Higher = jumps higher |
| `time_to_peak` | 0.38 | Time from jump start to peak (s) | Lower = faster rise |
| `time_to_fall` | 0.30 | Time from peak back down (s) | Lower = snappier fall |
| `jump_cut_multiplier` | 0.45 | Fraction of upward speed kept on release | Lower = shorter tap jumps lower |
| `max_fall_speed` | 600 | Terminal speed along the gravity direction | Higher = can fall faster |
| `coyote_time` | 0.10 | Grace window after leaving the ground where jump still works (s) | Higher = more forgiving |
| `jump_buffer_time` | 0.10 | Pre-input window for jump before landing (s) | Higher = more forgiving |

### 3.4 Assist Feel
Must be implemented: coyote time, jump buffering, variable jump height (cutting short on key release). These three are the baseline for "good" platformer feel — they cannot be skipped.

### 3.5 Gravity-Flip Behavior Details
- The flip moment doesn't change horizontal velocity — only gravity direction and `up_direction` change.
- If the player is airborne at the moment of the flip, they keep accelerating along the new gravity; if on the ground, they start falling toward the other side.
- `flip_v` on the sprite is set automatically by the controller (requires the art to point `sprite_path` at a node that supports `flip_v` — see §8.2).

---

## 4. UI / UX Design

### 4.1 Essential UI
The **only "unplayable without it" UI in this game is the sacrifice-status indicator**. Everything else is a nice-to-have, kept minimal for the MVP.

### 4.2 Sacrifice-Status Indicator (Required)
- Content: number of slots (N boxes), one icon per unlocked concept.
- State visibility: not-unlocked = gray/hidden; unlocked-but-inactive = normal; active = highlighted.
- A text-based version is acceptable during the demo phase (the current HUD already implements Slots/Active/Unlocked); swap for icons once art is ready — the mechanics code doesn't change.

### 4.3 Toggle Feedback (Recommended)
At the instant a sacrifice toggles, give a very short full-screen reaction in addition to the icon change (a slight screen tint / a line of text popping up), giving weight to "the rules of the world just changed." This is a game-feel item, not information UI.

### 4.4 Control Prompts (Recommended, Diegetic Preferred)
Prompt the corresponding action the first time the player enters a given altar's range. Prefer making this a diegetic, in-world prompt (a sign next to the altar) rather than a standalone UI panel — cheaper to build and more in keeping with the tone. The prompt should state that confirming requires pressing `interact`.

### 4.5 UI Explicitly Not Built
Health bars (no combat damage), a minimap (the demo is only a few screens), a proper pause menu (the demo has no pause functionality), a main menu/settings (the jam build goes straight into the game, with at most one title screen).

### 4.6 UI as a Sacrifice Target
Two are included (`hud`, `fourthwall`); specs are in §2.6. Core design judgment: **UI-type sacrifices always go through the "permanent sacrifice" layer, never as an always-on-hand reversible tool** — because UI flickering on and off frequently would be annoying, and its irreversible loss lands squarely on the "the world is getting stripped bare" main-thread emotion. In implementation, these aren't new systems — it's just having the HUD script listen for `hud`/`fourthwall` signals the same way `BlueObject` listens for `blue`, and hide/disintegrate the corresponding elements (see §7.6).

**UI sacrifices not included, and why**: a health/failure-state sacrifice (this game has no fail state, so there's nowhere to hang it), a crosshair/aim-UI sacrifice (no directional-aiming action). Both are kept as reserves, to be reconsidered if the corresponding systems get added later.

---

## 5. Level Design

### 5.1 Design Principles
Every new mechanic is introduced in the rhythm of "**teach → test → see the threshold → get the key → break through**." The map is deliberately kept small, with short backtracks. The solution to any puzzle must be derivable by the player from the "lose→gain" two-sided relationship.

### 5.2 Full Demo Level Flow (Authoritative Level Goal)
The following 6-room flow is the authoritative goal for the Demo. The official level is built in the editor with a TileMap + placed altars/mechanism scenes (see §8.1); the current actual implementation progress and test level follow `DEV_STATUS.md`.

```
                 [R6  Exit · Ending (fourthwall)]
                      │ (upward)
                 [R5  Blue vertical shaft]  ← the core threshold, needs gravity+blue at once
                      │
   [R4 Double-slot shrine (sacrifice jump)]──[R3  Blue area · blue altar]
                      │
                 [R2  Gravity shaft]
                      │
                 [R1  Start · gravity altar]
```

- **R1 start (teach gravity, ~45s)**: flat ground, with an unreachable ledge to the right. Walk to the gravity altar → press interact to unlock → learn to sacrifice gravity → "fall" up to the ledge (now a ceiling-side foothold) → flip back to land at the exit. Teaches exactly one thing: sacrificing gravity makes "up" reachable.
- **R2 gravity shaft (test gravity, ~30s)**: a purely vertical passage, climbing to the top exit by alternating gravity between floor and ceiling. No enemies.
- **R3 blue area + blue altar (teach blue and reveal the threshold, ~60s)**: entering the door there's a blue wall → the blue altar → press interact to unlock → learn to sacrifice blue and pass through the wall. Key point: from this room you can see the entrance to R5's blue vertical shaft — a place that needs both "up" (gravity on) and "through the spikes" (blue on) at once, impassable either-or under a single slot. This is how the player realizes they need the double slot. R3 also connects to R4.
- **R4 double-slot shrine (get the double slot, ~60s)**: a dead-end room reachable on flat ground (**deliberately requires no jumping**). The shrine trades a permanent sacrifice of `jump` for the double slot (two altars stacked: `SET_SLOTS 2` + `PERMANENT_SACRIFICE jump`; standing within range of both and pressing interact (E) once triggers both simultaneously). Return to R3 after getting it.
- **R5 blue vertical shaft (break through the core threshold, ~45s)**: with both gravity and blue on at once, "fall" upward through an entire shaft lined with blue spikes to the top. This is exactly the "impassable before, now cleared with the new ability" moment — the loop completes here.
- **R6 exit · ending (~40s)**: a sealed exit + the final altar, demanding the `fourthwall` sacrifice; the UI disintegrates, the demo ends.

One playthrough takes about 5 minutes (7–8 minutes for a first-timer).

**Post-MVP: the shipped build extends past this R1–R6 flow.** The R1–R6 flow above is still exactly what the first of three chained levels (`Level1.tscn`) plays out — its `fourthwall` altar was originally "the ending" as described here, but now instead advances to a second full level (`Level2.tscn`, introducing `red`/`green` alongside repeats of `gravity`/`blue`/`hud`/the double-slot/`jump`), which in turn advances to a third, larger level (`Level3.tscn`, combining all six concepts including `red`/`green` into one bigger space). Only `Level3`'s ending is the literal, final "getting out" moment this section describes; `Level1`'s and `Level2`'s `fourthwall` altars now mean "advance to the next level" instead. See `DEV_STATUS.md` §2 for the exact chaining mechanism and §3 for each level's content — this section's per-room narrative (teach → test → threshold → key → breakthrough) was not re-authored room-by-room for `Level2`/`Level3`, only the concept/altar inventory is confirmed.

### 5.3 Gate-to-Key Correspondence Table
| Gate / obstacle | Location | Required sacrifice | Required slots |
|---|---|---|---|
| Unreachable ledge | R1 | `gravity` | 1 |
| Vertical passage | R2 | `gravity` (toggled repeatedly) | 1 |
| Blue wall | R3 | `blue` | 1 |
| Blue vertical shaft (up + spikes) | R5 | `gravity` + `blue` | 2 |
| Final exit | R6 | `fourthwall` | — |

### 5.4 Level Hard Constraint (Must Be Verified Manually)
If the double slot is obtained by permanently sacrificing `jump` (the default scheme), then **the entire stretch from R4 → R5 → R6 must never require jumping** (use gravity flipping to cover all vertical movement). R1–R3 can use jumping freely, since the player never backtracks through them. **Verification method: after sacrificing jump, walk through room by room to confirm the level is clearable.**

### 5.5 The UI-Collapse Set-Piece (`hud` sacrifice, MVP)
A dedicated drop point: an unreachable ledge/gap in front of the player. Nearby, an altar with `PERMANENT_SACRIFICE hud`. After triggering, the HUD icons fall into the world and crash into several solid platforms at their designed positions, letting the player climb up to the ledge and pass through. The payoff is clear: impassable before the sacrifice, passable afterward thanks to the footholds that appear out of nowhere. Because the platforms are one-time and fixed in position, this is a set-piece rather than a generic mechanism.

### 5.6 The Ending Sequence (R6)
The player walks to the final altar → presses interact to trigger `fourthwall` → in sequence: UI elements fall away/fade out one by one → scene elements dissolve → one closing line of text → black screen. The sequence is purely visual and never manipulates the OS window.

---

## 6. Art Direction

### 6.1 Visual Style
Clean, geometric, low-saturation as the base, with high-saturation colors carrying "sacrifice-related" semantic information. The style serves the readability pillar (§1.3.2), avoiding complex textures that would interfere with judging solid/ghosted state.

### 6.2 Color Semantics (Hard Readability Rule)
- **Passable/sacrificed** objects: translucent (default alpha 0.35) + an outline, clearly distinguished from solid objects.
- The color **blue** is reserved exclusively for `blue`-concept objects — never used as pure decoration, to avoid misleading the player.
- If red/yellow/etc. gates are added later, the same rule applies — each color dedicated to its own concept.
- Altars use distinct, eye-catching colors (current placeholders: yellow for normal altars, purple for the double-slot shrine, green for the endpoint).

### 6.3 Character & Animation
- Required animations: idle, run, jump/fall (can be merged).
- The player's visible node should be an `AnimatedSprite2D` (or `Sprite2D`), with the player's `sprite_path` pointed at it — the gravity flip automatically sets its `flip_v`, so art doesn't need to write any code.
- Animation state is self-managed by art in an `AnimationPlayer`/`AnimatedSprite2D`, driven simply by reading `velocity` and `is_on_floor()`.

### 6.4 Concept Icons
One icon per concept, needs to be distinguishable in all three states (gray/normal/highlighted). Can be omitted during the MVP phase, using the text-based HUD as a stand-in.

---

## 7. Technical Architecture

### 7.1 Overview
Every system that reacts to a sacrifice communicates **only through the `Sacrifice` singleton's signals**. This is the root of the architecture: adding a new concept, a new mechanism, or a new level almost never requires touching the core scripts — it only requires listening for the `concept_id` you care about.

### 7.2 Sacrifice Singleton API (Authoritative Interface)
Registered as an autoload; the node name must be `Sacrifice`.

Signals:
- `concept_activated(id)` / `concept_deactivated(id)`: a concept's effect turns on/off.
- `concept_unlocked(id)`: a concept becomes toggleable.
- `slots_changed(new_slots)`: the slot count changes.
- `concept_permanently_sacrificed(id)`: a concept is permanently sacrificed.

Queries: `is_unlocked(id)`, `is_active(id)`, `is_permanently_sacrificed(id)`, `get_active()`, `get_unlocked()`.

Commands: `unlock(id)`, `activate(id)`, `deactivate(id)`, `toggle(id)`, `set_max_slots(n)`, `permanently_sacrifice(id)`, `reset()`.

The single-slot constraint and double-slot logic are centralized in `activate()` and `set_max_slots()` (evicting the earliest-activated one when at the slot limit) — never write a second copy of this elsewhere.

### 7.3 Script Inventory & Responsibilities
| Script | Attached to | Responsibility |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | The sacrifice-state brain, signal bus, slot constraint |
| `player_config.gd` | Resource | Feel values (data, pure export) |
| `player.gd` | CharacterBody2D | Movement, gravity-flip response, jump disabling |
| `blue_object.gd` | StaticBody2D | Reactive-object template (listens for some concept, toggles collision + transparency) |
| `altar.gd` | Area2D | Triggers unlock/change-slots/permanent-sacrifice (confirmed via interact) |
| `sacrifice_input.gd` | Node | Maps input actions → concept toggles (editable in the Inspector) |
| `hud.gd` | CanvasLayer | Sacrifice-status display; also the object that reacts to `hud`/`fourthwall` |
| `ending_sequence.gd` | CanvasLayer | The `fourthwall` ending: HUD fade-out → black screen → text → black screen, purely visual |
| `restart_controller.gd` | Node | Restart on `restart` (R): resets sacrifice state and reloads the current scene |
| `hud_collapse_platforms.gd` | Node2D | After `hud` is permanently sacrificed, spawns falling platforms at Marker2D landing spots |
| `ground.gd` | StaticBody2D | Reusable floor/platform geometry block (`size`/`color` drive the collision shape and visible polygon) |
| `room_template.gd` | Node2D | Comment-only, room-building instructions for the level designer |

### 7.4 Collision Layer Convention (Hard Rule)
- **Layer 1 = world entities** (terrain, walls, mechanisms).
- **Layer 2 = the player**.
- The player's `collision_mask` = 1 (collides with the world).
- The altar/endpoint Area's `collision_mask` includes 2 (detects the player).
- Blue/reactive entities default to Layer 1; when sacrificed, their own script disables their collision shape (`set_deferred("disabled", true)`), so this doesn't rely on layer switching.

### 7.5 Data-Driven Design
Feel is entirely driven by `PlayerConfig.tres`; jump/gravity values are re-derived from the config every frame, so runtime edits take effect immediately. Hardcoding any feel number in `player.gd` is forbidden.

### 7.6 Extension Pattern: How to Add a New Concept
Don't modify `sacrifice_manager.gd`. Three steps:
1. Copy `blue_object.gd` → rename it → change the `concept_id` default → swap "disable collision on sacrifice" for that concept's logic (e.g. for `time`: freeze platforms/bullets). Attach it to whatever object should react.
2. Only when the concept affects the player themselves (e.g. `gravity`) does it need a small addition in `player.gd`; concepts that affect world objects (time/sound/color) need no changes on the player's side. UI-type concepts are instead handled by `hud.gd` listening and hiding the corresponding elements.
3. Place an `Altar` (`Action=UNLOCK` or `PERMANENT_SACRIFICE`, filling in `concept_id`, `message` prompt text), and add a mapping in `SacrificeInput.bindings` (a key binding is needed if it's a reversible concept). The player entering the range will only see the `message` prompt, and must press `interact` (E) to actually trigger it.

The single-slot/double-slot/permanent-sacrifice rules automatically apply to the new concept.

### 7.7 Known Edge Case & Mitigation
**Restoring "blue" while embedded inside a blue wall traps the character**: free toggling guarantees the *movement mode* can always be toggled back, but if the character is currently embedded inside a blue solid and blue is restored to solid at that moment, they get stuck in the wall. Two mitigation options:
- At the level design layer (default): don't design a puzzle that "requires restoring blue while embedded in blue." Natural play essentially never hits this.
- At the code layer (optional hardening): before restoring collision in `blue_object.gd`, do a shape query to check whether the player overlaps it, and if so, delay the restore until the player leaves. Left out by default to keep things simple — add it if it turns out to be needed.

This edge case applies equally to any reversible concept with a "restores back to solid" behavior — level designers should be aware of it.

---

## 8. Extension Interfaces (By Role)

### 8.1 Level Designer
- Build terrain with a TileMap or `Ground.tscn` (StaticBody2D + `size`/`color` export), collision on Layer 1. Build steps are detailed in `scenes/HOW_TO_BUILD_A_LEVEL.md`.
- Place altars: `Area2D`+`altar.gd`+`CollisionShape2D`, set `Action`/`Concept Id`/`Slot Count` in the Inspector, check the player layer (2) in the Mask. One altar does one thing; stack two to do two things at once. After the player enters the range they must press `interact` (E) to actually trigger it; stacked altars each independently listen for the same key press, so one `interact` press triggers every altar in range simultaneously.
- Place reactive obstacles: `StaticBody2D`+`blue_object.gd` (or a copy of it) + a collision shape + a visible child node.
- Place the endpoint: an `Area2D`, checking `body is Player` in `body_entered`.
- Must honor the §5.4 hard constraint.

### 8.2 Artist
- Swap the player's placeholder block for an `AnimatedSprite2D`, and point the player's `sprite_path` at it — flipping then works automatically.
- Mechanism appearance: `BlueObject`'s `Solid Alpha`/`Passable Alpha` control transparency; adding an outline/glow to its visible child nodes is enough for special effects, mechanics are unaffected.
- Follow the color semantics in §6.2.

### 8.3 Feel-Tuning Lead
- Only touch `PlayerConfig.tres`, never the code (see the parameter table in §3.3).
- Feel free to build several `.tres` files for different characters/levels and swap between them at will. Runtime edits take effect immediately.

---

## 9. Development Plan

### 9.1 MVP Scope (Hard Boundary)
**Build**: the two reversible sacrifices `gravity`+`blue`, the single-slot constraint, the double-slot upgrade (priced at `jump`), the 6-room level (R1–R6), the `hud` UI-collapse set-piece, the `fourthwall` ending, the sacrifice-status HUD, basic toggle feedback and control prompts.

**Don't build (explicitly excluded during the jam)**: combat AI/bosses, a minimap, a proper pause/settings menu, the reserved-pool concepts (friction/time/sound).

**Post-MVP additions actually shipped (see `DEV_STATUS.md` for the up-to-date list)**: a title screen + intro-unlock sequence, the `red`/`green` reversible color-gate concepts (the §2.6 `blue` extension pattern, "etc." realized), and a minimal jump sound effect (BGM/other SFX remain out of scope — see `DEV_STATUS.md` §4 for the exact audio convention to follow if this is extended further).

Addition order (only if the MVP finishes early and there's time to spare, in this order): a 3rd reversible concept (friction, high reusability) → more flavor lines/polish.

### 9.2 Implementation Order (Vertical Slice)
1. Player controller (movement + jump) + test room → **feel polish first**.
2. `gravity` sacrifice + HUD indicator.
3. `blue` system + sacrifice.
4. Single-slot constraint + altar unlocking. (At this point the core action loop is independently playable.)
5. Double-slot upgrade + permanent sacrifice of `jump`. (Lights up the Metroidvania loop.)
6. Build the R1–R6 rooms and thresholds.
7. `fourthwall` ending sequence.
8. Feedback/flavor-text polish.

### 9.3 Milestones & Checkpoints
- Checkpoint ①: core mechanics are playable (Step 4 done).
- Checkpoint ②: R1–R6 fully clearable (Step 6 done).
- Checkpoint ③: ending + polish done, ready to submit (Step 8 done).

### 9.4 Suggested Division of Labor
Programming: §7 architecture + Steps 1–5. Level: §5 + Step 6 + the §5.4 verification. Art: §6 + character/icons/mechanism appearance. All three can work in parallel after Checkpoint ①.

---

## 10. Content & Asset Checklist (MVP Minimum)

- 1 player sprite set (idle/run/jump, supporting vertical flip).
- 1 tileset: solid ground, blue blocks/spikes, altars ×3 reskins (normal/shrine/endpoint), the exit.
- 2 concept icons (gravity/blue, three states each).
- A handful of dialogue boxes/signs (for control prompts and very short lines).

---

## Appendix A: Quick Concept Index
`gravity`(reversible/MVP) · `blue`(reversible/MVP) · `jump`(permanent/MVP · double-slot price) · `fourthwall`(permanent/MVP · ending) · `hud`(permanent/MVP · UI collapse) · `friction`·`time`·`sound`(reserved)

## Appendix B: Non-Negotiable Hard Rules Checklist
1. Every sacrifice must cut both ways (§1.3.1).
2. The player can read their current sacrifice state at any moment (§1.3.2, §4.1).
3. The single-slot/double-slot logic is implemented only inside the Sacrifice singleton (§7.2).
4. Zero hardcoded feel numbers — everything goes through PlayerConfig (§7.5).
5. Collision layer convention (world = 1, player = 2) (§7.4).
6. If using the jump price, no jumping is required to clear the game after that point (§5.4).
7. UI-type sacrifices only go through the permanent layer, and must have a clear traversal payoff (§4.6, §5.5).
8. The `fourthwall` ending is purely visual, never manipulates the OS window (§2.6, §5.6).
