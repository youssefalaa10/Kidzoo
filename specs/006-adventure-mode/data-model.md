# Data Model: Kidzo Adventures

## 1. Engine contract

```dart
abstract class ActivityEngine<TContent extends ActivityContent> {
  const ActivityEngine();
  ActivityEngineDescriptor get descriptor;
  TContent parseContent(ActivitySpec spec);      // throws with a JSON path
  Iterable<String> assetsFor(TContent content);  // precache
  ActivityCubit createCubit(ActivitySession<TContent> session);
  ActivityBoard createBoard();                   // the board ONLY
}

@immutable
class ActivityEngineDescriptor {
  const ActivityEngineDescriptor({
    required this.engineId,
    required this.kind,                // reusable | adaptedLegacy | bespoke
    required this.learningDomains,
    required this.interactionModes,
    required this.contentParameters,   // the engine-native parameters it accepts
    required this.adaptationAxis,      // which parameter the adaptive nudge steps
    required this.supportedLocales,    // {'en'} for literacy-shaped engines
    required this.schemaVersion,
    required this.justification,       // required non-empty when kind == bespoke
  });
}
```

An engine implements **three methods**; the base cubit owns everything else.

```dart
abstract class ActivityCubit<TContent extends ActivityContent,
                             TStep extends ActivityStep>
    extends Cubit<ActivityState> {
  List<TStep> buildSteps();                                   // once, may use injected Random
  ActivityJudgement judge(TStep step, ActivityAttempt a);     // PURE - no emit, no await
  ActivityStepView describe(TStep step, ScaffoldLevel level);

  // base provides (final): step cursor, attempt counting, no-fail escalation,
  // scoring, narration sequencing, isClosed guards, persistence, result assembly
}
```

`ActivityServices` deliberately exposes **no `BuildContext` and no `AppLocalizations`** — engine cubits are unit-testable with no widget tree. It carries `narrator`, `soundboard`, `strings`, `attemptsDao`, `gameScoresDao`, `profileDao`, and an injected `Random` so every generation test is deterministic.

## 2. Attempt types — one per interaction, hard cap of eight

```dart
sealed class ActivityAttempt {}
class ChoiceAttempt    extends ActivityAttempt { final String optionId; }
class PlacementAttempt extends ActivityAttempt { final String tokenId, targetId; }
class SequenceAttempt  extends ActivityAttempt { final List<String> orderedTokenIds; }
class QuantityAttempt  extends ActivityAttempt { final int value; }
class TextAttempt      extends ActivityAttempt { final List<String> graphemes; }
class TapPointAttempt  extends ActivityAttempt { final Offset normalized; }
class StrokeAttempt    extends ActivityAttempt { final List<Offset> points; final int strokeIndex; }
```

`TextAttempt` and `StrokeAttempt` ship in Phase 1 **with no consumer**. They exist so that adding the first literacy engine is not a change to the shared contract. A ninth variant deserves the same scrutiny as a new engine — it means engines are leaking internals into the shared contract.

## 3. Content schema

Five asset directories, fixed forever:

```
assets/adventures/
  manifest.json
  arcs/         lost_pages.json
  adventures/   jungle.json  market.json
  activities/   jungle_count_watchers.json  market_count_fruit.json
  packs/        animals.json  fruits.json
```

### Activity envelope

```jsonc
{
  "schemaVersion": 1,
  "instanceId": "jungle.count_watchers",
  "engineId": "counting",
  "locales": ["en", "ar"],
  "presentation": { "backgroundType": "jungle", "accent": "#4AC49A" },
  "narration": {
    "prompt": { "en": "How many animals are watching?", "ar": "..." },
    "hint1":  { "en": "Touch each one and count with me.", "ar": "..." },
    "hint2":  { "en": "Let's count together: one... two...", "ar": "..." },
    "model":  { "en": "There are three.", "ar": "..." }
  },
  "payload": {
    "mode": "countAndPick",
    "targetCount": 5,
    "countRange": [2, 5],
    "layout": "scatter",
    "itemsRef": "packs/animals",
    "itemIds": ["monkey", "parrot"],
    "roundCount": 5
  },
  "support": {
    "distractorCount": 2,
    "scaffolding": "errorless"
  },
  "adaptation": { "min": 3, "max": 7 }
}
```

**The same `counting` engine counts animals in the Jungle, fruit in the Market and stars in Space by swapping `itemsRef` + `itemIds` + `presentation`. The engine never names a domain** — that is the invariant the registry test protects.

Narration is **inline per-locale `LocalizedText`**, not keys into `app_localizations`. That is how hundreds of story strings ship without touching the 567-getter file.

```dart
@immutable
class LocalizedText {
  String resolve(String languageCode);            // falls back to 'en', then ''
  factory LocalizedText.fromJson(Object? json);   // bare String or {locale: text}
}
```

Merge order, unit-tested per layer:
`engine defaults → activity file → adventure presentation → node override → per-profile adaptive nudge`.

## 4. Configuration — engine-native parameters, not difficulty tiers

> **The story author configures the experience, not an abstract Easy / Medium / Hard tier.**

### The rules

1. **Gameplay is configured directly, in engine-native names, inside `payload`.** The author writes `pairCount`, `gridSize`, `maxNumber`, `targetCount`, `clueCount` — the thing they actually mean.
2. **Only genuinely cross-cutting settings are universal**, and they live in a separate `support` block: `distractorCount`, `scaffolding`, `tolerance`, `timeLimitSeconds`. These are inputs the **base** cubit and `NoFailCoach` own, not difficulty tiers — `distractorCount` *is* Terrace's errorless-fading procedure expressed as data.
3. **`level` does not exist in the authoring schema.** No `difficulty.level`, no `easy`/`medium`/`hard`, anywhere under `assets/adventures/`.
4. **Easy/Medium/Hard survives in exactly one place:** `LegacyActivityAdapter.mapDifficulty`, which converts an authored native parameter into whatever `int level` or per-game enum a legacy screen still expects. It is a compatibility shim carrying a deprecation note, not an API.
5. **The validator fails a file** that sets a parameter the engine does not declare, sets one out of range, or omits a required one — so "make this harder" can never silently do nothing.

### Adaptive nudge

Each engine declares an ordered `adaptationAxis` — the single parameter the adaptation steps along. The nudge moves one step for the *next* node of the same engine, bounded by the activity file's `adaptation.min` / `adaptation.max`, per profile. **Never mid-activity** — changing difficulty under a child's hands is disorienting.

### Parameters per activity

| Activity | `adaptationAxis` | Native parameters | Hardcoding it replaces |
|---|---|---|---|
| `counting` *(new)* | `targetCount` | `targetCount`, `countRange`, `layout`, `giveN`, `roundCount` | — |
| `hidden_clue` *(new)* | `clueCount` | `clueCount`, `cluePlacements[]`, `visualNoise`, `revealOnIdleSeconds` | — |
| `patterns` | `stepCount` | `unitLength`, `repetitions`, `taskType`, `verbalLabelEnabled` | — |
| `sorting` | `binCount` | `binCount`, `activeAttributes`, `heldConstant`, `itemsPerRound` | `FruitVegSorterGame` constants |
| `drag_drop` | `tokenCount` | `tokenCount`, `targetCount`, `pairing` | — |
| `multiple_choice` | `optionCount` | `optionCount`, `roundCount`, `itemPoolSize` | `animal_quiz_screen.dart:177-196` — `switch (level)` → pool 5/8/12 |
| memory *(adapter)* | `pairCount` | **`pairCount`** | `memory_game.dart:108-121` — switch → 4/8/10 |
| puzzle *(adapter)* | `pieceCount` | **`pieceCount`** — see caveat | `puzzle_screen.dart:30` computes `gridSize` then **discards it** |
| math *(adapter)* | `maxNumber` | **`maxNumber`**, `minNumber`, `operation` | `math_game_cubit.dart:17-23` → 10/20/30 and 1/5/10 |
| maze *(adapter)* | `gridSize` | `gridSize`, `requiredStars`, `timeLimitSeconds` | `MazeDifficulty` enum → 5/7/12 |
| color memory *(adapter)* | `initialSequenceLength` | `gridSize`, `colorCount`, `initialSequenceLength`, `timePerStep`, `maxRounds` | already a real config object |

### Two findings that make this cheap

- **`ColorMemoryGame`'s `LevelConfig`** (`lib/features/ColorMemoryGame/data/models/color_memory_constants.dart:133-184`) is the existing in-repo precedent for this whole model — a real config object with named gameplay fields. Generalize its shape; `LevelConfig.forLevel(level)` becomes adapter-only.
- **`difficultyLevel` is already nearly dead.** There is no `DifficultyLevel` enum. It is an `int` field on `Level` (`lib/features/LevelsMap/Data/Logic/Model/level_model.dart:13,20`), computed by `GameSequence.getDifficultyLevel`, **dropped by `copyWith`**, and **never read by any game** — games receive a plain `int level` from `GameSequenceItem.create`. It dies with `LevelsMap/` in Phase 4, so there is very little legacy debt to carry forward.

### Puzzle caveat — not papered over

Honouring an arbitrary `gridSize` means slicing arbitrary images into N pieces: real work, not a rename. Today the piece count is a property of the chosen image (`lib/features/Puzzle/bloc/cubit.dart:12-66` → 4, 4, 9). V1 exposes `pieceCount`, validated against what the bundled images actually support. Generalising the slicer is a later task.

## 5. No-fail feedback contract

Lives in `engine/support/no_fail_coach.dart`, owned by the **base** cubit. No engine implements escalation.

| Attempt | Level | Behaviour |
|---|---|---|
| 1 wrong | `gentleRetry` | Shake the card (`KidCardState.wrong`), `wrong.mp3`, speak `hint1`. Nothing removed. |
| 2 wrong | `narrowed` | Narrow to correct + 1 distractor; others fade to `KidCardState.done` (**keeps its slot, so the tray does not reflow under a finger** — that behaviour already exists). Speak `hint2`. |
| 3 wrong | `modelled` | Animate the correct action, speak `model`, then **re-offer the same step with only the correct option live** so the child performs it. Award `minPointsPerStep` — never zero. |

Never-zero is already the house rule (`kSorterMinRoundScore = 4`).

**`completion == completed` for every child who reaches the last step, regardless of hints.** The story reads only `completion`. `stepsIndependent` / `hintsUsed` / `masterySignal` feed the parent report and adaptation, and **never branch the story**.

**Telemetry separates motor error from knowledge error.** Flutter's `onWillAcceptWithDetails`/`onAcceptWithDetails` carry the drop offset, so `wrongSlotButRightItem` (missed the target) is distinguishable from `wrongItem` (chose wrong). **Never conflate these** — one means the child needs bigger targets, the other means they need more teaching. Both feed `ActivityAttempts`.

## 6. Localization and script

`LocalizedText` covers every declared locale or the content test fails — no silent English inside an Arabic chapter.

**Two schema hooks handle the real RTL cases:**

- `sequenceDirection: "reading" | "fixed"` — a pattern strip should read the way the child reads; a number line should not mirror.
- `mirrorAnchorsForRtl: false` — mirroring a painted jungle looks wrong; mirroring an abstract tray does not.

| Element | Mirror in Arabic? | Why |
|---|---|---|
| Patterns, story-sequence panels | **Yes** — item 1 rightmost | Read like text or a comic |
| Sorting bins, trays, chrome | **Yes** | Layout |
| Number line, ten-frame fill order | **No** | Math notation, not text. Numerals are LTR-invariant inside RTL text |
| Glyphs themselves | **Never** | Only the stroke start side and layout change |

**`GlyphRun` (reserved in Phase 1, unused in V1).** Literacy content is authored as a **pre-composed, pre-shaped glyph run** carrying its own stroke decomposition — never assembled at runtime from per-letter glyphs. Six letters (ا د ذ ر ز و) are right-joining only, and lam-alef (لا) is a mandatory fused ligature. Reserving the shape now means the loader does not change when literacy arrives.

All script-sensitive text renders through **`ActivityGlyphText`**, never raw `Text` inside a board, so Naskh face, harakat and shaping become a one-file change.

**Counting has one real trap:** Arabic number–noun agreement is irregular (3–10 take a broken plural; 11+ singular accusative). The solution is schema, not code: **no runtime sentence assembly — prompts are authored whole.** The validator rejects a `{count}` placeholder in any `ar` string without an explicit `plural` block.

Digits are locale-configurable and formatted host-side, never hardcoded per engine: Eastern Arabic-Indic ٠١٢٣ for Mashreq/Gulf, Western 0123 for Maghreb, Egypt mixed.

**Vowelisation is settled:** always render harakat for ages 3–8. Full tashkeel, no exceptions, in every Arabic string an early reader sees.

## 7. Persistence — Drift schema v3

Pure-add migration.

### New tables

**`StoryNodeProgress`** — `id`, `profileId`, `nodeId`, `completion` (enum), `stepsIndependent`, `hintsUsed`, `completedAt`

**`StoryChapterProgress`** — `id`, `profileId`, `chapterId`, `isUnlocked` (carries a future entitlement check), `startedAt`, `completedAt`

**`StoryRewards`** — `id`, `profileId`, `rewardId` (the recovered pages), `earnedAt`

**`ActivityAttempts`** — per-step mastery telemetry that `GameScores` cannot hold: `id`, `profileId`, `activityId`, `stepIndex`, `attemptIndex`, `outcome` (`correct` | `wrongItem` | `wrongSlotButRightItem`), `scaffoldLevel`, `elapsedMs`, `recordedAt`

### Changed tables

**`GameScores`** gains nullable `maxScore`, `starsEarned`, `durationSeconds`, `storyNodeId`; `level` finally gets written. **`activityId` == `gameKey`**, so history stays joinable and the five historical keys are preserved verbatim.

**`Profiles`** gains `hasMigratedLegacyCampaignProgress`. **`Profiles.totalPoints` stays dead** — it is a denormalization of a sum `ProfileAnalyticsCubit` already computes correctly.

## 8. Sequencing metadata

Every activity file carries `elofGoal`, `prereqSkills[]` and `masteryThreshold`, so progression can be topologically sorted rather than hand-ordered. Anchored to the **Head Start ELOF** framework rather than an invented taxonomy.
