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
