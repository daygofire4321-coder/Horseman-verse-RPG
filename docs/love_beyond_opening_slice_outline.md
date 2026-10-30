# Love Beyond — Opening Story Slice (Parts 1–3)

**Status:** Design outline for approval; no scene/event code implemented by this document.
**Source:** Author-supplied text for Part One *Aftermath*, Part Two *The Natural Order*, and Part Three *To Be Preyed Upon*.
**Canon:** Character dialogue, motivations, and final beats should follow the author's text. No user-choice branch rewrites canon.

## Core gameplay contract

- The existing Haniel–Asmodeus thundercloud fight can serve as a short prologue/tutorial; **any result transitions to the cave** with both severely drained. There is no game-over blocker.
- Parts 1–2 are paced mostly as a visual novel. All essential moral discussions use the provided script, not invented choices.
- Part 3 is a real **Asmodeus versus grizzly bear** boss phase. Bear starts at 100% HP. On reducing it to **50% HP or below**, player input ends and a scripted rescue starts.
- If Asmodeus's HP is depleted **before the trigger**, skip failure/game-over and go to the **same scripted rescue**, depicting the bear overpowering him. Thus progress cannot dead-end on harder difficulties.
- The canonical ending is the same either way: Asmodeus is battered; Haniel fires the rescue arrow, Asmodeus comments on her height, Haniel rolls her eyes, Haniel fires a final headshot, the bear and Haniel collapse, and Asmodeus rushes to her.
- **The player does not kill the bear with Asmodeus**; 50% is an *event threshold* rather than the bear's canonical actual remaining life. Haniel delivers the fatal shot.
- This is a **story encounter** with narrative override; the existing quick-battle duel remains a free-form rematch with ordinary win/loss.

## Scene-by-scene outline

| ID | Scene | Story moments to preserve | Player activity / event | Tentative archive visuals |
| --- | --- | --- | --- | --- |
| P00 | Thundercloud prologue (optional story tutorial) | A costly evenly matched battle | Fight as Haniel or Asmodeus; any result fades to cave | `e1-16.png`, `e1-17.png`, `e1-18.png` (`old elements2(1).zip`) |
| E01 | Cave aftermath: exhaustion | Asmodeus coughing blood, joking that the angel fought well | Narration/character dialogue; no free roaming | Archive image `#083` (both seated in cave), `#005` cave lighting |
| E02 | Cave: discovering Haniel's silence | Haniel's signs; Asmodeus realizes she is mute; his history with signed conversations | Render signed dialogue with a clear `Haniel [signing]` indicator, but never voice her as spoken words | `#083`, `#091` |
| E03 | Cave: survival truce | Work together to survive or fight again; names exchanged; she traces *Haniel* in Enochian; both were sent on misleading missions | Linear dialogue, perhaps a continue-only prompt; cut at both leaning back against rock | `#083`, `#087`, `#091` |
| E04 | Forest: Haniel collects wood | Fallen branches; refuses to fell the living oak; pile on bare earth | Optional lightweight 'collect fallen branches' interaction (3 taps), or autoplay as CG | `#051` and `#069` woodpile / forest, `#062` Haniel outdoors |
| E05 | Forest: failed fire attempt | Attempts friction fire; sore wrists; admiration of nature; wonders whether Asmodeus abandoned her | Visual-novel narration + simple failed-fire animation; preserve internal monologue | `#051`, `#062` |
| E06 | Camp: boar argument | Asmodeus brings dead female boar; signs and discussion about necessary food, natural order, and moral responsibility | Full dialogue; cut to fire lighting as he raises his finger | `#056` campfire; `#073`, `#088` conversation reference; actual boar may require art |
| E07 | Camp: closing image | He cooks boar; Haniel is disgusted but notices the smell | Quiet closing CG; fade to next day | `#056`, `#088` |
| E08 | Forest hunt | Asmodeus stalking boar, sudden unexplained alarm | 2–4 dialogue panels, camera shift and audio cue | `#035` / `#003` forest Asmodeus |
| E09 | Bear ambush | Bear knocks Asmodeus into tree, blood, bravado and desperate dodging | Scripted opening hit / forced lower starting HP; launch boss | `#064` Asmodeus struck by bear, `#074` Asmodeus confronting bear |
| B01 | Asmodeus vs Bear: survival phase | Asmodeus is outmatched and must struggle | Standard turn UI; Black Ice, Attack, Guard; trigger rescue on bear HP ≤50% OR on Asmodeus defeat; don't display victory | `#074` bear vs Asmodeus; bear enemy illustrated crop or CG |
| E10 | Scripted rescue begins | Bear gains upper hand, raised paw; Asmodeus accepts defeat; first blue arrow strikes | Lock commands; transition to Haniel CG; no Haniel gameplay phase | `#066` Haniel shooting bear, `#004` bear confrontation |
| E11 | Rescue dialogue | Asmodeus sees Haniel; comments she is shorter than he thought; eye roll | VN dialogue and expression cue | `#066`, `#080` |
| E12 | Final arrow and collapse | Haniel's blue arrow strikes bear's head; both fall at once; Asmodeus kneels beside Haniel | Scripted impact, fade, end-of-slice/title card leading into next chapter | `#066`, `#080`, `#060` / `#065` caring-for-Haniel CGs |

## Proposed encounter state machine

```text
BEAR_AMBUSH
  -> ASMODEUS_VS_BEAR (bear 100% HP, injured Asmodeus)
  -> On bear <= 50% HP: RESCUE_LOCK
  -> On Asmodeus HP <= 0 before threshold: RESCUE_LOCK
RESCUE_LOCK
  -> scripted bear overpowers Asmodeus
  -> first divine arrow hits / Haniel appears
  -> short height joke + eye roll
  -> second divine arrow kills bear
  -> Haniel collapses; Asmodeus reaches her
  -> save Part Three completion
  -> NEXT_STORY_EVENT (to be supplied from Part Four)
```

## Design decisions

**Story vs combat resolution:** Bear HP is a *progress indicator* for the player; entering the rescue at 50% does not imply Asmodeus could have finished the beast in canon. Even after a skilled fight, the bear overwhelms his exhausted body. At 0 player HP, immediately trigger rescue, not defeat/retry.

**Difficulty:** Use difficulty to affect the challenge of reaching the 50% threshold, without allowing a premature bear kill or narrative derailment. Consider nonlethal limit: clamp bear HP to >= 50% until the transition. A tutorial hint might say `Hold on until help arrives` or `Push back the bear` — not `Kill the bear`.

**Interactivity:** Chapter one is mostly direct, faithful dialogue; second part can introduce a small optional branch-collection action; third is the first mandatory scripted story fight. No player dialogue options should break Haniel's compassion or Asmodeus's established view.

**Sign language:** Haniel's lines are readable as clearly marked [signing] dialogue, not voiced speech. The Enochian name-tracing can be indicated with authored symbols once the author approves a consistent glyph treatment; no need to invent characters.

**Visual content:** The ZIP images are composited illustrations (RGB/opaque), so use them primarily as full-screen story CGs and cutscenes. Portrait crops can be used in dialogue UI as needed; separate transparent sprites are not required for the initial milestone.

**Pacing and ending:** No mandatory gameplay during reflective paragraphs. End with the two simultaneous falls and Asmodeus rushing to Haniel; do not invent the next day's recovery or dialogue before receiving Part Four.

## Asset index keys

The IDs below refer to `Love_Beyond_Archive_Review.zip` > `assets_index.csv`. All examples `#003`–`#091` are in `old emelemts.zip`, while `e1-16.png` etc. are in `old elements2(1).zip`.

| Archive ID | What the contact-sheet thumbnail depicts | Candidate use |
| --- | --- | --- |
| `#005` | Deep shadowy cavern with a shaft of light | Cave tone / establishing |
| `#083` | Asmodeus and Haniel seated apart in a cavern | Part 1 base CG |
| `#091` | Asmodeus and Haniel in a dark cave | Part 1 alternate |
| `#051` | Haniel near fallen wood / woodland | Firewood scene |
| `#069` | Haniel beside a built branch pile | Firewood interaction |
| `#056` | Forest campfire with Haniel and Asmodeus | Part 2 debate |
| `#064` | Bear attacking Asmodeus in autumn forest | Ambush |
| `#074` | Bear facing Asmodeus | Battle CG / boss art source |
| `#066` | Haniel aims blue energy toward a bear | Rescue cutscene |
| `#080` | Characters near bear in forest | Post-rescue cutscene candidate |
| `#060`, `#065` | Asmodeus near exhausted / resting Haniel | End beat candidates (verify timeline fit) |

## Approval checklist before implementation

- The **bear at 50% HP** always hands off into the scripted Haniel rescue.
- The tutorial duel leads directly into the canonical cave aftermath, never back to a stand-alone results menu.
- Use the author's exact dialogue from Parts 1–3, edited only for in-game line breaks.
- Check whether any cropped/edited archive image mismatches its intended scene before adding it.
- Provide a simple chapter-progress transition hook, but leave Part Four blank until supplied.

## Next development implementation order (after outline approval)

1. Build event runner (`dialogue`, `narration`, `background`, `wait`, `battle`, `cutscene`, `transition`) with battle outcome callbacks.
2. Transcribe Parts 1–2 into scene entries, with speaker, sign-language and internal thought presentation.
3. Wire Part 3 bear fight with 50% threshold and 0-player-HP fallthrough to rescue.
4. Import compressed, verified archive CGs selected in the index above.
5. Playtest story chronology, transitions, mobile-landscape readability, and both bear encounter paths.

**Note:** This file records design decisions only; it does not claim the story content, bear encounter, or events are already playable.
