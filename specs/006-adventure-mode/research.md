# Research: Kidzo Adventures

Why the design is shaped the way it is. Each section is a decision that was contested, with the evidence that settled it.

---

## 1. Why six engines, not ten

The nine mechanics originally requested (`counting`, `sorting`, `drag_drop`, `patterns`, `logic`, `multiple_choice`, `hidden_clue`, `problem_solving`, `matching`) collapse onto **six engines**, because `sorting`, `drag_drop`, `patterns` and `logic` all crowd the same interaction mode — drag-to-target with a judged placement. Building four near-identical engines is how a solo developer drowns.

The registry test makes this mechanical rather than a matter of discipline: **no two `reusable` engines may share the same `(learningDomains, interactionModes)` pair**, failing with *"duplicate capability — extend `counting` with content instead."*

Promote a mechanic to its own engine when content demonstrably cannot express it — not before.

---

## 2. The `quiz_engine_screen` post-mortem

`lib/features/QuizEngine/ui/quiz_engine_screen.dart` exists and is **never instantiated**. This is the single most instructive failure in the codebase, and the engine layer is designed around not repeating it.

It is a fully closed layout with zero extension points: hard-coded `Scaffold`, `AppBar('Quiz')` with an English literal, `Color(0xfffaf5f1)`, plain `ElevatedButton`. No `KidGameShell`, no `KidMetrics`, no `KidResultView`, no haptics, no confetti.

Its one real consumer, `vehicles_game_screen.dart`, needed per-question scene composition, sound effects and a result view. So it wrote ~280 lines of its own layout over `QuizCubit` and ignored the screen entirely.

> **The boundary was drawn in the wrong place.** The Cubit — state machine and scoring — *was* reused. The Screen was not, because it tried to share the **board** instead of the **chrome**.

Hence the inversion: `ActivityHostScreen` owns *all* chrome and every engine supplies only the interactive middle. Grep tests over `engines/**` forbid `Scaffold`, `AppBar`, `MediaQuery.of`, `Color(0x` literals and `import app_localizations.dart`, so an engine **cannot** grow its own screen.

**Second cause, equally important:** `QuizCubit` takes already-localized strings, so authoring happens in Dart. Once you are writing a Dart file anyway, writing a layout is a small increment. **Content-in-Dart is what makes bespoke screens cheap.** Hence inline `LocalizedText` in JSON rather than keys into `app_localizations`.

---

## 3. Why inline `LocalizedText`, not localization getters

`app_localizations.dart` is 860 lines with ~700 hand-written getters, each of the form `_localizedValues['key']!` — a **throwing** lookup. Adding a story string today costs three edits (both JSON files plus a getter) with no tooling to catch drift; `en.json` and `ar.json` already differ by one line.

Hundreds of narration strings cannot go through that. So content carries its own per-locale text inline, and `AppLocalizations` gains one **non-throwing** helper for content keys:

```dart
String resolve(String key, {String? fallback}) => _localizedValues[key] ?? fallback ?? key;
```

The deliberate difference from the 567 existing getters: `resolve` does not throw, **because content keys are data, not code**.

This is not hypothetical. `en.json` lacks `freehandModeEnabled` and `straightLineModeEnabled`, yet `drawlab_screen.dart:1572-1573` calls those getters — **toggling DrawLab's line mode in English crashes today.** Fixed in Phase 0 (T002), and it is exactly the failure mode non-throwing content lookup prevents.

---

## 4. Pedagogical constraints that bind the contract

Three rules recur across every mechanic, so they are architectural rather than per-engine.

**Errorless first exposure.** Wrong answers quietly return; explicit right/wrong is reserved for mastery levels. Terrace (1963) showed that structuring acquisition so the learner rarely errs produces faster, more extinction-resistant learning. Sago Mini has no points, no levels, no Game Over, no wrong state at all; Busy Shapes makes the wrong answer *geometrically impossible*.

> This turns the difficulty model inside out. Early content shows only one plausible target, so a wrong drop is nearly impossible; later content widens the choice set. **`distractorCount` *is* Terrace's fading procedure expressed as data** — which is why it stays a cross-cutting `support` field rather than an engine-native parameter.

**Tap-to-select is first-class, not a fallback.** The motor data is decisive: drag succeeds ~73% at age 3 and ~89% over 5, but in a 7–8-year-old study **drag-and-drop succeeded only 30% of the time** against 83% for tap. WCAG 2.2 SC 2.5.7 (*Dragging Movements*) now **requires** a single-pointer alternative to every drag. So `allowTapToSelect` lives on the base contract, defaulted on — an engine cannot opt out, and a widget test asserts every board is completable by tap alone.

**Audio-first.** Every prompt is an audio key; text is decoration. If a preschooler taps and nothing happens, they assume it is broken.

**A concrete finding against existing code:** `KidUi.minTouch = 76`. NN/g's guidance for young children is **2cm × 2cm — roughly 96–120dp**, four times the adult minimum, and children aged 7–10 miss 7mm targets ~30% of the time. Hence `KidUi.minTouchYoung` (~112) for primary interactive targets in engines; `minTouch` stays for chrome.

### Per-engine specifics that are data, not code

- **Counting.** Gelman & Gallistel's one-to-one principle forces a **visible counted-state change** on every tagged item — without it children double-count. Arrangement difficulty is ordered and fMRI-backed: **dice → ten-frame → linear → scattered cluster → random**. Count-first-then-state-the-total beats stating the total first. **Never overlay dots on a numeral glyph** — children touch-count the decoration instead of subitizing. `give-N` (produce N) is strictly harder than "how many?" and is the real cardinality test.
- **Number paths.** Ramani & Siegler (2008): ~1 hour on a **linear, numbered** 1–10 board improved magnitude, estimation, counting and numeral ID with gains at 9 weeks; a colour-only board improved **nothing**, and a follow-up found **circular boards did not work**. If a counting activity uses a number path it must be straight, numbered and narrated — not a pretty winding trail. This constrains the *counting mechanic*, not the Adventure map, which is navigation rather than magnitude.
- **Sorting.** Overselective attention is the hidden failure: young children respond to the most salient attribute (usually colour) even when it is irrelevant. **When teaching a new attribute, hold all others constant** — never pit a subtle target attribute (size) against a salient distractor (bright colour) in early content. Hence `activeAttributes` + `heldConstant` as explicit schema fields.
- **Patterns.** Task difficulty is ordered: duplicate → fill-missing → extend → translate → identify-unit → create. **Verbal labelling of the structure ("A-B-A-B") measurably improves performance and transfer**, so `verbalLabelEnabled` defaults on — it is a teaching mechanism, not chrome.
- **Read-along.** Takacs, Swart & Bus (2015), 43 studies, n=2,147: congruent narration-synced animation helps comprehension (g+ = 0.39), but adding **interactive hotspots erases it (g+ = −0.14)** — and even *story-relevant* interactivity is non-significant. Congruent animation yes, hotspot minigames no; `hotspotCount` capped at 0–1. A strong argument for keeping `read_along` deferred rather than building it richly.

---

## 5. Why difficulty tiers are not the configuration API

**The story author should control the experience, not choose an abstract Easy / Medium / Hard tier.**

A tier is a lossy encoding of the thing the author actually cares about. "Medium memory" means nothing to someone writing a jungle chapter; "eight pairs of trail-marker symbols" means exactly what it says. Tiers also hide the pedagogy: the ordering that matters for counting is *arrangement* (dice → ten-frame → linear → scattered → random), which no single 1–5 scale can express alongside item count.

So Adventure content configures real gameplay parameters directly — `pairCount`, `gridSize`, `maxNumber`, `targetCount`, `clueCount` and clue placement — and only genuinely cross-cutting settings (`distractorCount`, `scaffolding`, `tolerance`, `timeLimitSeconds`) stay universal, in their own `support` block. Full table in [data-model.md](./data-model.md) §4.

**This is cheaper than it looks, for two reasons.**

First, `difficultyLevel` is **already nearly dead**. There is no `DifficultyLevel` enum — it is an `int` on `Level` (`level_model.dart:13,20`), computed by `GameSequence.getDifficultyLevel`, **dropped by `copyWith`**, and **never read by any game**; games receive a plain `int level` from `GameSequenceItem.create`. It dies with `LevelsMap/` in Phase 4.

Second, the pattern already exists in the repo and works. `ColorMemoryGame`'s `LevelConfig` (`color_memory_constants.dart:133-184`) is a real config object with named gameplay fields — `gridSize`, `colorCount`, `initialSequenceLength`, `timePerStep`, `maxRounds`. Generalizing its shape is the whole amendment; `LevelConfig.forLevel(level)` becomes adapter-only.

**Easy/Medium/Hard is kept, temporarily, in exactly one place:** `LegacyActivityAdapter.mapDifficulty`, converting an authored native parameter into whatever `int level` or per-game enum a legacy screen still expects. It carries a deprecation note. New Adventure content never sees it, and the content validator rejects the tokens `level`, `difficulty`, `easy`, `medium` and `hard` in any activity file so it cannot creep back.

**The honest cost:** Puzzle. Honouring an arbitrary `gridSize` means slicing arbitrary images into N pieces — real work, not a rename. Today piece count is a property of the chosen image (`Puzzle/bloc/cubit.dart:12-66` → 4, 4, 9). V1 exposes `pieceCount` validated against what the bundled images support; generalising the slicer is a later task.

---

## 6. Why Arabic literacy is a separate content and engine track

> **"The UI supports Arabic" does not make an activity bilingual.**

Bilingual status is a property of the engine *and its authored content*, declared in `supportedLocales`, and it defaults to `{'en'}` for anything literacy-shaped until real Arabic content exists. `tracing`, `phonics`, `word_building` and `read_along` are **never** marked bilingual by default.

### What Arabic literacy actually requires

- **Proper letterforms.** ~110 pre-rendered glyphs: 28 letters × up to 4 contextual forms. **There are no Arabic letterform assets anywhere in the project today.**
- **Connected contextual shaping.** كتب is **not** the visual concatenation of ك + ت + ب, and dropping a letter changes its neighbours' rendered shapes. This breaks naive letter-tile UIs outright — which is precisely what `word_building` is.
- **RTL stroke and layout data.** RTL stroke starts, leftward guide sprite, mirrored layout — and the glyph itself **never** mirrors.
- **Dots (i'jām) as separate, always-last strokes**, validated as a **tap inside a target circle**, not as a traced path. ب ت ث ن ي share one skeleton and differ only in dots. In one study visual attention span explained 33% of variance in letter recognition, which explained 50% of syllable-reading variance.
- **Arabic-specific pedagogy.** English phonics (grapheme→phoneme, CVC blending) and Arabic early reading (harakat, syllable units) are **different pedagogies wearing one name**. Do not build one bilingual engine; build `phonics` and later a separate `arabic_harakat` sharing the base cubit and widgets. **This is the single most likely place this architecture over-generalises.**
- **Teaching order by shape family**, not alphabetically: ا ل → bowl family ب ت ث ن ي → hook ج ح خ → and so on. Four positional forms are taught in **two cycles** — all 28 isolated forms first, then connected. Introducing four forms of one letter at once is a known frustration source.
- **Naskh** for children, never a display or Kufi face. Full harakat for ages 3–8: diglossia and orthographic complexity interact *multiplicatively*, and the benefit of vowelisation is strongest in early grades and gone by Grade 7.

**One revision worth noting:** `tracing` and `word_building` need the *same* Arabic asset set. That is a shared cost, not two costs, which makes doing both later cheaper than the deferral list implies. It does not change the V1 order.

### This does not block V1

First Adventures use **bilingual-safe mechanics**: counting, matching (`drag_drop`), sorting, memory, patterns, maze, puzzle, math, `hidden_clue` — plus `multiple_choice`, safe as long as prompts are authored whole per locale rather than assembled at runtime. **This maps cleanly onto the Adventure 1 beat map, which needs no change.**

### Seams built in Phase 1 so literacy lands later without a rewrite

Each is cheap now and a contract change later.

1. **`supportedLocales` on the descriptor**, with the content test asserting `locales ⊆ supportedLocales`. Authoring an Arabic tracing node fails the suite.
2. **`TextAttempt` and `StrokeAttempt` in the sealed `ActivityAttempt` set from day one**, with no consumer. Adding a literacy engine must not change the shared contract.
3. **The `GlyphRun` content type reserved in the schema.** Literacy content is authored as pre-composed, pre-shaped glyph runs with their own stroke decomposition, never assembled at runtime. Six letters (ا د ذ ر ز و) are right-joining only; lam-alef (لا) is a mandatory fused ligature.
4. **All script-sensitive text through `ActivityGlyphText`**, never raw `Text` in a board, so Naskh/harakat/shaping is a one-file change.
5. **Engines split by pedagogy, never by language.**
6. **Digits formatted host-side**, locale-configurable (٠١٢٣ vs 0123), not per engine.

### When tracing is eventually built

James & Engelhardt (2012) is the finding that matters: pre-literate 5-year-olds printed, typed, or traced letters, and the reading circuit was recruited **only after free printing — not after typing and not after tracing.** The mechanism is perceptual variability, which tracing by definition does not produce. **So the `write` mode is not the optional advanced tier — it is where the letter-recognition benefit lives.** A tracing-only product is pedagogically hollow.

**A usable head start:** [Antura and the Letters](https://github.com/vgwb/Antura_arabic) is open source (BSD-2 / CC-BY), an EduApp4Syria winner with a published EGRA evaluation, and contains directly relevant Arabic minigames — ColorTickle (colour inside the outline, a low-precision tracing precursor), Maze (stroke direction), DancingDots, SickLetters. Worth mining for both mechanics and assets before authoring 110 glyphs from scratch.

### Two related findings in the current code

- `lib/features/Alphabets/` shows **26 hardcoded English letters read aloud with the Arabic voice** when the locale is `ar`. A real bug and a real content dependency — but an **explicit non-goal** for V1, logged as a separate content task.
- `maze_models.dart:127-141` holds **hardcoded Arabic outside the l10n system** (`'سهل - Easy'`, and a `description` getter). The maze adapter must not inherit it.

### RTL reality check

There are **zero** `Directionality` / `TextDirection` / `textDirection:` usages in `lib/` today — RTL is entirely implicit via `GlobalWidgetsLocalizations`. Adventure Mode's map and sequence layouts will be the **first thing in the app that genuinely needs explicit direction control**, so `sequenceDirection` and `mirrorAnchorsForRtl` are implemented and widget-tested in Phase 1, not deferred.

One genuinely unresolved question: Arabic monoliterate children show a *reverse* SNARC effect (small numbers map rightward) before formal reading instruction, but Arabic textbooks overwhelmingly print number lines left-to-right. Expose `numberPathDirection` as a flag and test with real children rather than guessing.

---

## 7. Narration timing

`Speech.speak` returns on **dispatch**, not completion (documented at `speech.dart:128-134`), and the codebase compensates with scattered magic delays — `Future.delayed(500ms)` at `quiz_cubit.dart:60`, `800ms` at :73, `600ms` at :81, `550ms`+`800ms` in `vehicles_game_screen.dart:199-206`, `400ms` in `sorter_cubit.dart:82`. Those numbers are why prompts sometimes talk over each other.

`ActivityNarrator` — an **instance**, injected, while `Speech` stays the static facade it is — awaits `Speech.speak`, then a `clamp(700ms, chars × 55ms, 8s)` estimate guarded by a cancellation token. This deletes every scattered delay in the new layer.

A future `Speech.speakAndWait()`, completing from `flutter_tts`'s `setCompletionHandler` or `AudioPlayer.onPlayerComplete` depending on route, belongs **inside `Speech`** — two places attaching handlers will race.

---

## 8. Drag mechanics — specifics that are easy to get wrong in Flutter

```
Pick up      : plain Draggable, NOT LongPressDraggable - a 500ms hold is a skill 3-5s fail.
Feedback     : render the dragged item OFFSET ABOVE the finger (-40..-60 logical px) so the
               finger does not occlude it. Use pointerDragAnchorStrategy + Transform.translate;
               childDragAnchorStrategy keeps it under the finger, which is wrong for kids.
Origin ghost : faded outline in the source slot - working memory is weak at this age.
Hit target   : drop-zone hit area 1.5-2.0x its visual bounds.
Magnetism    : PREVIEW the snap before release (target scales ~8%, glows) so the child sees
               it will work before committing.
Wrong drop   : errorless. Animate back to origin over 200-400ms, neutral-encouraging sound.
               No red X, no buzzer, no shake, no score loss.
Cancel       : auto-return on pointer-cancel and app-background - kids abandon mid-drag constantly.
Idle hints   : ~12s wiggle the correct target; ~25s highlight + audio; ~45s demonstrate.
```

Two Flutter traps: `DragTarget.hitTestBehavior` defaults to `translucent`, but overlapping targets in a `Stack` often fail to fire because an opaque ancestor swallows the hit. And use the `...WithDetails` callbacks so the drop offset is available for the motor-vs-knowledge telemetry split.

---

## 9. Widget reuse audit

**Reuse verbatim:** `KidGameShell`, `KidTopBar` (**already the progress-pips widget** — do not rebuild), `KidPromptBanner`, `KidResultView` + `.starsFor`, `KidPickCard` (**already the draggable token**, with the exact six card states the no-fail ladder needs), `kidFitCardSize`, `KidUi`/`KidMetrics`/`KidHaptics`.

**Extend (small additive edits):** `KidResultView` gains `heroAsset`/`subtitle`/`onContinue` (an Adventure node continues the story rather than "play again"); `KidTopBar` gains `onHelp`; `KidPickCard` gains `badge` and `shape`.

**Build new:** `ActivityDropTarget` (lift from `FruitVegSorterGame/ui/widgets/basket_target.dart`, which already has armed/hinted/wrong states), `ActivityItemTray`, `ActivityScene` (normalized-coordinate pins), `ActivityFeedbackOverlay`, `ActivityHelpButton`, `ActivityQuantityPad`, `ActivityGlyphText`, `ActivityTraceCanvas` (later).

---

## Reference

The full pedagogy research — interaction specs, stroke-validation algorithm, tolerance tables, sequencing chains and sources — is archived at `C:\Users\youss\.claude\plans\spicy-fluttering-lynx-agent-a9248796082d9fe17.md` (~1,100 lines). The sections that bind the design are folded into this file and [data-model.md](./data-model.md).
