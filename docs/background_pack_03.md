# Background Pack 03 — Love Beyond environments

Seven backgrounds were supplied by the author as transparent or RGBA PNGs, each measuring **1672 × 941**. We converted **copies** to 1280 × 720, high-quality WebP images (~2.6 MB total) for easier downloading and fast Godot import. The originals were not modified.

## Install

1. In GitHub Desktop, **Fetch origin → Pull origin**.
2. Download `Paleverse_Love_Beyond_Backgrounds_Pack_03.zip` from this ChatGPT conversation.
3. Extract it at your repository root, beside `project.godot`. The ZIP has an `assets/` root; **do not extract it inside the existing `assets/` folder**.
4. Open Godot 4.7.2 and let it import the seven WebP files.
5. Press **F5**. On the title screen, select **VIEW SEVEN NEW LOCATIONS** and use **NEXT LOCATION** to page through.
6. Play the tutorial duel, hunt, the scripted bear fight, Cliffside alley, and daily camp routines to see the matching locations.

| Original upload | Installed path under `assets/love_beyond/pixel_battles/` | Use |
|---|---|---|
| `intro.png` | `thundercloud_battle.webp` | Asmodeus and Haniel prologue duel |
| `forest.png` | `forest_clearing_battle.webp` | Hunt / boar / wolf encounters |
| `deep forest.png` | `bear_forest_battle.webp` | Story bear encounter |
| `cliffside alley.png` | `cliffside_alley_battle.webp` | Two-wave Joren and thug fight |
| `cave.png` | `forest_camp_bg.webp` | Existing daily-life interludes |
| `market.png` | `market_street_bg.webp` | Location preview now; shop later |
| `smith.png` | `alric_smithy_bg.webp` | Location preview now; Alric equipment shop later |

## Implementation

- Area definitions live in `data/battle_areas.json`.
- The default scene is `scenes/prototype_story_v9.tscn`, which extends Prototype 008 and retains **Skip Dialogue**.
- `scripts/prototype_story_v9.gd` chooses the new WebP or an existing legacy PNG, with the old illustrated story art as a final fallback.
- The bear encounter is now routed to `bear_forest` rather than the ordinary `forest_clearing`.
- While in free-time mode, the cave/camp is used behind the daily-options panel.
- The title-screen location gallery previews all seven; market and smithy are **not yet implemented as shops**.
- The sprite pack remains separate. Keep existing character PNGs in `pixel_battles/`.
- No story text, save-file version, party members, leveling rules, inventory, discounts, or battle results were changed.

## Next systems

Planned: up-to-three-character party, Pokémon/Digimon-style stats, unique passive ability and up to four equipped moves, training points for unlocking abilities, three per-character item slots, one-use food, market inventory/currency after the Joren encounter, and Alric's smithy with a party-member discount. Those are not part of this art update.
