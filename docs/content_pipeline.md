# Chapter and Combat Content: First Iteration

**The main F5 scene is unchanged.**

An experimental, data-driven variant is available at `scenes/prototype_modular.tscn`.
Open it in Godot and press F6 to test.

## Why this exists

Dialogue, fighter lists, and abilities should live in content files, not be hardcoded in the UI.
This is groundwork, not a completed chapter editor, XP system, or party system.

## File responsibilities

- `data/chapters/love_beyond_prototype_001.json`: chapter metadata, backgrounds, dialogue, and intro.
- `data/characters/haniel.json` and `asmodeus.json`: names, IDs, variants, max HP, moves, and simple AI.
- `scripts/core/content_store.gd`: JSON loading and error messages.
- `scripts/core/duel_engine.gd`: character-independent duel state and actions.
- `scripts/prototype_modular.gd`: combines data with the existing illustrated UI.
- `tests/smoke_test.gd`: basic content and both-sides smoke tests.

## Data examples

Dialogue: `{"speaker":"NARRATOR","text":"Lightning strikes beyond the clouds."}`

Move: `{"id":"divine_arrow","name":"Divine Arrow","kind":"damage","power":23}`

Move kinds supported so far: `damage`, `heal`, `guard`. Enemy damage is deterministic.
AI healing is limited to once per fight. These values are placeholders, not canon.

## How to playtest

1. Pull the GitHub repository using GitHub Desktop.
2. Open `scenes/prototype_modular.tscn` in Godot.
3. Press F6 (Run Current Scene) and test both fighters.
4. If errors occur, share the exact Output/Debugger text.

Optional headless smoke test: `godot --headless --path . --script res://tests/smoke_test.gd`

The main F5 scene remains the working visual prototype. The existing artwork is untouched.

## Later extension points

- Separate character IDs for additional forms and variants.
- Campaign unlocks/custom parties using stable character IDs.
- Experience, difficulty, items, and save files linked to stable IDs.
- Branching dialogue, chapter events, and multi-character battles.

## Prototype difficulty and saves (2026-10-29)

The optional `scenes/prototype_modular.tscn` now adds a difficulty picker after
choosing a fighter. Profiles in `data/difficulties.json` currently modify
**enemy HP** and **enemy damage** only. They do not alter player HP, experience,
or characters' canonical strength. Values are provisional.

| Difficulty | Enemy HP | Enemy damage |
| --- | --- | --- |
| Story | 80% | 70% |
| Normal | 100% | 100% |
| Hard | 130% | 125% |
| Nightmare | 160% | 150% |

`scripts/core/save_store.gd` contains a versioned, local save model. Godot
stores this in `user://paleverse_save_v1.json`, NOT the repository. It
remembers difficulty and prototype victory counts by chapter/character/
difficulty. A helper for future character unlocks exists but is not yet used
by this tutorial scene; canon unlock rules still need designing.

**No grinding, real leveling, or campaign progression yet.** This adds a
foundation for those features rather than pretending they are complete.

## Automatic checks

`.github/workflows/godot-smoke.yml` tries to import the project and run
`tests/smoke_test.gd` on pushes/PRs. It uses Godot 4.7.2, matching our local
project version. Smoke tests exercise story data, both sides of the duel,
damage scaling, and in-memory save manipulation (without writing a player's
real save).

Run the optional scene with **F6** and the familiar working illustrated demo
with **F5**. If anything appears broken, the working F5 version is still there.
