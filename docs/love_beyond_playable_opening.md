# Love Beyond — Three-part playable opening (Prototype 003)

## What is playable

This iteration contains the actual story progression following the existing 
tutorial duel:

**Thundercloud duel (either result) → Part One cave → Part Two forest / campfire → Part Three bear ambush → Asmodeus boss phase → scripted Haniel rescue → end-of-slice.**

The author-provided prologue dialogue is loaded from 
`data/chapters/love_beyond_prototype_001.json`. The story scenes are 
transcribed and lightly condensed from the author's **Parts 1–3**, using 
`data/chapters/love_beyond_opening_story.json`.

### Rules

- Tutorial duel: winning or losing both lead to **Part One: Aftermath**.
- Narrative events: speaker text, narration, Haniel's signing and thoughts, background switches and chapter title cards.
- Interactive forest beat: gather **three fallen branches**.
- Bear boss: control **Asmodeus**. Starts weakened (65 HP before the boss's first turn). The bear is scaled by selected difficulty.
- When bear HP reaches **50% or less**, **or** Asmodeus falls first, controls are replaced by the authored Haniel rescue sequence.
- No amount of damage lets Asmodeus kill the bear in the story encounter; the fatal shot belongs to Haniel.
- Rescue cutscene includes the original height joke, eye roll, second arrow, both falls and Asmodeus rushing to her.
- At the end, the save file records `campaigns.love_beyond.opening_parts_completed = 3`. Part Four is intentionally not invented.

**The QUICK BATTLE menu option is still a non-canon sparring mode with regular win/loss.**

## Artwork installation

The full-story artwork pack is provided separately as a small ZIP file:

`Paleverse_Opening_Story_Art_Pack.zip`

It contains **11 JPEGs** optimized from the user's original Love Beyond audiobook archives, inside
`assets/love_beyond/story_001/`.

1. Extract the ZIP **at the root of the Horseman-verse-RPG project**, alongside `project.godot`.
2. The final path should resemble `assets/love_beyond/story_001/cave_after.jpg`.
3. Launch Godot so it imports the images, then press **F5** once Prototype 003 is the default.
4. In GitHub Desktop, commit and push the new artwork if you want it backed up and synchronized to other computers.

The event runner falls back to the existing `storm_duel.jpg` if a story CG is missing. This prevents hard errors, but the correct visual experience requires the art pack.

## Original image mapping

| Name in game | Contact sheet source index |
|---|---|
| cave_after.jpg | #083 |
| cave_names.jpg | #091 |
| forest_gather.jpg | #069 |
| forest_fire.jpg | #051 |
| campfire.jpg | #056 |
| forest_hunt.jpg | #003 |
| bear_ambush.jpg | #064 |
| bear_boss.jpg | #074 |
| haniel_rescue.jpg | #066 |
| bear_aftermath.jpg | #080 |
| haniel_collapse.jpg | #060 |

These are **static cinematic images**, not transparent sprites.

## Editable files

- `scenes/prototype_story.tscn` — new playable scene.
- `scripts/prototype_story.gd` — event navigation, gathering, bear encounter, rescue threshold and completion.
- `data/chapters/love_beyond_opening_story.json` — story beat order, narration, dialogue, image references.
- `data/characters/grizzly_bear.json` — boss stats and scripted threshold metadata.

The earlier Prototype 001 and 002 scene files remain in the project as safe fallbacks.

## QA checklist

- [ ] Press **Begin the Chapter** and play either tutorial outcome; both continue to cave.
- [ ] Check the cave and camp scenes follow the book dialogue.
- [ ] Gather three fallen branches and continue.
- [ ] Reach the bear using Asmodeus and reduce the bear below half health.
- [ ] Check the rescue triggers and Haniel delivers the kill.
- [ ] On Nightmare difficulty, allow Asmodeus to fall; rescue must still play.
- [ ] Check the final cutscene and Part Three complete card.
- [ ] Check that **Quick Battle** still behaves like a regular sparring match.
- [ ] Confirm art renders with the pack installed, and that UI remains readable in 16:9 landscape.

### Known limitations

- Narration is compressed into game-sized beats to prevent endless giant text boxes; the author's quoted dialogue is preserved with light copyediting.
- Bear effects are provisional and use a timed color flash; proper animated bear sprites and sound effects are later milestones.
- No auto-save at each line; progress is recorded at the end of Part Three.
- The script assumes an authored, linear opening and does not yet implement a general-purpose campaign event graph.
