# Prototype 022 — Levels, Party EXP, Difficulty Scaling

## What changed

This update makes optional party battles, real Cliffside patrol fights and solo hunting encounters scale to **an expected play level**. It does **not** raise enemies automatically when the player grinds. Training, optional fights and equipment still offer a meaningful advantage.

- Active party members each earn the real encounter's EXP on victory; reserves do not. Even an active party member KO'd in combat receives the reward.
- The free-time protagonist keeps the existing `InterludeEngine.earn_hunt_exp()` rules. Other active teammates receive EXP using the same **30 × current level** threshold and **+8 maximum HP** per level; the shared reward isn't duplicated.
- Higher-level enemies now have their **level printed on the enemy-side HP card** as `LV N • Enemy`; their level affects health, damage, and a modest armor penalty against player attacks.
- Higher-level allied characters receive a small level-derived damage bonus in level-aware battles, in addition to trained moves and attack stats.
- Existing Story, Normal, Hard and Nightmare **HP/damage multipliers remain**. The new level target stacks with those multipliers.
- Existing scripted prologue, bear, Joren/alley story battles and their outcomes are **unchanged**. Level-aware scaling applies to optional solo hunting, three-character battle practice, and live Cliffside encounters only.

## Expected play level

This is an initial design target, **not** an assertion that every player will naturally reach the listed level. It assumes some ordinary days of exploration and repeatable combat.

| Completed part | Expected party level | Story enemies | Normal enemies | Hard enemies | Nightmare enemies |
|---|---:|---:|---:|---:|---:|
| 0–2 | 1 | 1 | 1 | 1 | 2 |
| 3–5 | 2 | 1 | 1 | 2 | 3 |
| 6–8 | 3 | 1 | 2 | 3 | 4 |
| 9–11 | 4 | 2 | 3 | 4 | 5 |
| 12–14 (future) | 5 | 3 | 4 | 5 | 6 |

Story mode stays well below the expected party level, Normal trails it by one, Hard meets it, and Nightmare pushes one above. Story progress—not the party's current level—sets the enemy target. A player who spends time training gets an advantage rather than facing a permanently rising treadmill.

**The HP/damage curves:** Each enemy level beyond 1 grants +9 base HP and +2 raw enemy damage before difficulty multipliers (Story 0.8× HP / 0.7× damage; Normal 1.0× / 1.0×; Hard 1.3× / 1.25×; Nightmare 1.6× / 1.5×). The enemy also gains 1 armor per level after 1; allied level bonuses and trained moves counter it. The existing guard, damage reduction, item and party-switch rules still matter.

For example, at completed Part Six the game's expected level is **3**. Hard opponents appear at **LV 3**. A player still at LV 1 can face them, but leveling, training and bringing a full party improves their odds; Nightmare opponents appear at LV 4.

## Where to choose difficulty

Open **Love Beyond → Adventure → Challenge Settings**. Choose Story, Normal, Hard or Nightmare. The screen explains the assumed current level, the resulting enemy level, and the HP and damage multipliers. This selection is saved in the existing `settings.difficulty` field and can be changed later without replaying the introductory duel.

## How to install / test

1. GitHub Desktop → **Fetch origin → Pull origin**.
2. Open Godot → **F5**; the default scene is `scenes/prototype_story_v22.tscn`.
3. Open **Love Beyond → Adventure → Challenge Settings** and select Hard or Nightmare.
4. Run **Practice & Extras → Three-Character Battle Practice** or an unlocked Cliffside daily Patrol/Explore encounter. Check the enemy level beside each HP bar.
5. Finish a real patrol fight with two or three active party members, then open **Party & Character Sheets**. Each active fighter has earned EXP. Retreating does not award EXP. Practice battles remain non-canon and award nothing.
6. Test solo hunting from an ordinary Asmodeus day. Wildlife level and HP now reflect the same difficulty selection; his original hunt EXP and HP progression remain intact.

This is a first playable balance curve to tune against actual fighting. We have not implemented enemy skills, status effects, new equipment, combat AI revisions or rewards for scripted story battles as part of this update.

## Implementation and safety

- `scripts/core/encounter_balance.gd`: level target, HP, damage, armor.
- `scripts/core/character_leveling.gd`: save-safe EXP awards for active non-POV teammates.
- `scripts/core/party_battle_engine.gd`: enemy stats and player-level damage bonus apply **only** when `story_part` is explicitly supplied; legacy test fights remain unchanged.
- `scripts/core/duel_engine.gd`: optional hunts can use expected enemy levels; unscaled canonical tests remain compatible.
- `data/difficulties.json`: introduces nonbreaking `level_offset` and updated descriptions.
- `scripts/prototype_story_v22.gd`: passes story context only to optional encounters, awards active teammate EXP once, displays levels and offers challenge settings.
- `tests/smoke_test.gd`: verifies all difficulty targets, saved settings, HP/damage curves, one-time XP, retreat behavior, and preservation of story checkpoints.

No new images or save schema migration are required.
