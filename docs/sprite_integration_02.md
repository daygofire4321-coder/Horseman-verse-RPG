# Sprite Integration 02 — User-Supplied Love Beyond Character Sheets

## What was done

The user's ten paired/group sprite PNG images were extracted into **26 separate, transparent sprites** (with no character redesign), with the active game cast and future variants separated. The pack is delivered as `Paleverse_Love_Beyond_Sprite_Pack_02.zip`.

The Godot battle configuration is `data/battle_areas.json`. The new scene is `scenes/prototype_story_v6.tscn` and the new presentation layer is `scripts/prototype_story_v6.gd`. Earlier prototype scenes are preserved.

The active story uses:
- Prologue: Asmodeus battle pose and Haniel with bow
- Bear encounter: Asmodeus and grizzly bear
- Hunting: Asmodeus and wild boar (the wolf/lynx still need dedicated sprites)
- Alley Wave 1: Haniel + Alric versus knife thug and club thug
- Alley Wave 2: Asmodeus + Alric versus two thugs and Joren's boss pose

The larger future cast (Azrael, Azazel, Michael, Gabriel, Uriel), optional wild animals, and alternate poses are filed in the pack for later story events. **No new encounters or dialogue were invented to use these sprites.**

The **VIEW NEW CHARACTER SPRITES** option on the title screen opens a three-page gallery to inspect the images before replaying the manuscript. The old **PIXEL BATTLE PREVIEW — ASMODEUS VS BOAR** button remains available.

## User steps

1. In GitHub Desktop, **Fetch origin → Pull origin** for `Horseman-verse-RPG`.
2. Download the new `Paleverse_Love_Beyond_Sprite_Pack_02.zip`.
3. Extract the ZIP directly into the `Horseman-verse-RPG` folder that holds `project.godot`. This ZIP **replaces** existing `asmodeus.png` and `wild_boar.png` from the older pixel pack; accept overwrites.
4. Do **not** extract into `assets/` or you will end up with `assets/assets/`.
5. Check: `assets/love_beyond/pixel_battles/asmodeus.png` and `.../joren_boss.png` should exist. PNGs in the `variants/` subfolder are optional later forms.
6. Open Godot, let it import the PNGs, then press **F5**.
7. Use **VIEW NEW CHARACTER SPRITES** to page through the cast, then **PIXEL BATTLE PREVIEW** for Asmodeus vs. Wild Boar.
8. To see Alric, thugs and Joren in combat, continue the story into Part Six's two-wave Cliffside fight.

The location-specific pixel battle backgrounds are still supplied by the **earlier Pixel Battle Pass 01 ZIP**. This new ZIP contains the character replacements only. Story VN illustration backgrounds still use the **Parts 1–6 art pack**.

### Folder layout

```text
Horseman-verse-RPG/
├─ project.godot
└─ assets/
   └─ love_beyond/
      └─ pixel_battles/
         ├─ asmodeus.png
         ├─ haniel.png
         ├─ joren_boss.png
         ├─ joren_idle.png
         ├─ alric.png
         ├─ bandit_knife.png
         ├─ bandit_club.png
         ├─ grizzly_bear.png
         ├─ wild_boar.png
         ├─ michael.png
         ├─ deer.png
         ├─ goat.png
         ├─ rabbit.png
         ├─ pheasant.png
         ├─ duck.png
         └─ variants/
            ├─ asmodeus_idle.png
            ├─ haniel_idle.png
            ├─ azrael.png
            ├─ azazel.png
            └─ (other optional variants)
```

## Art scope and limitations

- These are **static sprites**. Idle/attack/hurt animations come later.
- Character-scale and exact poses should be reviewed at 1280×720 and on phone landscape; the current battle-stage layouts are first-pass.
- User may wish to confirm the named Joren boss sprite, as it is drawn from the file `boss joren and thug.png`; his alternate neutral pose is separately saved as `joren_idle.png`.
- Gallery and battle sprites use nearest-neighbor filtering. The source sheets were large images, so crops have been resized conservatively to up to 680 pixels tall.
- Full multi-target targeting and health bars for individual alley enemies are **not** introduced here; the existing alley battle engine and scripted outcome remain intact.
- Future characters' available sprites do **not** make them currently playable or added to the story.
