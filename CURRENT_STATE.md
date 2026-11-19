# Pale Horseman RPG — Current State

Last audited: 2026-11-19. Baseline: Prototype 022 on main. Prototype 023 maintenance work lives on `prototype-023-technical-foundation` until reviewed.

## Run the game

- Godot 4.7.2, F5, default scene `scenes/prototype_story_v22.tscn`.
- The playable campaign is Love Beyond Parts 1–9. Blades is Coming Soon.
- Local saves are in `user://paleverse_save_v1.json`, not the GitHub repository.
- Automated smoke tests: `godot --headless --path . --script res://tests/smoke_test.gd`.

## Implemented systems

Story checkpoints, dialogue portraits, skip dialogue; daily routines and repeatable hunting; three-slot party, sheets and reserves; move training; equipment, backpack and consumables; Cliffside market and optional outlaw fights; chapter-aware encounter levels, four challenge modes and EXP for active fighters; sprite combat targeting and HP feedback.

## Current limitations

- The ordinary-day forest Explore action is a static supply/counter reward, not randomized scenarios.
- Hunger and food-as-survival are not yet implemented.
- Combat AI uses predictable targeting; no full enemy skill/status system.
- The current UI is constructed through a long version-to-version GDScript inheritance chain. Refactor only with regression coverage.
- The repository now tracks all 36 curated chapter images and 26 dialogue portraits, plus pixel-battle and story sprites. Old README install notes about separate ZIP downloads refer to historical prototypes. Verify local display via Love Beyond > Practice & Extras > CHECK INSTALLED STORY & PORTRAIT ART.

## Regression priorities

Run both outcomes of the opening duel and bear fight, Cliffside scripted alley scene, optional hunts, three-character battles, ordinary/exciting days, Parts 7–9 resume, shopping, equipment, EXP/levels, and challenge selection.

Keep canon story outcomes unchanged; do not move story checkpoints from ordinary days. Do not overwrite an unsupported save schema.
