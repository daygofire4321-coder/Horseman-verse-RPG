# Horseman-verse-RPG

An expandable Pale Horseman-verse visual novel / turn-based RPG built in **Godot 4.7.2**.
Mobile landscape is the eventual target. This is a playable desktop prototype, not a finished game.

## Launch with F5 — Prototype 002

**Prototype 002** (`scenes/prototype_v2.tscn`) is now the main F5 scene.

- Illustrated **Pale Horseman** main menu with **Begin the Chapter**, **Quick Battle**, and **About This Build**.
- Story dialogue driven by `data/chapters/love_beyond_prototype_001.json`.
- Two illustrated character cards (choose **Haniel** or **Asmodeus**).
- **Story / Normal / Hard / Nightmare** difficulty selection.
- Turn-based duel using character abilities from JSON.
- Visual feedback: blue Divine Arrow projectile, jagged Black Ice shards, regular hits, healing and guarding, damage flashes, floating labels, and animated HP bars.
- Test victory records and difficulty settings saved locally in Godot's `user://` directory.

Dialogue and combat numbers are placeholders. This duel is a test, **not** a canon account of its outcome.

## Keeping the earlier prototypes

All earlier scenes remain available:

| Scene | Purpose |
| --- | --- |
| `scenes/prototype_v2.tscn` | Latest menu + VFX build (**F5**) |
| `scenes/prototype_modular.tscn` | Original data-driven duel; open and press **F6** |
| `scenes/prototype_illustrated.tscn` | Earlier working illustrated duel; press **F6** |
| `scenes/prototype.tscn` | Original text-only proof of concept |

## Artwork

The prototype uses four existing, optimized audiobook illustrations, already stored under:

- `assets/love_beyond/prototype_001/storm_duel.jpg`
- `assets/love_beyond/prototype_001/storm_clash.jpg`
- `assets/love_beyond/prototype_001/haniel_portrait.jpg`
- `assets/love_beyond/prototype_001/asmodeus_portrait.jpg`

No new external image dependencies are required for the effects; they're made from Godot nodes.

## Architecture

- `data/chapters` — written story content and battle scene metadata
- `data/characters` — one definition per playable fighter variant
- `data/difficulties.json` — scalable difficulty settings
- `scripts/core/content_store.gd` — typed JSON content loading
- `scripts/core/duel_engine.gd` — standalone, UI-independent duel logic
- `scripts/core/save_store.gd` — versioned local save framework
- `scripts/prototype_v2.gd` — new front end and battle effect presentation
- `tests/smoke_test.gd` — headless Godot checks

See [the content pipeline guide](docs/content_pipeline.md) for details.

## Testing

Pushes run [Godot import and smoke tests](.github/workflows/godot-smoke.yml). Locally, you can run:

```bash
godot --headless --path . --script res://tests/smoke_test.gd
```

The automated test covers the new scene's creation, menu navigation, both special-attack effect paths, difficulty scaling, data integrity, and save-model helpers. Visual quality and touch controls still require manual testing.

### Next iterations

Implement canon dialogue, proper character sprites/expressions, music and audio cues, richer combat presentation, multi-character battles, leveling, unlock rules and optional cross-campaign team selection.
