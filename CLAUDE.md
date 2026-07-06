# CLAUDE.md — 《Sacrifice》 Project AI Collaboration Rules

## Who You Are / What This Is

You are the **implementation (coding) assistant** for this Godot 4.x project. The project is a "subtractive Metroidvania": the player sacrifices abstract concepts to get through places that were otherwise impassable.

- The full design lives in `GDD.md`, the **sole authority**.
- The build order lives in `DEV_PLAN_CORE.md`.
- **Read both files before doing anything.**

---

## ⛔ Top-Priority Rule: No Git Operations, Ever

- You **must never** run any git command: `git init` / `add` / `commit` / `push` / `pull` / `branch` / `checkout` / `merge` / `stash` / `rm` / `reset`, etc. — **none of them, ever**.
- Version control is **entirely the human developer's job, done manually**. You only create and modify files — never touch repository state.
- Even when a piece of work would "normally" come with a commit, you **only make the file changes and stop there**, leaving the commit to the developer.
- You may hint in one sentence that "this would be a good point to commit," but **do not do it yourself**, and do not suggest specific git commands in a way that implies someone else should run them on your behalf.

---

## Tech Stack & Conventions

- Godot 4.2+, GDScript. Indent with **Tabs**.
- Directory layout: `scripts/` (logic), `scenes/` (scenes), `tuning/` (config resources, `.tres`), `assets/` (art).
- Anything the player or a teammate should be able to tune must be exposed to the Inspector via `@export` and packaged as a **reusable `.tscn` prefab** — never hardcode it in the script.
- Every script has a top comment stating its responsibility; keep clear inline comments on key functions.

---

## Architectural Hard Rules (Never Break These)

1. All sacrifice-related state lives only in the `Sacrifice` singleton; any other system communicates with it only through its **signals** — never build a second global state holder.
2. All of the player's feel values come only from the `PlayerConfig` resource; the code **must never contain a hardcoded movement/jump number**.
3. Any "object that reacts to a sacrifice" follows one unified pattern: listen to `Sacrifice` signals and filter by its own `concept_id`. Never add object-specific branches inside the singleton.
4. The single-slot / double-slot / permanent-sacrifice rules are implemented only inside the `Sacrifice` singleton — never re-implemented elsewhere.
5. Collision layers: world entities = Layer 1, player = Layer 2 (see GDD §7.4).
6. The singleton's autoload name must be exactly `Sacrifice` (capital S).

---

## How to Work

- Work on only the **current step's** scope from `DEV_PLAN_CORE.md` at a time — **do not implement content from later steps ahead of schedule**.
- Before each change, list in a few sentences "which files I'm going to create/modify, and what I'm adding," then start; don't rewrite systems that already work.
- Don't expand scope on your own initiative: don't add combat, menus, networking, save systems, or anything else explicitly excluded by GDD §9.1.
- Make sure the project can run with F5 and be play-tested by a human at the end of every step.
- Don't modify Project Settings (autoload / Input Map / main scene) — these are set up manually by the human in the editor. If you need an input action or an autoload to exist, just reference it normally in code and let the human configure it in the editor.
