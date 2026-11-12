# Horseman-verse-RPG

## F5: Prototype 010 — Three-person party and character sheets

**New playable menu:** **PARTY & CHARACTER SHEETS** on the title screen (now scrollable), and also inside the ordinary-day menu. Inspect a Pokemon/Digimon-inspired sheet for each unlocked character, and fill, swap or clear any of three active slots. The party is saved to the existing Love Beyond campaign save without changing story checkpoints, EXP, ordinary days or prior settings. Existing save files remain compatible.

**Roster unlocks:** Asmodeus and Haniel start available. Alric can join an optional active party once **Part Six** is completed. Existing saves already past that encounter unlock him automatically when the Party menu is opened.

**What works now:** 3-slot party editor, saved party selection, character stats/level/HP/EXP sheet, actual current move list shown in 4 move slots, unique-ability display, and three future item-slot placeholders. Artwork uses the already installed character sprite pack.

**What is not yet implemented:** Party changes **do not alter the scripted story battles**; ATK/DEF/SPD are preliminary sheet stats; new training, move unlocks, equipment, food, actual shops and Alric's discount still need their systems. The 20% `Friends and Family` smithy discount is noted as a future passive, not falsely applied.

**To play:** GitHub Desktop → **Fetch origin → Pull origin**, then Godot → **F5**. No new ZIPs or images are required for this code update. See [full party-system guide](docs/party_system_010.md).

---


## F5: Prototype 009 — Seven author-made environment backgrounds

The default scene is now `scenes/prototype_story_v9.tscn`. Download **Paleverse_Love_Beyond_Backgrounds_Pack_03.zip** from the conversation and extract directly into the repository root beside `project.godot`. Then **Fetch origin → Pull origin** and press **F5** in Godot.

**New environments:** Thundercloud duel, bright forest for wildlife, deep forest for the bear, Cliffside alley, camp cave for daily routines, market street (preview), and Alric's smithy (preview). The optimized background files are WebP, 1280×720, around 2.6 MB total; the original PNGs are unchanged. Older battle PNGs continue working as fallback. Story dialogue, EXP, saves, sprites, and the **Skip Dialogue** feature are unchanged.

**New title-menu option:** **VIEW SEVEN NEW LOCATIONS** lets you examine each environment without replaying chapters. The game loads each background from `data/battle_areas.json`; if the art ZIP isn't installed, you get a safe fallback instead of a crash.

**Note:** Marketplace inventory, Alric's shop, the party discount, team management, training points and item slots are planned systems, not implemented by the environment pack. See [background integration and install steps](docs/background_pack_03.md).

---


## F5: Prototype 008 — Skip dialogue safely

The default scene is now `scenes/prototype_story_v8.tscn` (earlier prototypes remain for rollback).

- **SKIP INTRO DIALOGUE** jumps directly to the prologue's **Choose your fighter** prompt; it does not skip the tutorial battle.
- **SKIP DIALOGUE • Next gameplay** appears during the main story's dialogue and chapter-title screens. It fast-forwards narration until the next required interaction: branch gathering, the scripted bear encounter, an optional free-time interlude, or a Cliffside combat wave.
- Skipping does **not** automate gameplay, force an exciting day, remove story beats from the data, bypass a fight, or erase your progress. Skipped part-title labels and completion checkpoints are still processed.
- The old scene `prototype_story_v7.tscn` remains available if needed.

**To try:** In GitHub Desktop select **Fetch origin → Pull origin**, then run **F5** in Godot. **No new art ZIP is needed.**

Next: the four dedicated battle backgrounds, then expanded leveling and party management systems.

---


## F5: Prototype 007 — Daily-action and battle-layout fixes

The default Godot scene is now `scenes/prototype_story_v7.tscn`. All earlier prototypes remain for rollback.

**Daily routine:** The activity screen now scrolls instead of clipping long options. You can select Rest, Care for Haniel, Explore, or Work on Camp while you have daily actions remaining. When all three activities are used, the game explains why they are disabled and shows a direct **START ANOTHER ORDINARY DAY** button. Choosing an ordinary day restores actions **without moving forward in the canonical story**. The original Go to Bed screen still allows choosing between ordinary and exciting days, and a save/resume keeps the refreshed activity count.

**Battle presentation:** Asmodeus faces toward the enemy from the left, sprite slots are more compact and lower, the battle stage reserves room above the commands, and combat images render **behind** the HUD and move buttons instead of blocking them. The cliffside multi-character formation is retained. Story scene illustrations and all authored fight outcomes are unchanged.

**Install:** This update changes code only. Pull the latest `main` with GitHub Desktop and press **F5**. Keep the existing `Paleverse_Sprites_COMPLETE_Fresh_Link.zip` characters and earlier pixel background art extracted under `assets/love_beyond/pixel_battles/`; there is **no new sprite download** for this fix.

**Automated coverage:** `tests/smoke_test.gd` now presses the Rest, Care, Explore and next ordinary-day buttons and checks that the story cursor remains unchanged. It checks saves, sprite orientation, dedicated stage spacing and UI layering, plus the earlier six-part combat/story tests.

**Next work:** Dedicated pixel battle environments, followed by expanded leveling/party management, inventory/shops, and character-specific daily routines. Neither the new battle backgrounds nor the new systems are included in this patch.

---


## F5: Prototype 006 — Your Love Beyond character sprites

The default scene is now `scenes/prototype_story_v6.tscn`; earlier versions remain available for testing and rollback.

**New:** User-supplied sprite sheets have been separated into 26 transparent character/creature PNGs in a downloadable pack, and `data/battle_areas.json` maps the assets to active encounters. The title screen's **VIEW NEW CHARACTER SPRITES** button opens a three-page gallery; **PIXEL BATTLE PREVIEW** launches Asmodeus vs Wild Boar.

The prologue shows Asmodeus and Haniel. The bear encounter shows Asmodeus and the grizzly bear. The Cliffside alley now shows **Haniel/Asmodeus plus Alric versus two thugs, adding Joren in Wave 2**. Story dialogue, scripted resolutions, ordinary/exciting day choices, EXP and existing saves are unchanged.

**Install:** Download `Paleverse_Love_Beyond_Sprite_Pack_02.zip` from this conversation, extract it directly into the repository root (beside `project.godot`), accepting overwrite of the older `asmodeus.png` and `wild_boar.png`. The existing Pixel Battle Pass 01 backgrounds and Parts 1–6 story art are still used separately.

See [the detailed sprite integration steps](docs/sprite_integration_02.md) and [current sprite mapping](data/battle_areas.json). If the pack isn't installed, fallback labels appear instead of missing-image crashes.

**Limitations:** The new sprites are static. The current two-wave alley combat engine remains simplified, with shared enemy progression rather than individually selectable targets. Future boss/angel sprite variants are prepared but not yet given gameplay events.

---

## F5: Prototype 005 — Battle Visual Pass 1

The default Godot scene is now `scenes/prototype_story_v5.tscn`. **All six Love Beyond story parts, both interludes, EXP and save data remain intact.** Prototype 004 is preserved in `scenes/prototype_story_v4.tscn`.

**New:** A pixel-art combat stage with backgrounds that automatically change by encounter (thundercloud duel, forest hunts, story bear, Cliffside alley). An original, weapon-free Asmodeus sprite and Wild Boar enemy sprite are provided in a separate art pack. The non-pixel visual novel scenes keep the existing anime illustrations.

To test instantly without replaying the story, choose **PIXEL BATTLE PREVIEW — ASMODEUS VS BOAR** on the title screen. The preview does not affect campaign saves or EXP.

### Required for the new pixel graphics

Download **`Paleverse_Pixel_Battle_Pass_01.zip`** from our ChatGPT conversation. Extract the ZIP **into the project root beside `project.godot`**, not into `assets/`, which would create an extra folder.

The resulting files will live under:

`assets/love_beyond/pixel_battles/`

The ZIP includes four illustrated pixel-art combat environments and two transparent character sprites. Without the ZIP, the new scene still works but shows the prior illustrations and labeled sprite placeholders. The previous Parts 1–6 art pack still supplies the VN backgrounds.

Read [the visual pass guide](docs/battle_visual_pass_01.md) and [the area/sprite map](data/battle_areas.json).

**Scope note:** Only Asmodeus and Wild Boar have finished first-pass sprite graphics; the other characters are placeholders. This version adds lightweight damage feedback but not full sprite-sheet animation.

---

## F5: Prototype 004 — The first six Love Beyond parts and free-time days

The new default scene is `scenes/prototype_story_v4.tscn`. Earlier versions are preserved.

**Story route:** Thundercloud duel → Parts 1–3 → Part Four (*To Give Thanks*) → **Interlude A** → Part Five (*Playing House*) → **Interlude B** → Part Six (*The Nature of Man and Demons*) → two-wave Cliffside alley encounter → end-of-slice.

### Sleep is NOT a forced story trigger

After the first bear recovery scene, Asmodeus gets optional daily activities. At bedtime the game asks:

> **Will tomorrow be an ordinary day, or an exciting one?**

- **An ordinary day:** advance the day counter, refresh three limited activities, restore a little HP and remain at the same point in the story. Do this as often as you want.
- **An exciting day:** advance to the *next* authored chapter. Never happens unless the player deliberately chooses it.
- **Not yet:** return to the activities for the current day, including repeatable hunting.

Daily choices are tied to the POV and chapter; the first two camps use Asmodeus. Hunt is repeatable without costing a daily action, with persistent HP, simple EXP/level gains, and encounter pools that expand from boars/wolves to lynx. Rest, Care for Haniel, Explore, and Work on Camp use limited daily actions. Future arcs can replace these choices with Farm, Speak with Townsfolk, and other chapter-specific choices.

Progress is saved at the interlude. **CONTINUE SAVED ADVENTURE** on the title screen resumes from the active interlude. The main **BEGIN THE CHAPTER** option still starts from the beginning.

### Cliffside battle

Part Six introduces Alric and Joren. **Wave 1:** Haniel and Alric versus two thugs, with Alric providing automatic ally attacks. **Wave 2:** Asmodeus and an injured Alric versus two thugs and Joren as the gang boss. Any win/loss eventually continues into the author's canonical alley resolution—no story character dies due to combat HP.

### Install the author-provided artwork

For Parts 1–6, download **`Paleverse_Love_Beyond_Parts_1_to_6_Art_Pack.zip`** from the related ChatGPT conversation. It includes **19 optimized illustrations** from the user's audiobook archive, including the 11 opening images plus eight recovery, camp, and Cliffside images.

Extract the archive's `assets/` folder into this project beside `project.godot` (preserving `assets/love_beyond/story_001/` and `story_002/`). It replaces the need to install the earlier art pack separately. The UI still runs without the added CGs, but temporary backgrounds are shown.

### Code and content

- `scripts/prototype_story_v4.gd` — new story+interlude UI and event routing
- `scripts/core/interlude_engine.gd` — day progression, activities and simple EXP levels
- `scripts/core/alley_wave_engine.gd` — ally-assisted, multi-enemy fight
- `data/chapters/love_beyond_parts_4_6.json` — the author's next three parts
- `data/interludes/love_beyond.json` — POV options, chapter gates and hunting pools
- `data/characters/` — Alric, Joren, bandits, wild creatures
- `tests/smoke_test.gd` — automated story traversal, daily loops, hunts and battle waves

See [the new design notes](docs/love_beyond_interludes_parts_4_6.md) for canon and system rules.

### Development roadmap (planned, not yet implemented)

1. **Battle Visual Pass 1 — next:** consistent pixel-art battlers for Haniel, Asmodeus, Alric, Joren and wildlife; battlefield backgrounds based on the actual encounter area (thunderclouds, forest, bear encounter, Cliffside alley). Keep the illustrated visual-novel cutscenes.
2. **Story presentation pass:** correct any illustration ordering, add character expressions, refine dialogue layout, and improve battle animation.
3. **Hunger and food survival — later:** both Haniel and Asmodeus have a food/hunger need tied to ordinary days. Hunts provide food as well as EXP; eventually farming, buying, preparing or sharing meals can also contribute. Balance so choosing extra ordinary days is meaningful without forcing the next story beat or creating an unwinnable starvation loop. Determine thresholds and rest/HP effects only when implementing.
4. **Expanded exploration event pool — later:** replace today's deterministic +1 supplies with a wide variety of region-, character-, and story-stage-specific optional encounters: discoveries, resource finds, wildlife, bandits, travelers, and relationship scenes. Mix peaceful and combat events, and allow authored rare events. Do not change canon plot events or auto-advance the story without the player's choice.
5. **Broader chapter / POV content:** Haniel-specific interludes; later Asmodeus activities such as Farm and Speak with Townsfolk; new hunt pools unlocked through recovery and geography. Avoid automatic scaling that removes the feeling of character progression.
6. **Deeper progression and balancing:** inventory, food economy, EXP curves, traits, skills, equipment, and eventually landscape/mobile playtesting.

**Story pacing rule remains permanent:** Sleeping and selecting **An ordinary day** must never advance the authored chapter. Only **An exciting day** advances. Daily needs and random exploration events must not override that decision.

### Known next milestones

- Manual visual playtesting in landscape and balancing (especially higher difficulties).
- Replace temporary stat and color-flash combat effects with sprites/animation.
- Make character expression variants for Haniel, Asmodeus, Alric and Joren.
- Build later POV profiles such as Haniel, and story-unlocked farm/townsfolk choices.
- Refine XP, inventory and growth once additional chapters establish progression pacing.

---

## Earlier Prototype 003 reference

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
