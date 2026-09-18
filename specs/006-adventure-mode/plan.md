# Implementation Plan: Kidzo Adventures

**Branch**: `[006-adventure-mode]` | **Date**: 2026-09-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-adventure-mode/spec.md`

## Summary

Replace the Challenge level map with a content-driven learning-story platform. The bulk of the work is an **activity engine layer**: one shared host screen owning all chrome, a base cubit owning lifecycle and the no-fail ladder, and small engines supplying only a board and three methods. Adventures are then authored as JSON under `assets/adventures/` with no Dart changes.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `flutter_bloc` (state management), `drift` (persistence), `flutter_tts` + `audioplayers` behind the existing `Speech` facade, `flutter_animate` (the `lottie` asset dirs are empty)

**Storage**: Drift (SQLite) — schema v3

**Testing**: `flutter_test`; content validation runs from disk with no widget tree

**Target Platform**: Android, iOS (phone, tablet; portrait and landscape)

**Project Type**: Flutter Educational App

**Performance Goals**: 60 FPS; no board overflow at 360×640, 780×390, 800×1200

**Constraints**: Zero static state. Engines get no `BuildContext` and no `AppLocalizations`. Session length 5–10 minutes.

**Scale/Scope**: 6 engines in V1, 1 host screen, 1 base cubit, 4 legacy adapters, 4 Adventures (1 built end-to-end, 3 as content)

## Constitution Check

*GATE: Must pass before Phase 0. Re-check after Phase 1 design.*

- **I. Zero Static State**: ✅ Improves it. The registry is **injected** (`default_engines.dart`), unlike today's static `GameSequence` switch, and Phase 0 **deletes** `NavigationService` (a `factory` + `static final _instance` with mutable `_isNavigatingFromLevelMap`) and `LevelCompletionManager`, bringing `lib/core` to zero mutable-state singletons. `Speech` stays a static *facade* with no mutable game state; `ActivityNarrator` is an injected instance.
- **II. State Management via BLoC / Cubit**: ✅ `ActivityCubit<TContent, TStep>` base plus per-engine subclasses; story progress in its own cubit.
- **III. Class-Based Widgets Only**: ✅ Every board and shared widget is a `StatelessWidget`/`StatefulWidget`. No functional widgets.
- **IV. Drift as Persistence Layer**: ✅ Schema v3 adds `StoryNodeProgress`, `StoryChapterProgress`, `StoryRewards`, `ActivityAttempts`. The legacy `SharedPreferences` campaign keys are read once during migration, then retired.
- **V. Injected Services**: ✅ `ActivityServices` carries `narrator`, `soundboard`, `strings`, DAOs and an injected `Random`. No service is constructed inside an engine.
- **VI. Descriptive Naming**: ✅ `ActivityEngineDescriptor`, `NoFailCoach`, `ActivityHostScreen`, `LegacyActivityAdapter`.

**One conflict to resolve first**: `.agentrules` prescribes Riverpod, get_it, freezed and AutoRoute — none of which this codebase uses, and all of which contradict the constitution. Task T006 reconciles it before any engine code is written.

## Project Structure

### Documentation (this feature)

```
specs/006-adventure-mode/
├── spec.md
├── plan.md            <- this file
├── research.md
├── data-model.md
├── quickstart.md
├── tasks-progress.md  <- the task-progress ledger
└── checklists/requirements.md
```

### Source

```
lib/features/Adventure/
├── engine/
│   ├── contract/          ActivityEngine, ActivityCubit, ActivityAttempt,
│   │                      ActivityContent, ActivitySpec, descriptors
│   ├── host/              ActivityHostScreen, ActivityBoard, shared widgets
│   ├── support/           no_fail_coach.dart, activity_narrator.dart,
│   │                      activity_services.dart, localized_text.dart
│   ├── engines/           counting/ sorting/ drag_drop/ patterns/
│   │                      multiple_choice/ hidden_clue/
│   ├── adapters/          legacy_activity_adapter.dart + per-game adapters
│   ├── bespoke/           empty on day one; that is the point
│   └── default_engines.dart
├── story/                 arc/adventure/node models, AdventureMapScreen, book hub
└── data/                  content loader, story DAOs

lib/core/catalog/          GameCatalog, GameDescriptor

assets/adventures/
├── manifest.json
├── arcs/          lost_pages.json
├── adventures/    jungle.json  market.json
├── activities/    jungle_count_watchers.json  ...
└── packs/         animals.json  fruits.json
```

Five asset directories, **fixed forever**. New Adventures add *files*, never *directories* — `pubspec` asset entries are non-recursive, and a test asserts no subdirectory exists below these five.

## The activity engine layer

### Why the last attempt failed

`lib/features/QuizEngine/ui/quiz_engine_screen.dart` exists and is **never instantiated**. It is a fully closed layout with zero extension points — hard-coded `Scaffold`, `AppBar('Quiz')` with an English literal, `Color(0xfffaf5f1)`, plain `ElevatedButton`. No `KidGameShell`, no `KidMetrics`, no `KidResultView`, no haptics. Its one real consumer, `vehicles_game_screen.dart`, needed per-question scene composition, sound effects and a result view, so it wrote ~280 lines of its own layout over `QuizCubit` and ignored the screen.

> **The boundary was drawn in the wrong place.** The Cubit (state machine + scoring) *was* reused. The Screen was not, because it tried to share the **board** instead of the **chrome**.

Second cause: `QuizCubit` takes already-localized strings, so authoring happens in Dart. Once you are writing a Dart file anyway, writing a layout is a small increment. **Content-in-Dart is what makes bespoke screens cheap.**

### The split

```
ActivityHostScreen   (ONE screen, owns ALL chrome)        <- shared
   └── ActivityBoard (the interactive middle only)        <- per engine
         ^ driven by
ActivityCubit<TContent, TStep>  (base owns lifecycle; engine supplies 3 methods)
```

An engine returning a `Scaffold` or `AppBar` is a **test failure**. Full contracts in [data-model.md](./data-model.md).

### Engine set for V1 — six, not ten

The nine mechanics originally requested collapse onto six engines, because `sorting`, `drag_drop`, `patterns` and `logic` all crowd the same interaction mode. Building four near-identical engines is how a solo developer drowns.

| Engine | Covers | Locales |
|---|---|---|
| `counting` | counting, quantity matching | en + ar |
| `sorting` | sorting, classification | en + ar |
| `drag_drop` | generic matching, simple logic, most problem solving | en + ar |
| `patterns` | patterns, sequencing, story ordering | en + ar |
| `multiple_choice` | quiz-shaped activities (replaces `QuizCubit`) | en + ar |
| `hidden_clue` | find-the-object scenes | en + ar |

Deferred with reason, not dropped: `tracing`, `word_building`, `phonics`, `read_along` — all literacy-shaped, all requiring Arabic content that does not exist. See [research.md](./research.md).

### Reuse ladder — structural, not policy

1. **Reuse** — one JSON file, **zero Dart**. The default, because it is the only rung that never touches `lib/`.
2. **Adapt** — add payload fields, bump `schemaVersion`. A test asserts every field on an engine's content model is set to a non-default value by at least one activity file — dead knobs fail the build.
3. **New reusable engine** — new folder, descriptor, one line in `default_engines.dart`.
4. **Bespoke** — lives in `engine/bespoke/`, the shaming folder. Empty on day one.

The registry test is the teeth: **no two `reusable` engines may share the same `(learningDomains, interactionModes)` pair**, failing with *"duplicate capability — extend `counting` with content instead."*

## Phases

| Phase | Goal | Definition of done |
|---|---|---|
| **0** | Gate removal, catalog, contract prep | Grids pixel-identical; all 6 campaign games still launch; no mutable statics in `lib/core` |
| **1** | Engine contract, **no engines** | `EchoEngine` (test-only) runs end-to-end through the host; all architecture tests green |
| **2** | `counting` — the first engine | Three content files — jungle, market, space — on the same engine, zero Dart difference |
| **3** | `sorting` — the second, deliberately | Port `FruitVegSorterGame` and diff. **If reproducing it costs more than the original, the abstraction is wrong** |
| **4** | Adventure 1 end-to-end | A child can explain what happened in the jungle and why each activity mattered |
| **5** | Polish + real scores | Adventure 1 tuned; each old `insertScore` deleted in the same PR that adds the central writer |
| **6** | Adventures 2–4 | **Content only.** Any code change here is a signal Phases 1–3 were wrong |

Task-level breakdown and live status: [tasks-progress.md](./tasks-progress.md).

## Changes to existing systems

**Activity catalog.** One injected `GameCatalog` replaces the three disconnected registries. **`activityId` == `GameScores.gameKey`**, so history stays joinable; the five historical keys are preserved verbatim (`feed_animal_game`, `fruit_veg_sorter`, `vehicles_game`, `fruits`, `vegetables`). Descriptors carry `titleLocalizationKey` (a key, not a resolved String — makes the catalog context-free) and a **lazy** `screenBuilder`. `surface` drives grid membership, so Games/Education keep their exact current contents.

**The gate.** Delete `navigation_service.dart`, `protected_game_screen.dart`, `LevelCompletionManager`. Net deletion. Each of the 6 subclasses becomes a plain `StatefulWidget` with an identical public API — **keep init in `didChangeDependencies` behind the existing one-shot latch**, because `animal_quiz_screen.dart`'s `onGameInit()` reads `context`.

**Drift v3.** New tables `StoryNodeProgress`, `StoryChapterProgress`, `StoryRewards`, `ActivityAttempts`. `GameScores` gains nullable `maxScore`, `starsEarned`, `durationSeconds`, `storyNodeId`, and `level` finally gets written. `Profiles` gains `hasMigratedLegacyCampaignProgress`. Pure-add migration. **Leave `Profiles.totalPoints` dead** — it is a denormalization of a sum `ProfileAnalyticsCubit` already computes correctly.

**Localization.** Two non-breaking helpers, no existing getter changes:

```dart
String resolve(String key, {String? fallback}) => _localizedValues[key] ?? fallback ?? key;
bool hasText(String key) => _localizedValues.containsKey(key);
```

`resolve` deliberately does **not** throw, unlike the 567 existing getters, because content keys are data, not code.

**Migration.** Everyone starts at Adventure 1. Since free play is not gated, no access is lost, so no compensating unlock is needed. Keep the old prefs keys for one release so a bad migration is recoverable by clearing a flag.

**Monetization — architecture only, nothing built.** Adventure boundaries are natural gates by construction. Recovered pages stay free and non-scarce — no rarity, no RNG, no paywalled collectibles. *Apple Kids Category note:* it forbids third-party analytics and ads and is a one-way door; there are zero third-party SDKs today, so it is cheap now and expensive later.

## Verified findings (checked against the code; several contradict existing docs)

1. **`test/level_progression_test.dart` is already failing** — it asserts `getGameTypeForStage(3) == puzzle` and a 12-stage/4-game cycle; the code ships **18 stages in a 6-game cycle** (stage 3 is `colorMemoryGame`). Baseline `flutter test` first.
2. **`lib/features/LevelsMap/README.md` is stale** (documents the old 12-stage design).
3. **A live crash:** `en.json` lacks `freehandModeEnabled` and `straightLineModeEnabled`, yet `drawlab_screen.dart:1572-1573` calls those getters, which are `_localizedValues['key']!`. **Toggling DrawLab's line mode in English crashes today.** Two-line fix, folded into Phase 0 — and exactly why content strings use non-throwing lookup.
4. **`AlphabetModel.alphabets` is a hardcoded list of 26 English letters** with a 26-case `switch` for localization. An Arabic-speaking child opening "Alphabet" sees English letters read aloud in Arabic. **No Arabic letterform assets exist anywhere** in the project.
5. **`NavigationService` will block every legacy activity node.** Every legacy game extends `ProtectedGameScreen`, which shows *"Games can only be accessed through the Level Map"* and pops. Hard prerequisite, not cleanup.
6. **`onGameInit()` bodies read `context`** — `animal_quiz_screen.dart` calls `AppLocalizations.of(context)` and `Localizations.localeOf(context)` in `didChangeDependencies` behind a one-shot latch. **Moving it to `initState` will crash.** Highest-probability breakage.
7. **Five `insertScore` call sites**, not one writer: `feed_animal_cubit.dart:257`, `fruits_game_screen.dart:97`, `sorter_cubit.dart:227`, `quiz_cubit.dart:112`, `vegetables_game_screen.dart:92`. Centralizing without deleting these **doubles every score row**.
8. **Content-as-closures is everywhere** — `String Function(AppLocalizations)` in sorter, feed, vehicles, alphabet. **Not serializable.** Every port replaces it with `LocalizedText`.
9. **Eager widget construction in three places:** `OptionItem.screen` (18 screens per grid rebuild), `character.dart:71`, `levelmap_screen.dart:101`.
10. **`.agentrules` contradicts the constitution** — prescribes Riverpod, get_it, freezed, AutoRoute, none of which this codebase uses.
11. **`assets/gen/lottie/` and `assets/gen/gif/` are empty** while `lottie` is a dependency. The no-fail `modelled` animation must degrade to `flutter_animate`.
12. **`sqlite3` is only a transitive dependency** — needs to be explicit (with `sqlite3_flutter_libs`) before any Drift in-memory or migration test.
13. `lib/core/routing/app_router.dart` and `routes.dart` are **both empty**.
14. **Zero `Directionality` / `TextDirection` usages in `lib/`** — RTL is entirely implicit via `GlobalWidgetsLocalizations`. Adventure Mode is the first thing in the app that genuinely needs explicit direction control.

## Risks

| Risk | Containment |
|---|---|
| **Over-generalising with ten engines and one developer.** The likeliest failure. | Six engines in V1; the registry uniqueness test surfaces crowding mechanically |
| **`payload` is untyped by necessity**, so all safety comes from `parseContent` + the content test | **Write the content test before the second engine.** Non-negotiable ordering |
| Adventure Mode leaks into free play | `surface` drives grid contents; a regression test asserts today's contents exactly |
| Engines grow their own screens (the `quiz_engine_screen` failure, repeated) | Grep tests forbid `Scaffold`/`AppBar`/`MediaQuery` in `engines/**` |
| Catalog work balloons into 24 game refactors | Phase 0 touches zero files under `lib/features/<Game>/` beyond mechanical de-protection |
| `NavigationService` blocks legacy nodes on integration day | Deleted in Phase 0, before any engine exists |
| `ActivityAttempt` variant creep | Hard cap of eight; a ninth needs new-engine-level scrutiny |
| Story stays a wrapper | `beat` is mandatory and test-enforced; Phase 4 has a behavioural DoD; the child test is the real gate |
| Double score rows | Phase 5 deletes each `insertScore` in the same PR that adds the central writer |
| Narration bloat — child listens more than plays | Hard budget ≤2 sentences / ≤8s per beat, always skippable |
| Adventures 2–4 need code | Treat as a signal the abstractions were wrong, not as a task |
| Drag-only interactions exclude the youngest users and breach WCAG 2.2 SC 2.5.7 | `allowTapToSelect` is on the base contract, defaulted on; an engine cannot opt out |
| Touch targets sized for adults — `KidUi.minTouch = 76` is below the 2cm young-child guidance | Add `KidUi.minTouchYoung` (~112) for primary engine targets |
| **Difficulty tiers creep back in as the authoring API** | The content validator rejects the tokens `level`/`difficulty`/`easy`/`medium`/`hard` in any activity file |
| **An engine is marked bilingual because the UI is bilingual**, shipping English inside an Arabic chapter | `supportedLocales` defaults to `{'en'}` for literacy-shaped engines; the content test asserts `locales ⊆ supportedLocales` and full per-locale coverage |
| **Adding the first Arabic literacy engine forces a contract change** | `TextAttempt`/`StrokeAttempt`, `GlyphRun` and `ActivityGlyphText` all exist from Phase 1 with no consumer |

## Open before content authoring

- **The companion's name** and **the book's name** — both appear in every narration line.
- **Arc 1 ending** — what happens when the book is whole, and what Arc 2 is about.
- **Digit system per market** — Eastern Arabic-Indic vs Western, with Egypt mixed.
