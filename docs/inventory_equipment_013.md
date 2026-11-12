# Prototype 013 — Inventory & Equipment

This build adds the first fully interactive inventory layer to *Love Beyond*: one shared backpack, three readied/equipped slots per character, real gear stat bonuses, enchanted item effects, and single-use food. It keeps the original story, party management, move training and optional three-person combat intact.

## Installation / playtest

1. In GitHub Desktop, choose **Fetch origin → Pull origin**.
2. Open the project in Godot 4.7.2 and press **F5**. The default scene is now `scenes/prototype_story_v13.tscn`.
3. Scroll down the title screen to **INVENTORY & EQUIPMENT**. The first visit grants and saves a one-time starter kit, even on old save files. The kit is **not** awarded again on reopening.
4. Select Asmodeus or Haniel, then select an **EMPTY** item slot. Choose an item from the shared backpack. For example, equip Asmodeus with *Black Ice Focus* and *Iron Charm*, and Haniel with *Bowstring Wrap*.
5. Open **PARTY & CHARACTER SHEETS** to view each character's equipped gear and effective stats. You can open **MANAGE [CHARACTER]'S ITEMS** from the sheet itself. You can also reach the inventory from an ordinary-day camp without spending a daily activity.
6. To test healing food, take some damage while hunting and return to camp. Equip **Travel Rations** or **Herbal Bread** in an empty slot, select that slot and choose **EAT NOW**. The character's HP increases, the food disappears permanently, and the interlude HP stays synchronized.
7. To test food in the **non-canon Party Battle Practice**, equip food before entering. On the food holder's turn, choose **USE FOOD**, select the item and a wounded ally. It consumes the fighter's turn and disappears *in that battle only*. Returning to the title shows the saved food is still there, because practice battles are reward-free and don't permanently consume inventory.

## Starter backpack

| Item | Category | Effect | Restrictions |
|---|---|---|---|
| Black Ice Focus ×1 | Equipment | +4 Attack | Asmodeus |
| Bowstring Wrap ×1 | Equipment | +3 Attack, +2 Speed | Haniel |
| Leather Bracers ×1 | Equipment | +4 Defense | Any unlocked member |
| Iron Charm ×1 | Equipment | +1 Defense; reduce each enemy attack by 2 HP in party practice battles | Any unlocked member |
| Travel Rations ×3 | Food | Restore 20 HP; consumed on use | Any unlocked member |
| Herbal Bread ×2 | Food | Restore 15 HP; consumed on use | Any unlocked member |

The catalog also defines **Reinforced Hammer Grip** for Alric (+3 Attack, +1 Defense) but it is **not in the starter backpack**. It is reserved for a later shop/loot unlock.

## Rules

- The party shares one **stackable backpack**, while each unlocked character has exactly **three slots**. Weapons/armor/accessories and food compete for those slots.
- Equipping removes one backpack copy. Unequipping restores exactly one. Changing to an occupied slot requires unequipping first.
- Restrictions prevent wrong-character gear (for example, Haniel cannot use Asmodeus's Black Ice Focus) and stop equipment from being assigned to locked party members.
- Eating food is valid only for a living, wounded character. Food is not wasted at full HP and cannot revive KO'd allies.
- Camp food restores the active interlude's HP and saves it; other characters' saved progression is updated separately. Food and inventory management do **not** consume a daily activity.
- Equipped bonuses apply to the character sheet and **optional party-practice combat**. Existing canon story battles still use their previously authored scripts and outcomes.
- Equipped Iron Charm provides flat damage mitigation in party practice, and defending still reduces the remaining damage as usual.
- A practice battle snapshots equipped food into temporary combat state, including for reserves. Using food there costs a turn but cannot consume the persistent saved inventory or affect campaign EXP, HP, training, story checkpoints or inventory.
- The only initial source of items is the one-time starter kit. **Gold, shops, purchases, selling and repeatable battle rewards are not implemented yet.**

## Developer files

- `data/items/love_beyond.json`: editable catalog, starter inventory, character compatibility, item bonuses, restorative food and future values.
- `scripts/core/inventory_engine.gd`: one-time starter grant, backpack stack counts, three slots, equipping, unequipping, consumption, stats, additive version-1 save integration.
- `scripts/core/party_engine.gd`: character sheets now include equipment totals and prepared items.
- `scripts/core/party_battle_engine.gd`: absorbs protective wards and provides temporary combat food actions with ally targeting.
- `scripts/prototype_story_v13.gd` and `scenes/prototype_story_v13.tscn`: title/camp/sheet entrypoints, backpack UI, per-character slots, eating, battle food menus, safe returns.
- `tests/smoke_test.gd`: validates starter kit awarded exactly once, character restrictions, three-slot limits, gear stat bonuses, ward mitigation, one-use food, shared backpack transfers, save continuity, camp HP sync, battle-use targeting and no permanent practice consumption.

**Save compatibility:** The save schema remains version 1. The new `campaigns.love_beyond.inventory` dictionary is optional and additive; saves without it receive one starter kit at first inventory visit. Existing party composition, EXP, chapter completion, story checkpoints and training are not replaced.

## Next

**Prototype 014:** Coins, market inventories, buying/selling, earned rewards, appropriate unlock after the Joren alley encounter; then **Prototype 015:** Alric's Smithy and his *Friends and Family* 20% discount when he is in the active party.
