# Prototype 012 — Playable Three-Person Party Combat

This is the first isolated, playable party-battle system for Love Beyond. All six original story chapters, opening duel, bear rescue, the two scripted Cliffside waves, interlude routines, trained moves, character sheets, saves and seven area backgrounds remain in place.

## How to test

1. Open **GitHub Desktop → Fetch origin → Pull origin**.
2. Open the game in Godot and press **F5**. The default scene is now `scenes/prototype_story_v12.tscn`.
3. Scroll down the title screen to **PARTY BATTLE PRACTICE**.
4. Choose **WOODLAND SKIRMISH** (Wild Boar and Gray Wolf, forest clearing) or **CLIFFSIDE DRILL** (two thugs, alley).
5. Each available party member gets a turn in **Speed order**. Click a move; when prompted, select the enemy to attack or ally to heal. Ice Guard / other defensive moves act immediately.
6. At the end of the active team's turns, surviving enemies retaliate. KO'd units no longer act or appear as valid targets. Defeat every enemy to win; lose if all active allies fall.
7. To check trained moves, learn **Black Ice Lance** with Asmodeus's Train activity during ordinary days, then launch Party Battle Practice again. It will appear as a fourth selectable move.
8. After **Part Six**, Alric is recruitable. To test **SWITCH FIGHTER**, edit your active party in the existing Party menu to leave Alric in reserve. You can bring him in during battle, but swapping **costs the current character's turn**. If all three available allies are active, there is no reserve to swap in.

## Working gameplay

- Up to three active allies, with saved party configuration and unlocked bench members available for switching.
- Multi-target enemy encounters; choose the intended enemy or ally.
- Speed affects party turn order. Attack contributes modestly to outgoing damage; Defense reduces received damage.
- Moves: attack, heal, guard. Each character's moves come from the existing four character sheet slots, including learned techniques.
- Prototype passive: Asmodeus's *Black Ice Affinity* gives +2 damage to his black-ice techniques in this practice system.
- Prototype passive: Haniel's *Angelic Grace* adds +3 healing to her healing abilities.
- Alric's passive *Friends and Family* remains a shop-related ability and provides **no combat bonus** until the equipment/shop systems exist.
- Guard lowers damage received during the enemy phase.
- Replacement from reserves consumes the current fighter's action; invalid moves/targets/switches never consume a turn.
- Existing character sprite sheets are shown in combat cards, against the installed forest/alley backgrounds. A wolf sprite is pending and will appear without artwork until its asset exists.

## Deliberate limits

**Practice fights are non-canon and have no rewards.** They do not modify saved HP, EXP, story checkpoints, unlocked techniques, item inventory or interlude days. In the opening arc, Haniel is injured; party practice is separate from the story and does not pretend she is fighting during her recovery.

The opening duel, grizzly rescue, and authored two-wave Joren scene still use their original scripted combat engines. Once this mode is balanced and visually approved, we can connect the team engine to new repeatable post-Cliffside encounters, then expand the menu into item use, equipment modifiers, move loadout editing and additional character-specific passives.

## Developer files

- `scripts/core/party_battle_engine.gd` — data-driven party turns, target selection, stats, passives, enemy retaliation, guard, swapping, KO/victory conditions.
- `scripts/prototype_story_v12.gd` + `scenes/prototype_story_v12.tscn` — menu entry, two practice arenas, sprite cards, action buttons, heal/enemy target menus, reserves.
- `data/party/love_beyond.json` — records which provisional passive effects now work in practice combat.
- `tests/smoke_test.gd` — tests the full battle engine and UI, including target validation, battle swapping, learned-move use, speed, guarding, healing and no save mutations.

No new ZIP or images are required. The story save format remains version 1.
