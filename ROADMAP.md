# Pale Horseman RPG — Development Roadmap

## Prototype 023 — Technical foundation (in progress)

- Add staged local save writes, a last-good backup, corruption recovery, and downgrade protection.
- Test save persistence and compatibility without touching actual player saves.
- Audit and document installed art/portrait paths; consolidate optional art packaging for distribution.
- Gradually reduce deeply inherited prototype UI scripts **after** the matching UI regression tests exist. Do not replace the 22-prototype chain in one risky step.
- Confirm default F5 scene and GitHub CI remain healthy; manually playtest UI/saves on desktop.

## Prototype 024 — Hunger and survival (planned)

- Individual party hunger (0–100), including reserves; decrease at ordinary-day boundaries, never in story scenes.
- Proposed tiers: 80–100 +5% ATK/DEF; 50–79 neutral; 25–49 -5%; 1–24 -10%; 0 -15%.
- Hunting grants meat and EXP; food from markets, exploration and future farming/cooking.
- Keep hunger manageable, avoid unrecoverable starvation, preserve canonical battle outcomes.

## Prototype 025 — Data-driven exploration engine (planned)

- Random miniature scenarios based on location, POV, story state, rarity and history.
- Combat (including multi-wave camps), social events, emotional events, discoveries and everyday life.
- Progressive rewards per completed wave; retreat between waves retains earned rewards.
- Context-appropriate loot: a boar thief supplies lots of food, modest gold and medium EXP; a 2–3 wave bandit camp supplies big gold/EXP but little food.
- Expand Haniel's Observe the Town and other equivalent activities, accounting for her nonverbal communication and personality; keep Reflection distinct.
- Unique scenarios do not repeat; use explicit repeatability and cooldown rules.

## Prototype 026 — Exploration content (planned)

- Target ~30 authored events: 8 social, 5 emotional, 7 combat, 5 discoveries, 5 everyday-life.
- Examples: lost child reunited with mother; dying demon's last wish; boar thief; outlaw encampment.
- Character-specific resolutions for Asmodeus and Haniel. Some encounters reward only a meaningful story.

## Later

Improve enemy AI, move/status variety, combat VFX/audio, gardening/woodworking utility, more Love Beyond chapters, eventual browser/mobile polish, Blades campaign, crossover parties, What If? and optional Character Interaction Room.

## Project rules

Preserve existing saves, keep ordinary days separate from authored story advancement, test each incremental change, and respect canon even when a combat result differs.
