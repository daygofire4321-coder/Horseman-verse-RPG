# Playtest UI Repair Pass — November 19, 2026

## Reported issues

- Intro text/dialogue panel covers portrait faces.
- Intro portraits/character bodies are cut off near the bottom.
- Story dialogue often overlaps character faces.
- Alleged failure to target enemies during the two-wave Cliffside fight; possibly decorative UI overlays obscuring enemy characters.
- No apparent enemy turns in some story sequences and progression without beating waves; **not yet proven to be combat-logic errors**.
- Part Six / Cliffside ordinary-day screen does not make continuing the story obvious.

## Fixes in this branch

1. Place speaking portraits in the upper side regions (x=1–35% and 65–99%; y=2.5–67%). This creates clear lower space for dialogue. Existing portraits, expressions and authored dialogue are unchanged.
2. Attach on-sprite target buttons before setting full-rect anchors. Set full bounds explicitly; provide pointer cursor and focus/hover indication. Corrects potential zero-sized interactive areas.
3. Set all decorative battle status panels and labels to ignore mouse input during target selection, so they cannot intercept a click.
4. Surface **CONTINUE STORY — PART SEVEN/EIGHT/NINE** directly on the Cliffside daily routine when appropriate, in addition to the existing Love Beyond campaign menu.
5. Expand smoke tests for portrait bounds, real click-target rectangle alignment and prominent continuation.

## Safety and remaining work

- No changes to story-wave outcomes or forced canonical progression. The reported wave/turn behavior still requires a live reproduction if it continues after hitbox fixes.
- The portrait positions are conservative defaults, not a measured guarantee for every screen resolution. Manually check 1280×720, 1920×1080 and a narrow viewport.
- Only the default current prototype inherits these improvements; old scenes remain available for regression.
- No UI-system rewrite, new hunger/exploration mechanic, or save-schema changes.

## Manual test plan

1. Open the default Godot scene and replay the intro. Confirm faces and lower dialogue controls do not overlap, including long lines.
2. Resume Part Six. Enter Cliffside daily life and find the new **CONTINUE STORY** button near the top. Verify it starts Part Seven, not a previous story checkpoint.
3. Start a three-character battle, choose an attack requiring a target, and click each enemy sprite with the mouse, including enemies beside HUD panels. Confirm hovered/focused targets highlight.
4. Play both story alley waves and distinguish enemy turns from authored continuation behavior.
5. Test keyboard focus, 1280×720 and 1920×1080. If parts of portraits still crop, capture a screenshot showing the full window and visible dimensions.
6. Ensure older saved games and all chapter/portrait assets still load normally.
