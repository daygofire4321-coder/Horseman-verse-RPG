# Prototype 020 — Rounded Daily Routine Dashboard

The daily routine interface was becoming crowded as the game gained training, party sheets, inventory, Cliffside, market, and the new homestead. This update is **presentation-only**: all original gameplay callbacks, action costs, disabled states, story checkpoints, and save data are kept.

## Install and playtest

1. **GitHub Desktop → Fetch origin → Pull origin**.
2. In Godot, press **F5**. The default scene is now `scenes/prototype_story_v20.tscn`.
3. Continue an existing early Forest Recovery or Playing House checkpoint, or enter **Love Beyond → Adventure → Cliffside Free Time** (Part Six) or **Cave Homestead** (Part Nine).
4. Try Rest, Training, market, swapping protagonists, and gardening/woodworking. All still perform the same original actions.
5. Use the vertical scrollbar on smaller windows. Activity cards become a **single column** under narrower viewport widths; desktop-sized windows show **two columns**.

**No image ZIP or new asset downloads are required.** All existing artwork, story content, portraits, and battle screens are preserved.

## Visual layout

- **Large rounded header** shows the active protagonist, daily routine name and location.
- **Six smaller status bubbles** show Day, remaining Actions, HP, Level, EXP, and Supplies.
- **Context-specific status cards** appear only where needed: gold/outlaw victories in Cliffside, gardening/woodworking sessions in the homestead.
- **Last activity** and **out-of-actions** messages are short, clearly separated cards rather than long text lines mixed into the actions.
- **Today's Activities** are large two-column rounded cards, each showing a distinct title, description, numbered accent badge and actual button. Color accents help group Rest, Train, Hunt, Gardening, Woodworking and other tasks.
- **Friends Helping Out** holds Toren and injured Joren's existing sprite rows at the homestead.
- **Manage & Travel** houses character sheets, inventory, market, character switch, bedtime, save, and the ordinary-day refresh option. These are separate from activities and retain their original navigation behavior.
- **Unavailable Wildlife Hunt** is still in the scene for compatibility, but visually hidden in Cliffside and Haniel's homestead routine. A disabled button otherwise stays disabled and cannot spend an action.

## How it works

The new `scripts/prototype_story_v20.gd` extends Prototype 019 and calls `super._draw_interlude()` first. The established routine renderer creates every functional control and connects it to the established methods. The new code **reparents those existing Buttons into rounded PanelContainers** and styles them; it does not create duplicate clickable actions or bypass the combat/save logic.

The daily scroll keeps its existing identity `DailyActivitiesScroll`, and all existing public control names (`Daily_action_rest`, `Daily_VisitMarket`, `Daily_Bedtime`, `Daily_NewOrdinaryDay`, etc.) remain unchanged. This preserves existing tests and makes future additions automatically appear in the right sections.

## Checks

`tests/smoke_test.gd` verifies:
- A valid Prototype 020 Godot scene and existing scroll container.
- Six distinct status cards and a two-column activity grid on desktop.
- Existing activity Buttons remain inside the new bubbles and spend exactly one action.
- Activity-result text appears in its own bubble.
- Cliffside wallet/market and character-switch buttons work, while irrelevant Hunting stays hidden.
- Homestead status, helpers, woodworking progression, and bedtime navigation remain functional.
- No story/dialogue, quests, item inventory, or save data formats have changed.

## Future refinements

Potential next UX steps: artwork-driven card icons, small animation on hover, and an optional compact-mode toggle. These are *not* part of this pass.
