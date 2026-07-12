# Sacrifice

*The price of sacrifice.*

A "subtractive" Metroidvania built in Godot 4.x: instead of gaining new abilities, you get through places that were otherwise impassable by **permanently or temporarily giving things up**. Gravity, color, jump, your own HUD, even the fourth wall — every ability you lose opens a path that was closed before. The further you play, the less you have, and the more places you can reach.

---

## Table of Contents

- [Concept](#concept)
- [How to Play](#how-to-play)
- [The Sacrifice System](#the-sacrifice-system)
- [Level Structure](#level-structure)
- [Technical Architecture](#technical-architecture)
- [Project Structure](#project-structure)
- [Development Status](#development-status)
- [Documentation Index](#documentation-index)

---

## Concept

Conventional Metroidvanias do addition: defeat a boss, gain a double jump, a new area opens up. *Sacrifice* does the opposite. The player keeps **deleting concepts from the world**, and the core design promise is that **every sacrifice cuts both ways** — closing off one thing while opening another. Give up gravity, and "down" stops meaning anything, but "up" becomes reachable. Give up the color blue, and blue platforms and switches stop working, but blue walls and doors no longer block you. This keeps the game inside the familiar Metroidvania loop of "I couldn't get through here before, and now I can" — just approached from the opposite direction.

Three design pillars govern every tradeoff (in priority order):

1. **Every sacrifice must cut both ways.** A sacrifice that's all cost and no traversal payoff doesn't belong in the game.
2. **Readability first.** At any moment, the player must be able to tell what they've sacrificed, how many slots they have left, and which objects are currently solid versus passable.
3. **Losing control is the theme.** The world grows emptier and stranger as you progress; "winning" means having stripped the world down to nothing but the exit. The tone stays transactional and unemotional — conveyed through small in-world details (an altar's reaction, a disintegrating UI, terse text), never through narration.

---

## How to Play

| Action | Key |
|---|---|
| Move left / right | A / D |
| Jump | Space |
| Sacrifice `gravity` | 1 |
| Sacrifice `blue` | 2 |
| Sacrifice `red` | 3 |
| Sacrifice `green` | 4 |
| Confirm an altar's action | E (`interact`) |
| Restart the current level | R |

Run the project in Godot (F5) to boot the title screen. Press `interact` to break through it into the game. Each level ends at an altar that demands the sacrifice of `"fourthwall"` — pressing it there carries you into the next level, until the third and final level's altar plays the real ending and returns you to the title screen. `R` resets and reloads whichever level you're currently on, including mid-ending.

Approaching any altar shows an in-world hint of what it does; nothing actually happens until you press `interact` to confirm. Concepts start locked — you have to find and trigger the right altar before a key does anything.

---

## The Sacrifice System

Sacrifices come in two layers:

- **Reversible concepts** — always-on-hand tools that can be toggled instantly, for free, at any moment (number keys). Because toggling is free, the player is never soft-locked. Toggling one on while at the slot limit automatically evicts the earliest-activated one.
- **Permanent sacrifices** — irreversible, triggered via altars, and carry the story's emotional weight: the world getting progressively stripped bare.

A **slot** is the number of reversible concepts that can be active at once. It starts at 1, meaning only one reversible ability can be "on" at a time — this alone generates puzzles, since a passage that needs two abilities at once is impassable until the player earns a second slot. The **double-slot upgrade** (1→2 slots) is bought with a permanent sacrifice of `jump`, mirroring the "double jump" power spike of a traditional Metroidvania, except paid for by losing something rather than gaining it.

### Concepts

| id | Type | You lose | You gain | Status |
|---|---|---|---|---|
| `gravity` | Reversible | Normal falling — you instead "fall" upward | Ceilings become walkable; vertical shafts open up | Shipped |
| `blue` | Reversible | The solidity of blue objects | Passage through blue walls/doors | Shipped |
| `red` | Reversible | The solidity of red objects | Passage through red walls/doors | Shipped |
| `green` | Reversible | The solidity of green objects | Passage through green walls/doors | Shipped |
| `jump` | Permanent | The ability to jump, ever again | Pays for the double-slot upgrade | Shipped |
| `hud` | Permanent | The ability to see your own sacrifice state | The falling HUD icons become solid platforms, opening previously unreachable ledges | Shipped |
| `fourthwall` | Permanent | The game's integrity as "just a game" | Passage to the next level / the true ending | Shipped |
| `friction` | Reversible | Friction — the world becomes ice | Fast slides through long slopes and narrow gaps | Reserved for future extension |
| `time` | Reversible | Anything running on a timer stops | Frozen obstacles become footholds | Reserved for future extension |
| `sound` | Reversible | The whole scene goes silent | Sound-perceiving hazards are disabled | Reserved for future extension |

`red` and `green` are the shipped realization of the game's built-in extension pattern — copies of the same reactive-object template used by `blue`, with nothing but the `concept_id` and color changed. `friction`/`time`/`sound` are designed and named but not implemented; they're a ready-made pool for future content, following the same pattern.

### Feedback

A sacrifice-status HUD (slot count + one icon per unlocked concept, in three visual states: locked/inactive/active) is always on screen — until you sacrifice `hud` itself, at which point it disintegrates and you're left relying on memory and a brief screen flash on every toggle. Every toggle gets that same short full-screen flash, regardless of whether the HUD is still around to show you anything else.

---

## Level Structure

The game is **three self-contained levels chained together**, not one continuous scene:

```
Title Screen --(E)--> Level 1 --(fourthwall)--> Level 2 --(fourthwall)--> Level 3 --(fourthwall)--> Title Screen
```

- **Level 1** teaches the core loop from scratch: `gravity` → `blue` → the `hud` set-piece → the double-slot shrine (permanently losing `jump`) → a shaft that demands `gravity`+`blue` together → the exit altar.
- **Level 2** repeats and layers the full concept set — `blue`, `gravity`, `red`, `green`, `hud`, the double slot, `jump` — introducing the two color concepts for the first time.
- **Level 3** is the largest of the three, combining every concept (`gravity`/`blue`/`red`/`green`/`hud`/`jump`) into one bigger space, and ends in the real ending sequence: the HUD fades, the screen dissolves to black, one closing line of text appears, then the game returns to the title screen.

Every level's exit altar sacrifices the same concept, `"fourthwall"` — in the first two levels this means "advance to the next level," and only in the third does it mean the literal, final ending the name was designed for. Progress (unlocked/active/permanently-sacrificed concepts) resets at every level transition — nothing carries over between levels.

Each level is built from the same small set of reusable prefabs (see below): a level is nothing more than terrain (`Ground`), altars (`Altar`), reactive objects (`BlueObject`/`RedObject`/`GreenObject`), and a handful of singleton-adjacent utility scenes, all wired together entirely through the Godot Inspector.

---

## Technical Architecture

- **Engine**: Godot 4.6, GDScript, Forward Plus rendering.
- **Single source of truth**: a `Sacrifice` autoload singleton (`scripts/sacrifice_manager.gd`) holds *all* sacrifice-related state — which concepts are unlocked, active, or permanently sacrificed, and the current slot count. Every other system talks to it only through its signals and query/command methods; nothing else is allowed to hold a second copy of this state.

  ```gdscript
  # Signals
  concept_activated(id) / concept_deactivated(id)
  concept_unlocked(id)
  slots_changed(new_slots)
  concept_permanently_sacrificed(id)

  # Queries
  is_unlocked(id) / is_active(id) / is_permanently_sacrificed(id)
  get_active() / get_unlocked()

  # Commands
  unlock(id) / activate(id) / deactivate(id) / toggle(id)
  set_max_slots(n) / permanently_sacrifice(id) / reset()
  ```

- **Reactive-object pattern**: any object that needs to respond to a sacrifice (a wall going passable, a UI disintegrating, a platform falling) listens to `Sacrifice`'s signals and filters by its own `concept_id` — never a special case hardcoded into the singleton. `blue_object.gd` is the reference implementation of this pattern (toggling collision + transparency); `hud_collapse_platforms.gd` is a second flavor of it (spawning geometry instead of toggling it).
- **Data-driven feel**: every movement/jump number lives in a `PlayerConfig` resource (`tuning/default.tres`), re-read every frame — there is no hardcoded feel number in `player.gd`, and tuning changes apply live.
- **Extending with a new concept** requires no changes to `sacrifice_manager.gd`: copy the reactive-object template, change its `concept_id`, place an `Altar` configured to `UNLOCK` or `PERMANENT_SACRIFICE` it, and (for reversible concepts) add a key binding to `SacrificeInput`. The single/double-slot and permanent-sacrifice rules apply automatically.
- **Collision layers**: world entities (terrain, walls, reactive objects) sit on Layer 1; the player is on Layer 2; altars are Area2Ds that only detect the player (`collision_mask = 2`) and never participate in physics collision.

### Script Inventory

| Script | Attached to | Responsibility |
|---|---|---|
| `sacrifice_manager.gd` | autoload `Sacrifice` | The single source of sacrifice state and the signal bus. |
| `player_config.gd` | `Resource` | Pure-data container for the player's feel values. |
| `player.gd` | `CharacterBody2D` | Movement, split-gravity jump, the `gravity` sacrifice response, jump SFX. |
| `blue_object.gd` | `StaticBody2D` | Generic reactive-object template — `blue`/`red`/`green` all reuse this one script. |
| `altar.gd` | `Area2D` | The unlock/set-slots/permanent-sacrifice trigger, with an interact-to-confirm prompt. |
| `sacrifice_input.gd` | `Node` | Maps input actions to concept toggles, editable entirely in the Inspector. |
| `hud.gd` | `CanvasLayer` | The sacrifice-status display, and the object that reacts to `hud` being sacrificed. |
| `ending_sequence.gd` | `CanvasLayer` | The `fourthwall` handler — plays the ending (or skips straight through) and advances to the next scene. |
| `restart_controller.gd` | `Node` | Resets all sacrifice state and reloads the level on `restart`. |
| `hud_collapse_platforms.gd` | `Node2D` | Spawns falling platforms at designer-placed landing spots when `hud` is sacrificed. |
| `ground.gd` | `StaticBody2D` (`@tool`) | Reusable floor/platform/wall block, editable live in the editor. |
| `title_screen.gd` | `Node2D` | The title screen and its transition into the first level. |
| `integration_intro.gd` | `Node` | The "shatter into gameplay" intro gate at the start of Level 1. |

---

## Project Structure

```
scripts/    Game logic (GDScript)
scenes/     Godot scenes: reusable prefabs (Player, Altar, Ground, ...) and the three levels
tuning/     PlayerConfig .tres resources — all feel values, no code changes needed to retune
assets/     Sprites and the one audio clip (jump SFX) used in the game
```

Everything a designer needs to place or configure lives on an `@export` field in the Inspector — extending the game with new content should rarely, if ever, require touching a script.

---

## Development Status

Development is **complete**. All planned steps have shipped, plus several rounds of post-plan additions: the title screen and intro sequence, the three-level chained structure, the `red`/`green` concepts, the jump sound effect, and a pass of redundant-code cleanup.

---

## Documentation Index

| File | What it's for |
|---|---|
| [`GDD.md`](GDD.md) | The sole design authority — what the game is meant to be. |
| [`DEV_STATUS.md`](DEV_STATUS.md) | The current, actual state of the project — what's really built, file by file. |
| [`DEV_PLAN_CORE.md`](DEV_PLAN_CORE.md) | The historical build-order record. |
| [`CLAUDE.md`](CLAUDE.md) | AI-assistant collaboration rules for this repository. |
| [`scenes/HOW_TO_BUILD_A_LEVEL.md`](scenes/HOW_TO_BUILD_A_LEVEL.md) | A prefab-by-prefab tutorial for building or extending a level (Chinese/English/Japanese). |
| [`scenes/change_point.md`](scenes/change_point.md) | A running changelog of feature-level changes (Chinese/English/Japanese). |

If any document disagrees with another, `DEV_STATUS.md` wins for "what currently exists"; `GDD.md` wins for "what it's designed to be."
