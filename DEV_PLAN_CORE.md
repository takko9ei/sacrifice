# Core Development Steps (Your Part) · Vibe Coding Edition

> **Status: all steps below are complete; development is finished.** This file remains as the historical build-order record. For the actual final state (which extends past what's described here — see Step 5's superseded note below), read `DEV_STATUS.md` first.

> Companion docs: `GDD.md` (authoritative design), `DEV_STATUS.md` (current actual state), `scenes/HOW_TO_BUILD_A_LEVEL.md` (build tutorial for level designers)
> Your goal: produce a version that is **roughly playable and contains all core mechanics**, then hand it off to whoever does gimmicks and whoever does the map.
> Team split: you = game core / B = gimmicks (mechanisms and extension concepts) / C = map building.
> Premise: both the `hud` UI collapse and the `fourthwall` ending are in MVP scope — implement them per the steps below.

---

## 0. Before You Start (Read This First)

### 0.1 What You Already Have on Hand

The previous round already produced these scripts (in `scripts/`): `sacrifice_manager.gd`, `player.gd`, `player_config.gd`, `blue_object.gd`, `altar.gd`, `sacrifice_input.gd`, `hud.gd` (text version). **This plan builds on top of that foundation — it is not a rewrite.**

### 0.2 Give the AI This "Architecture Briefing" at the Start of Every New Session

Since you don't read the code closely, the biggest risk is the AI reinventing the wheel each time and putting logic in the wrong place, which leaves B and C unable to build on it during handoff. So before letting the AI work each time, paste this constraint block first (worth saving as an `AI_CONTEXT.md` you reuse):

> This is a Godot 4.x GDScript project. Hard rules:
>
> 1. All sacrifice-related state lives only in the `Sacrifice` singleton; any system communicates with it only through its signals — don't build a separate global state.
> 2. All of the player's feel values come only from the `PlayerConfig` resource; the code must never contain a hardcoded movement/jump number.
> 3. Any "object that reacts to a sacrifice" is written following the `blue_object.gd` pattern: listen to the signal, filter by its own `concept_id`. Don't add object-specific branches in the manager.
> 4. The single-slot / double-slot / permanent-sacrifice rules live only in `sacrifice_manager.gd` — don't reimplement them elsewhere.
> 5. Anything configurable by the player or teammates is exposed to the Inspector via `@export` and packaged as a reusable scene (.tscn) — don't hardcode it in the script.
>    Please work within these constraints, and before making a change explain which file you're going to modify and what you're adding — don't rewrite existing systems.

### 0.3 How You Accept Each Step (Key)

You don't review code, so **each step's completion criterion = physically testing every item on that step's "play-through" checklist**. If any item on the checklist is off, throw the symptom back at the AI to fix — don't go read the source yourself. Every step comes with a "regression re-test" too, because vibe coding easily breaks B while fixing A.

### 0.4 Handoff Principle

What you hand off isn't "a pile of code" — it's **a set of Inspector-tweakable prefabs, plus one copyable template per extension category**. B and C should be able to start working with almost no need to write code. So nothing in this plan that says "make it a scene / expose the parameters" can be skipped — that's the lifeline of handoff quality.

---

## Step 1: Project Bootstrap + Prefab-ification + Feel Polish (one big session)

**Goal**: the project runs, the character's movement/jump feel is good in the test room, and all core objects have become reusable scenes.

**Deliverables**:

- Project directory structure set up: autoload `Sacrifice`, Input Map, main scene, `scripts/`+`scenes/`+`tuning/` directory layout.
- Loose scripts turned into prefab scenes: `Player.tscn` (CharacterBody2D + CollisionShape2D + **AnimatedSprite2D placeholder** + Camera2D, `sprite_path` pointing at that AnimatedSprite2D), `Altar.tscn`, `BlueObject.tscn`, `HUD.tscn`. All parameters `@export`ed to the Inspector.
- `PlayerConfig` saved as `tuning/default.tres` and attached to Player.
- Player animation state machine (idle/run/jump-fall) driven by **placeholder frames**, with logic reading `velocity` and `is_on_floor()` — so art can later swap frames without touching logic.
- A simple test room (a handful of platforms) for feel-testing.
- Feel polish: coyote time, jump buffering, and variable jump height all working.

**Suggested prompt**:

> Based on the existing scripts, help me set up the project: build the directory structure, turn player/altar/blue_object/hud into reusable .tscn prefabs respectively, expose every configurable item with @export. Add an AnimatedSprite2D to Player using solid-color placeholder frames, build an idle/run/jump animation state machine driven by velocity and is_on_floor, and point the player's sprite_path at it. Also make a test room scene with a few platforms. Make sure coyote time, jump buffering, and variable jump height all work. All feel values should come from default.tres.

**Completion criteria (play through)**:

- [ ] F5 runs, the character moves left/right and jumps normally.
- [ ] Jump feel: a short tap jumps low, holding it jumps high (variable height works).
- [ ] Stepping off a platform edge still allows jumping for a very short window afterward (coyote time).
- [ ] Pressing jump slightly before landing auto-triggers a jump the instant you land (buffering).
- [ ] Changing `move_speed` in `default.tres` and re-running actually changes the speed (proves data-driven).
- [ ] Animation switches correctly between idle/run/jump.

**Unlocks**: everyone now has instantiable prefabs; art can start swapping Player's frames.

---

## Step 2: Both Reversible Sacrifices Fully Working (gravity + blue) + Single-Slot Constraint + Toggle Feedback (one big session)

**Goal**: the core gameplay's "feel layer" is complete — press 1 to sacrifice gravity, press 2 to sacrifice blue, only one can be on at a time, and toggling gives clear feedback.

**Deliverables**:

- `gravity` sacrifice complete: gravity flip, reversed `up_direction`, sprite `flip_v` automatic, able to stand and jump on the ceiling.
- `blue` system complete: `BlueObject` prefab listens to the signal and toggles collision + transparency; a few blue walls/blue platforms placed in the test room.
- Single-slot constraint working (opening a second one auto-closes the first).
- `SacrificeInput` bound to keys 1/2.
- **Toggle feedback**: a very short full-screen flash the instant a toggle happens (slight screen tint / a line of text popping up) + a reserved SFX hook. Text-based HUD updates in real time.

**Suggested prompt**:

> Make gravity and blue, the two reversible sacrifices, fully work. gravity: flip gravity, reverse up_direction, auto flip_v, make sure is_on_floor is true on the ceiling and the player can jump off it. blue: BlueObject listens to the signal, disables collision and turns translucent when sacrificed. Place a few blue walls and blue platforms in the test room. Bind key 1 to toggle gravity, key 2 to toggle blue. Add a toggle-feedback system: a brief full-screen tint whenever any concept toggles on/off, plus a hook for playing a sound effect. Confirm the single-slot constraint — opening a second concept automatically closes the first.

**Completion criteria (play through)**:

- [ ] Press 1: the character "falls" upward to the ceiling, the sprite flips vertically, and it can walk on the ceiling.
- [ ] Press jump while on the ceiling: able to jump off the ceiling (toward the floor).
- [ ] Press 1 again: falls back to the floor, sprite flips back.
- [ ] Press 2: the blue wall turns translucent and can be walked through.
- [ ] Standing on a blue platform and pressing 2: the platform loses its solidity and the character falls through.
- [ ] Pressing 2 while gravity is already on: gravity auto-disappears from the HUD, leaving only blue (single-slot constraint).
- [ ] Every toggle has a visible flash of feedback.

**Regression re-test**: re-run all 6 feel checks from Step 1 (especially confirming that normal jumping still works after adding gravity flip).

**Unlocks**: B (gimmicks) can now copy the `BlueObject` template to make new reactive objects.

---

## Step 3: Altar System + Unlock Flow + Double-Slot Upgrade + Permanent Sacrifice of jump + In-World Prompts (one big session)

**Goal**: the full Metroidvania growth loop works end to end — concepts start locked, altars unlock them, buying the double slot (permanently losing jump), being able to have two on at once.

**Deliverables**:

- All concepts start locked; only walking to an altar and confirming with interact unlocks them (`SacrificeInput` only allows toggling already-unlocked concepts).
- `Altar.tscn` supports three Actions (UNLOCK / SET_SLOTS / PERMANENT_SACRIFICE), configurable in the Inspector.
- Double-slot shrine: two altars stacked (SET_SLOTS 2 + PERMANENT_SACRIFICE jump), one press of interact (E) while standing in both ranges triggers both at once.
- After permanently sacrificing jump, the jump key stops doing anything.
- **In-world control prompt**: when the player walks up to an altar, show what to do next to it (e.g. a sign/floating text saying "press interact to confirm") — no standalone UI panel.

**Suggested prompt**:

> Implement the unlock flow: all concepts start locked, and SacrificeInput only allows toggling concepts that are already unlocked. Let the Altar prefab choose between three behaviors in the Inspector: UNLOCK/SET_SLOTS/PERMANENT_SACRIFICE. Build the double-slot shrine — stack two Altars, one sets slots to 2, the other permanently sacrifices jump, and one press of interact after the player enters both ranges triggers both at once. After permanently sacrificing jump, the jump key does nothing. Also add an in-world prompt: when the player gets near an altar, show a line of text nearby describing the action, which only actually triggers after pressing the interact key to confirm.

**Completion criteria (play through)**:

- [ ] At game start, pressing 1/2 does nothing (not yet unlocked).
- [ ] Walking to the gravity altar and pressing interact unlocks it, after which pressing 1 works; same for the blue altar with 2.
- [ ] After walking to the double-slot shrine and pressing interact: the HUD's slot count becomes 2, and the jump key stops working from then on.
- [ ] After getting the double slot, pressing 1 then 2: both stay lit (HUD shows 2 active), no longer knocking each other out.
- [ ] Getting close to an altar shows the action-prompt text, and the corresponding effect only actually triggers after pressing interact.

**Regression re-test**: Step 2's single-slot constraint — confirm that with **only 1 slot** (before buying the double slot), opening a second concept still knocks out the first.

**Unlocks**: C (map) can start placing altars and designing puzzles.

---

## Step 4: All UI Sacrifices (hud UI Collapse + fourthwall Ending) (one big, heavier session)

**Goal**: build out both UI-type sacrifices completely. This is the messiest step — block out a large chunk of time.

**Deliverables**:

- **HUD upgrade**: switch from text to icons, one icon per concept, three states (gray/normal/highlighted), and wire the HUD itself into the signal bus (it too is "an object that reacts to a sacrifice").
- **hud (UI collapse)**: after permanently sacrificing hud, the status UI disintegrates and disappears; at the moment of sacrifice, spawn several one-time static solid platforms at preset locations (landing spots configured via Marker2D child nodes, no hardcoded coordinates) that the player can stand on to reach places that were previously unreachable. Package it as a prefab so B has a template to copy later (a different flavor of "reactive object": spawning geometry instead of toggling geometry).
- **fourthwall ending**: after the final altar triggers, UI elements fall/fade out one by one, scene elements dissolve, a closing line of text appears, then black screen. **Purely visual, never touches the OS window.**

**Suggested prompt**:

> Do the UI sacrifices in three parts. ① Switch the HUD to an icon version, one icon per concept with three states, and have the HUD listen to Sacrifice signals. ② Implement the hud sacrifice: after permanently sacrificing it the status UI disintegrates and disappears; at the moment of sacrifice, spawn one-time solid platforms at preset Marker2D landing spots, packaged as a reusable scene (landing spots adjusted by adding/moving Marker2D nodes in the editor, no hardcoded coordinates). ③ fourthwall ending: after the final altar triggers, make the HUD fall away piece by piece, scene elements fade out, show one line of closing text, then black screen — entirely visual, never touching the OS window.

**Completion criteria (play through)**:

- [ ] HUD icons correctly show all three states as concepts get unlocked/activated/slots change.
- [ ] After sacrificing hud, the status UI disappears; platforms fall into place at the preset spots, and the high ledge/gap that was previously unreachable can now be stepped up onto.
- [ ] After walking to the final altar and pressing interact: the UI and scene disintegrate in sequence down to black screen, and the window itself was never touched.

**Regression re-test**: after sacrificing hud, play for a bit relying on memory alone, confirming the game is still operable without any UI (gravity/blue can still be toggled).

**Unlocks**: B now has the "spawn a platform on sacrifice" set-piece template.

---

## Step 5: Single-Scene Integration Level + Room Template (one big session)

**⚠️ Superseded — kept as a historical record, not current architecture.** The "no room-switching, one continuous scene" decision below was later reversed: the shipped, complete game is three separate chained scenes (`Level1.tscn`/`Level2.tscn`/`Level3.tscn`) connected via `get_tree().change_scene_to_file()` — exactly the room-switching approach this step ruled out. `Level2.tscn` (the room template referenced below) was itself later repurposed into a real, played level rather than staying a copy-source template. See `DEV_STATUS.md` §2 and §3 for the actual final architecture and content. The text below is left unmodified as a record of the decision made at the time.

**Goal**: assemble a **rough** integration level, chained together in a single scene, covering every mechanic from start to finish, and give C a copyable room template — proving all the mechanics can be strung together into a full clear.

> **Architectural decision (replacing this step's original room-switching plan)**: no room-to-room switching system (door/boundary triggers + multi-scene loading). All rooms live in the same scene, divided into areas by coordinate ranges, with the camera continuously following the player — no scene switching. When C later expands the content, the priority is to make this one scene longer (adding areas, adding coordinate ranges) rather than splitting it into multiple scenes connected by transitions. The room template (`Level2.tscn`) is meant for "copying its node structure to new coordinates within the current scene," not "duplicating it into an independent, switchable new scene."

**Deliverables**:

- Room template: `Level2.tscn` (one `Ground` + one example altar + one example gimmick), for C to copy nodes from and change coordinates/`concept_id`; contains no scene-switching or camera-handling logic.
- One rough integration level (single scene), chained per GDD §5.2's R1→R6 flow: teach gravity → test gravity → teach blue and reveal the threshold → double-slot shrine → dual-sacrifice clears the blue shaft → fourthwall ending. **Placeholder blocks for geometry are fine, doesn't need to look good** — polish is left to C.
- Rigorously self-check the GDD §5.4 hard constraint: after sacrificing jump, no jump is required anywhere from that point to the end (walk through room by room to confirm).

**Suggested prompt**:

> Use placeholder blocks to assemble one complete level in a single scene, divided into R1→R6 by coordinate ranges, chained in this order: teach gravity, gravity shaft, teach blue while being able to see the blue shaft's entrance, double-slot shrine (sacrifice jump), a blue-spiked shaft that requires gravity and blue on at the same time, fourthwall ending. No room switching/multi-scene loading — one scene throughout, camera follows continuously. Rough geometry is fine. Specifically confirm: after sacrificing jump, every room from that point on can be cleared without ever pressing jump. Also make a room template scene (one floor + one example altar + one example gimmick) for later node-copying.

**Completion criteria (play through)**:

- [ ] Can play from the start all the way to the ending black screen without getting stuck partway.
- [ ] The blue shaft is genuinely impassable with only a single slot, and passable after getting the double slot (the Metroidvania loop holds).
- [ ] **Key check**: after sacrificing jump, the entire stretch from the shrine to the ending can be cleared without ever pressing jump.
- [ ] Moving across areas within the single scene, the camera follow is smooth, doesn't jitter, and never falls out of the world.

**Regression re-test**: while doing the full playthrough, watch that every mechanic from Steps 2–4 still works correctly in the real level.

**Unlocks**: C has the room template and a reference level, and can start building the map for real (continuing to add areas within the same scene); at this point the "roughly playable, all core mechanics present" version has been achieved.

---

## Step 6: Polish + Handoff Packaging (one session)

**Goal**: finish off overall feedback polish, and package everything into a handoff bundle ready to "ship out."

**Deliverables**:

- Feedback polish: give the toggle tint and the ending disintegration a pass on how they feel.
- **Handoff docs** (see the checklist below), pointing out one template for each extension category.

**Completion criteria (play through)**:

- [ ] Playing the whole flow start to finish feels coherent, with no obvious bugs.
- [ ] Every item in the handoff checklist can be pointed to somewhere in the project.

---

## Handoff Checklist (for B and C)

Before handing off, confirm every item below holds (this is what guarantees B/C can pick it up smoothly):

**For B (gimmicks)**:

- [ ] Two reactive-object templates: `BlueObject.tscn` (toggles collision + transparency) and `HudCollapsePlatforms.tscn` (spawns platforms at Marker2D landing spots on sacrifice), each directly copyable by changing `concept_id` or the landing spots.
- [ ] A short write-up on "how to add a new concept" (following GDD §7.6 "extension pattern"): copy the template → change the id → place a UNLOCK altar → add a key binding in SacrificeInput.
- [ ] Note that the reserved concepts (friction/time/sound) are to be implemented by B, using the two templates above.

**For C (map)**:

- [ ] How to use the room template + the `scenes/HOW_TO_BUILD_A_LEVEL.md` build tutorial (copying nodes to new coordinates in the current scene, not creating a new switchable scene).
- [ ] How to configure `Altar.tscn`'s three Actions in the Inspector.
- [ ] One reference integration level.
- [ ] Two hard constraints that must be followed: GDD §5.4 (no jump required after sacrificing jump) and §7.7 (don't design a puzzle that requires "restoring blue while inside a blue wall").

**General**:

- [ ] Every configurable item lives in the Inspector / .tres — B and C essentially never need to touch code.
- [ ] Pass along this document's §0.2 architecture hard-rules block to B and C, so their vibe coding follows the same rules too.

---

## Appendix: Vibe Coding Pitfall-Avoidance (for "not reading code closely + needing to hand off")

1. **Always run the regression checklist at the end of every step**, not just test the new feature. Fixing A while breaking B/C is the norm in vibe coding — catch it by actually playing.
2. **Watch for architectural drift**: you don't read the code, but you can have the AI self-check — every few steps, throw in a line like "check this: is any sacrifice-related state living outside the Sacrifice singleton? Any hardcoded movement numbers? Any object referencing another object directly instead of through signals? Fix it if so." This is a "checkup" you can do without reading code.
3. **Stick to prefab-ification**. The moment something exists only in code and hasn't been made into a scene, B/C will have to read your code at handoff time — exactly what you're trying to avoid. If you spot this, have the AI turn it into a .tscn + export.
4. **Save/commit after every step**. Save a revertible checkpoint after every "completion criterion" passes, so a break can be rolled back to the last playable version.
5. **Don't let the AI casually expand scope**. It might proactively add combat, add menus — per GDD §9.1, anything not on the list doesn't get built.
