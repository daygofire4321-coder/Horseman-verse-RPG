# Prototype 019 — Parts 7–9 and the Care Package

This update adapts the author's manuscript **Part Seven: Michael**, **Part Eight: Explanation**, and **Part Nine: Understanding**, and integrates the **26 original artworks** supplied in `care package.zip`. The original six-part opening, Cliffside market, patrols, combats, saves and portrait system remain in place. This batch deliberately adds **no invented boss fight** to the quieter story chapters.

## Installation

1. In **GitHub Desktop** choose **Fetch origin → Pull origin**.
2. Download `Paleverse_Parts_7_to_9_Asset_Pack.zip` from this ChatGPT conversation.
3. In GitHub Desktop choose **Repository → Show in Explorer**; this opens the project root containing `project.godot`.
4. Open the art ZIP and drag the **assets** folder inside into the project root, merging with your existing `assets` folder. The pack does **not** overwrite Parts 1–6 art or existing character portraits. The image loader can also detect common one-level extra extraction folders.
5. Open Godot and press **F5**. The main scene is `scenes/prototype_story_v19.tscn`.
6. Play the original story from the beginning, or load an existing save with **Part Six completed** and select **Love Beyond → Continue Story: Part Seven — Michael**. Saves completed through Part Seven or Eight offer the next chapter instead.

## The three new parts

- **Part Seven — Michael:** The ivory tower, Uriel's questions, Michael's white flames and the blue glass sphere. Four Michael and four Uriel portraits respond to the dialogue. Michael's revelation about the bear is included; there is **no invented playable boss battle**.
- **Part Eight — Explanation:** Alric's living room, cups and pastries, Haniel's anger after the alley, the old drying-rack joke and Haniel's request to study carpentry. The single supplied story illustration appears at her table gesture.
- **Part Nine — Understanding:** Alric arrives with injured Joren and young Toren, the apology, gardening and woodworking lessons, and Haniel and Alric's conversation about family. The supplied chained-brother memory picture appears at that exact moment; the ending leads to the Cave Homestead's daily activities.

All original speaker dialogue is included. Extra narration is split into readable visual-novel segments without inventing new dialogue or changing canonical events. Portraits appear for Michael, Uriel, Toren and the original Asmodeus/Haniel/Alric/Joren cast. Haniel's signed passages still use her speaking portrait.

## Asset inventory

The ZIP includes **26 optimized WebP files**, all derived from the supplied PNGs:

| Category | Qty | Game asset path |
|---|---:|---|
| Story paintings and backgrounds | 14 | `assets/love_beyond/curated_chapters/part_07/...`, `part_08/...`, `part_09/...` |
| Michael expressions | 4 | `assets/love_beyond/dialogue_portraits/michael/{neutral,annoyed,angry,contemplative}.webp` |
| Uriel expressions | 4 | `assets/love_beyond/dialogue_portraits/uriel/{neutral,skeptical,concerned,annoyed}.webp` |
| Toren expressions | 2 | `assets/love_beyond/dialogue_portraits/toren/{neutral,cheerful}.webp` |
| Story sprites | 2 | `assets/love_beyond/story_sprites/{toren,joren_wounded}.webp` |

The original uploaded folders were labeled `micheal`, `toen`, and `spites 2`. To keep paths consistent with character IDs, these are normalized to `michael`, `toren`, and `story_sprites`. The submitted `contimplative` expression is installed as `contemplative`; the original image remains unchanged.

**Optional-art diagnostics:** Go to **Love Beyond → Practice & Extras → CHECK INSTALLED STORY & PORTRAIT ART**. With all previous chapter and portrait packs plus this new pack installed, the expected totals are **36/36 chapter images** and **26/26 speaking portraits**. If the image pack is not copied into the Godot project, the game safely uses older background art, and uninstalled portraits are hidden.

## Homestead free time — unlocked after Part Nine

The Part Nine ending enters **Haniel's homestead day**. Afterward you can revisit both protagonists from **Love Beyond → Adventure → Cave Homestead**.

- **Asmodeus**: Gardening with Joren and Toren, hunting, training, resting and forest exploration.
- **Haniel**: Woodworking with Alric's tools, reflection, training and rest; she does not hunt in her homestead routine.
- Each character has **three limited activities per ordinary day**. Gardening/woodwork practice tracks separately and persists in existing save data as simple progress counters.
- The homestead shows Toren and injured Joren's supplied pixel sprites when the pack is present.
- **Ordinary days do not advance the story.** There is deliberately no "exciting day" at Part Nine yet, since no later manuscript has been adapted.
- Homestead routines do not overwrite story resume checkpoints. The existing Cliffside free-time activities, shop, optional outlaw encounters, wallet and unlocked party remain available.
- This update introduces gardening and woodworking *practice*, not fabricated crop recipes, finished furniture, or a full crafting economy. Those are future systems.

## Development files and testing

- `data/chapters/love_beyond_parts_7_9.json`: authored three-part story, chapter images, speaker expressions, checkpoint records, ending.
- `data/portraits/love_beyond.json`: Michael, Uriel and Toren aliases and expression paths.
- `data/interludes/love_beyond.json`: two additive post-nine free-time profiles.
- `scripts/prototype_story_v19.gd`, `scenes/prototype_story_v19.tscn`: story aggregation, continue-next-part from old saves, homestead routines, story completion and UI.
- `tests/smoke_test.gd`: asserts manuscript content, exact picture and portrait counts, existing Parts 1–6 preservation, saves resuming Part Seven/Eight/Nine correctly, actual Chapter Nine finale transition, ordinary-day isolation and camp routine counters.

Note: the actual large WebP images are provided by ZIP rather than committed as repo binaries; the GitHub update contains the code and reference paths.
