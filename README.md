# Horseman-verse-RPG

An expandable Pale Horseman-verse visual novel / turn-based RPG, built in Godot 4.

## Prototype 001 — Love Beyond: Haniel vs Asmodeus

Run the Godot project (press F5). The experimental illustrated scene includes:
- Intro dialogue in a thundercloud
- Choose Haniel or Asmodeus as the player-controlled character
- Small turn-based duel with distinct abilities, opponent AI and HP bars
- Ending screen and replay options

**Status:** prototype / playtest, not final dialogue or combat balancing. The original text-only working scene is preserved in `scenes/prototype.tscn`.

### Optional artwork

The illustrated scene looks for these files:
- `assets/love_beyond/prototype_001/storm_duel.jpg`
- `assets/love_beyond/prototype_001/storm_clash.jpg`
- `assets/love_beyond/prototype_001/haniel_portrait.jpg`
- `assets/love_beyond/prototype_001/asmodeus_portrait.jpg`

These are lightweight, cropped/resized copies of existing Love Beyond audiobook illustrations. They can be copied in from the prepared Art Pack 01. The scene also works without them, using a plain dark background.

### Notes

- Target aspect ratio: **16:9 landscape**, 1280×720 virtual viewport.
- Scene: `scenes/prototype_illustrated.tscn`
- Script: `scripts/prototype_illustrated.gd`
- Original text-only test: `scenes/prototype.tscn`
- This is a reusable first visual pass, *not* the final script or final transparent character sprites.

## Development experiment: Modular content pipeline

The original illustrated game remains the default **F5** scene. An **optional** new scene,
`scenes/prototype_modular.tscn`, tests loading the same encounter from JSON character and
chapter data. Open that scene in Godot and press **F6** to try it.

See [the content pipeline guide](docs/content_pipeline.md) for architecture, test commands,
and editing instructions. The modular scene has not yet been verified in the Godot editor,
so keep using the original F5 scene if it reports errors.

### Optional test features

The modular scene now offers **Story / Normal / Hard / Nightmare** difficulties,
loads scaled battle values from `data/difficulties.json`, and remembers your
selected difficulty and test wins in Godot's local `user://` save folder.

The working F5 scene is unchanged. See the [content pipeline guide](docs/content_pipeline.md)
for details and the GitHub Actions import/smoke-test workflow.
