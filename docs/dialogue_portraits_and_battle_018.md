# Prototype 018 — Speaking Portraits and Facing Battlefield

The author supplied a second `pngs(1).zip` containing **16 transparent, expression-named PNG portraits**. This update integrates all four characters' four expressions into dialogue and positions allies/enemies as opposing pixel battlers in non-boss team battles. It is a presentation pass; existing story, combat, saves, economy and chapter illustrations remain intact.

## Install

1. **GitHub Desktop → Fetch origin → Pull origin** (code changes).
2. Download **Paleverse_Dialogue_Portraits_018.zip** from the ChatGPT conversation.
3. Extract the ZIP directly into the **Horseman-verse-RPG Godot project root** (the same folder as `project.godot`). It must create `assets/love_beyond/dialogue_portraits/asmodeus/neutral.webp` and similar character folders.
4. In Godot, allow the imported WebP assets to update, then press **F5**. The default scene is `scenes/prototype_story_v18.tscn`.
5. Play Love Beyond story scenes, including the opening and Parts One–Six. The speaking portraits appear beside the existing dialogue panel; the supplied chapter-specific illustrations are still the backgrounds. The new portraits are optional: no ZIP means text and all gameplay continue normally.
6. For battle immersion, choose **Love Beyond → Practice & Extras → Three-Character Battle Practice** (or repeatable Cliffside encounters after Part Six). Enemy battlers now appear to the **left**, player battlers to the **right**, each oriented inward, with compact names and HP on their own sides. The HP status strip and Attack/Skills/Items/Guard/Switch dock remain functional.

## Portraits (names supplied by the author)

| Character | Folder | Four available expressions |
|---|---|---|
| Asmodeus | `asmodeus` (source folder `asmo`) | `mad`, `neutral`, `sad`, `smile` |
| Haniel | `haniel` | `mad`, `neutral`, `sad`, `smile` |
| Alric | `alric` | `angry`, `neutral`, `sad`, `smile` |
| Joren | `joren` | `mad`, `sheepish`, `smile`, `villainsmirk` |

The pack retains every distinct expression name; it does not invent a `neutral` image for Joren. His default is the supplied `sheepish`. The original transparent PNG files are not altered or deleted. The optional pack contains optimized transparent WebP versions (about 1.5 MB total).

## Dialogue behavior

- Two large transparent portraits occupy left/right sides of the backdrop, behind the existing dialogue box and buttons. Asmodeus and Haniel are the initial pair.
- The **current speaker is bright**. The other portrait dims but stays on screen. Narrator lines dim both.
- `HANIEL [SIGNING]` and `HANIEL [THOUGHT]` count as Haniel; the `BLOND YOUTH` is recognized as Joren without rewriting his authored introduction.
- On the relevant Part Six lines, Joren is introduced on the right, and Alric appears on the left when he first speaks. **They do not appear before their spoken introductions.**
- Selected dialogue events now optionally include `portrait_expression` metadata such as `smile`, `mad`, or `villainsmirk`. Other lines retain the last expression for that character. Chapter titles reset the expression state and cast, and the portrait scene can reconstruct its state when resuming or skipping dialogue.
- Future events can explicitly override screen composition with `portrait_left` and `portrait_right` values. If an image or expression is missing, the renderer falls back safely to that character's default or simply hides the missing visual.
- Portraits are hidden on menus, during battles, and during free-time management so they never cover the gameplay UI.

## Battle formation and UI

- **Enemies on the left**, facing toward the right. **Allied sprites on the right**, flipped horizontally to face the enemies. These are actual sprite visual nodes on a separate transparent battlefield stage over the existing landscape, rather than thumbnail portraits inside the HP cards.
- Character formations use small staggered vertical offsets; the acting ally has a gold outline, and KO sprites are dimmed.
- Enemy name/HP cards stack along the **left edge**, party name/HP cards along the **right edge**, with normal-enemy HP bars remaining compact. The three-party bottom strip shows each ally's HP and status.
- When choosing a skill or food target, diamond indicators appear over valid field battlers, while the existing target buttons remain clickable.
- **Boss/story fights remain unchanged** and continue using their authored HUDs and outcomes. Party practice and real Cliffside outlaw fights share the new formation UI; reward/HP/EXP logic isn't altered.

## Implementation files

- `data/portraits/love_beyond.json`: asset paths, character default expression, valid expressions, aliases and default on-screen sides.
- `data/chapters/love_beyond_opening_story.json`, `data/chapters/love_beyond_parts_4_6.json`: non-narrative `portrait_expression` metadata on selected spoken lines; **all original dialogue, chapter art and Part Six backgrounds are preserved**.
- `scripts/prototype_story_v18.gd`: layering, active/inactive portrait logic, story-state reconstruction, speaker aliases, side formations, HP chips and valid target markers.
- `scenes/prototype_story_v18.tscn`: main scene.
- `tests/smoke_test.gd`: tests aliases, 16-expression registry, Joren/Alric reveal timing, chapter scene reset, asset-safe fallback, inward flip directions, two-sided panels, target markers and unchanged saves.

## Future art polish

This pass doesn't add character attack animations or expression transitions. Later we can animate the existing sprite nodes (step forward, shake, damage numbers, black-ice effect, bow shot) without changing battle mechanics. You can also add more expressions by placing a similarly named image into a character's folder and adding its relative path to the portrait registry.
