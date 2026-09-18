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
| 6 — Adventures 2–4 | not started (content only) | — | — |

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

## Phase 6: Adventures 2–4

*Expanded at the Phase 5 checkpoint.*

**Content only.** Any code change here is a signal Phases 1–3's abstractions were wrong — treat it as a finding, not a task.

---

## Notes and decisions

*Append dated entries as work proceeds. Newest first.*

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
