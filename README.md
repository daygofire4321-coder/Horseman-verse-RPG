# Horseman-verse-RPG

An expandable, story-driven Pale Horseman-verse visual novel / turn-based RPG, built in **Godot 4.7.2**. Mobile landscape is the eventual target.

## F5: Prototype 003 — Love Beyond (Parts 1–3)

**The first full story arc is now the default:** `scenes/prototype_story.tscn`.

### Playable flow

1. **Thundercloud prologue** — Haniel versus Asmodeus, using the author's opening dialogue; either battle result progresses to the story.
2. **Part One: Aftermath** — The cave, their names, the survival truce and the realization that both Heaven and Hell misled them.
3. **Part Two: The Natural Order** — Haniel gathers three fallen branches, struggles with fire, and debates the boar and the natural order with Asmodeus.
4. **Part Three: To Be Preyed Upon** — Asmodeus is attacked by a grizzly bear.
5. **Bear boss fight** — Control a weakened Asmodeus. **At 50% bear HP or when Asmodeus falls, gameplay hands over to Haniel's canonical rescue.**
6. **Scripted cinematic** — Haniel saves Asmodeus, then delivers the fatal arrow; both she and the bear collapse. Asmodeus rushes to her.
7. **Part Three completion** — local game save stores the completion marker. Part Four is not invented yet.

All author-provided dialogue is included with light copyediting; narration is shortened for game reading. The prologue and combat damage values remain prototype work.

### Art pack REQUIRED for correct visuals

The added story scene references **11 optimized existing Love Beyond illustrations**, in addition to the original four prologue images.

Download the separately shared `Paleverse_Opening_Story_Art_Pack.zip` and extract its `assets` folder into the project root beside `project.godot`. Example final file:

`assets/love_beyond/story_001/cave_after.jpg`

**The scene works without this ZIP**, but missing backgrounds fall back to the earlier storm illustration. No additional images were generated.

Once installed, you may commit and push the 11 JPEGs in GitHub Desktop to back up the assets.

### Quick Battle versus Story

**Quick Battle** on the title screen still lets you replay the non-canon Haniel–Asmodeus duel with regular victory/defeat. Only the main story uses guaranteed progression.

### Earlier builds (preserved)

| Scene | Use |
| --- | --- |
| `scenes/prototype_story.tscn` | Current main story (F5) |
| `scenes/prototype_v2.tscn` | Menu, illustrated duel, battle VFX (open scene, F6) |
| `scenes/prototype_modular.tscn` | Experimental data-driven duel (F6) |
| `scenes/prototype_illustrated.tscn` | Original illustrated duel (F6) |
| `scenes/prototype.tscn` | First text-only proof of concept (F6) |

## For developers

- Story events: `data/chapters/love_beyond_opening_story.json`
- Author-written prologue dialogue: `data/chapters/love_beyond_prototype_001.json`
- Asmodeus, Haniel, and bear: `data/characters/`
- Story runner and bear trigger: `scripts/prototype_story.gd`
- Battle engine: `scripts/core/duel_engine.gd`
- Local save: `scripts/core/save_store.gd`
- Automated Godot smoke tests: `tests/smoke_test.gd`

See [the story playable guide](docs/love_beyond_playable_opening.md), [design outline](docs/love_beyond_opening_slice_outline.md), and [core system notes](docs/content_pipeline.md).

Automated checks run on GitHub Actions after each change. Visual quality, sound, on-device touch targets and final lore review still require manual testing.
