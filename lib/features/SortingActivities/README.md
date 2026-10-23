# Reference sorting activities

Three independent Education cards launch `ToothFoodSortingScreen`,
`WeatherSortingScreen`, and `LaundrySortingScreen` directly. There is no combined
menu. Each route owns a fresh cubit, progress, narration, effects and replay.
Kidzo's existing catalog, profile flow, localization, music preference and result
view are reused; no account/authentication system or dependency is added.

## Reference layout and interaction

`SortingWorksheetLayout` reproduces the supplied worksheets on a 700 × 970
logical canvas. The sad tooth, raincloud and washer stay on the left in both
languages. Each character sits above its empty classification box; the teeth
overlap the top border. Ten individual cutouts occupy a fixed two-row, five-column
dashed tray below the boxes, in the reference's order. Weather includes both
yellow and green boots. Laundry starts with the five dirty garments above the
five clean garments. A short toolbar and spoken instruction sit outside the
worksheet.

The child chooses any remaining item. Dragging into its category animates the
item into that box, leaving the original tray slot empty. An incorrect placement
returns it to its original slot with a gentle shake and encouraging feedback.
Tap an item then its box provides the same interaction without dragging. Repeated
or unknown item IDs cannot advance progress. Completion requires all ten unique
correct placements. Replay clears both boxes and restores the reference order.
On short landscape windows the worksheet scrolls vertically to keep recognizable
objects and useful touch targets, rather than changing its arrangement.

Food categories distinguish everyday foods from sugary treats. The left tooth
illustrates tooth decay gently. Plain yogurt and sweetened cereal are named
explicitly, avoiding ambiguity in those food groups.

## Illustrations and asset provenance

All 36 illustrations were originally generated with the built-in imagegen tool
on 2026-10-23; no third-party artwork was downloaded. The three prompt sets are
recorded in [sorting_art_prompts.md](../../../tool/sorting_art_prompts.md).
Transparent source atlases are processed by `tool/prepare_sorting_assets.cjs`.
The script finds silhouette bounds so wide objects aren't cut at grid edges,
preserves alpha and writes quality-91 WebP with lossless alpha, up to 240 px for
cutouts and 440 px for headers, without enlarging source pixels. The 36 bundled
WebP files total 739,240 bytes. Original atlases and redundant PNG copies are not
bundled. Flutter's native image decoder handles WebP on the target platforms.

To process newly generated atlases, install `sharp` outside the application and
run:

```
node tool/prepare_sorting_assets.cjs <sharp-module-path> <teeth.png> <weather.png> <laundry.png>
```

The script also preserves the reference item order, updates bilingual content,
and synthesizes the original PCM sound assets deterministically.

## Audio mapping

Every game has its own pickup, two placement and completion assets under
`assets/audio/sorting_<theme>_*.wav`. The three games share one gentle
`sorting_return.wav` for retry, avoiding duplicate copies (13 effects total):

| Cue | Teeth | Weather | Laundry |
| --- | --- | --- | --- |
| `pick` | Quiet rounded note | Soft paper/cloth flick | Cloth-like rustle |
| `left` | Gentle placement chime | Three droplet-like notes | Soft basket-like landing/rustle |
| `right` | Bright placement chime | Soft breeze-like swish/note | Small hanger-like clicks |
| `retry` | Gentle paper-return swish | Gentle paper-return swish | Gentle paper-return swish |
| `complete` | Short rising motif | Short rising motif in another register | Short rising motif in another register |

These are deliberately short, synthesized effects accompanying illustrated
sorting, not recordings of physical tooth brushing or washing. `boop.wav` was
inspected as an existing RIFF asset and is not copied, renamed or mapped by these
games. Neither `wrong.mp3` nor the old generic success/score files are used here.

Kidzo's `Speech` facade supplies the configured English/Arabic TTS voice for the
short introduction, selected object names, destination inspection, category
feedback, gentle retry and game-specific congratulations. Narration is runtime
TTS, not a bundled recording. The on-screen caption remains usable and a caption
indicator appears if voice playback fails. Arabic still uses Kidzo's existing
voice setup.

One effect player and a generation guard prevent queued/overlapping actions.
Background music pauses for the route. Mute, backgrounding, route exit and
disposal stop speech and effects; delayed completion and late voice callbacks
cannot mutate a disposed cubit.

## Verification

`test/sorting_activities/sorting_activities_test.dart` checks independent routes,
ten objects per board, two initially empty boxes, free selection order, wrong
placements, duplicate rejection, real mouse/touch drag gestures, tap placement,
completion, replay, audio mapping, missing voice behavior, and lifecycle cleanup.
It decodes every WebP through the actual Flutter board and exercises English and
Arabic at 360×640, 780×390 and 800×1200. Preview capture loads local fonts when
available:

```
flutter test test/sorting_activities/sorting_activities_test.dart --dart-define=SORTING_PREVIEW=true
```

Rendered previews are written to `build/sorting_previews/`. Catalog, content,
architecture and localization regression checks also run. Physical speaker
balance, the installed TTS voice and real touchscreen feel need a device
playthrough; automated checks do not certify those.
