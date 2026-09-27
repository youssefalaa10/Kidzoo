# Adventure 3 — The Deep Blue — implementation report

**Date**: 2026-09-23 · **Branch**: `story-line` · **Baseline**: 444 tests passing
**Final**: **509 passing**, `flutter analyze` **0 errors**, Android debug APK builds.

---

## 1. What this chapter was allowed to cost

Phase 6b was written down as *"Adventures 3–4 — content only"*, and the plan's own risk table says
any code change here is a signal that Phases 1–3 were wrong. This chapter breaks that in two places
and it is worth being precise about which, because one of them is the interesting one.

| Change | Kind | Why it was not content |
|---|---|---|
| `engines/patterns/` + 1 line in `default_engines.dart` | **new engine** | `patterning` is a declared `LearningDomain` with nothing behind it. `sorting` judges category membership, which is the same verdict wherever an item is dropped; this judges *position in a sequence*, where the same shell is right in one hole and wrong in the next. No arrangement of bins expresses that. |
| `host/widgets/activity_stage.dart` + `presentation.stage` | **shared chrome** | "Every activity visibly changes the world" cannot be authored in JSON against boards that show one object, two boxes and a step counter. |
| `sorting` — `bins[].settleMotion`, visible accumulation | **rung 2, adapt** | Turns float/sink from a quiz about buoyancy into an experiment with it. |
| `trace_path` — `keepCompleted` | **rung 2, adapt** | Two figures that are one route have to end up on screen together. |
| `host/widgets/activity_feedback_scope.dart` | **shared chrome** | A rhythm ticked by the cubit while the board animates on its own clock drifts apart. |
| `background_resolver.dart:20` | one line | `ocean` resolved to `cloudy_bg_mob.png` — **a cloudy sky** — for the whole chapter. |

Nothing in `engines/` learned the word "ocean". Every one of the adaptations is domain-neutral and
content-driven, and the two shipped engines that gained a knob behave exactly as before for the
activities that do not set it (asserted, in `engines_test.dart`).

**Four of the six activities are zero Dart**: `hidden_clue`, `balance_experiment`, `counting` and —
with one new payload flag each — `sorting` and `trace_path`. Only the climax needed an engine.

---

## 2. The chapter

**The Deep Blue.** The Blue Page went over the reef edge into the trench, where there is no light.
**Sadaf** (صَدَف, "seashell"), a young sea turtle, saw it go and has never been down there.

| Node | Beat | Engine | Why the sea needs it | Skill |
|---|---|---|---|---|
| n1 | openingProblem | — | The page went over the edge; Sadaf saw it | — |
| n2 | discovery | `hidden_clue` | The storm buried the reef mouth | visual search under occlusion |
| n3 | obstacle | `sorting` | Sort salvage into what rides up and what stays down | classification on an unseen property |
| n4 | obstacle | `balance_experiment` | The float lifts only so much | composing a quantity |
| n5 | progress | — | The lift floats; below the reef there is no light | — |
| n6 | obstacle | `counting` (`giveN`) | String glow-weed on Sadaf's shell | cardinality |
| n7 | obstacle | `trace_path` | Draw the light down the trench wall, and the way home | controlled stroke |
| n8 | **climax** | **`patterns`** | The gate opens on the current's beat | patterning |
| n9 | resolution | — | Caught on the wall you lit: the Blue Page | — |
| n10 | clueOnward | — | On this page it is night | — |

**The chain is literal.** The floats you sort *become* the lift; the lift is the basket you load; the
light you gather is strung on Sadaf's shell; her light is what lets you see the wall to draw on; the
line you draw is what shows you the gate; the beat you read is what opens it. A test plays the whole
chapter and asserts every authored `revealLine` is actually spoken, in both locales.

**Six activities, not the Market's seven.** The Market's own report flagged its length as an untested
bet; attention at four to five runs eight to twelve minutes. Six lands inside that with the beats.

**Six different engines, none repeated inside the chapter**, and `multiple_choice` and `code_path`
are deliberately rested because Adventure 2 used both. A new test pins this for every chapter:
*"no chapter repeats an interaction inside itself"* — a failure that is invisible to every
per-activity test and would let seven activities be seven rounds of one game.

**The child resolves it.** Sadaf carries, but she cannot read the current and says so. Adventure 2's
climax is resolved by Dalia, an adult NPC; this one is not.

---

## 3. `patterns`, and why it earned a folder

**Capability key `patterning | dragToTarget`.** Unique against all seven — `sorting` is
`classification|…`, `balance_experiment` is `arithmetic|…` — so the registry's uniqueness assertion
passes with **no change to `LearningDomain` or `InteractionMode`**. Sharing an interaction with
`sorting` is the registry working as designed rather than a loophole: the key is the pair.

Pre-K repeating-pattern skill predicts fifth-grade mathematics after controlling for the rest of
early maths, reading and demographics. The app had no way to express it at all.

**One engine for both readings.** `extend` opens the end of the strip and can be answered by
carrying on; `fillGap` opens the middle and cannot. They share a unit, a repeat count and a list of
holes, and differ only in where the holes are — the same argument `trace_path` made for not
splitting tracing from connect-the-dots.

**Most of the engine is about the ways round reading the pattern.** Each of these is a route to a
right answer that teaches nothing, and each is a parse-time rejection:

- a unit with one distinct item (fill the hole by matching its neighbour)
- gaps that all fall on the same position in the unit (copy a fixed distance back, forever)
- a first gap that arrives before the `revealedRepeats` the activity promises (the scaffolding dial
  has to be *true*, not declared)
- an `extend` round that does not open the end (the mode as a label rather than a description)
- a tray with no spare tile — **`trayExtraCount ≥ 1`**, because without it the last hole of a round
  is answerable by elimination, and a child who does that has practised counting the tray

**The wave.** When the last hole is filled, every tile pulses in turn left to right with one soft
tick each, and on the final beat the reef gate parts. It is one `AnimationController` over
`Transform` and `Opacity` — no layout animation, no Lottie, no Rive.

**Deferred, with reasons**: `findUnit` (drag a bracket over the smallest repeating chunk — the real
5–6+ rung, but a second board and a second interaction); `translate` (the same pattern in claps,
which needs authored audio); and **`sequence_memory`** (`memory | orderSequence`), genuinely
uncovered and a natural fit here, but two new engines in one content chapter is exactly what the
plan's risk table warns about.

---

## 4. Making the world respond

Three of the six activities needed something the boards did not do. One general mechanism, two small
adaptations — not six special cases.

**`ActivityStage`.** A picture of *the thing being built*, filling and brightening as
`ActivityState.progress` rises, authored as `presentation.stage: { art, mode }`. It renders **inside
the prompt banner's row**, so it costs no vertical space — which is what lets it survive 780×390,
where the board has barely 200dp. Reusable by construction: a market cart, a jungle vine.

It is deliberately **optional**, and three of the six activities omit it. A scene being uncovered, a
line being drawn and a gate being opened already *are* the world changing; a stage on top of those
would be a second progress display saying the same thing twice. A content test asserts exactly that.

*Worth naming:* `KidTopBar` shows a step counter and a score — an abstract symbolic progress tracker,
which children of this age understand far less well than a direct depiction of the thing itself.
The stage is the diegetic version sitting next to it.

**`sorting` answers with physics.** Bins gain `settleMotion` (`rise` | `sink` | `settle`): a correct
placement travels that way into the bin, and a **misplaced** float drifts back *up* out of the sea
floor before returning to hand. The object tells the child what it is, which is something they can
use on the next piece; a buzzer tells them only that an adult disagreed. Sorted pieces also stay
visible in the bin, so the lift being built is on screen — carried on the step, not accumulated in
the board, so it survives a child leaving half way.

**`trace_path` keeps the route lit.** `keepCompleted` leaves each finished figure glowing while the
next is drawn, so the chapter's descent and its way home end up on screen as one thing. Off by
default: unrelated shapes in one box would pile up.

---

## 5. Content notes worth keeping

**The float/sink cast is cross-balanced against size in both directions.** Driftwood, a coconut and a
crate are big and float; a key and a coin are tiny and sink. "Big things sink" fails on the second
piece and "small things float" fails on the third, so neither rule is confirmed long enough to stick.
This is the Market's colour-balanced restocking trick applied to a new dimension.

Consequently **`heldConstant` is empty, deliberately**, and a `_comment` says why: size has to vary,
and vary *against* the answer. Claiming size as held constant would be a lie the validator catches.

**`giveN`, not `countAndPick`.** "How many are there?" can be answered by reciting over the objects;
"give her four" cannot. The supply always holds more than the answer, so "take everything" cannot
work. And the thing being filled is **Sadaf**, not a bowl — she brightens a step per round and stays
bright, so what the child made is carried by a character into the next activity rather than scored
and forgotten.

**The hidden-clue covers were solved, not eyeballed.** The engine asserts at least a quarter of the
clue stays uncovered at every board size; the first attempt buried the compass completely and the
assertion caught it. The offsets are the output of running that geometry across board widths from
140 to 1100, picking a layout that stays legal everywhere while each cover still sits within one
clue-size so it counts as lying over the page when the hint nudges it.

**The marker is a compass, not the page.** A chapter that opens by hunting the thing it closes by
finding has spent its ending in the first minute.

---

## 6. Assets

**Microsoft Fluent Emoji, MIT** — the licence file was fetched and read. `github.com` is unreachable
from this environment; `cdn.jsdelivr.net/gh/microsoft/fluentui-emoji@main/...` is not.

Eighteen items in `assets/gen/images/sea/`, each with a named job — nothing shipped because it was
available. Downscaled to 256px, alpha-trimmed, centred and quantised: **599 KB raw → 112 KB**, which
is less than one of the repo's existing fruit images (`apple.png` is 183 KB at ~500px).

Three files are custom: `story/page_blue.png` (built from `page_green.png` by hue-rotating in HSV so
the flat fills, the anti-aliasing and the grey drop shadow all stay exactly as the green and amber
pages have them, with a two-swell wave motif in place of the leaf), and `backgrounds/ocean_mob.png` +
`ocean_tab.png` — pale through the upper two thirds because that is where every board renders, with
the reef only at the bottom edge.

**Replaceable by design.** Every creature is referenced by path from `packs/tide_pool.json`, so
upgrading Sadaf to commissioned house-style art later is a one-line content edit. She uses one file
at every appearance — `speakerArt` on n1/n5/n9 and the n6 stage — so she reads as the same character.

**MIT requires the copyright notice to ship with the work.** No credits file was added, by request;
the cheapest compliant home is one line in the existing settings screen or the store listing.

*Not created by this work, but found by it:* the repo's existing PNGs carry no metadata and no
recorded source, and `animal/fish.png` shows faint repeated marks consistent with a stock-site
watermark. That deserves an audit of its own.

---

## 7. Tests

444 → **509** (+65). Two new files; five extended.

| File | What it adds |
|---|---|
| `patterns_engine_test.dart` *(new, 32)* | Every parse-time rejection, each pinned to the message so it fails on the rule it names rather than an earlier one; tray invariants; drag/tap parity; strip history; resume mid-round on the same seeded board; RTL unit order; the board at four sizes |
| `ocean_screenshot_test.dart` *(new, 7)* | Renders every Ocean board to `build/adventure_shots/` so "does it look like a reef ledge with holes in it?" has an answer without a device |
| `adventure_e2e_test.dart` | Adventure 3 end to end in both locales; all three chapters back to back; **no chapter repeats an interaction inside itself** |
| `content_validation_test.dart` | A `patterns` group (gaps in range, no copy-a-repeat-back round, no duplicate question, a spare tile always) and a `stage` group |
| `engines_test.dart` | `settleMotion`, visible accumulation, `keepCompleted` — and that activities which did not ask for them are unchanged |
| `story_continuity_test.dart` | The ocean is now **locked** rather than **comingSoon**; only the stars are still a silhouette |
| `boards_widget_test.dart` | Picked the new board up automatically |

**Two real bugs the existing tests caught before a human did**: the hidden-clue covers fully burying
the compass (the engine's own assertion), and the pattern ribbon overflowing 360dp by 45px — the
same failure the `code_path` tray had at exactly the same width, and for the same reason: a row is
not its tiles. It also spends width on padding, a border, the gaps and the gate.

---

## 8. Still needs a physical device

1. **The wave against real TTS.** Every test narrator resolves instantly, so the interleaving of the
   115ms beat with a spoken reveal line is a device judgement.
2. **Touch.** Dragging a tile into a hole on a small phone once the ribbon has wrapped to two rows,
   and whether the recess reads as a target under a finger.
3. **Haptics** on the pattern board.
4. **The generated art at real DPI** — `page_blue.png` beside the green and amber pages, and the
   ocean plates behind a board rather than in a screenshot.
5. **Whether the Fluent set reads as one family beside the hand-drawn fruit** in the reward book,
   where a sea creature and an apple can appear on the same screen.
6. **Session length.** Six activities is the correction to the Market's seven; worth timing with a
   real child rather than assuming.
