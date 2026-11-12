# Optional Story Art & Speaking Portraits — Repair Guide

## Why images sometimes showed the old backgrounds

The GitHub commits for Prototypes 017–018 included **code and image references**, but the image files were distributed separately as ZIPs. Pulling GitHub updates alone does not place these binary art files in the project. Windows **Extract All** often creates an extra folder named after the ZIP; the older Godot code only checked one fixed `res://assets/...` path, and silently continued with the old art when it found nothing.

The fix:
- `scripts/core/optional_art_loader.gd` checks the normal project-root `assets` folder **and** the common one-level nested folder produced by Windows extraction.
- If new WebP/PNG art has not yet been imported into Godot's resource database, it can load the image bytes directly via `Image.load`. Missing art does not cause a crash.
- `scripts/prototype_story_v17.gd` uses this loader for curated Parts 1–5 backgrounds.
- `scripts/prototype_story_v18.gd` uses this loader for all 16 speaker expressions and adds an **Art Check** entry to Love Beyond's Extras menu.

## Install the complete art pack

The ChatGPT conversation supplies **Paleverse_Story_Art_and_Portraits_Fix.zip**, containing both previous optional art packs:

- **22** optimized chapter scenes in `assets/love_beyond/curated_chapters/part_01` through `part_05`
- **16** optimized transparent speaking portraits in `assets/love_beyond/dialogue_portraits/{asmodeus,haniel,joren,alric}`

**Installation on Windows:**

1. GitHub Desktop → **Fetch origin → Pull origin**. Verify that the Godot project uses `scenes/prototype_story_v18.tscn` for F5.
2. In GitHub Desktop, select **Repository → Show in Explorer**. This opens the project folder containing `project.godot`.
3. Open **Paleverse_Story_Art_and_Portraits_Fix.zip** in Windows File Explorer.
4. Drag the **assets** folder *inside* the ZIP onto the **Horseman-verse-RPG** project folder beside `project.godot`, and choose to merge. **Do not drag the ZIP itself or leave the extracted folder in Downloads.**
5. Alternatively, extract the ZIP anywhere, then double-click `INSTALL_IMAGES.cmd`. It will look for `project.godot` next to the extraction folder or its parent; if not found, paste the path to your GitHub Desktop project folder. The script copies only images, not your saves or scripts.
6. In Godot, press **F5**, open **Love Beyond → Practice & Extras → CHECK INSTALLED STORY & PORTRAIT ART**.

**Expected result:** `CHAPTER BACKGROUNDS: 22 / 22 FOUND` and `SPEAKING PORTRAITS: 16 / 16 FOUND`, with small actual-image previews. If either is lower, the game still cannot find those image files at runtime; check the exact paths in the UI and the `assets` folder inside the project.

An example of the **correct** local layout:

```
Horseman-verse-RPG/
  project.godot
  assets/
    love_beyond/
      curated_chapters/
        part_01/
          01_cave_truce.webp
      dialogue_portraits/
        haniel/
          neutral.webp
        asmodeus/
          smile.webp
```

**Scene timing:** Curated chapter backgrounds start at **Part One: Aftermath, following the opening tutorial duel**. The prologue itself still has its existing storm imagery. Parts One–Five receive the supplied art; **Part Six deliberately keeps its existing Cliffside images**. Portraits appear when a character is speaking during normal dialogue; menus, free-time screens, and combat intentionally hide them.

## Automated regression coverage

`tests/smoke_test.gd` now verifies:
- Existing PNG assets can be decoded by the loader.
- Missing images fail safely without breaking scene/menu navigation.
- Runtime-created WebP images **inside a one-level Windows-style extraction subfolder** are discovered and decoded even without prior Godot import.
- The Chapter Art Check counts the 22/16 expected sources and shows previews when images are present.
- A newly extracted chapter WebP can be displayed as the actual scene background.
- A newly extracted transparent WebP can be displayed as the active character's visible speaking portrait.
- No existing battle, story, save, or Part Six background logic is changed.
