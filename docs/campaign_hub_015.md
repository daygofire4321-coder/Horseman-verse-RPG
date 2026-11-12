# Prototype 015 — Campaign Select & Visual UI Pass

The Pale Horseman game now opens with a **campaign selector** rather than a growing list of prototype buttons. All existing Love Beyond story content and gameplay remain in place; only menu navigation and visual styling have changed.

## Install the update

1. In GitHub Desktop: **Fetch origin → Pull origin**.
2. Open the project in Godot, press **F5**. The default scene is now `scenes/prototype_story_v15.tscn`.
3. For the full title-screen illustration, extract the separately provided `Paleverse_Campaign_Title_Art_Pack.zip` **into the root of your Horseman-verse-RPG project**. It creates the required file `assets/paleverse/campaign_title.webp`. Let Godot import the image, then F5 again.
4. The game is still playable without this title-art ZIP: it falls back to the previously installed storm art.

The supplied illustration has been optimized to **1280 × 720 WebP**, preserving the original widescreen composition. The translucent campaign panel sits toward the right so the characters remain visible on the left.

## New menu organization

**THE PALE HORSEMAN → SELECT CAMPAIGN**

- **Love Beyond Heaven or Hell** — playable. Opens a dedicated campaign menu.
- **Blades of Courage and Ferocity** — a visible, disabled **COMING SOON** entry. It cannot be clicked and creates no Blades save or character roster.

**Love Beyond →**

- **Continue Saved Adventure** — enabled only if there's a real resumable story/interlude checkpoint.
- **Begin the Story** — starts the existing Love Beyond opening; it does not automatically delete any older save.
- **Adventure: Party, Inventory & Town** — the management hub.
- **Practice & Extras** — optional battles, galleries, and information.
- **Back to Campaign Select** — returns to the universe hub.

**Adventure →** Party & Character Sheets; Shared Backpack & Equipment; Cliffside Free Time (Asmodeus Explore / Haniel Patrol, after Part Six); Cliffside Market (after Part Six). The Back action from party, inventory, and market now returns to Adventure rather than dumping the player at the root title.

**Practice & Extras →** Three-Character Battle Practice, Haniel vs. Asmodeus Quick Duel, Location Gallery, Sprite Gallery, About This Build.

This hierarchy is intentionally expandable. Future campaigns will be added to the registry without bloating the first screen. When Blades is implemented it will have its own story/data/save namespaces, rather than inheriting Love Beyond's checkpoints.

## Visual design pass

- **Deep navy and translucent charcoal panels** to complement your title art.
- **Warm gold borders and headings**, icy-blue secondary text, warm-white primary text.
- **New button states:** default, gold hover, pressed, keyboard focus, and visibly disabled.
- **Right-positioned campaign panel** over the open storm-sky region of the title illustration.
- **Scrollable campaign menus** for shorter screen heights and smaller displays.
- **Dialogue panel and story command styling** updated to use the same fantasy interface treatment.
- Existing party, inventory, market, daily routine and optional battle menus use the shared new panel/button styling. No story text, combat balance or authored outcomes were rewritten.

## Technical overview

- `data/campaigns/registry.json` — one registry for campaign names, status, descriptions and namespaces.
- `scripts/prototype_story_v15.gd` — new root campaign selection, Love Beyond submenus, Blades disabled guard, UI style helpers and optional title-art fallback.
- `scenes/prototype_story_v15.tscn` — F5 entrypoint.
- `assets/paleverse/campaign_title.webp` — optional user-supplied asset, installed from the separate title-art pack; not committed to the text-only GitHub code updates.
- `tests/smoke_test.gd` — verifies title navigation, Blades unavailable/no save mutation, new menu structure, old systems reachable, part-six gates and correct Back destinations.

**Save compatibility:** unchanged. `campaigns.love_beyond` is still the only playable campaign save; `campaigns.blades` is not created.

## Quick playtest checklist

- On F5, the first screen reads **SELECT CAMPAIGN**, showing both named series; **Blades** says **COMING SOON** and is disabled.
- Select Love Beyond, then **BEGIN THE STORY**. The original intro remains intact.
- Open **ADVENTURE** and visit **PARTY** and **BACKPACK**, then back out. You should return to Adventure.
- After Part Six, open **CLIFFSIDE MARKET**, buy an item, and back out into Adventure.
- Open **PRACTICE & EXTRAS** to confirm the existing battle and art menus are still available.
- If the title screen shows old storm art instead of the supplied four-character illustration, check that `assets/paleverse/campaign_title.webp` is directly inside the Godot project root.
