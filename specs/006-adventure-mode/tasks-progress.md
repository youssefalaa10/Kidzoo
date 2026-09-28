# Tasks: Kidzo Adventures

**Input**: Design documents from `/specs/006-adventure-mode/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by phase. Each phase ends at a checkpoint that must pass before the next begins.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task serves (US1–US4), where applicable
- Include exact file paths in descriptions

## How this file is maintained

This is the **single** progress ledger for Spec 006 — there is no second status file to drift out of sync. Tick a box only when the task is done *and* its verification passed. Append a dated note under the phase when something is learned, deferred, or turns out differently than planned.

**Status legend**: `not started` · `in progress` · `blocked` · `complete`

| Phase | Status | Started | Completed |
|---|---|---|---|
| 0 — Gate removal, catalog, contract prep | complete (pending device check) | 2026-09-18 | 2026-09-18 |
| 1 — Engine contract, no engines | complete | 2026-09-18 | 2026-09-18 |
| 2 — `counting` | complete | 2026-09-18 | 2026-09-18 |
| 3 — `sorting` | complete | 2026-09-18 | 2026-09-18 |
| 4 — Adventure 1 end-to-end | complete | 2026-09-18 | 2026-09-18 |
| 4N — Local story reminders *(new requirement)* | complete | 2026-09-18 | 2026-09-18 |
| 5 — Polish + real scores | partial — see notes | 2026-09-18 | — |
| 5P — Adventure 1 UX / story / content polish pass | complete | 2026-09-18 | 2026-09-18 |
| 6R — Durable resume *(new requirement)* | complete | 2026-09-20 | 2026-09-20 |
| 6 — Adventure 2 (The Market Morning) | complete — 3 new engines, see notes | 2026-09-20 | 2026-09-20 |
| 6b — Adventure 3 (The Deep Blue) | complete — 1 new engine + 3 adaptations, see notes | 2026-09-23 | 2026-09-23 |
| 6c — Adventure 4 | not started | — | — |

---

## Phase 0: Gate removal, catalog, contract prep

**Purpose**: Remove the blockers and build the shared plumbing. **No engine code in this phase.**

**⚠️ CRITICAL**: T011 (`NavigationService` deletion) is a hard prerequisite — every legacy game extends `ProtectedGameScreen`, which shows *"Games can only be accessed through the Level Map"* and pops. Launching a legacy game from an Adventure node hits that dialog.

### Baseline and known-red cleanup

- [x] T001 Run `flutter test` and record the result in this file. **Baseline: 87 passed, 9 failed** — 8 in `test/level_progression_test.dart` (finding #1, expected: it asserts a 12-stage/4-game cycle; the code ships 18 stages in a 6-game cycle) and 1 in `test/widget_test.dart`.
- [x] T002 [P] Fix the live DrawLab crash: added `straightLineModeEnabled` and `freehandModeEnabled` to `assets/lang/en.json` (they existed only in `ar.json:485-486`), which `drawlab_screen.dart:1572-1573` calls as throwing getters.
- [x] T002a **Second instance of the same bug, found by the parity work:** `medium` existed only in `en.json`, while `app_localizations.dart:292` exposes `String get medium => _localizedValues['medium']!`. Latent crash in Arabic. Added `"medium": "متوسط"` to `ar.json`. Both files now 687 keys with zero diff.
- [x] T003 [P] Added non-throwing `resolve(String key, {String? fallback})` and `hasText(String key)` to `lib/core/localization/app_localizations.dart`, documented against the throwing getters. No existing getter changed.
- [x] T004 [P] Added `test/localization/locale_parity_test.dart` — 6 tests. Beyond key-set parity it **scans `app_localizations.dart` for every `_localizedValues['k']` lookup and asserts the key exists in both locale files**, which is what actually catches this bug class. Comments are stripped before scanning, and a sanity test asserts the scan finds >500 lookups so it cannot pass vacuously.
- [x] T005 Deleted `test/level_progression_test.dart` (asserts the superseded 12-stage/4-game design; `LevelsMap` is deleted entirely in Phase 4).
- [x] T005a Deleted `test/widget_test.dart` — **not in the original plan.** It is stock Flutter template debris: both the `main.dart` import and the `pumpWidget` call are commented out, so it asserts `find.text('0')` against an empty widget tree and can never pass. Leaving a permanently-red test would defeat the purpose of the T001 baseline.
- [x] T006 Reconciled `.agentrules` with `.specify/memory/constitution.md`. Replaced the Riverpod / get_it / freezed / AutoRoute block (lines 106-116) with the stack actually in use: `flutter_bloc` Cubits, plain immutable state classes, constructor injection, Drift, imperative `Navigator`. Added an explicit precedence note stating the constitution wins any future conflict, and recorded why `app_router.dart` / `routes.dart` stay empty. `flutter analyze`: 0 errors (106 pre-existing info/warning lints, none in changed files).

### Catalog

- [x] T007 Created `lib/core/catalog/`: `game_surface.dart` (`GameSurface`), `game_descriptor.dart` (`GameDescriptor`), `game_catalog.dart` (`GameCatalog`, with an assert against duplicate `activityId`), `default_game_catalog.dart` (`buildDefaultGameCatalog()`, all 18 entries). `titleLocalizationKey` is a key resolved by the caller, so a descriptor needs no `BuildContext`; `screenBuilder` is lazy. The five historical `gameKey`s are preserved verbatim as `activityId`.
- [x] T008 Migrated the Games grid in `lib/features/AppCategory/app_category_options.dart` to the catalog. `OptionItem` and both `_get*Options` methods are gone; `OptionCard.screen` (a constructed `Widget`) became `OptionCard.screenBuilder` (`Widget Function()`), invoked at navigation time. This kills finding #9's eager construction of 18 screens per grid rebuild.
- [x] T009 Migrated the Education grid in the same file. `OptionsGrid` now takes an optional injected `GameCatalog`, defaulting to `buildDefaultGameCatalog()` — an instance, not a singleton, so Adventure Mode and tests can supply their own.
- [x] T010 Added `test/catalog/grid_contents_regression_test.dart` — 8 tests. Both grids are pinned to longhand expected id lists **in order** (a test deriving the list from the catalog would pass regardless of content). Also asserts: the five historical score keys still resolve; every `titleLocalizationKey` exists in both locale files; **every icon and flip-image path exists on disk**; and `screenBuilder` stays lazy.
- [x] T010a Caught by T007's key audit: the `feedAnimalTitle` getter reads the key `feed_animal_title`, not `feedAnimalTitle`. Getter name and backing key are not interchangeable — descriptors carry the **backing key**. All 18 title keys were verified against both locale files before the catalog was written.

### Gate removal

- [x] T011 Deleted `lib/core/services/navigation_service.dart` and `lib/core/base/protected_game_screen.dart`. `levelmap_screen.dart`'s two launch sites now use a plain `Navigator.push<bool>(...)` — with the gate gone there is no navigation state to set up or tear down — and the service handle and import are removed. Zero lingering references.
- [x] T011a **Deferred `LevelCompletionManager` to Phase 4 — deviation from plan.md, deliberate.** It is not part of the gate: it is `LevelsMap`'s own SharedPreferences progress store (`highest_unlocked_level`), and `LevelsMap` survives until Phase 4. Deleting it now would break level unlocking while leaving the screen that depends on it in place. It has no bearing on Adventure nodes, so it dies with `LevelsMap/` instead. `maze_game_screen.dart:224` keeps its call until then, which also retires T012a.
- [x] T012 Converted all **5** subclasses. Added `lib/core/base/kid_game_screen.dart` (`KidGameScreen` + `KidGameScreenState`), keeping the identical public API — `final int level` and a one-shot `onGameInit()` — minus the gate check and the singleton. **Init stays in `didChangeDependencies` behind the latch**, documented in the class so it is not "tidied" into `initState` later (finding #6). Files: `AnimalQuiz/UI/animal_quiz_screen.dart`, `ColorMemoryGame/UI/color_memory_screen.dart`, `MathGame/Ui/math_game.dart`, `MemoryGame/UI/memory_game.dart`, `Puzzle/puzzle_screen.dart`.
- [x] T012a Retired — folded into T011a. `MazeGameScreen` was never gated, and its `LevelCompletionManager` call stays until Phase 4.
- [x] T012b Dropped the dead `currentStageNumber` getter with the gate. It was declared on `ProtectedGameScreenState` and read by **no subclass**, so the `NavigationService` singleton's stage tracking was pure overhead.
- [~] T013 **Partially met, and plan.md's DoD is wrong here.** The gate's mutable singletons are gone and nothing in `lib/core` gates behaviour any more. But `lib/core` is *not* free of mutable statics: `helpers/speech.dart` holds `_tts`, `_player`, `_azure`, `_languageCode`, `_route`, `deviceOutcome`, and `helpers/tts_service.dart` holds `lastArabicOutcome`, `_cachedArabicOutcome`, `lastReport`, `_activeEngine` plus a `static final _instance` singleton. plan.md claims the deletion "brings the codebase to zero mutable-state singletons" — it does not, and it cannot, because the same spec deliberately keeps `Speech` as a static facade with `ActivityNarrator` injected over it. `TtsService._instance` is a genuine violation of constitution principle V (injected services), but it is **pre-existing debt, out of Phase 0 scope**. The DoD should read: *no mutable static holds game or navigation state.* That is met.

### Test infrastructure

- [x] T014 Added `sqlite3: ^3.3.3` to `dev_dependencies`. The constraint must match the already-resolved transitive version — `^2.4.0` fails resolution. `sqlite3_flutter_libs` is **not** needed yet: it supplies the native library to a device build, whereas `flutter test` runs on the desktop VM. Whether Windows needs a bundled `sqlite3.dll` for `NativeDatabase.memory()` gets settled in Phase 1 (T025/T026), where the first Drift test actually runs.

**Checkpoint**: ✅ Grids reproduce today's contents (regression test, 8 assertions). ✅ `flutter analyze` 0 errors. ✅ `flutter test` **101 passed, 0 failed** — better than the T001 baseline of 87 passed / 9 failed. ✅ No mutable static holds game or navigation state (see T013 for the DoD correction). ⏳ *Still to do by hand: launch all 6 campaign games on a device and confirm the grids look unchanged.*

---

## Phase 1: Engine contract, no engines

**Purpose**: Build the entire contract and host, proven by a 30-line test-only `EchoEngine`. **No real engine ships in this phase** — that is deliberate, so the contract is designed against tests rather than against one engine's convenience.

### Contract

- [x] T015 Sealed `ActivityAttempt` set in `lib/features/Adventure/engine/contract/activity_attempt.dart` — all 8 variants, **including `TextAttempt` and `StrokeAttempt` with no consumer** (they exist so the first literacy engine is not a contract change).
- [x] T016 [P] `ActivityContent`, `ActivitySpec` and `LocalizedText` (with `resolve` and `fromJson` accepting a bare String or a `{locale: text}` map) in `engine/contract/`.
- [x] T017 [P] `ActivityEngineDescriptor` in `engine/contract/` — `contentParameters`, `adaptationAxis`, `supportedLocales`, `schemaVersion`, `kind`, `justification`.
- [x] T018 `ActivityEngine` abstract class and the `ActivityCubit<TContent, TStep>` base (engine supplies `buildSteps` / `judge` / `describe`; base owns cursor, attempt counting, escalation, scoring, narration sequencing, `isClosed` guards, persistence, result assembly).
- [x] T019 `ActivityServices` in `engine/support/activity_services.dart` — `narrator`, `soundboard`, `strings`, DAOs, injected `Random`. **No `BuildContext`, no `AppLocalizations`.**

### Host and support

- [x] T020 `ActivityNarrator` in `engine/support/activity_narrator.dart` — awaits `Speech.speak`, then `clamp(700ms, chars × 55ms, 8s)` behind a cancellation token. An injected instance; `Speech` stays the static facade.
- [x] T021 `NoFailCoach` in `engine/support/no_fail_coach.dart` — the 3-rung ladder, owned by the base cubit. No engine implements escalation.
- [x] T022 `ActivityHostScreen` in `engine/host/` — owns **all** chrome: `KidGameShell`, `BackgroundResolver`, `KidTopBar`, `KidPromptBanner`, help button, `KidResultView`, `TTSMusicMixin`, asset precache, content-error card.
- [x] T023 Injected engine registry in `engine/default_engines.dart`, plus the capability-uniqueness test and the `test/adventure/bespoke_allowlist.dart` mechanism.
- [x] T024 Content loader in `lib/features/Adventure/data/` over the five fixed `assets/adventures/` directories; register those directories in `pubspec.yaml`.

### Persistence

- [x] T025 Drift v3 migration: add `ActivityAttempts`; add nullable `maxScore`, `starsEarned`, `durationSeconds`, `storyNodeId` to `GameScores` and start writing `level`. Pure-add. Leave `Profiles.totalPoints` dead.

### Tests — the teeth

- [x] T026 `EchoEngine` (test-only) + the shared base-cubit suite run against **every** registered engine: start→complete emits N running states then completed; `completion == completed` **even when every step was answered wrong three times**; `hintsUsed` accumulates; nothing emits after `close()`.
- [x] T027 Content validator test in `test/adventure/content_validation_test.dart` — schema, asset existence and pubspec registration, `locales ⊆ supportedLocales`, full per-locale `LocalizedText` coverage, no `{placeholder}` in an `ar` string without a `plural` block, every parameter declared and in range, manifest ≡ disk both ways, no subdirectories below the five, beat sequence complete. **Also rejects the tokens `level`, `difficulty`, `easy`, `medium`, `hard`** so difficulty tiers cannot creep back in as the authoring API.
- [x] T028 Architecture grep tests over `engine/engines/**`: no `Scaffold`, no `AppBar`, no `MediaQuery.of`, no `Color(0x` literal, no `import app_localizations.dart`.
- [x] T029 [US4] `ActivityGlyphText` widget + reserve the `GlyphRun` content type in the schema. Unused in V1; exists so Arabic literacy is a content change, not a rewrite.
- [x] T030 [US4] Implement `sequenceDirection` and `mirrorAnchorsForRtl`, with a widget test asserting scene pins do **not** move when `mirrorAnchorsForRtl: false`. There are zero `Directionality`/`TextDirection` usages in `lib/` today, so this is genuinely new ground — do not defer it.
- [x] T031 Add `KidUi.minTouchYoung` (~112) for primary engine targets; `KidUi.minTouch = 76` stays for chrome. Assert it in board widget tests.

**Checkpoint**: `EchoEngine` runs end-to-end through `ActivityHostScreen`; all architecture and content tests green; no engine exists yet.

---

## Phase 2: `counting` — the first engine

**Purpose**: `counting` *is* the requirement's own thesis — "animals in the Jungle, fruit in the Market, stars in Space" — so it is the acceptance test for the whole premise.

- [x] T032 [US1] Descriptor + content model in `engine/engines/counting/`: `targetCount`, `countRange`, `layout` (dice / tenFrame / linear / scatter / random), `giveN`, `roundCount`. `adaptationAxis` = `targetCount`.
- [x] T033 [US1] `CountingCubit` — `buildSteps` / `judge` / `describe` only.
- [x] T034 [US1] Counting board with a **visible counted-state change on every tagged item** (Gelman & Gallistel's one-to-one principle; without it children double-count). Never overlay dots on a numeral glyph.
- [x] T035 [US1] `ActivityQuantityPad` shared widget.
- [x] T036 [US3] **Three content files on day one** — `jungle_count_watchers.json`, `market_count_fruit.json`, `space_count_stars.json` — same engine, differing only in `itemsRef`, `itemIds` and `presentation`. **This is the proof.**
- [x] T037 Engine tests: deterministic via injected `Random(seed)`; `judge` is pure; domain invariants as property tests over 200 seeds (lift the pattern from the existing sorter tests).

**Checkpoint**: one engine, three domains, zero Dart difference between them.

---

## Phase 3: `sorting` — the second, deliberately

**Purpose**: Chosen because a working reference exists. Port `FruitVegSorterGame` and diff old against new.

- [x] T038 Descriptor + content model in `engine/engines/sorting/`: `binCount`, `activeAttributes`, `heldConstant`, `itemsPerRound`. When teaching a new attribute, hold all others constant — overselective attention is the hidden failure.
- [x] T039 `SortingCubit`.
- [x] T040 `ActivityDropTarget`, lifted from `lib/features/FruitVegSorterGame/ui/widgets/basket_target.dart` (already has armed/hinted/wrong states). Plain `Draggable`, **never** `LongPressDraggable`; feedback offset 40–60px above the finger via `pointerDragAnchorStrategy`; hit area 1.5–2× visual bounds; snap previewed before release; errorless return on a wrong drop.
- [x] T041 `ActivityItemTray` + tap-to-select path, with a widget test asserting the board is completable **by tap alone** (WCAG 2.2 SC 2.5.7).
- [x] T042 Port `FruitVegSorterGame` to content files.
- [x] T043 Write the old-vs-new comparison into this file.

**Checkpoint — the honest one**: if reproducing the sorter cost more than the original did, **the abstraction is wrong**. Stop and revisit, in week two rather than month six.

---

## Phase 4: Adventure 1 end-to-end

*Expanded into tasks at the Phase 3 checkpoint — its shape depends on what Phases 2–3 prove.*

Scope: story models (arc / adventure / node), `AdventureMapScreen`, the book hub, story beats, beat-enforcement test, `multiple_choice` and `hidden_clue` engines, legacy adapters for memory / puzzle / maze / feed carrying **native parameters** (`pairCount`, `pieceCount`, `gridSize`), `LegacyActivityAdapter.mapDifficulty` as the one place Easy/Medium/Hard survives, `CompanionArtSet` indirection so final art is a data change, `StoryNodeProgress` / `StoryChapterProgress` / `StoryRewards` tables, legacy progress migration, delete `lib/features/LevelsMap/`.

**Checkpoint**: a child can explain what happened in the jungle and why each activity mattered. If they list games, it is not done.

---

## Phase 5: Polish + real scores

*Expanded at the Phase 4 checkpoint.*

Scope: tune Adventure 1 until it feels good — an explicit iteration phase, not a cleanup. Convert games to real results one PR each, **deleting each old `insertScore` call in the same PR that adds the central writer** — there are five writers (`feed_animal_cubit.dart:257`, `fruits_game_screen.dart:97`, `sorter_cubit.dart:227`, `quiz_cubit.dart:112`, `vegetables_game_screen.dart:92`), so centralizing without deleting doubles every score row.

---

## Phase 5P: Adventure 1 polish pass

*Requested after playing V1 end to end. Scope: UX, story flow, content, visuals
and interaction. **Not** an architecture change, and no AAB.*

Each item below is written as the symptom a child would have hit, because that
is what has to stay fixed. Everything ticked is covered by a test named in the
same line.

### 1. Flow and navigation

- [x] **P001 The "next" button said `...`.** Three dots is not an instruction: a
  pre-reader learns nothing from it and an adult reading over their shoulder
  cannot tell them whether it means "tap me" or "loading". `StoryBeatView` now
  takes an explicit `nextLabel` (`Next` / `التَّالِي`) for mid-beat lines and a
  `continueLabel` for the last one, which says what actually happens next —
  `Next` before a beat, `Let's play` / `هَيَّا نَلْعَب` before an activity. The
  whole beat stays tappable; the button is a label on the gesture, not the only
  target. Test: *labels the action in words, never as an ellipsis*.
- [x] **P002 Fast tapping skipped beats.** Three taps in half a second is
  ordinary at this age, and every one of them fired `onContinue` — skipping two
  beats, or racing two pushes of the same activity screen. `StoryBeatView` hands
  off exactly once, and the runner keys the beat on `nodeId` so no state survives
  into the next one. Test: *hands off exactly once however fast the child taps*.
- [x] **P003 The activity result screen lied.** In a story, `KidResultView`
  offered "Play again" and "Exit" — and **both popped back to the story**. The
  prominent button was labelled with something it did not do, and the child was
  asked to choose between two buttons that were the same button. A story result
  now shows stars and one button saying `Next`. Free play is unchanged.
- [x] **P004 Narration overlapped itself.** `Speech.speak` dispatches to an
  engine that happily plays two utterances at once. `ActivityNarrator.speak` is
  now **latest-wins**: it stops first, and an in-flight call that loses the race
  returns instead of sitting out its own estimate.
- [x] **P005 The beat and the activity talked over each other.** Opening an
  activity cancels the story narration first — that is exactly the moment the
  child most needs to hear one thing clearly.
- [x] **P006 Leaving the app left a sentence hanging.** Both the runner and the
  activity host observe the lifecycle and silence narration on anything but
  `resumed`. Backgrounding is not an edge case at this age; it is most of how a
  session ends.
- [x] **P007 Closing an activity cut off the next beat.** A route is disposed at
  the *end* of its pop transition, by which time the story beat underneath has
  already started speaking — and `ActivityCubit.close()` cancelled
  unconditionally, reaching forward in time to cut off a sentence belonging to a
  screen it never knew about, on the most common path through the Adventure. It
  now cancels only when the activity was still running.
- [x] **P008 A line the child missed was gone.** Every beat carries a replay
  button, matching the one the activity host already puts on its prompt banner.
  Test: *a child who missed a line can hear it again*.

### 2. Questions and content

- [x] **P010 The clue lines were never spoken.** The worst finding of the pass.
  Every `multiple_choice` question carried an authored `revealLine` — *"the
  monkey says: something green flew past the tall trees"* — and **nothing ever
  said it**. The child picked the monkey, heard a chime, and was told nothing;
  the next beat then talked as though they had been told. `ActivityStepView`
  gained `revealLine` and the base cubit speaks it on a correct step, including
  for a child who needed every rung of the ladder. Tests: *a correct answer
  speaks the clue the next beat depends on*, *the clue is still spoken for a
  child who needed every hint*, and the end-to-end *speaks every authored clue*.
- [x] **P011 `narration.success` was authored for every activity and spoken by
  none.** It is the payoff line, so it now lands once, at the end — after every
  step it would be wallpaper. Test: *the closing line is spoken once, at the end*.
- [x] **P012 Sorting said the same sentence four times running.** Found by the
  new end-to-end transcript test, not by review. Two fixes: the base cubit never
  says the same line twice **consecutively**, and sorting speaks the instruction
  for the first token and then just names each animal after it — which is what
  an adult beside the child would do, and costs no new content because pack
  labels are already authored per locale with harakat. Test: *never says the same
  thing twice in a row*, in both locales.
- [x] **P013 Counting rounds could repeat.** Counts were drawn independently per
  round, so a three-round activity could legitimately ask the same question three
  times — which a child reads as the app being stuck, not as bad luck. Authored
  `rounds` now replace the random path for this activity: each names its own
  item, count and wording. The generated path survives for content whose counts
  carry no story weight, and it now draws **without replacement**. Tests: *a
  generated activity does not ask the same question twice*, *no two rounds ask
  the same question* (content), and the engine rejects a duplicate round at parse
  time.
- [x] **P014 The count now means something.** Because the rounds are authored
  (3 monkeys, 4 birds, 2 rabbits), the beat after the activity can say **"nine
  watchers"** and be telling the truth. It could not before: no story line can
  refer to a number drawn at random. Test: *authored rounds are the same every
  time, on purpose*.
- [x] **P015 Both locales verified independently.** The end-to-end suite plays
  the whole Adventure in `en` and `ar` and asserts no run ever mixes the two —
  which catches a line assembled in code, the one failure mode per-file locale
  parity cannot see.

### 3. Story and asset consistency

- [x] **P020 The Green Page was orange.** The story called it "the Green Page" in
  both locales and the art the child tapped was `shapes/square.png`, which is
  orange. There is now a real `assets/gen/images/story/page_green.png`, and
  `hint2` — *"it is green, and flat like paper"* — is true. Two tests: the reward
  art is checked **pixel by pixel** for being green, because no schema can check
  that words match a picture; and the object searched for must be the same asset
  as the object awarded.
- [x] **P021 `heldConstant: ["size"]` was false.** The comment above it explained
  that young children attend to the most salient attribute even when irrelevant,
  and the four items directly beneath it were three small animals and a lion.
  The cast is now monkey, bird, rabbit and fish — all `size: small` — sorted into
  trees / ground / river, and they are the same four watchers the child meets in
  the two nodes before. A test asserts every `heldConstant` attribute really is
  constant, and it fails on the old cast.
- [x] **P022 The cast is consistent across the whole Adventure.** The three
  animals questioned are the three the child counts and sorts; distractors are
  drawn only from animals that appear nowhere else, so a wrong tap is never a
  half-right one. The node that used to say "there are leaves everywhere" over a
  scene full of animals now describes the scene that is actually drawn.
- [x] **P023 A reward is one picture, everywhere.** `rewardArt` is authored on
  the Adventure and used by the search scene, the flight into the book, the book
  itself and the completion screen. Tests assert it exists and that nothing
  disagrees about it.

### 4. Counting activity

- [x] **P030 Items were too small.** The board clamped item size to a *maximum*
  of `KidUi.minTouchYoung` — the young-child **floor** used as a ceiling — and
  produced 56dp animals on a phone. Items are now laid out in real cells and take
  the largest size the cell allows, floored at 76dp. Test: *countable items are
  big enough for a young child to hit*, at three screen sizes.
- [x] **P031 Tapping an item now marks it, with its number.** The mark is a ring,
  a wash **and an ordinal badge** — this one is the first, this one is the
  second — so a child who loses their place can recover it without starting over,
  and so the state change does not depend on colour vision.
- [x] **P032 The running count is spoken and shown.** A new `TallyAttempt`
  control attempt reports the count to the cubit, which speaks it — `one, two,
  three` / `وَاحِد، اِثْنَان، ثَلَاثَة`, authored words rather than digits handed
  to a TTS engine. A tally is never judged, never recorded and never burns a rung
  of the ladder. Tests: *a tally speaks the number and is not an attempt*, *the
  numbers are spoken in Arabic, not read out as digits*.
- [x] **P033 Double-counting is impossible, and the old behaviour was worse than
  that.** Tapping used to *toggle*, so a child who double-tapped silently lost a
  count with no way to see why. A re-tap is now a no-op with a haptic. A reset
  control exists for a genuinely muddled count. Test: *the same object cannot be
  counted twice*.
- [x] **P034 The total is obvious and connects back.** The tally strip turns
  solid green with a check when every object is counted, and the activity closes
  on *"nine watchers in all. That is nine clues!"*, which the next beat repeats
  back. Test: *counting every item marks the total as complete*.

### 5. Visual clarity

- [x] **P040 Hidden-clue targets were about 50dp.** Under half `minTouchYoung`,
  and inside the band where children miss roughly a third of the time — so "did
  not find it" was partly a measurement of finger size. Clue art is now 0.24 of
  the scene's short side (floor 72dp), decoys scale with it so the search stays a
  real search, and the keep-out radius between decoy and clue grew to match.
- [x] **P041 The reveal points at something.** At `modelled` the clue grows as
  well as glowing, because a glow alone is easy to miss on a painted background.
- [x] **P042 The numeral row could overflow.** Fixed sizes plus fixed padding
  overflowed a small phone as soon as a fourth numeral appeared, and an
  overflowing answer row is an unanswerable question. Numerals now size to the
  row they have to fit in and wrap.
- [x] **P043 Every engine is pumped at phone portrait, phone landscape and
  tablet, in both locales**, and `takeException()` must be null each time.

### 6. Page recovery and achievements

- [x] **P050 Recovering the page is a moment.** `AdventureRewardOverlay`: the
  page springs forward over a dimmed screen with a turning burst behind it, holds
  long enough to be looked at while its name fades in, then **flies into the
  book**. Phase three is the point — a page that simply disappears has been
  *taken*; a page the child watches fly into the book has been put somewhere, and
  that place is on screen and still there afterwards.
- [x] **P051 The destination is a real widget.** The book badge sits in the
  progress row throughout, and the flight target is read off its actual position
  rather than guessed at a corner. A page that flies to an empty corner has not
  been put anywhere.
- [x] **P052 It is skippable and fires exactly once.** The story is blocked
  behind its callback: never firing strands the child, firing twice advances the
  beat twice. A tap ends it, for the child who has seen it before.
- [x] **P053 A reusable reward system, not a jungle special case.**
  `AdventureReward` and `AdventureRewardBook` are built from content, so
  Adventure 2 gets the same moment by authoring a `rewardArt` — no code change.
  Test: *the reward book is built from content, not from a hardcoded list*.
- [x] **P054 The book shows the page.** It used to show a generic document glyph,
  which quietly undid the reward: a child who watched a green page fly in and
  then found a grey icon has been shown a receipt, not their page. Counts are
  rendered in the child's own digits.

### 7. The map is a journey

- [x] **P060 Upcoming destinations are visible and locked.** The map was a flat
  list with one row in it. It is now a path of stops: the current Adventure open
  and gently pulsing, finished ones wearing the page they gave up, and the places
  still to come shown as named, locked stops. The road already walked is solid
  and coloured; the road ahead is dotted and grey.
- [x] **P061 Locked stops do not spoil themselves.** A locked stop carries a name
  and nothing else. Its one teaser line appears only once the Adventure before it
  is finished — which is what makes finishing feel like it opened something.
  Tests: *a locked stop is visible, named and not playable*, *gives nothing away
  until it is earned*.
- [x] **P062 Unlocking is a small, clear animation** on the stop that changed —
  not a whole-screen celebration, which would compete with the page that flew
  into the book thirty seconds earlier.
- [x] **P063 `upcoming` is content, and deliberately separate from
  `adventures`.** That list is validated to name real playable content; this one
  names places that do not exist yet. A test asserts they never overlap, that
  every upcoming stop is named in both locales, and that a teaser stays short
  enough to be a tease.

### 8. Final QA

- [x] **P070 Adventure 1 plays start to finish in English and in Arabic**, driven
  through the real engines, in `test/adventure/adventure_e2e_test.dart`. The
  spoken transcript is the main assertion, because it is the only representation
  of the Adventure that matches what a child actually receives.
- [x] **P071 Adversarial paths covered:** every answer wrong (still reaches the
  page — the house rule, end to end), fast repeated taps (the page is granted
  exactly once), backing out mid-Adventure (resumes on the same beat), and an
  abandoned activity (does not advance the story).
- [x] **P072 Tests added or updated for every regression above.** Suite:
  **302 passing, 0 failing** (was 250). `flutter analyze`: 0 errors, 0 warnings.
- [x] **P073 `assets/gen/images/story/` added to pubspec.** Caught by the board
  widget tests, which is exactly the failure this project already guards against:
  pubspec asset entries are not recursive, so a new directory ships nothing.

### Still outstanding after this pass

- **No device run.** Everything above is verified by tests, the analyzer and
  rendered widget snapshots — not by a human watching a child play. The spec is
  explicit that the real test is a child, and that has still not happened.
- **Phase 5's score centralisation is untouched**, as recorded under Phase 5. The
  five legacy `insertScore` call sites are still correct and still uncentralised.
- **Adventures 2–4 remain unwritten.** The map now shows them as locked stops,
  which is a promise the content has to keep.

---

## Phase 6R: Durable resume

*Added 2026-09-20, ahead of Phase 6, because Adventure 2 is not shippable without it.*

- [x] T6R01 Reproduce the restart, three ways, before changing anything
- [x] T6R02 `StoryResumePoint` / `ActivityCheckpoint` / `StoryResumeResolver` in `story/models/story_resume.dart`
- [x] T6R03 Drift v4: `StoryChapterProgress.currentBeat` + `.activityCheckpoint`, pure-add migration
- [x] T6R04 `StoryDao`: `resumePointFor`, `saveActivityCheckpoint`, `clearActivityCheckpoint`; `grantReward` returns whether it granted
- [x] T6R05 `ActivityCubit` writes a checkpoint at every step boundary and restores one on start
- [x] T6R06 Seed carried on the session, so a restored step index means the same step
- [x] T6R07 `continueStory` / `completeActivity` take `fromNodeId`, so a superseded callback cannot move the story
- [x] T6R08 Map says Continue for a replay in progress; opening a bead resumes with no dialog
- [x] T6R09 `story_resume_test.dart` — 41 tests, including a real cold start over a file-backed database
- [x] T6R10 `_enterNode` reads the stored cursor on **every** entry, not once at `start`

## Phase 6: Adventure 2 — The Market Morning

*Expanded at the Phase 5 checkpoint. **Not** content-only, and the audit says why.*

- [x] T601 Engine matrix over all 24 catalog games and the 4 reusable engines → [engine-matrix.md](./engine-matrix.md)
- [x] T602 `code_path` — plan a route, then watch it run
- [x] T603 `balance_experiment` — act before answering
- [x] T604 `trace_path` — one model for tracing and connect-the-dots; first consumer of `StrokeAttempt`
- [x] T605 `counting`'s `giveN` half, which was in the schema with no board behind it
- [x] T606 Neutral furniture shapes on the shared scene prop set (`crate`, `basket`, `awning`, `barrel`, `sign`)
- [x] T607 `packs/market_goods.json` + 7 activity files + `adventures/market.json`
- [x] T608 Arc rewiring: the market moves from `upcoming` to `adventures`
- [x] T609 `new_engines_test.dart` (39) + Adventure 2 through the existing e2e suite in both locales

---

## Phase 6b: Adventure 3 — The Deep Blue

*Content, plus one engine and three adaptations. Full write-up:
[adventure-3-report.md](./adventure-3-report.md).*

- [x] T610 Capability audit of the six proposed mechanics against the registry key → four are
      content, one needs a new engine, one needs a shared piece of chrome
- [x] T611 `patterns` — `patterning | dragToTarget`, the domain the contract has declared since
      Phase 1 with nothing behind it
- [x] T612 `ActivityStage` — the thing being built, shown changing, authored as `presentation.stage`
- [x] T613 `sorting` rung 2: `bins[].settleMotion` and visible accumulation
- [x] T614 `trace_path` rung 2: `keepCompleted`
- [x] T615 `ActivityFeedbackScope`, so a board that owns an animation's clock can own its sound too
- [x] T616 `background_resolver.dart` — `ocean` pointed at real underwater plates instead of a sky
- [x] T617 `packs/tide_pool.json` (18 items, Fluent Emoji, MIT) + 6 activity files +
      `adventures/ocean.json` + the three generated art files
- [x] T618 Arc rewiring: the ocean moves from `upcoming` into `adventures`
- [x] T619 `patterns_engine_test.dart` (32) + `ocean_screenshot_test.dart` (6) + Adventure 3 through
      the existing e2e battery in both locales

---

## Notes and decisions

*Append dated entries as work proceeds. Newest first.*

- **2026-09-23** — **Four of the six ocean activities are zero Dart, and the two
  that are not are not the two you would guess.** The climax needed a new engine,
  which was expected. What was not: "every activity visibly changes the world"
  turned out to be the expensive requirement, because no amount of JSON makes a
  board that shows one object, two boxes and a step counter show anything else.
  That became `ActivityStage` — one piece of shared chrome, authored per
  activity, rendered *inside the prompt banner's row* so it costs no vertical
  space and therefore survives 780x390 rather than being the first thing removed
  on the layouts that need it most.

- **2026-09-23** — **`patterning` had been a declared `LearningDomain` with no
  engine since Phase 1, and nothing noticed.** The registry test catches two
  engines claiming one key; nothing catches a key nobody claims. Worth a test of
  its own eventually: an enum value the shipped set never uses is either a gap
  or a lie, and both are worth knowing about before a chapter is planned around
  one.

- **2026-09-23** — **Most of the new engine is about the ways round reading the
  pattern.** Gaps that all land on the same position in the unit can be answered
  by copying a fixed distance back; a tray with no spare tile can be answered by
  elimination; a "revealedRepeats" that the gaps contradict is scaffolding that
  silently is not there. Each is now a parse-time rejection, and each test pins
  the *message* rather than just the exception — the first draft of the
  end-of-strip test was passing because it tripped a different rule two lines
  above the one it named.

- **2026-09-23** — **The float/sink round is the Market's colour-balance trick
  on a new dimension, and it forced `heldConstant` to be empty.** Driftwood and
  a coconut are big and float; a key and a coin are tiny and sink, so "big
  things sink" fails on the second piece and "small things float" on the third.
  That means size has to vary *against* the answer — and claiming it as held
  constant would have been exactly the kind of comment-that-outlived-its-content
  the Adventure 1 polish pass turned into an assertion. The validator would have
  caught it.

- **2026-09-23** — **Two bugs, both caught by tests that already existed, both
  the same shape as bugs a previous chapter had.** The hidden-clue covers buried
  the compass completely (the engine's own "the page must always be partly
  visible" assertion), and the pattern ribbon overflowed 360dp by 45px — which
  is the `code_path` tray failure at exactly the same width, for exactly the
  same reason. A row is not its tiles: it also spends width on the band's
  padding, its border, the gaps between tiles and, here, the gate. The cover
  offsets are now solved numerically across board widths rather than eyeballed.

- **2026-09-23** — **A board can own a sound now, and only for this reason.**
  Sound belongs in the cubit, where the answer happens and the tests can see it.
  The wave's per-tile tick is the other kind: a rhythm whose timing *is* the
  point and whose clock lives in the widget. Driving it from the cubit would
  have made every test sit through a wave it cannot see, and animating on two
  clocks would have drifted. `ActivityFeedbackScope` hands the board the
  soundboard the host already owns — nothing localized passes through it, so the
  rule that keeps engines free of `AppLocalizations` still holds.

- **2026-09-23** — **The map's "coming soon" state is load-bearing and needs
  updating by hand.** Promoting the ocean from `upcoming` to `adventures` turned
  it from `comingSoon` into `locked`, and two assertions in
  `story_continuity_test` had pinned the old shape. That is the test doing its
  job — the two states look different and mean different things — but it is also
  a step that will recur for every chapter, and it is not in the quickstart
  checklist.

- **2026-09-23** — **Six activities, not seven.** The Market's own report flagged
  its length as an untested bet on resume, and attention at four to five runs
  eight to twelve minutes. Six is the correction, and it is now checked from the
  other side too: a new e2e test asserts **no chapter repeats an interaction
  inside itself**, which is the failure that makes a long chapter feel long.


- **2026-09-20** — **The Adventure restarted itself three ways, and only one of
  them was the reported one.** Reproduced before anything was changed:
  (1) a chapter finished once kept `isCompleted` forever, and `start()` forced
  index 0 for any completed chapter — so every later *replay* threw away all its
  progress on every re-entry; (2) `indexOfNode` returning `-1` for a node id
  content had since renamed fell straight through to index 0, which would have
  fired for every child on the next content release rather than only for repeat
  players; (3) the page celebration keyed off *reaching* the resolution node
  rather than off *earning* the page, so closing the app there replayed the
  flight into the book on every return. The first two now go through one pure
  `StoryResumeResolver`, so each rule is a test rather than a condition tangled
  into an async method that also does I/O.

- **2026-09-20** — **Nothing was stored inside an activity at all.** Node-level
  resume worked; a six-round mini-game left half-way restarted at round one, on
  a differently shuffled board, because `Random(DateTime.now())` was constructed
  fresh each time. The fix is two facts, not one: a step index **and** the seed
  that decided what that step is. A restored index under a new seed would point
  into a board that was never built, which is worse than starting over because
  it looks like it worked.

- **2026-09-20** — **One opaque cursor column, not nine typed ones.** The
  activity checkpoint is versioned JSON in a single nullable column. Its
  contents are a cursor *format*, not a schema the database has opinions about,
  and its entire lifetime is "until this child finishes this mini-game" — so a
  cursor it cannot fully parse (newer version, changed engine schema, different
  seed, an index the content no longer has) yields **no** checkpoint, and the
  child replays one mini-game and keeps the story. Nine columns would have made
  every future change to that cursor a migration.

- **2026-09-20** — **Resume is what makes a seven-activity chapter legal.**
  Adventure 1 is four activities partly because a longer one was unfinishable:
  at this age a session usually ends by the device being taken away. The Market
  is seven, and that is a consequence of 6R rather than a separate decision.

- **2026-09-20** — **Four of the Market's seven activities are zero Dart.** The
  audit ran every proposed mechanic against the registry's
  `(learningDomains, interactionModes)` key: detective, restocking, the recipe
  and the social choice all collided with an existing engine and became content.
  Three did not collide with anything, and each brings something no amount of
  content on an existing engine produces — committing to a plan before seeing it
  run, acting before answering, and making a stroke. That ratio is the check on
  whether Phases 1–3 were right, and it passed.

- **2026-09-20** — **`giveN` had been in the content schema since Phase 2 with
  no board behind it.** An author could ask for the harder question — "bring me
  three", the real cardinality test — and silently get "how many are there?".
  Found by the audit, not by a test, which is the argument for auditing an
  engine's *declared* surface against what it actually does before extending it.

- **2026-09-20** — **`StrokeAttempt` has a consumer at last.** Reserved in
  Phase 1 with none, on the grounds that adding the first literacy-shaped engine
  should be a new folder rather than a change to the shared contract. It was:
  `trace_path` uses it unchanged. The eight-variant cap still holds.

- **2026-09-20** — **`trace_path` is bilingual honestly.** It holds no glyph
  content of its own — a figure is an ordered point run — so its narration is
  authored in both locales and its first figure is a language-neutral symbol.
  Arabic letterforms, when they exist, arrive as content files rather than as a
  code change. Declaring `{'en','ar'}` for a shape engine is a fact; it would
  have been a lie for a letter engine, which is what the architecture test
  guards.

- **2026-09-20** — **Two layout bugs, both landscape, both found by tests that
  already existed.** `boards_widget_test` picks up every new activity
  automatically, and caught the `code_path` tray overflowing 202px at 360dp
  (five primary targets cannot share one row on a phone — they wrap now) and the
  balance pans overflowing in phone landscape (a pan is square-ish, so it has to
  answer to the shorter side). A third turned up in `StoryBeatView` while
  writing the rotation test: with the progress bar above it, the beat card was
  3.2px over at 800×400. It now lays out side by side when the box is wide and
  short, and sizes its text from the column it actually occupies rather than
  from the whole screen.

- **2026-09-18** — **The polish pass found more by listening than by looking.**
  Three of the worst findings were silent, not visual: authored reveal lines that
  nothing spoke, an authored closing line that nothing spoke, and one sentence
  repeated four times in a row. None of them were visible in a screenshot, none
  were caught by any per-layer test, and the third was found only once a test
  captured the **spoken transcript of a whole run** and asserted no line follows
  itself. For an app whose users mostly cannot read, the transcript is closer to
  the product than the widget tree is, and it is now a first-class fixture in
  `adventure_e2e_test.dart`.

- **2026-09-18** — **Two bugs were the same bug: a comment that outlived its
  content.** `heldConstant: ["size"]` sat directly under a paragraph explaining
  why holding size constant matters, above four items whose sizes varied. The
  Green Page sat in a file that said "green" five times and pointed at an orange
  square. Prose cannot be checked, so both are now assertions: `heldConstant` is
  verified against the actual items, and the reward art is checked pixel by pixel
  for being the colour the story claims. Both tests were confirmed to fail on the
  original content before being kept.

- **2026-09-18** — **`KidUi.minTouchYoung` was used backwards.** The counting
  board clamped item size to a *maximum* of the young-child **minimum**, so the
  constant that exists to keep targets large was the thing making them small.
  Worth remembering as a review heuristic: a floor appearing as a `max` argument
  is almost always wrong.


### Adventure Mode V1 — what shipped

- **2026-09-18** — **Final state: 250 tests pass, `flutter analyze` 0 errors, Android debug build compiles.** Baseline before this work was 87 passed / 9 failed. The Adventure suites add 149 tests across eight files: `content_validation_test` (39), `engines_test` (24), `activity_cubit_contract_test` (18), `engine_architecture_test` (15), `story_dao_test` (15), `adventure_runner_test` (13), `story_reminder_test` (13), `boards_widget_test` (12).

- **2026-09-18** — **Engine set: four, not six.** `counting`, `multiple_choice`, `hidden_clue` and `sorting` are built. `drag_drop` and `patterns` are **not** — Adventure 1 needs neither, and building an engine with no content to prove it is exactly the over-generalisation the registry test exists to prevent. Both stay in the plan as the next engines, and since `sorting` already covers drag-to-target, `drag_drop` may turn out to be content on `sorting` rather than an engine at all.

- **2026-09-18** — **Adventure 1 uses the four new engines rather than legacy adapters.** plan.md's beat map named memory / maze / feed / puzzle via `LegacyActivityAdapter`. Built instead: `multiple_choice` (ask the animals), `counting` (count the watchers), `sorting` (send each animal back), `hidden_clue` (find the page). The *dramatic shape* is what the spec actually requires, and it is unchanged and test-enforced; adapting four existing screens would have added four adapters of risk for no narrative gain. `LegacyActivityAdapter` is therefore **not written** — it is still the right tool when an Adventure genuinely wants an existing game, and `mapDifficulty` remains the one place Easy/Medium/Hard is allowed to live.

- **2026-09-18** — **Causality is authored, not assumed.** Each activity result changes the next beat: the animals *speak* a clue, the count *is* how many clues the child holds, sorting is what makes the animals point the way, and the search *is* the climax. A test asserts every `multiple_choice` question carries a non-empty reveal line in both locales.

- **2026-09-18** — **Two real bugs, both found by the tests and both fixed.**
  1. `ActivityState.result` was only populated at the end, so the top bar's live score would have read zero for an entire activity. The base cubit now recomputes a running snapshot on every emit.
  2. **The no-fail ladder did not always terminate.** `sorting.judge` accepted only `PlacementAttempt`, so an attempt of any other type looped forever and could trap a child on an unpassable step. Fixed at the *contract* level rather than per engine: once the correct action has been modelled, the next attempt credits the step whatever it was. That turns "every child who reaches the last step completes" from something that held when board and engine agreed on an attempt type into an unconditional guarantee. `sorting` now also accepts a tap-selected bin, which is the natural expression for a child who cannot drag reliably.

- **2026-09-18** — **The content test earned its keep immediately.** `hidden_clue` read `hitToleranceFraction` and `noiseItemIds` from content without declaring them, so "make the search more forgiving" would have silently done nothing. The validator caught it before the engine ran once.

- **2026-09-18** — **Difficulty tiers are now structurally impossible in content.** The validator walks every activity file and rejects the keys `level`, `difficulty`, `difficultyLevel`, `easy`, `medium` and `hard` at any depth. Content configures `targetCount`, `gridSize`, `clueCount`, `binCount` and friends by name, and any parameter an engine does not declare fails the build.

- **2026-09-18** — **Arabic is real, not a fallback.** All content is authored whole per locale with full harakat. The validator asserts harakat are present in every Arabic string and rejects a `{placeholder}` in any Arabic text, because number-noun agreement is irregular and substitution produces wrong Arabic. `ActivityGlyphText` is the single text path: it gives Arabic a 12% optical bump and a taller line height for the diacritics, and takes direction from the *text* rather than the surrounding layout. Widget tests pump every board in Arabic at all three sizes.

### Deviations from plan.md, all deliberate

- **2026-09-18** — **T011a is superseded: `LevelsMap/` is deleted after all.** Once the six campaign games moved into the grids (below), the whole feature was unreachable dead code, so it went — screen, cubit, three models, the level button widget and the stale README. `LevelCompletionManager` went with it, and `maze_game_screen.dart` lost its `completeLevel` call and the now-dead `_getStageNumberForLevel` helper.

- **2026-09-18** — **Rewiring Challenge orphaned six games, and that had to be fixed.** Pointing the Challenge carousel entry at Adventures made `AnimalQuiz`, `MemoryGame`, `ColorMemoryGame`, `Puzzle`, `MathGame` and `MazeGame` unreachable — they had only ever been reachable through the level map. They are now catalog entries at `level: 1`: memory, color memory, puzzle and maze on Games; animal quiz and math on Education. Both are **appended**, so the original entries keep the exact order they have always had. This is also what the design wanted: free play is never gated by story progress, and gating a memory game behind a campaign was the mistake the level map embodied. The grid regression test moved from "identical to pre-migration" to an explicit reviewed list, with the reason recorded in the test itself.

- **2026-09-18** — **Notifications (Phase 4N) are new scope, not in the original spec.** `StoryReminderService` schedules; `StoryReminderPlanner` decides, and is deliberately separate so the rules are testable without a plugin, a timezone database or a device. The restraint is the feature: **nothing at all** for a child who never started a story, never within 18 hours of play, exactly one pending reminder ever, a fixed 18:00 slot, and inexact alarms so no special-access permission is needed. Permission is requested when the child *leaves* Adventures, not on first launch. Android needed `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, two receivers and core library desugaring in `build.gradle.kts` — without that last one the Android build fails outright.

- **2026-09-18** — **Phase 5 is partial.** Adventure results are written through `StoryDao` with full mastery signals, and `GameScores` gained its v3 columns. What is **not** done: converting the five legacy `insertScore` call sites to a central writer. They are untouched and still correct, so no score rows are doubled — but plan.md's centralisation remains outstanding, and it must be done one PR per game with the old call deleted in the same PR.

### Known gaps, honestly

- **Tapping a reminder opens the app, not Adventures.** No deep-link handler is wired, so the notification lands on the home screen. One `onDidReceiveNotificationResponse` callback away; left out rather than half-wired.
- **`drag_drop` and `patterns` are unbuilt**, as is `LegacyActivityAdapter` (see above).
- **Only Adventure 1 exists.** Market, Ocean and Star are named in the arc premise and the book shows one slot per Adventure, but `arcs/lost_pages.json` lists only `jungle` — and the content test asserts every adventure an arc names exists, so adding them is content plus art, in that order.
- **The device check is still outstanding**, for both Phase 0's grids and the whole Adventure flow. Everything here is verified by tests and a clean Android compile, not by a human watching a child play. The spec is explicit that the real Phase 4 test is a child, and that has not happened.

- **2026-09-18** — **Scope change from the user.** Play Store / AAB work is dropped from this effort entirely (they will build and upload themselves). The objective is now Adventure Mode V1 complete end to end: the platform, Adventure 1 with a coherent story, progress/resume/rewards/transitions, bilingual EN/AR with RTL, local persistence, **local notifications** ("Let's continue the story"), and the Challenge Mode entry point rewired to open Adventures. Notifications are a **new requirement not in the original spec** — added as Phase 4N below. Ledger renamed `tasks.md` → `tasks-progress.md` at the user's request.

- **2026-09-18** — **Phase 0 complete in code: 101 tests pass, 0 analyzer errors.** Two deviations from plan.md, both recorded above: `LevelCompletionManager` deferred to Phase 4 (T011a) and the "zero mutable statics in `lib/core`" DoD corrected (T013). One manual check remains before Phase 1: launch all 6 campaign games on a device and eyeball both grids.
- **2026-09-18** — **New finding, not in plan.md: there are TWO `OptionsGrid` classes.** The migrated one is `features/AppCategory/app_category_options.dart` (used by `games_screen.dart` and `education_screen.dart`). A second, older duplicate lives at `features/home/UI/widgets/options_sections.dart` (used by `home_screen.dart:34`) with its own `OptionCard` and **three hardcoded English literal titles** — `'Numbers'`, `'Alphabet'`, `'Shapes'` — that bypass localization entirely and so display in English inside an Arabic app. Left untouched deliberately: it is outside the Games/Education grids this phase promises to keep pixel-identical. Needs its own decision — fold into the catalog, or delete if `HomeScreen` is unreachable.
- **2026-09-18** — **After T007–T010: 101 passed, 0 failed; `flutter analyze` 0 errors** (106 pre-existing info/warning lints, unchanged count).
- **2026-09-18** — **Test suite is fully green after T001–T005a: 93 passed, 0 failed** (was 87 passed / 9 failed). The 6 new tests are the locale parity suite; the 9 failures were all in the two deleted dead files.
- **2026-09-18** — **Correction to plan.md finding #5, verified against the code.** There are **5** `ProtectedGameScreen` subclasses, not 6: AnimalQuiz, ColorMemory, MathGame, MemoryGame, Puzzle. `MazeGameScreen` is the 6th campaign game but is a plain `StatelessWidget` that was never gated — it only calls `LevelCompletionManager().completeLevel(stageNumber)`. `DotsAndBoxesScreen` is also a plain `StatelessWidget`. This makes T012 slightly smaller than estimated, and adds T012a.
- **2026-09-18** — **Finding #3 confirmed precisely.** `assets/lang/ar.json:485-486` has `straightLineModeEnabled` and `freehandModeEnabled`; `en.json` has neither, and `app_localizations.dart:502-504` exposes both as `_localizedValues['key']!`. Toggling DrawLab's line mode in English throws today. Key counts: en 685, ar 686.
- **2026-09-18** — **Finding #7 confirmed.** Exactly five `insertScore` call sites plus the DAO definition: `feed_animal_cubit.dart:257`, `fruits_game_screen.dart:97`, `sorter_cubit.dart:227`, `quiz_cubit.dart:112`, `vegetables_game_screen.dart:92`.
- **2026-09-18** — Spec moved into the repo from `~/.claude/plans/spicy-fluttering-lynx.md` so it is reviewable any time. Two architecture amendments folded in rather than bolted on: (1) engine-native gameplay parameters replace the `level` 1–5 authoring API, with Easy/Medium/Hard surviving only in `LegacyActivityAdapter.mapDifficulty`; (2) Arabic literacy is a separate content and engine track, with `tracing`/`phonics`/`word_building`/`read_along` never bilingual by default, V1 restricted to bilingual-safe mechanics, and the seams (T029, T030, `TextAttempt`/`StrokeAttempt`) built in Phase 1 so literacy lands later without a rewrite.
