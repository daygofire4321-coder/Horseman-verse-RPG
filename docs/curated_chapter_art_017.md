# Prototype 017 — Author-curated illustrations for Parts 1–5

The author supplied `1-6.zip` with **22 illustrations for Parts One through Five** and an empty folder for Part Six. The decision was explicit: **keep Part Six as it is**. This build adds the selected art to existing story scenes without editing dialogue or changing the six-part story sequence.

## Installation

1. In GitHub Desktop, choose **Fetch origin → Pull origin**.
2. Download and extract **Paleverse_Curated_Chapter_Art_017.zip** (provided in the ChatGPT conversation) directly into the **Horseman-verse-RPG project folder**. Keep the ZIP's directory structure. After extraction, an example file will be `assets/love_beyond/curated_chapters/part_01/01_cave_truce.webp`.
3. Let Godot import the new images, then press **F5**. The default scene is now `scenes/prototype_story_v17.tscn`.
4. Start **Love Beyond Heaven or Hell → Begin the Story** to see the image changes. Saved events and dialogue skipping continue to work, and the art is restored when a saved scene resumes.
5. If the optional asset pack is missing, the code uses the **legacy story images** instead, with no broken scenes.

All supplied images have been converted to optimized **1280 × 720 WebP** for the existing 16:9 game window. The original PNGs in the author's uploaded ZIP were not changed.

## Scene placement

| Story part | Curated scenes |
|---|---|
| **Part One — Aftermath** | Cave truce, Haniel close-up, Asmodeus close-up, cave conversation/name introduction, parting in the cave |
| **Part Two — The Natural Order** | Collecting branches, trying to light firewood, Haniel's reflection, Asmodeus starting the fire, evening campfire |
| **Part Three — To Be Preyed Upon** | Asmodeus watching the boar, bear confrontation and battle backdrop, Haniel's bow rescue, fallen bear/aftermath |
| **Part Four — To Give Thanks** | Haniel recovering in the cave, seashell water, quiet conversation, thanks after the bear fight |
| **Part Five — Playing House** | Uncooperative hide-drying rack, Haniel at the cave, camp at sunset |
| **Part Six — The Nature of Man and Demons** | **No changes; retains all existing Cliffside street, alley and battle images** |

### Author's Part Three note

The supplied `1-6/3/info.txt` says:

> 1 and 2. battle screen with bear sprite for fight. then 3 and 4 after battle.

The build honors this by displaying **Part Three image 1** as the approach/ambush setup, **image 2** for the confrontation **and the interactive grizzly battle**, with the existing grizzly sprite and HP UI still present. **Images 3 and 4** are shown only **after** the fight, for Haniel's rescue and the aftermath.

## Technical safety

- `data/chapters/love_beyond_opening_story.json` and `data/chapters/love_beyond_parts_4_6.json` now contain optional per-event `curated_image` keys. The original `image` values and all dialogue/action content remain unchanged.
- **Part Six events are identical to the previous edition**, with no `curated_image` keys added.
- `scripts/prototype_story_v17.gd` resolves the nearest preceding curated scene image across dialogue lines and saved checkpoints. **A new title with no curated image resets that lookup**, preventing Part Five art from leaking into Part Six.
- When the optional art pack isn't installed, a failed lookup leaves the original image in place; the game never references a missing texture as required content.
- The actual bear fight's existing pixel sprite, damage, player controls and required rescue remain unchanged. Only its illustrated backdrop changes.
- The new art is story illustration only; the existing pixel-art battle backgrounds, market and Smithy backgrounds, and campaign title art are not overwritten.
- `tests/smoke_test.gd` verifies all 22 unique supplied images have story placements, the author's bear scene ordering, original Part Six scene files and no inheritance into Part Six. Godot scene import remains included in continuous integration.

## Future curated-art workflow

You can put `info.txt` or `README.md` files in each chapter image folder. These are reviewed alongside the images to assign the desired scene transitions. Filenames do not need to be renamed in the original source archive. New art packs should preserve existing story and asset fallback behavior and only replace images for chapters the author selected.
