# Prototype 016 — JRPG Battle HUD & Title Screen Cleanup

This is a visual-and-navigation update inspired by the user's JRPG battle reference (compact party status along the bottom, smaller enemy HP panels at the enemy side, a clear command menu and selected target feedback). Gameplay rules, combat balance, story, campaign selection, gold and inventory are unchanged.

## Install and test

1. GitHub Desktop: **Fetch origin → Pull origin**.
2. Open the Godot project and press **F5**. Main scene: `scenes/prototype_story_v16.tscn`.
3. The title screen no longer shows the large empty black rectangle across the artwork. This was the old visual-novel dialogue panel, now hidden while choosing campaigns.
4. Open **Love Beyond → Practice & Extras → Three-Character Battle Practice**, choose **Woodland Skirmish** or **Cliffside Drill**. If you're past Part Six, the same HUD also appears in **Asmodeus Explore** and **Haniel Patrol** real encounters.
5. In combat, enemies occupy a **left-hand column** with **small red HP bars**; allied character sprites appear on the **right**, with a **three-member status strip along the bottom**. The current actor has a gold highlight, wounded members get gold low-health fill, and defeated members show **KO**.
6. The **bottom command dock** has categories **Attack**, **Skills**, **Items**, **Guard**, **Switch**, and **Exit/Retreat**. Choose a category to update the accompanying action pane without consuming a turn:
   - Attack: basic physical attack (or Alric's Hammer)
   - Skills: nonbasic learned/equipped moves, including Black Ice Lance and Haniel's Heal
   - Items: prepared food with healing quantities and target eligibility
   - Guard: an equipped defensive move such as Ice Guard
   - Switch: bring in an unlocked reserve, costing the actor's turn
   - Exit (practice) or Retreat (real daily encounters)
7. Select an attack/skill to display **diamond-reticle target cards**, complete with compact HP indicators, for living enemies or allies. Pick the intended target to execute the actual existing combat action.
8. Return to the title; the empty dialogue panel should remain hidden. Begin the original story and confirm the dialogue box reappears as intended.

## Design choices

- The battle reference's **status-strip hierarchy** is adapted for **three party members**, without copying any UI textures or exact copyrighted assets.
- The game has **HP and character equipment** but no implemented SP/MP/AP resource systems. The status strip therefore shows actual HP and guard/turn/KO states rather than misleading placeholder resources.
- The **full-width battle view** leaves more of the existing forest/alley illustration visible than the original opaque centered command stack.
- Existing boss and authored story-battle HUDs are **unchanged**. These compact bars apply to **nonboss party battles**—repeatable outlaw encounters and optional practice fights.
- Tabs are navigation, not actions; changing tabs is free, and invalid targets still never spend a turn.
- The existing battle engine still decides turn order, damage, healed HP, food consumption, victory and rewards. The UI does not alter any saved progression rules or item economics.

## Files

- `scripts/prototype_story_v16.gd`: campaign title/dialogue visibility fix, styled compact HP gauges, side lanes, party status strip, command dock and diamond reticles; inherits the v15 multi-campaign hub and full v1–v14 content.
- `scenes/prototype_story_v16.tscn`: default F5 scene.
- `tests/smoke_test.gd`: checks title bar hiding/restoring, both campaign choices, compact enemy bars, ally HUD, all combat tabs, learned skills, target reticles, action selection and no practice save mutation.
- `project.godot`: default main scene updated.

**No new art ZIP or image required.** Reuses your existing title art, character sprites and environment backgrounds. Missing sprite images retain safe fallbacks.

## Further visual polish later

The update is a **layout/interaction pass**, not yet full animation. Later we can add pixel battler positioning, animated attacks, spell effects, damage number popups, target movement, combo/AP systems (if desired), and tailored boss HUDs. Your curated chapter 1–6 imagery can also improve the story presentation independently.
