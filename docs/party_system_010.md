# Prototype 010 — Party Management and Character Sheets

The first systems-building pass adds a functioning **three-slot party roster** and character sheets to the Love Beyond Godot prototype. The prototype retains all seven environments, the 26-sprite pack, **Skip Dialogue**, six story parts, normal/exciting days, hunting EXP and authored combat outcomes.

## Playtesting

1. In GitHub Desktop: **Fetch origin → Pull origin**.
2. Open the `Horseman-verse-RPG` project in Godot and press **F5**.
3. On the title screen, scroll to **PARTY & CHARACTER SHEETS**.
4. Click a party member to view their character sheet. Click **EDIT SLOT 1**, **EDIT SLOT 2** or **EDIT SLOT 3** to assign or swap unlocked allies. The party changes are saved immediately.
5. Start or resume an ordinary day, and open **PARTY & CHARACTER SHEETS** there too. **BACK** returns to the same daily-routine screen without advancing time or story.
6. Completing **Part Six** makes Alric available for optional party use. This works for existing saves which already show `opening_parts_completed >= 6`. You don't need to replay Part Six.
7. Party members who are already active swap positions when chosen for another slot. The engine never duplicates a character, lets the active party exceed three, or lets you remove the last active character.

## Rules in this first pass

- **Party capacity:** Exactly 3 slots, with the option to leave a slot empty.
- **Starting availability:** Asmodeus and Haniel. **Alric** becomes available at Part Six completion (after the Joren alley fight). Joren, Michael, and others are **not** early party recruits.
- **Character sheet:** HP, level, accumulated EXP and next-level requirement reflect the existing save/interlude progression. The new ATK, DEF, and SPD numbers are **provisional sheet-design stats only**; current combat remains balanced using the existing battle engine.
- **Unique ability:** Each character gets a display entry. The effects are **not yet applied in combat**. Asmodeus's *Black Ice Affinity* and Haniel's *Angelic Grace* are working design labels, not settled canon powers.
- **Move list:** 4 slots displayed per character. Existing moves come from the original `data/characters/*.json` definitions, and remaining slots are **EMPTY**. No skills are invented or automatically learned by leveling.
- **Item slots:** 3 placeholders per character. No equipping, purchasing, or eating is implemented yet.
- **Alric's unique ability:** *Friends and Family* previews the planned 20% discount at his smithy **when he's in the active party**; shops aren't available yet, so the price effect isn't active.
- **Battle party:** Story fights still use their original canon participants. The roster editor does **not yet add additional turns** or change scripted battles. Full three-character combat is a separate systems phase.

## Technical organization

- `data/party/love_beyond.json`: data-driven party rules, story unlock parts, preview stat values, passive descriptions.
- `scripts/core/party_engine.gd`: UI-independent roster manager for unlocked characters, swapping/clearing slots, generating sheets, and saving party state inside `campaigns.love_beyond.party`.
- `scripts/prototype_story_v10.gd` and `scenes/prototype_story_v10.tscn`: the party menu, selection UI, character sheets, sprite previews, and navigation between title and daily life.
- `tests/smoke_test.gd`: checks party limits, safe slot swaps, story unlocks, original moves, EXP and checkpoint preservation, in-game controls, and return to free-time.

**Save compatibility:** The existing save schema is unchanged (`version: 1`). `campaigns.love_beyond.party` is an additive optional field. Old games without it receive a default two-character party; existing chapter checkpoints, interlude days, progression, and battle records remain intact.

## Next passes

1. **Training:** A daily Train activity accumulates move-specific training points toward new techniques, independently of character levels. Preserve unlimited ordinary days and story-dependent advanced techniques.
2. **Party combat:** Up to three active characters take battle turns, with targeting, enemy formations, equipment modifiers and safe transition from original scripted story fights.
3. **Inventory:** Three usable item slots per character. Equipment changes stats, enchanted items add effects, food restores a small amount of HP **once** and is consumed.
4. **Market / Smithy:** Unlock shop access after the Joren fight. Alric's `Friends and Family` discount becomes active at his smithy only when he's one of the three active party members.
