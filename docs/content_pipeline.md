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
