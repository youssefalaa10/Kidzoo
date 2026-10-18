# Quickstart: Adding an Adventure

## Overview

Adding an Adventure is **content, not code**. If you find yourself opening a file under `lib/`, stop — that is the signal something is wrong with the abstraction, not with your Adventure.

This guide covers adding a new activity to an existing Adventure, then adding a whole Adventure.

## The five directories

```
assets/adventures/
  manifest.json     every file, listed both ways
  arcs/             the season wrapper
  adventures/       one file per Adventure
  activities/       one file per activity instance
  packs/            reusable item sets (animals, fruits, ...)
```

**These five are fixed forever.** `pubspec` asset entries are non-recursive, so a new subdirectory would silently ship nothing — a test asserts none exists.

## Add an activity to an existing Adventure

### 1. Write the activity file

`assets/adventures/activities/market_count_fruit.json`:

```jsonc
{
  "schemaVersion": 1,
  "instanceId": "market.count_fruit",
  "engineId": "counting",
  "locales": ["en", "ar"],
  "presentation": { "backgroundType": "market", "accent": "#F2A65A" },
  "narration": {
    "prompt": { "en": "How many apples are on the cart?",
                "ar": "كَمْ تُفَّاحَةً عَلَى الْعَرَبَةِ؟" },
    "hint1":  { "en": "Touch each one and count with me.",
                "ar": "الْمِسْ كُلَّ وَاحِدَةٍ وَعُدَّ مَعِي." },
    "hint2":  { "en": "Let's count together: one... two...",
                "ar": "لِنَعُدَّ مَعًا: وَاحِد... اثْنَان..." },
    "model":  { "en": "There are four apples.",
                "ar": "هُنَاكَ أَرْبَعُ تُفَّاحَاتٍ." }
  },
  "payload": {
    "mode": "countAndPick",
    "targetCount": 4,
    "countRange": [2, 6],
    "layout": "tenFrame",
    "itemsRef": "packs/fruits",
    "itemIds": ["apple", "orange"],
    "roundCount": 5
  },
  "support": { "distractorCount": 2, "scaffolding": "errorless" },
  "adaptation": { "min": 2, "max": 6 },
  "elofGoal": "MATH.counting.cardinality",
  "prereqSkills": ["MATH.counting.rote_10"],
  "masteryThreshold": 0.8
}
```

**Write the gameplay parameters you actually mean.** `targetCount: 4`, not `"level": 2`. There is no difficulty tier — the validator rejects `level`, `difficulty`, `easy`, `medium` and `hard` outright. See [data-model.md](./data-model.md) §4 for each engine's parameters.

### 2. Reference it from the Adventure

In `assets/adventures/adventures/market.json`, add a node inside a beat:

```jsonc
{ "nodeId": "market.n3", "beat": "obstacle",
  "type": "activity", "activityRef": "activities/market_count_fruit" }
```

**Every activity node must sit inside a declared beat.** The beat sequence is a content contract, enforced by test:

```
opening problem → discovery → obstacle → progress
                → climax → resolved ending → clue + page
```

### 3. Register it in the manifest

`manifest.json` must match disk in **both** directions — a file not listed fails the test, and a listed file that does not exist fails too.

### 4. Run the content test

```bash
flutter test test/adventure/content_validation_test.dart
```

It walks every file from disk and checks: it parses; `engineId` is registered; the engine's own `parseContent` runs over it; every asset path exists *and* its directory is listed in pubspec; `locales ⊆ supportedLocales`; every `LocalizedText` covers every declared locale; no `{placeholder}` in an `ar` string without a `plural` block; every parameter is declared by the engine and in range; the manifest matches disk; no subdirectories below the five; and every chapter declares the full beat sequence.

Failures name the JSON path. Fix and re-run.

## Add a whole Adventure

1. `adventures/<id>.json` — the Adventure, its beats and nodes, and its `presentation` defaults.
2. One activity file per activity node.
3. A `packs/` file if the items are new.
4. Art into the existing asset directories, or a new one — **which needs a line in `pubspec.yaml`**,
   because asset entries are not recursive and a missing one ships nothing, silently.
5. Add the Adventure to `adventures` in `arcs/lost_pages.json`, **and delete its entry from
   `upcoming`**. An id in both fails the suite, and the two states are not interchangeable: a stop in
   `upcoming` renders as *coming soon* (a silhouette of something unwritten) and one in `adventures`
   as *locked* (a place the child reaches by finishing the one before it). Promoting a chapter
   changes which of those the map shows, so expect `story_continuity_test` to need its expectations
   updated in the same change.
6. Update `manifest.json` — the adventure, every activity **and** any new pack.
7. Run the content test, then play it.

**Still no Dart.** If a node needs behaviour no engine provides, that is a new-engine conversation (see the reuse ladder in [plan.md](./plan.md)), not an inline exception.

## Writing Arabic content

- **Author prompts whole, per locale.** Never assemble a sentence at runtime — Arabic number–noun agreement is irregular (3–10 take a broken plural; 11+ singular accusative), and the validator rejects a `{count}` placeholder in an `ar` string without an explicit `plural` block.
- **Full harakat, no exceptions**, in every Arabic string an early reader sees.
- **Check the engine supports Arabic first.** All eight shipped engines declare `{'en', 'ar'}`:
  `counting`, `sorting`, `multiple_choice`, `hidden_clue`, `code_path`, `balance_experiment`,
  `trace_path` and `patterns`. None of them holds glyph content of its own, which is what makes that
  claim honest rather than a box ticked — the wording around them is authored per locale. A future
  literacy-shaped engine would declare `{'en'}` until Arabic letterform content exists, and
  authoring an Arabic node against it would **fail the suite by design** — see
  [research.md](./research.md) §6.
- **Mirroring is a per-engine decision, not a global one, and some of it must NOT happen.**
  `code_path`'s arrows are spatial, so they are not mirrored: a mirrored arrow drives the cart the
  wrong way. A `patterns` ribbon lays out in the locale's direction, but the **unit order is never
  reversed** — a reversed pattern is a different pattern, and the answer would change. Both are
  pinned by tests rather than left to a content flag.

## Validation scenarios

### Scenario 1 — the new activity plays
1. `flutter run`, open Adventures, reach the node.
2. Verify the prompt is spoken before the board is interactive.
3. Answer correctly — verify the story beat that follows reflects the result.

### Scenario 2 — the no-fail ladder
1. Answer wrong three times on one step.
2. Verify: shake + `hint1`; then the set narrows to correct + 1 distractor + `hint2`; then the correct action is modelled and re-offered with only the correct option live.
3. Verify the node still completes and awards points — never zero, never a Game Over.

### Scenario 3 — Arabic
1. Switch to Arabic, replay the node.
2. Verify every line is Arabic with harakat, and that nothing falls back to English.
3. Verify scene pins did **not** move if `mirrorAnchorsForRtl` is false.

### Scenario 4 — layout
1. Rotate to landscape; repeat on a tablet.
2. Verify no overflow at 360×640, 780×390 and 800×1200.

## Success

If your Adventure plays start to finish in both languages, the content test is green, and you never opened a file under `lib/`, the platform is working as designed.
