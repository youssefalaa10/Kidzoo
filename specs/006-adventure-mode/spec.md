# Feature Specification: Kidzo Adventures

**Feature Branch**: `[006-adventure-mode]`

**Created**: 2026-09-18

**Status**: Draft

**Input**: User description: "Replace the Challenge level map with an expandable learning-story platform. Story drives activities; activities move the story. Reuse existing activities but build reusable content-driven engines, never one-off games for one chapter."

## Summary

Kidzo today is ~24 unrelated mini-games reached from two flat grids (Games / Education) plus a "Challenge" level map of 18 stages. The Challenge map has no story — it is a sequence of drills with a background image behind it.

This feature replaces the Challenge experience with an expandable learning-story platform, and touches nothing else.

## Scope Boundaries

| Area | Change |
|---|---|
| Challenge / `LevelsMap` | **Fully replaced** by Adventure Mode |
| Games grid | Unchanged, independent, always accessible |
| Education grid | Unchanged, independent, always accessible |
| Free-play access | **Never gated by story progress.** No locks, no unlock-as-you-go |

## Direction

1. **A platform, not a wrapper.** Adventure Mode reuses existing activities *and* introduces new educational mechanics, built as reusable content-driven engines — never one-off games for one chapter.
2. **Story drives activities; activities move the story.** Not `story → game → game → reward`. The shape is: *story problem → meaningful learning activity → the result changes the story → new problem → next activity → climax → resolved ending*.
3. **Expandable content hierarchy** so Kidzo can grow for years without stretching one storyline.
4. **Reuse first**, but the current catalog must not cap the quality of future Adventures.
5. **Adventure 1 end-to-end is the V1 objective.** Validate that it feels good before building more. After that, new Adventures should be mostly content, not code.

## Product Architecture

```
Kidzo Adventures            (the permanent product)
  └── Story Arc / Season    ("The Lost Pages", then others)
        └── Adventure       (Jungle, Market, Ocean, Star)
              └── Node      (story beat | activity instance)
                    └── Activity Engine + authored content
```

"The Lost Pages" is **Arc 1**, not the permanent story. When it reaches a real ending, a new Arc ships with a different premise on the same platform. This is the most important structural decision here: it is what makes years of content possible without a story that overstays.

## Arc 1 — "The Lost Pages"

> The companion's storybook has come apart. Its pages blew into different worlds. Every page you bring back makes the book stronger — and the book is how you reach the next world.

The book is hub, progress meter, and reason to continue in one object. It gives a pre-literate child a spatial, non-numeric answer to *"how far am I?"*, and it is the classic frame story shape (Kalīla wa-Dimna, 1001 Nights) — a wrapper containing self-contained tales, which exists precisely because it scales by addition.

| # | Adventure | Backdrop (existing asset) | Page |
|---|---|---|---|
| 1 | **Jungle** | `jungle_mob` / `jungle-tab` | The Green Page |
| 2 | **Market** | `colorful_*` | The Golden Page |
| 3 | **Ocean** | `cloudy_*` (placeholder) | The Blue Page |
| 4 | **Star** | `tech_*` | The Last Page |

Each Adventure ends resolved, with the page recovered, the book visibly fuller, and a clue pointing onward.

### Required dramatic shape (enforced by test)

```
opening problem → discovery → obstacle → progress
                → climax → resolved ending → clue + page
```

Every chapter must declare these beats and every activity node must sit inside one. This is a **content contract**, not a guideline.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Playing Adventure 1 end to end (Priority: P1) 🎯 MVP

A child opens Adventures, meets the companion, learns the Green Page is lost in the jungle, and works through a sequence of story beats and learning activities until the page is recovered and the book is visibly fuller.

**Why this priority**: This is the whole thesis. If one Adventure does not feel like a story, no amount of additional content helps.

**Independent Test**: Install fresh, open Adventures, complete Adventure 1 without assistance.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the child opens Adventures, **Then** they see Adventure 1 available and the book with no pages recovered.
2. **Given** the child finishes an activity node, **When** the result is applied, **Then** the next story beat reflects what they just did — the animals speak a clue, the count *is* the number of clues collected, the maze *is* the trail.
3. **Given** the child answers every step wrong three times, **When** they reach the last step, **Then** the node still completes, the story still advances, and no "Game Over" or failure state is shown.
4. **Given** Adventure 1 is complete, **When** the child returns to the book, **Then** the Green Page is present and a clue points to the Market.

**The real test is a child.** Watch one play Adventure 1 unaided, then ask what happened in the jungle. If they narrate a story it worked. If they list games, it is not done.

### User Story 2 — Free play is never gated (Priority: P1)

A child or parent can open any game in the Games or Education grid at any time, regardless of story progress.

**Why this priority**: The existing product promise. Adventure Mode must add, not subtract.

**Independent Test**: With zero story progress, open every entry in both grids.

**Acceptance Scenarios**:

1. **Given** no Adventure has been started, **When** the child opens the Games grid, **Then** every game present today is present and launchable.
2. **Given** any story state, **When** a game is launched from a grid, **Then** no "Games can only be accessed through the Level Map" dialog appears.

### User Story 3 — Adding an Adventure is content, not code (Priority: P2)

An author adds a new Adventure by writing JSON files and dropping in art, with no Dart changes.

**Why this priority**: It is the difference between a platform and a wrapper, and it is what makes Phase 6 cheap.

**Independent Test**: Add a new counting activity in a new setting using only files under `assets/adventures/`.

**Acceptance Scenarios**:

1. **Given** a new activity file referencing an existing engine, **When** the app runs, **Then** the activity plays with no Dart change.
2. **Given** an activity file that sets a parameter its engine does not declare, **When** the content test runs, **Then** the build fails, naming the offending JSON path.

### User Story 4 — Arabic children get real Arabic, or nothing (Priority: P2)

Every activity a child reaches in Arabic is genuinely authored in Arabic. An activity that cannot yet be authored in Arabic is not reachable in Arabic.

**Why this priority**: Shipping English content inside an Arabic chapter is worse than shipping less content.

**Independent Test**: Switch to Arabic and complete Adventure 1.

**Acceptance Scenarios**:

1. **Given** the app is in Arabic, **When** the child plays Adventure 1, **Then** every prompt, hint and model line is Arabic, with full harakat.
2. **Given** an activity file declares a locale its engine does not support, **When** the content test runs, **Then** the build fails.

## Adventure 1 — Jungle, beat by beat

Every node has a narrative job, and the *result* of each activity causes the next beat.

| Beat | Story | Activity | Why it is causal |
|---|---|---|---|
| Opening problem | The Green Page is lost in the jungle. | *(story beat)* | — |
| Discovery | Ask the animals what they saw. | `multiple_choice` *(legacy: animal_quiz)* | Each correct answer makes an animal **speak a clue** |
| Obstacle | Count how many watchers are in the trees. | **`counting`** | The count **is** the number of clues you collect |
| Obstacle | The animals showed symbols on the trees — remember them. | *(legacy: memory_game, story symbols)* | The cards **are** the trail markers |
| Progress | Follow the symbols deeper in. | *(legacy: maze_game)* | The maze **is** the trail |
| Obstacle | A hungry animal blocks the path. | *(legacy: feed_animal_game)* | Already a "help this creature" game |
| Climax | Find the page hidden in the leaves. | **`hidden_clue`** | The search **is** the climax |
| Resolution | The page is torn — put it back together. | *(legacy: puzzle, page art)* | Literally rebuilding the page |
| Clue onward | On the mended page: a drawing of a busy market. | *(story beat)* | Sets up Adventure 2 |

Two new engines (`counting`, `hidden_clue`), one ported engine (`multiple_choice`), four legacy adapters.

## Success Criteria

- A child completes Adventure 1 unaided and narrates it back as a story, not a list of games.
- Adding an Adventure requires zero files under `lib/`.
- Games and Education grids contain exactly what they contain today, verified by regression test.
- Every child who reaches the last step of a node completes it, regardless of hints used.
- Adventure 1 is playable start to finish in both English and Arabic.
- Session length fits a 4–6 year old attention span: 5–10 minute Adventures of short sub-activities.

## Edge Cases

- App force-killed mid-Adventure: progress resumes at the last completed node.
- A content file references a missing asset: the content test fails the build; at runtime the host shows a content-error card rather than crashing.
- A child answers everything wrong: the no-fail ladder reaches `modelled` within three attempts and awards `minPointsPerStep`, never zero.
- Landscape and tablet: every board renders without overflow at 360×640, 780×390 and 800×1200.

## Out of Scope

- IAP, paywall UI, parent dashboard, analytics SDK. `StoryChapterProgress.isUnlocked` carries a future entitlement check; nothing is built.
- Arabic literacy engines — tracing, phonics, word building, read-along. See `research.md`.
- Fixing `lib/features/Alphabets/` (26 hardcoded English letters read aloud with the Arabic voice). Real bug, logged separately.
- Named routing. `lib/core/routing/app_router.dart` and `routes.dart` are both empty and stay that way; two parallel navigation systems would be worse than one imperative one.
