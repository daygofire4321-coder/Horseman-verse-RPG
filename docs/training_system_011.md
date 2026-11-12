# Prototype 011 — Train actions and move progression

This update implements the first **playable Train activity** for the forest-camp ordinary days in *Love Beyond*. Training and leveling are two separate progressions:

- **Battles/hunts award EXP**, increasing a character's level and HP as before.
- **Train uses one ordinary-day activity** to grant **10 move-training points** toward the next learnable technique.
- Fill the move bar to unlock a technique. Newly learned moves are recorded in the existing save and appear on the Pokémon/Digimon-inspired character sheet.
- **Ordinary days remain unlimited** and never automatically progress the story.
- Techniques may require a narrative milestone, so characters cannot unlock advanced moves just by sleeping and training indefinitely.
- Existing **four equipped move slots** remain. Learned techniques fill empty slots first; later move-loadout selection and use in actual combat are separate upcoming features.

## How to test

1. In GitHub Desktop, **Fetch origin → Pull origin**, and press **F5** in Godot. The main scene is `scenes/prototype_story_v11.tscn`.
2. Start or resume your forest camp ordinary-day interlude, available after Part Four or Part Five.
3. You should see a **Train** activity alongside **Rest**, **Explore**, and **Care for Haniel / Work on Camp**.
4. Click **Train**. You will see the next move's name, a numeric progress bar and a **TRAIN NOW** button. You can return without spending anything.
5. Confirm practice to spend **one** of your **three** daily activities and earn **10/30** training points toward **Black Ice Lance**. Repeat for three sessions to learn the move.
6. Open **PARTY & CHARACTER SHEETS → Asmodeus** to see the unlocked move in his fourth move slot and his current training bar. The next proposed move, *Ice Aegis*, remains story-locked until Part Six.
7. Choose **an ordinary day** to refill activity opportunities without advancing the story.
8. Saving and reopening the adventure preserves points and learned moves. This also works for older save files.

**Note:** The authored manuscript and story outcomes are untouched. Asmodeus is the active training POV for the two current forest-camp interludes while Haniel recovers. Data-driven future tracks are included for Haniel (*Focused Arrow*) and Alric (*Hammer Guard*) but **no new daily routines for those two are active yet**.

## Implementation files

- `data/training/love_beyond.json`: training point rate, prototype techniques, their cost and story milestones.
- `scripts/core/training_engine.gd`: save-compatible move points, learned move IDs, validation, story gates and unlocking.
- `data/interludes/love_beyond.json`: adds Train without removing existing activities.
- `scripts/core/party_engine.gd`: loads learned move definitions into empty sheet slots; preserves all original moves.
- `scripts/prototype_story_v11.gd`: dedicated Train action/confirm/cancel screen, progress bar, character sheet training display and save integration.
- `tests/smoke_test.gd`: covers practice, cancel, old saves, an exact three-action day, XP/level isolation, unlocked move display, Part Six gate, and progression across interludes.

## Boundaries and future work

**Playable now:** spending a daily action to train, filling a bar, unlocking a move, seeing it on a character sheet, and persistent saves. 

**Not yet playable:** casting the trained move during a hunt or scripted battle, editing a four-move loadout when more than four are learned, training Haniel while injured, Alric's shop, items, and full three-member battle turns. Technique names and power values are provisional and can change following author review. Existing canonical battle roles and results remain unchanged.

The save schema is still version 1; `campaigns.love_beyond.training` is an optional additive field that does not replace party slots, character progression, interlude checkpoints, or chapter completion.
