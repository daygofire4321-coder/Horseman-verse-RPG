# Prototype 023 — Technical Foundation

## Purpose

Establish safe maintenance practices before adding hunger or a richer exploration event engine. This is intentionally not a gameplay rewrite.

## Save behavior

- Primary save: `user://paleverse_save_v1.json`
- Recovery copy: `user://paleverse_save_v1.json.bak`
- Staged output: `user://paleverse_save_v1.json.tmp`
- A successful second and subsequent save first preserves the previous validated primary as recovery.
- If the primary is unreadable, a valid current-version backup may be loaded.
- Unsupported newer save versions are never overwritten. A corrupt primary without a valid backup is also never overwritten.
- Writes use a temporary file, flush/close/readback validation, then installation. This reduces risk but is not a fully atomic write across every OS failure mode.
- `tests/smoke_test.gd` uses `user://paleverse_smoke_023.json` and cleans up all scratch files; it does not touch the real game save.
- Existing schema version remains 1. No speculative migration is performed.

**If the game recovers from backup, recent progress made after that backup may be missing.** Preserve a copy of both files before manual troubleshooting.

## Art status

Most required art paths are referenced in `data/chapters`, `data/portraits`, and `data/battle_areas.json`. The built-in Love Beyond art diagnostic reports installed backgrounds and portraits. If using a local art pack, merge the pack's `assets/` directory beside `project.godot`; a one-level nested extraction fallback also exists. Future packaging should eliminate separate ZIP installs, but do not remove the fallback until distribution has been tested.

## Inheritance refactoring

`scenes/prototype_story_v22.tscn` launches `scripts/prototype_story_v22.gd`, which extends v21 and earlier prototypes. That architecture is functional but difficult to maintain. Consolidate focused pieces into `scripts/core/` or reusable UI helpers incrementally. Preserve old scenes for regression until a new stable root scene has equivalent coverage.

## Manual verification

1. Fetch branch, open Godot 4.7.2, F5.
2. Open Love Beyond > Adventure > Challenge Settings; ensure changes persist.
3. Continue old save, run an ordinary day and purchase an item, then save/reopen.
4. Run a combat practice and actual Cliffside encounter, verifying that only real encounters grant persistent rewards.
5. Verify all portrait and curated art counts in Extras and check the console for missing assets.
6. Compare saved values before/after; deliberately corrupt **only a disposable test save**, never your personal save.

## Not completed by this patch

No mass script consolidation and no repackaging of missing external art assets. Both require separate validated work; the repo's own optional-art diagnostics and existing test coverage remain available.
