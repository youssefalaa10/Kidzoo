# Engine matrix — audit before Adventure 2

**Date**: 2026-09-20 · **Purpose**: decide, mechanically, what Adventure 2 may reuse and what genuinely
has to be built. Temporary working document; it exists to make the "new engine" decision arguable
rather than felt.

The question this answers is not "what games do we have". It is: **for each mechanic, is there an
existing engine whose `(learningDomains, interactionModes)` pair already covers it?** That pair is
the registry's uniqueness key, so it is also the only definition of "duplicate engine" the build can
check.

---

## 1. Reusable Adventure engines (the ones content can actually author against)

| Engine | Interaction | Domain | Capability key | Reusable | Themes it already serves | Verdict |
|---|---|---|---|---|---|---|
| `counting` | state a quantity | counting | `counting \| stateQuantity` | yes | any pack: animals, produce, stars, cargo | **Reuse.** `giveN` mode is an unused half of it — the Market recipe is exactly what it was built for |
| `sorting` | drag to target (tap alt.) | classification | `classification \| dragToTarget` | yes | any pack with an attribute: habitat, stall, material | **Reuse** |
| `multiple_choice` | choose one | vocabulary | `vocabulary \| chooseOne` | yes | authored questions, any pack | **Reuse** — also the right home for a social-choice beat, because errorless scaffolding means no punitive branch |
| `hidden_clue` | tap in scene | visual search | `visualSearch \| tapInScene` | yes | any scene: it already has content-authored props, movable covers and a named-shape ground | **Reuse + extend.** Its `ScenePropShape` enum is jungle-only; adding neutral furniture shapes is content-facing and costs no new engine |

**Nothing in this table covers**: programming a route, comparing weights, or producing a stroke. Those
are three different interaction modes, and two of them (`traceStroke`) already exist in the contract
with no consumer.

## 2. Free-play games in the catalog (24), as candidate mechanics

Grouped by what they would contribute, not by feature folder.

| Game | Interaction | Domain | Already covered by | Verdict |
|---|---|---|---|---|
| AnimalQuiz, Fruits, Vegetables, Vehicles, FlagGame, AnimalNameGame, MissingLetter | choose one | vocabulary | `multiple_choice` | **Leave alone.** All seven are the same mechanic with different art. Content, not engines |
| FruitVegSorter, FeedTheAnimal | drag to target | classification | `sorting` | **Leave alone** — `sorting` was ported from FruitVegSorter in Phase 3 |
| MemoryGame, ColorMemoryGame | choose one (paired) | memory | — | **Later, as an adapter.** Genuinely a different domain, but neither is needed by the Market, and both are playable in free play today |
| Puzzle | drag to target | spatial | `sorting`-adjacent | **Leave alone.** Piece count is a property of the bundled image; generalising the slicer is real work with no story asking for it |
| MazeGame | continuous steering | spatial | — | **Do not convert.** Real-time steering is not a mechanic a 3–5 year old succeeds at on a first try, and `code_path` covers the *thinking* part of navigation far better |
| DrawLab | free stroke | expression | — | **Leave alone, but note it.** 2 000 lines of freehand canvas with no target, no tolerance and no accuracy scoring. It proves stroke capture works on this codebase; it is not a tracing engine and could not become one without being rewritten |
| DotsAndBoxes | tap an edge | strategy (2P) | — | **Leave alone.** Despite the name, it is competitive territory capture, not connect-the-dots |
| Shapes, Numbers, Alphabets | browse | exposure | — | Reference content, not activities |
| Game2048, FlappyBird, PaddleBounce, ColorSwitch, TicTacToe, WorldMap | arcade / strategy | — | — | **Leave alone.** No story reason, and reflex games sit badly inside a narrative beat |
| MathGame | state a quantity | arithmetic | `counting` partially | **Later.** Symbolic arithmetic is past this age band; the Market uses weight comparison instead, which is the concrete precursor |

## 3. Crowding check — did anything duplicate?

Running every proposed Market mechanic against the registry's key:

| Proposed | Key it would claim | Collides with | Outcome |
|---|---|---|---|
| Detective / find the list | `visualSearch \| tapInScene` | `hidden_clue` | **Content only** |
| Restocking | `classification \| dragToTarget` | `sorting` | **Content only** |
| Recipe / fruit bowl | `counting \| stateQuantity` | `counting` (`giveN`) | **Content only** |
| Social choice | `vocabulary \| chooseOne` | `multiple_choice` | **Content only** |
| Code the cart | `spatialReasoning \| orderSequence` | nothing | **New engine** |
| Balance scale | `arithmetic \| dragToTarget` | nothing (`sorting` is `classification`) | **New engine** |
| Trace / connect dots | `spatialReasoning \| traceStroke` | nothing | **New engine** |

Four of seven Market activities are reachable with **zero Dart**. That ratio is the check on whether
Phases 1–3 were right, and it passed.

## 4. The three new engines, and why each earned its place

Each had to clear the same three tests the Adventure itself is held to: enjoyable with the
educational label removed, a meaningfully different skill from its neighbours, and plausibly reusable
in **five** themes.

### `code_path` — `spatialReasoning | orderSequence`
The only mechanic in the app where the child commits to a plan *before* seeing it run. Everything
else is immediate-feedback tapping. That gap — predict, run, watch, revise — is the whole of early
computational thinking, and no amount of content on top of `sorting` produces it.

Five themes: market delivery · jungle, guiding an animal home · ocean, steering a turtle · space, a
rover · city, routing a vehicle.

### `balance_experiment` — `arithmetic | dragToTarget`
Shares an interaction with `sorting` and nothing else: sorting judges *where* a thing went, this
judges *how much* is there, and the beam gives continuous physical feedback before any answer is
committed. It is the only activity in the app the child can experiment inside — add, watch, remove,
watch — rather than being asked a question first.

Five themes: market, weighing produce · jungle, choosing materials · ocean, sink and float · space,
balancing cargo · workshop, comparing objects.

### `trace_path` — `spatialReasoning | traceStroke`
`StrokeAttempt` has been on the contract since Phase 1 **with no consumer**, reserved for exactly
this. Fine-motor control is the one domain Adventure Mode has never exercised.

Deliberately broader than letter tracing, and one engine rather than two: connect-the-dots and
continuous tracing share the same state (an ordered list of points, a cursor, a tolerance) and differ
only in whether the points are shown and whether the gesture between them is scored. Splitting them
would have produced two engines with one model.

Five themes: market sign repair · jungle trail · ocean current · constellation · workshop blueprint —
plus numerals and shapes anywhere.

**Explicitly not made bilingual by assertion.** The engine has no glyph content at all; it takes
authored point lists. Arabic letterforms, when they exist, arrive as content files, not as a change
here. The Market's first use is a language-neutral symbol for that reason.

## 5. Deferred, with the reason recorded

| Candidate | Why not now |
|---|---|
| Rhythm / echo | Needs authored audio per beat; none exists, and TTS cannot carry rhythm |
| Aim / physics | A reflex mechanic inside a narrative beat fights the no-fail rule |
| Build / repair (assembly) | Overlaps `sorting`'s interaction closely enough that it needs a story that proves it does not. Revisit for the Workshop |
| Memory pairs (adapter) | Real, but no Market beat needs it, and it is already playable in free play |
