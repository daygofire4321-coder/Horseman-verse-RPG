# Battle Visual Pass 1 — Asmodeus vs Wild Boar (Prototype 005)

This is a **focused playable pixel-art proof of concept**, built on the working Prototype 004 story. No changes to author dialogue, interlude timing, EXP math or canon outcomes.

## Install

1. Pull the latest GitHub changes in GitHub Desktop.
2. Download **`Paleverse_Pixel_Battle_Pass_01.zip`** from the related ChatGPT conversation.
3. Extract the ZIP directly into the repo root (the folder containing `project.godot`).
4. Verify **`assets/love_beyond/pixel_battles/asmodeus.png`** and **`assets/love_beyond/pixel_battles/forest_clearing.png`** exist. Do **not** extract into `assets/` (avoids `assets/assets/`).
5. Open Godot; **F5** opens Prototype 005.
6. On the title screen choose **PIXEL BATTLE PREVIEW — ASMODEUS VS BOAR** to immediately test a standalone fight. No campaign save or EXP is affected.
7. Alternatively play the story, then **Hunt** in a forest camp interlude.

The six PNGs in this pack:
- `asmodeus.png` — canonical horned Asmodeus with black ice and **no sword**; transparent pixel sprite.
- `wild_boar.png` — transparent enemy battler.
- `forest_clearing.png` — wild animal hunts and bear fight.
- `forest_camp.png` — future forest-edge encounters.
- `cliffside_alley.png` — two-wave Alric/Joren encounter.
- `thundercloud.png` — opening duel.

The visuals are deliberately **separate from VN backgrounds**. The battle art and character sprite assets are replaceable without touching story text or combat balance.

## Runtime routing

Defined in `data/battle_areas.json`:
- Intro duel -> `thundercloud`
- Forest hunt -> `forest_clearing`
- Story bear encounter -> `forest_clearing`
- Cliffside waves -> `cliffside_alley`

Defined in `scripts/prototype_story_v5.gd`:
- A distinct pixel-sprite display layer with nearest-neighbor filtering and damage flash.
- A playable, save-safe, **one-click battle preview** from the title screen.
- Existing sprite slots that show a label when an enemy/hero sprite isn't created yet.
- Art-file fallback to the older illustrations, allowing the Godot smoke tests to run without downloaded PNGs.

## Scope and future work

- First pass provides actual character sprites for **Asmodeus and Wild Boar** only. Haniel, Alric, Joren, wolves, lynxes, thugs and the bear currently use labeled placeholders in pixel combat. **No art is falsely claimed complete.**
- Battle artwork is a draft; game readability, foreground scale and mobile-size presentation should be assessed together before making the full cast.
- Idle sprites are static, with initial feedback flash for hits. Attack/idle/hurt/defeat sprite sheets, black-ice projectiles and full character-specific effects are upcoming work.
- Battle location backgrounds are separate PNG assets from the authored anime story illustrations. The image pack was prepared from a generated pixel-art concept and includes hand-built transparent sprite pixel art.

### Canon safeguards

- Asmodeus is a **black-ice mage**, not a swordsman; no sword is included in his battler sprite.
- The Part Three bear rescue still triggers at bear half HP **or** Asmodeus depletion.
- Both waves of the Cliffside brawl still end in the authored outcome.
- The ordinary/exciting bedtime choice, hunting XP, and local save files remain unchanged.
