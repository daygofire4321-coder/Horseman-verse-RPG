# Prototype 014 — Cliffside Economy, Explore & Haniel Patrol

**Prototype 014** adds a playable economy and eight optional bandit/thug scenarios for the two lead characters. These additions are **story-gated after Part Six**, once Haniel has been able to participate in the Cliffside alley scenes. No new artwork is needed; bandits use sprite assets already in the project.

## Installation and playtest

1. In GitHub Desktop: **Fetch origin → Pull origin**.
2. Open the project in Godot 4.7.2, then press **F5**. The default scene is `scenes/prototype_story_v14.tscn`.
3. Complete the authored **Part Six**, or load an old save already marked `opening_parts_completed >= 6`.
4. On the scrollable title screen, select **CLIFFSIDE FREE TIME**. Choose either **Asmodeus — Explore** or **Haniel — Patrol**.
5. Each has **three limited activities per ordinary day**. Asmodeus's **Explore Cliffside** and Haniel's **Patrol the Streets** each cost one activity and start a randomized repeatable outlaw encounter. Winning grants the scenario's **gold range + EXP**, saved to the selected protagonist's progression.
6. You can **Retreat** without gold or EXP. Wounds carry over and battle food is really consumed. Win rewards are applied only once.
7. Open **VISIT THE MARKET** from the routine without spending a daily action, or **CLIFFSIDE MARKET** from the title screen. Choose the Provisioner or Outfitter to **buy**, or sell an unequipped backpack item at **50% of its catalog value** (rounded down).
8. Choose **AN ORDINARY DAY** to refresh all three daily activities without advancing the story. Swap POV between Asmodeus and Haniel at any time from the town routine; each person's free-time state is saved separately.

**Before Part Six**, the original forest interludes remain unchanged. Haniel is recovering then, so no premature Haniel combat patrols are offered. Market access is also locked. The original Joren and thug story fight remains scripted and unchanged.

## The eight encounters

| Character and action | Encounter | Enemies | Gold reward | EXP |
|---|---|---|---:|---:|
| Asmodeus — Explore | The Toll Nobody Authorized | Knife thug + club thug | 14–22 | 17 |
| Asmodeus — Explore | Roadside Shortcuts | Dagger bandit + club thug | 18–28 | 19 |
| Asmodeus — Explore | Wagon Held Hostage | Shielded bandit + dagger bandit | 27–40 | 26 |
| Asmodeus — Explore | The Outlaw Barricade | Heavy outlaw + veteran brigand | 54–76 | 39 |
| Haniel — Patrol | A Silent Warning | Knife thug | 8–15 | 12 |
| Haniel — Patrol | Market Street Extortion | Knife thug + club thug | 17–26 | 18 |
| Haniel — Patrol | The Missing Courier | Dagger bandit + shielded bandit | 28–42 | 28 |
| Haniel — Patrol | The Lantern Patrol | Veteran brigand + heavy outlaw | 52–74 | 38 |

These are repeatable side situations with different narrative openings, not new canon chapter events. All are non-lethal interventions where defeated outlaws flee, and they reuse the Cliffside alley, market, or forest clearing backdrops.

## Shops in Prototype 014

The market has two merchants: **Cliffside Provisioner** and **Market Outfitter**.

| Market | Item | Buying price | Selling price |
|---|---|---:|---:|
| Provisioner | Travel Rations (+20 HP) | 15 gold | 7 gold |
| Provisioner | Herbal Bread (+15 HP) | 12 gold | 6 gold |
| Outfitter | Leather Bracers (+4 Defense) | 45 gold | 22 gold |
| Outfitter | Iron Charm (+1 Defense, 2 flat mitigation) | 100 gold | 50 gold |
| Outfitter | Bowstring Wrap (+3 Attack, +2 Speed; Haniel only) | 85 gold | 42 gold |
| Outfitter | Black Ice Focus (+4 Attack; Asmodeus only) | 90 gold | 45 gold |

Alric's Reinforced Hammer Grip and **Friends and Family** shop discount remain **reserved for Prototype 015**; they are not available at the general market.

## Integration and save safety

- **Gold wallet:** `campaigns.love_beyond.economy.gold`, initialized to zero on old saves; the win counter is also additive.
- **Inventory:** purchases and sales use the existing `campaigns.love_beyond.inventory` shared backpack; buying requires sufficient gold; selling removes a backpack item and never equips/unequips it automatically.
- **Real battles:** Explore/Patrol creates a normal party combat engine with selected POV guaranteed in the active team (even if previously benched), up to two other saved party members, any unlocked reserves, their trained moves and equipped bonuses. Outcome HP is saved. If all active allies are defeated, the game returns the POV to 1 HP so you can recover.
- **Real battle food:** a successfully used item is immediately removed from the saved equipped slot, even if you retreat; it consumes that fighter's turn. The old optional **Party Battle Practice** still uses temporary copies and never changes saved supplies.
- **Day action cost:** the daily Explore/Patrol action is spent and saved **before** the fight; retreat/defeat cannot refund it. Each completed victory receives gold and EXP only once. Extra days are unlimited but gold awarded per encounter depends on its difficulty, not how many days passed.
- **Canon:** Optional town free time doesn't create, advance, or overwrite a story event checkpoint. Part Six completion is the only gate. Older forest scenes, story duels and authored outcomes remain unchanged.

## Implementation reference

- `data/encounters/cliffside_outlaws.json`: four authored situation entries for each protagonist, enemy compositions and reward ranges
- `data/characters/bandit_*.json`: actual repeatable enemy combat definitions
- `data/interludes/love_beyond.json`: post-six daily profiles with separate Asmodeus Explore and Haniel Patrol
- `data/battle_areas.json`: maps bandit sprites already included in the previous asset packs
- `data/shops/cliffside_market.json`: two merchants, stock and prices
- `scripts/core/economy_engine.gd`: wallet and transactions; always validates story gate and sufficient funds
- `scripts/core/inventory_engine.gd`: backpack add/remove and permanent food consumption for real encounters
- `scripts/prototype_story_v14.gd` / `scenes/prototype_story_v14.tscn`: title and town UI, market, patrol scenarios, combat resolution and state saving
- `tests/smoke_test.gd`: validates eight scenarios, market lock, currency and items, no double rewards, story-safe POV routines, real HP/EXP rewards, action cost, retreat, and permanent battle-food use.

**Next step:** Prototype 015 adds Alric's dedicated Smithy, character-specific weapon upgrades, and the agreed 20% discount while Alric occupies an active party slot.
