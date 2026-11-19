# Optimization Pass 01 — Reusable Core and Safe Content Caching

This is an incremental cleanup against Prototype 022, deliberately isolated from the Prototype 023 save-safety pull request.

## Changed

- `scripts/core/character_stats.gd`: one testable calculation for base character attack/defense/speed plus leveling and equipped bonuses. Optional stat multipliers default to 1.0; **no hunger effects are active yet**.
- `scripts/core/party_engine.gd`: character sheets now consume this shared calculation while preserving all previous base formulas.
- `scripts/core/daily_action_catalog.gd`: descriptions and action-cost labels extracted from the inherited visual script.
- `scripts/prototype_story_v20.gd`: the daily dashboard reads those reusable descriptions without altering buttons, costs, callbacks, or progression.
- `scripts/core/content_store.gd`: cache successfully parsed JSON definitions and return deep copies so menu, character-sheet and fight lookups can share parsing while callers can safely edit returned data. `clear_cache()` allows explicit invalidation in development.
- `tests/smoke_test.gd`: verifies neutral and optional-modified stat math, action descriptions, and cache isolation in addition to the existing playthrough tests.

## Scope

This pass does **not** rebuild the whole UI or replace the historical prototype inheritance chain. That is a higher-risk step requiring profiling and dedicated interaction tests. It also doesn't introduce hunger, scripted events, or any different combat balance.

## Recommended next passes

1. Profile UI redraw time and allocations on desktop and target browsers before changing redraw strategy.
2. Consolidate related daily UI rendering helpers in small steps, preserving named controls and their existing tests.
3. Move character status effects, including food/hunger modifiers, through the shared stat-calculation entry point once the hunger rules are implemented.
4. Implement data-driven exploration scenarios using separate validation and narrative definitions rather than hardcoding events in `InterludeEngine`.
5. Test any art-texture caching with the current art diagnostic and fresh-install workflow so missing images remain discoverable.
