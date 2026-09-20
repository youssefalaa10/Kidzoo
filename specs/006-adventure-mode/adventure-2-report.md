# Adventure 2 + durable resume — implementation report

**Date**: 2026-09-20 · **Branch**: `story-line` · **Baseline**: 345 tests passing
**Final**: **444 passing**, `flutter analyze` **0 errors**, Android debug APK builds.

---

## 1. Repo findings

Checked against the code, not the docs.

| Finding | Consequence |
|---|---|
| Node-level resume **already worked**; `saveResumePoint` was written on entering every node | The reported restart was not "nothing is saved" — it was three narrower bugs, below |
| Nothing at all was stored *inside* an activity | A six-round mini-game left half-way restarted at round one |
| `Random(DateTime.now().millisecondsSinceEpoch)` per activity | Even a correct step index would have restored into a differently shuffled board |
| `grantReward` was idempotent in the table; the **celebration** was not | Closing the app on the resolution beat replayed the page flight on every return |
| `giveN` in the `counting` schema since Phase 2, with **no board behind it** | An author could ask for the harder question and silently get the easier one |
| `StrokeAttempt` reserved in Phase 1, still no consumer | Phase 1's bet was right: it needed no contract change to use |
| `ScenePropShape` was jungle-only (leaf, frond, bush, rock, grass, log, flower) | A second scene needed furniture, but as an extension, not a new engine |
| `QuizEngineScreen` still exists, still never instantiated | Untouched; the host/board split is the working replacement |

## 2. Engine matrix conclusions

Full matrix: [engine-matrix.md](./engine-matrix.md). The decision rule was mechanical — run each
proposed mechanic against the registry's `(learningDomains, interactionModes)` key, which is the only
definition of "duplicate engine" the build can check.

| Proposed Market mechanic | Collides with | Outcome |
|---|---|---|
| Detective / find the list | `hidden_clue` | **content only** |
| Restocking the stalls | `sorting` | **content only** |
| Recipe / fruit bowl | `counting` (`giveN`) | **content only** |
| Social choice | `multiple_choice` | **content only** |
| Code the cart | nothing | **new engine** |
| Balance scale | nothing (`sorting` is `classification`) | **new engine** |
| Trace / connect the dots | nothing | **new engine** |

Four of seven activities are zero Dart. Of the 24 free-play games, **none** were converted: seven are
`multiple_choice` in different art, two are `sorting`, and the rest (arcade, two-player, free drawing)
have no story reason. DrawLab is 2 000 lines of freehand canvas with no target and no tolerance — it
proves stroke capture works here, and is not a tracing engine.

## 3. Resume root cause

Reproduced all three **before** changing anything:

1. **Replay in progress restarted.** `markChapterCompleted` set `isCompleted` and it outlived the run.
   `start()` then forced `_index = 0` for *any* completed chapter, so a child who had finished a story
   once lost all progress on every re-entry. `left at jungle.n3, resumed at jungle.n1`.
2. **A renamed node restarted.** `indexOfNode` returns `-1` for an id content no longer has, and `-1`
   fell through to `0`. This would have fired for every child on the next content release — including
   this one.
3. **The page re-celebrated.** `justEarnedRewardId` was set on *reaching* the reward node rather than
   on *earning* the page.

Plus the gap underneath all three: **no activity-level state existed**, so requirement 3 (restore the
step) had nothing to restore from.

## 4. Resume implementation

**One cursor.** `StoryResumePoint` carries profile, adventure, node, beat, an optional
`ActivityCheckpoint` (activity, engine, engine schema version, step index, **seed**, score,
independent steps, hints, elapsed, optional engine payload, cursor version) and a timestamp. Logical
progress only — no frames, no drag offsets, no playback positions.

**Persistence**: Drift **v4**, pure-add, two nullable columns on the chapter row the resume point
already lived on — `currentBeat` and `activityCheckpoint` (versioned JSON). One opaque column rather
than nine typed ones because the contents are a cursor *format*, not a schema the database has
opinions about, and its whole lifetime is "until this child finishes this mini-game".

**Written as progress happens**, never on the way out: the resume point on entering every node, the
activity cursor at every step boundary *and* on arrival. Lifecycle callbacks flush too, and are
documented as secondary — an app the OS kills never reaches one, and the cold-start test proves the
point by closing the database with no flush at all.

**The rules are one pure function.** `StoryResumeResolver` — finished-with-no-live-node restarts,
finished-with-a-live-node resumes, a stored node resolves to its index, an unknown node falls back to
the first unfinished node in the stored *beat*. Each branch is a test rather than a condition tangled
into an async method that also does I/O.

**Exactness comes from the seed.** It is chosen once, persisted, and `Random` is rebuilt from it on
resume, so "step three" means the same step three. A mismatch — different seed, different activity,
different engine, bumped engine schema, newer cursor version, or an index the content no longer has —
yields **no** checkpoint: the child replays one mini-game and keeps the story (requirement 10).

**No double credit.** `grantReward` now reports whether it granted, so the celebration fires once;
`saveNodeResult` upserts on `(profileId, nodeId)`; a finished activity clears its cursor so a later
replay starts fresh, while an abandoned one keeps it.

**No stale callbacks.** `continueStory` / `completeActivity` take `fromNodeId`; a narration future or
a late pop carrying the old node is ignored rather than advancing a beat the child never saw.

**No dialog.** Opening a bead resumes. The map now says *Continue* for a replay in progress too,
which it did not before — it said "Again", and then restarted.

## 5. Market story structure

**The Market Morning** — the market cannot open, and every activity is a piece of getting it open.

| Node | Beat | Engine | Why the market needs it | Skill |
|---|---|---|---|---|
| n1 | openingProblem | — | Dawn. Dalia has to open at the bell; she cannot open it like this | — |
| n2 | discovery | `hidden_clue` | The wind took her order list | observation, vocabulary |
| n3 | obstacle | `sorting` | The list says which stall each thing goes on | classification |
| n4 | obstacle | `balance_experiment` | Each order has a weight beside it | comparison, early maths |
| n5 | progress | — | Stalls full, baskets weighed, cart loaded — but the lanes are narrow | — |
| n6 | obstacle | `code_path` | The cart only goes where it is told | sequencing, planning |
| n7 | obstacle | `counting` (`giveN`) | The first customer's bowl needs *exactly* that many | cardinality, practical life |
| n8 | obstacle | `multiple_choice` | Someone at the far stall needs something, unnoticed | SEL, everyday reasoning |
| n9 | **climax** | `trace_path` | The wind broke the sign's line, and the bell waits for it | fine motor, spatial |
| n10 | resolution | — | The bell rings; folded inside the sign's frame, the Amber Page | — |
| n11 | clueOnward | — | On this page: deep, cold, very blue water | — |

Each activity's outcome is **spoken** and the next beat depends on it — the list tells you what to
restock, restocking fills the baskets the scale weighs, the weighed baskets are what the cart carries,
the cart arriving lets Dalia make the first bowl. A test asserts every authored reveal line is
actually said in a full run, in both locales.

Seven activities is long, and that is a consequence of §4 rather than a separate decision: before
durable resume, a chapter this length was unfinishable for the age it is written for.

## 6. Reused engines (zero Dart)

`hidden_clue` · `sorting` · `multiple_choice` · `counting`. New content only: one pack
(`market_goods`, 11 items carrying `stall` / `weight` / `size` / `colour`), seven activity files, one
adventure file, one arc edit.

Two content notes worth keeping: the sorting cast is **colour-balanced** — red and orange each appear
once on each stall — so a child who sorts by colour gets half right and finds out quickly that colour
is not the rule; and the order list is drawn cold white with grey ruling precisely so it is never
mistaken for the warm amber page.

## 7. New engines, and why each deserved to exist

Each had to clear three tests: fun with the educational label removed, a meaningfully different skill
from its neighbours, and plausibly reusable in five themes.

**`code_path`** — `spatialReasoning | orderSequence`. The only mechanic in the app where the child
commits to a whole plan before seeing any of it run. The cart drives the program in full — including a
wrong one — *before* anything is judged, because watching what your plan did is the lesson. Any
arriving program is correct, including a wandering one; there is no shortest-route bonus. Absolute
arrows and relative turns are both simulated, so the harder command set is a one-word content change.
*Market · jungle · ocean · space · city.*

**`balance_experiment`** — `arithmetic | dragToTarget`. The only activity a child can act inside
before answering: add, watch the beam, take it back, as often as they like. Only handing the basket
over is judged, and that control works whatever the scale says — a child who hands over the wrong
basket should be answered by the seller, not by a button that quietly refused to be pressed. Weights
live on the pack so an orange weighs two everywhere.
*Market · jungle · ocean · space · workshop.*

**`trace_path`** — `spatialReasoning | traceStroke`. The first consumer of `StrokeAttempt`, reserved
in Phase 1 with none. **One** engine for tracing and connect-the-dots, because they share the same
state — an ordered anchor list, a cursor, a tolerance — and differ only in two flags. Drag and tap are
both first-class. Language-neutral on purpose: it holds no glyph content, so Arabic letterforms will
arrive as content rather than as a code change.
*Market · jungle · ocean · constellation · workshop, plus numerals and shapes anywhere.*

**Extensions, not engines**: `counting`'s `giveN` board (the mode existed with nothing behind it), and
five neutral furniture shapes on the shared prop set — `crate`, `basket`, `awning`, `barrel`, `sign`,
named for what they are so a harbour or a cargo bay can use them without extending the enum again.

## 8. Tests added

345 → **444** (+99). Two new files, five extended; `engines_test` and `adventure_polish_test` were touched by the linter only.

| File | Tests | What it covers |
|---|---|---|
| `story_resume_test.dart` *(new)* | 41 | Every requirement in Goal 1, each mapped to a reproduced bug |
| `new_engines_test.dart` *(new)* | 39 | The three engines plus `giveN`, incl. two widget tests |
| `adventure_e2e_test.dart` | 28 | Adventure 2 played end to end in both locales; both chapters back to back |
| `content_validation_test.dart` | 50 | Picked up all 7 new activity files automatically |
| `boards_widget_test.dart` | 16 | Picked up the new boards automatically; tablet landscape added |
| `story_continuity_test.dart` | 7 | Unlock rule, and bead labels matching what opening does |
| `story_dao_test.dart` | 16 | v4 columns nullable; a legacy row survives them |

Covering the requested list explicitly: leave during a beat → same beat ✓ · leave after an activity →
next incomplete node ✓ · leave mid-activity → same step, same board ✓ · **real** cold start over a
file-backed database, closed with no flush ✓ · repeated resume → no duplicate reward ✓ or score ✓ ·
separate profiles ✓ (point, page and checkpoint) · rotation ✓ · stale snapshot → current activity
restarts, six ways ✓ · superseded narration cannot advance restored state ✓. Plus the three bugs not
on the list: replay-in-progress ✓, renamed node ✓, and back-out-then-straight-back-in ✓ — the
commonest interruption of all, which the cursor survived a cold start but not, until late in the
work, a re-entry.

## 9. Final counts

- **`flutter test`**: 444 passing, 0 failing.
- **`flutter analyze`**: 0 errors; 2 warnings, both pre-existing and in files this work did not touch
  (`DrawLab/canvas_screen.dart`, `home/widgets/options_sections.dart`); 103 style infos.
- **`flutter build apk --debug`**: succeeds.
- Layout verified at 360×640, 780×390, 800×1200 and 1200×800 for every board, every activity, in
  both locales — which caught three real overflows (`code_path` tray 202px at 360dp; balance pans in
  phone landscape; `StoryBeatView` 3.2px at 800×400, now side-by-side when wide and short).

## 10. Still needs a physical device

1. **The v3 → v4 migration over a real installed database.** The columns are asserted nullable and a
   legacy row is asserted to survive them, but an in-memory database is created at the current version
   and never migrates. Upgrade an existing install and confirm a story in progress survives.
   *Highest-risk item here.*
2. **Real narration timing.** Every test uses a narrator that resolves instantly. The gating fix is
   preserved and tested, but the feel of `code_path`'s 520ms playback and `trace_path`'s 1.6s
   demonstration against real TTS is a device judgement.
3. **Touch.** `trace_path`'s pan gesture and its 14% tolerance, and whether `code_path`'s tray targets
   are comfortable on a small phone once they wrap to two rows.
4. **Haptics** on the new boards.
5. **The two generated images** (`page_amber.png`, `order_list.png`) at real DPI beside the hand-drawn
   art. They are hue-mapped from `page_green.png` with new motifs drawn in, so they are consistent by
   construction, but they have only been seen at 512px.
6. **Session length.** Seven activities is a deliberate bet on resume. Worth watching whether children
   actually come back, rather than assuming they can.
