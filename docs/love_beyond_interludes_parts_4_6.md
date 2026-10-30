# Love Beyond Prototype 004 — Daily-Life Interludes and Cliffside

Status: implementation design, using the author's Parts 4–6 and requested two-wave alley encounter.

## Absolute rule: the next day is NOT the next story beat

After a day of activities, the player gets a choice with two equally valid outcomes:

> **Will tomorrow be an ordinary day, or an exciting one?**

- **Ordinary day:** Sleep, increment the day counter, refresh limited activity points, persist, then return to the free-time menu. **Do not move the story event cursor.** There is no limit to consecutive ordinary days.
- **Exciting day:** Sleep and voluntarily start the pending next authored story scene. This advances the story cursor once. The active interlude is marked completed.
- **Keep going today:** Go back to free-time activities, useful if the player wants another hunt before bed.

The player may end a day without consuming all three limited actions. Repeatable hunts cost **zero** daily actions but are dangerous and require HP. Rest, care, and explore are limited. Never force a story beat through fatigue, a counter reaching zero, a random event, or a new morning.

This model supports Asmodeus and Haniel POVs and can replace the available actions later with farming, townsfolk conversations and other regional actions, all through editable JSON data. Progression and hunt enemy pools are chapter-based; enemies are not auto-scaled to the player.

## Canon chronology

- **Part Three ends** with Haniel collapsing after saving Asmodeus.
- **Part Four — To Give Thanks** follows *immediately*, with Haniel waking the next day, drinking from the seashell, learning she is on the bear-fur blanket, debating Asmodeus about mercy and thanking him. This has to occur before an optional open-ended interlude, because the manuscript specifies the bear attack was **yesterday**.
- **Interlude A — Forest Recovery** unlocks after Part Four. POV Asmodeus. Hunt (repeatable), Rest, Care for Haniel, Explore; three limited activities per ordinary day. Optional actions supplement but never replace essential care in canon.
- **Part Five — Playing House** follows **only** when the player chooses an exciting day. Includes his failed hide rack, thoughts about servants and Lucifer, and talk with Haniel about home.
- **Interlude B — The Forest Camp** opens after Part Five. POV Asmodeus; chores can replace the unique care activity. Repeated ordinary days are plausible here because the text already spans weeks.
- **Part Six — The Nature of Man and Demons** starts only on an exciting day. Haniel POV: Cliffside town, shop, dishonest lure into alley, Alric's intervention.
- **Alley encounter Wave One**: playable Haniel with Alric assisting vs two thugs, representing the scuffle without rewriting the story. On victory OR loss, Alric is injured; proceed to wave two.
- **Alley encounter Wave Two**: Asmodeus arrives, with Alric supporting, against two thugs and **Joren** as youth gang boss (per author's instruction; manuscript calls him gang leader or boy). Prevent player from killing Joren; scripted post-fight wrist injury, Haniel's grief and Alric's restraint end Part Six. A lost fight also follows this canonical cutscene.
- **After Part Six**: finish on a to-be-continued screen. Don't invent Parts 7+.

## Systems and safeguards

- Save interlude day count, daily action use, character HP, supplies, experience and level in existing version-1 save schema.
- Add title screen **Continue Adventure** for existing interlude checkpoints; don't force replaying six parts after leaving.
- Hunting uses real turn-based combat, character moves, enemy HP and selected difficulty; EXP on a win; no reward for defeat.
- The encounter pool starts with boars and wolves; future configs can unlock bears and bandits when progression warrants it, without rescaling weaker fauna.
- Explore has supplies and discoveries, possibly encounters in later zones, and cannot overwrite authored events.
- The first presentation pass reuses existing art or fallback backgrounds, with exact asset gaps documented for a later expression/visual sprint.
- Names in all dialogue follow manuscript; the explicit 'Joren' boss identity is from the author's message, not from his unnamed manuscript appearance.

## Test gates

1. Parts 1–3 still pass, including bear threshold and player-collapse rescue.
2. Normal day x3 preserves story cursor and increments day.
3. All 3 limited actions can be used; hunting does not consume them.
4. Rest restores HP; hunt win awards exp; state saves and resumes.
5. An exciting day starts **one and only one** next story scene.
6. Both alley waves trigger in order, enemy targets work, hero loss still advances.
7. Part Six ends in scripted canon (injury, intervention) and completion card.
