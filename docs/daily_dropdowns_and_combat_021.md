# Prototype 021 — Dropdown Daily Routines and Hands-On Combat

**Summary:** This update folds the sprawling daily dashboard into a compact set of exclusive dropdown sections and adds the first gameplay-facing combat feel improvements: clicking valid targets on their battlefield sprites, short lunges, hit/healing flashes and floating HP values. Combat mathematics, save data, chapter progression, EXP, training, equipment, and economy are unchanged.

## Installing and playing

1. In GitHub Desktop, **Fetch origin → Pull origin**.
2. Open the project in Godot 4.7.2 and press **F5**. The main scene is `scenes/prototype_story_v21.tscn`.
3. Choose **Love Beyond → Adventure → Cliffside Free Time** (after Part 6), **Cave Homestead** (after Part 9), or continue an older Forest Camp daily checkpoint.
4. Open and close the **Today's Activities**, **Character Details**, **Characters & Inventory**, **Places & Companions**, and **Tomorrow & Save** dropdown headings. The routine defaults to Activities expanded. Only one section expands at a time.
5. Try Rest, Training, Gardening/Woodworking, Inventory, Market, switch characters and Go to Bed to verify familiar actions and save compatibility.
6. For combat, choose **Love Beyond → Practice & Extras → Three-Character Battle Practice** or initiate a Cliffside patrol/outlaw fight. Select Attack or Skills, then **click a valid enemy sprite itself** (or use its traditional target button). Expect a fast forward lunge from the attacking party member, a brief flash, and floating HP damage over the impacted unit. Healing and enemy retaliation receive their own floating HP changes.

**No new art pack is needed.** The existing optional story and pixel sprite assets continue to work.

## Daily routine design

The old rounded cards are still used, but no longer sit open in a scrolling pile. The header always shows the current day, remaining actions and HP. Other statistics are folded away.

- **Today's Activities** (open by default): Free-time activity cards such as Hunt, Rest, Train, Explore, Patrol, Gardening and Woodworking. Costs and availability retain their previous behavior.
- **Character Details**: The six expanded day/action/HP/level/EXP/supplies bubbles.
- **Characters & Inventory**: Party management, character sheets, backpack and equipment.
- **Places & Companions**: Cliffside market, switch protagonist, and homestead helper sprites.
- **Tomorrow & Save**: Rest for a new morning, sleep/choose tomorrow, and save/exit.

These are accordion **dropdowns**, so selecting another heading closes the previous group. The layout keeps the narrower-window single-column mode from Prototype 020.

Existing control IDs and callbacks remain the same. For example, `Daily_action_rest`, `Daily_action_train`, `Daily_VisitMarket`, `HomesteadSwitchPOV`, `Daily_Bedtime`, and `Daily_Save` are *moved* into the dropdown bodies, not duplicated. Action costs are not changed or bypassed.

## Combat improvements

- During target selection, a transparent button is placed over each **valid actual battlefield battler sprite**. It uses the same underlying move/food execution callbacks as the target cards, with keyboard focus and hover feedback.
- The original target cards remain as an alternative for accessibility and compatibility.
- Real HP changes after an attack, heal, food use, or round-ending enemy retaliation get **floating signed HP numbers** over the matching on-field battler. Damage briefly tints the recipient red; healing tints green.
- Successful offensive moves make the acting allied sprite **lunge forward and return**, without changing the turn order, targeting, damage formula, enemy AI or timing of saved state changes.
- The 3-person party, enemy/ally sided HP panels, Guard, Switch, Retreat, and small enemy bars remain.

## Implementation notes

- `scripts/prototype_story_v21.gd` extends Prototype 020; `scenes/prototype_story_v21.tscn` is the new main scene.
- Daily dropdown construction executes **after** inherited routine display and reparents existing controls.
- `_field_target_markers` adds buttons only for real valid targets, and uses pending selected move/food slot to choose the right callback.
- `_combat_hp_snapshot` and `_combat_animate_changes` compare before/after HP, so animations describe actual battle results, not guesses.
- `tests/smoke_test.gd` verifies default dropdown visibility, navigation folding, real Rest and Woodworking costs, the on-field sprite target button, actual enemy HP reduction, on-field damage-number creation, and practice-save isolation.

## Future combat roadmap

This is the first **feel/interaction pass**, not an entirely new combat engine. Further work could add distinct attack/projectile effects for each fighter, full enemy actions, improved enemy AI, status effects, better small-screen battle responsive layout, audiovisual cue timing, and a better single-screen target selection flow. These should be prioritized from real playtest feedback rather than inserted speculatively.
