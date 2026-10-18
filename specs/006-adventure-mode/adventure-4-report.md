# Adventure 4 — Up Among the Stars — implementation report

**Date**: 2026-09-29 · **Branch**: `story-line`
**Baseline**: 676 passing, **27 failing** (see §1). **Final**: **all passing**, `flutter analyze`
0 errors / 0 warnings, and no analyzer finding in any file this work added or touched.

---

## 1. The baseline was red, and why

The last commit added a seventh Ocean activity, `ocean.n7b` → `ocean_spot_the_wall`, that was never
finished: it was not in `manifest.json`, both images it named (`assets/gen/images/ocean/wall_a.png`,
`wall_b.png`) did not exist, the e2e driver had no answer for its engine, and its story ("the shell is
the one holding the page") contradicted the chapter around it. Every Ocean and arc test failed on it.

At the user's direction it was **removed**: the node from `ocean.json` and the activity file. The Ocean
is back to the six activities its own tests describe. The `spot_the_diff` engine it introduced was kept
— and repaired, §4 — because Adventure 4 has the story that engine was waiting for.

## 2. Research → ideas → what was chosen

The brief ruled out reskins of counting, sorting, drag-and-drop, patterns and quizzes, and asked for
discovery, experimentation, cause and effect and mystery. Candidates were held to the registry's own
rule: a new engine must claim a `(learningDomains, interactionModes)` pair nobody else has, and be
plausible in five themes.

| Idea | Verdict | Why |
|---|---|---|
| **Light and shadow** — slide an object between a light and a wall | **Built: `shadow_play`** | PBS's *Shadow Shapes* (PEEP) is exactly this for K–2, and "closer to the light, bigger the shadow" is the standard preschool shadow experiment. Nothing in the app has a continuous input whose effect shows somewhere other than under the finger |
| **Colour mixing** — combine to make a target | **Built: `mix_lab`** | Parts vanish into a whole; the same ink is right in one round and wrong in the next. Not `sorting` (where), not `balance` (how many) |
| **Deduction by elimination** — clues rule suspects out | **Built: `deduction`** | The *Guess Who?* / *Outfoxed!* (ages 5–8) shape. The child never picks the answer; it is what the clues leave. This is the mystery the brief asked for, and it is the climax |
| Mirror / beam reflection | Rejected | Rotating mirrors then watching light go is `current_rider`'s `spatialReasoning | setDirection`. The collision is correct — it is the same mechanic |
| Constellation dot-to-dot | **Content on `trace_path`** | Iconic for the setting and already an engine; used one rung harder than the Ocean (numbers, no road) |
| Compare tonight's sky with a picture | **Content on `spot_the_diff`** | Repaired engine, first real chapter |
| Orbit / gravity slingshot | Rejected | Real-time aiming is a reflex mechanic and fights the no-fail rule |
| Lights-out style switch panel | Deferred | Inductive rule-finding is real, but a switchboard in the sky has no story reason |

Sources: [PBS LearningMedia — Shadow Shapes](https://www.pbslearningmedia.org/resource/buack2-sci-shadowshapes/shadow-shapes/),
[Science Sparks — shadow activities](https://www.science-sparks.com/shadow-activity-ideas/),
[Rhythms of Play — shadow activities](https://rhythmsofplay.com/educational-shadow-activities-for-kids/),
[BoardGameGeek — deduction games for kids](https://boardgamegeek.com/thread/2636451/deduction-games-for-kids),
[Enjoy Teaching — logic puzzles for kids](https://enjoy-teaching.com/logic-puzzles-for-kids/).

## 3. The chapter

**The mystery.** Above the clouds the stars are going out, one by one. **Suha** (سُهَى — in Arab
tradition the faint star in the Great Bear that tests keen eyes) saw "something flat and dark" slide
past. Every activity answers the question the one before it raised.

| Node | Beat | Engine | The question it answers | What the child leaves with |
|---|---|---|---|---|
| n1 | openingProblem | — | Stars are going out | — |
| n2 | discovery | `spot_the_diff` | **What** is happening? | Four stars missing *in a line*: something moved through |
| n3 | obstacle | **`shadow_play`** | **Why** do stars go dark? | Something in front of a light covers what is behind it — and the last shadow is a page |
| n4 | progress | — | "Nobody is stealing the stars. Something as big as a page is passing in front." | — |
| n5 | obstacle | **`mix_lab`** | **Who saw it?** | Three relit stars, three clues: above the clouds · a long shining tail · cold as ice |
| n6 | obstacle | `trace_path` | **How** do we get up there? | A path of the relit stars to the crossing |
| n7 | climax | **`deduction`** | **Who has it?** | Owl, kite ✗ (not high) · saucer, satellite ✗ (no tail) · dragon ✗ (breathes fire) → the comet |
| n8 | resolution | — | The comet never took the page; it caught on its tail. **The Silver Page** | reward |
| n9 | clueOnward | — | The comet saw every page fly on one wind — and the wind came from somewhere | → Adventure 5 |

**The chain is literal, and tested.** The last shadow round casts the page; the clue labels of the
climax quote the relit stars *by the colour the child made* ("The orange star said…"), and a test
fails if the mix rounds and the clues are reordered apart. **The mystery holds**: a test asserts the
word "comet" is first spoken in the line that solves it, in both languages.

**The child resolves it.** Suha shines, carries and reports; she never works anything out.

**Five activities, not six.** Each of these asks the child to try something before answering, so each
takes longer to think through than an Ocean activity. Five lands inside eight to twelve minutes with
the beats — worth timing with a real child (§8).

**No interaction repeats**, no activity is a `chooseOne`, and the chapter both reuses engines
(`trace_path`, `spot_the_diff`) and brings new ones — all asserted.

## 4. `spot_the_diff`, repaired

The engine shipped with four defects, each of which would have broken this chapter:

1. **Correct taps judged wrong.** Each step precomputed its "already found" set from a *shuffled*
   order, so a child who found the second difference first was later told a right answer was wrong.
   Progress now lives in the cubit, through a new contract hook (below), and any unfound spot is
   right on any step. Test: finding all four in reverse is four independent steps.
2. **The answers were drawn on screen.** A pulsing ring sat on every unfound spot from the first
   frame. Now nothing is marked until the child asks for help: a wide halo at the first hints, a
   tight ring when modelled.
3. **Coordinates did not land on the art.** Panels used `BoxFit.cover`, which crops by aspect ratio,
   so authored fractions pointed at different pixels on every screen. Panels are now square, side by
   side or stacked (whichever is bigger), and a pixel test proves every authored spot is where the two
   pictures differ and that they differ nowhere else.
4. **The instruction was repeated after every find.** The next step's spoken prompt is now the find
   just announced, which the cubit already de-duplicates to silence.

Missed taps are **not judged** — a local ripple only. Judging them would let random tapping walk the
ladder to a free credit; the help button and idle nudge are the route to hints.

**Contract change: `ActivityCubit.onStepCompleted`.** A protected hook called once when a step finishes
(correct, or credited after modelling), before its reveal is spoken; returning true re-describes the
view so the reveal is the one for what the child actually did. It exists for engines whose steps are
answered in the child's order — `spot_the_diff` and `deduction` both need it — and pairs with the
existing `captureResumePayload` so that order survives an interruption. Existing engines do not
override it and are unchanged.

## 5. The three new engines

Two new `LearningDomain`s (`causeAndEffect`, `logic`) and three new `InteractionMode`s (`slideToAdjust`,
`combine`, `eliminate`), each documented against the mode it would otherwise have been confused with.
All three keys are unique; the registry test passes with no exemptions.

### `shadow_play` — `causeAndEffect | slideToAdjust`
Two views that move together: the wall face-on (the outline to fit, the shadow, the stars behind it
disappearing) and the track side-on (light, object, the cone and the dark wedge the object cuts from it).
The shadow's size is point-light optics, `size × (light→wall ÷ light→object)`. Dragging, tapping the
track and the arrows **only move** the object; the shine button answers. Near-misses are the motor
verdict. Parser refusals: every round moving the same way (a habit, not a rule); a round starting
within reach of its answer; two consecutive rounds with the same answer; a target off the track.
From narrowed onward the arrow pointing the right way glows — a direction, never a position.

### `mix_lab` — `causeAndEffect | combine`
Ink in, ink out, the vessel recolours live (an implicit `TweenAnimationBuilder` — no controller), one
commit. The colour table is **authored and must be complete** — every non-empty combination declared —
because a child experimenting will make all of them. Refused: missing combinations, two results of one
colour (the target would be ambiguous), a round nobody needs to mix for. The ladder never removes an
ink (a child who cannot use the wrong ones cannot learn they are wrong); it points at the right ones.
Paint mixing rather than light mixing, and framed as *stardust*, so the story never claims physics it
is not doing.

### `deduction` — `logic | eliminate`
Clues arrive one at a time; past ones stay on screen as chips so the reasoning is laid out. One step
per card a clue rules out, so help is per decision. Tapping a card the clue *keeps* shakes it and shows
the clue's picture on it — the reason it stays. A card the *next* clue rules out is not yet out: apply
the clue you have. **The parser proves the puzzle before anyone plays**: every candidate carries every
attribute a clue asks about, every clue rules someone out, none rules everyone out, and exactly one
survives. The answer is derived, never authored, so it cannot disagree with the clues.

**Suspects chosen to be checkable against the picture.** A balloon was dropped (its string reads as a
tail); a rocket was dropped (its small flame reads as a tail to some children and not others). An
ambiguous card makes a careful child wrong. The dragon is the best wrong suspect on purpose: high,
long-tailed, and out on the one fact every child knows.

## 6. Assets

All new art is in `assets/gen/images/stars/` (one new pubspec line) plus two plates and one page. Every
item is referenced by path from `packs/sky.json` or an activity file, so each is replaceable by editing
content.

| File | Source | Licence | Changes |
|---|---|---|---|
| `stars/suha.png` | Microsoft Fluent Emoji — *Glowing star* (3D) | MIT | none |
| `stars/comet.png` | Fluent Emoji — *Comet* | MIT | **recoloured** red → icy blue (HSV hue shift), because the third clue is "cold as ice" |
| `stars/owl.png` `kite.png` `flying_saucer.png` `satellite.png` `dragon.png` | Fluent Emoji — *Owl*, *Kite*, *Flying saucer*, *Satellite*, *Dragon* | MIT | none |
| `stars/cloud.png` `maple_leaf.png` `page.png` | Fluent Emoji — *Cloud*, *Maple leaf*, *Page facing up* | MIT | none |
| `stars/sparkles.png` `snowflake.png` | Fluent Emoji — *Sparkles*, *Snowflake* | MIT | none |
| `stars/star_vessel.png` | derived from Fluent *Glowing star* | MIT | converted to white, shading kept as luminance, so a modulated colour still reads as a rounded star |
| `stars/sky_as_drawn.png` `sky_tonight.png` | generated for this project | project-owned | one painter; the second omits four stars on one curve |
| `stars/sky_wall.png` | generated | project-owned | — |
| `backgrounds/stars_mob.png` `stars_tab.png` | generated | project-owned | same pixel sizes as the Ocean plates; stars thin toward the middle where boards sit |
| `story/page_silver.png` | derived from the project's `page_blue.png` | project-owned | recoloured to silver, star motif in place of the wave, drop shadow untouched |

Fluent Emoji source: `cdn.jsdelivr.net/gh/microsoft/fluentui-emoji@main/assets/<Name>/3D/*.png`; the
licence file was fetched and read (MIT, © Microsoft Corporation). **MIT requires the copyright notice
to ship with the work** — the same open item the Ocean report raised; one line in the settings screen
or store listing covers both chapters.

Sizes: the 13 Fluent images are 256 px and about 400 KB together; the generated scenes are 512 px.
Every board decodes images at the size drawn (`cacheWidth`), not the file's size.

## 7. Performance

- **No new continuous work.** `spot_the_diff`'s hint controller runs only while a hint is showing;
  its miss ripple is 350 ms once. `deduction`'s shake controller runs 420 ms after a refused tap.
  `mix_lab` and `shadow_play` own no controllers at all. No timers, streams or listeners were added.
- Every controller is disposed in its state's `dispose`.
- Painting is one `CustomPainter` per panel/track behind a `RepaintBoundary`, with `shouldRepaint`
  keyed to what changed. The shadow drag rebuilds one board; images are pre-decoded to draw size.
- No packages added.

## 8. Tests

| File | What it adds |
|---|---|
| `stars_chapter_test.dart` *(new, 33)* | Chapter shape; the clue chain; the answer; spot-the-diff any order, correct reveal, no double find, no rings before help, parser refusals; shadow monotonic, judge table, both-directions rule, board judges only on shine; mix order-free, half-recipe and mud refused, complete table, board judges only on commit; deduction step count, kept/next-clue cards refused, any order within a clue, summary spoken only when the clue is done, unsolvable content refused; **pixel test: spots are the only differences in the art**; **the Silver Page is silver**; silent device; resume keeps finds and eliminations |
| `stars_screenshot_test.dart` *(new, 15)* | Every Stars board at phone, phone-landscape and tablet to `build/adventure_shots/` |
| `adventure_e2e_test.dart` | Adventure 4 end to end in both locales (7 each, including "the mystery holds"); four chapters back to back; the stars bring and reuse an engine; no chapter repeats an interaction — now over every adventure in the bundle rather than a hand list |
| `story_continuity_test.dart` | Five stops; the stars open after the ocean; **Adventure 5 is never reachable**, and its teaser appears only once the stars are finished |

Three real bugs the tests caught before a device did: the shadow track overflowing by 7.6 px at every
size (the shine button is 1.1× the arrows), a semantics slider missing `increasedValue` (an assertion
in debug builds), and the side view drawing the object at 20 px because it was sized by the optics.

## 9. Still needs a physical device

1. **Dragging the object along the track** on a small phone, and whether the haptic tick per step
   helps or distracts.
2. **Comparing two 200 px skies** on a phone held in portrait — whether four missing stars are findable
   by a five-year-old without the halo.
3. **Colour on real screens**: whether the tinted star reads as the target swatch's colour.
4. **The reasoning, with a child.** Whether "set aside what stays lower" is understood as an instruction
   to remove, and whether children apply the current clue or guess ahead.
5. **Session length** with five think-first activities.
6. **The generated plates at real DPI**, behind the host chrome rather than in a screenshot.
