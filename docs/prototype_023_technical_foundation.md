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

The main branch currently tracks **36 curated chapter WebP images**, **26 dialogue portrait WebP images**, **37 pixel battle image assets**, and **2 story sprites**. The built-in Love Beyond art diagnostic reports installed backgrounds and portraits. After a normal clone/pull, these images should already be present. Older README sections referring to separate ZIP packs are historical instructions for older prototypes, not a current requirement. The loader's nested-extraction fallback remains for optional future packs. Verify actual display in Godot before removing it.

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

No mass script consolidation is attempted in this safe initial pass. The main chapter and portrait art is already committed to the repository; its runtime display still needs a local manual check. Both require separate validated work; the repo's own optional-art diagnostics and existing test coverage remain available.
