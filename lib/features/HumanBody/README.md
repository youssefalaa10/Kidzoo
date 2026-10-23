# Learn the Human Body

Open **Education → Learn the Human Body**. Free play uses the existing lazy
`GameCatalog` and imperative Navigator routing. The app uses local profiles;
there is no authentication service to add to this feature. No database changes
are needed for an in-session assembly activity.

The Cubit owns the three stages, selection, placement validation, progress,
restart, replay, hints and narration. Widgets receive immutable snapshots.
`BodyAudio` is injected at the screen boundary and can be replaced in tests.
There is no mutable global game state or additional dependency.

## Interaction and illustrations

There are 6 facial pieces, 7 upper body pieces and 5 lower body pieces. Paired
arms, hands, fingers, legs, knees, feet and toes are placed together by dropping
on either side. Left and right refer to the character facing the child.

The opening view shows the incomplete full body. Tapping a facial piece
zooms into the face; dragging keeps the view stable under the pointer.
The corner button switches between close-up and overview.
Upper body and lower body stages use appropriately sized views. Stage two's
head piece carries the face from stage one, so those features reappear when
the head is placed. Restart preserves completed earlier stages; replay clears
all 18 pieces.

Original vector illustrations in `body_artwork.dart` supply both the tray
and the character, including blank dotted silhouettes. Drawing, highlights,
drag drops and tap placement all use `BodyViewport` to map to a 360 × 560
coordinate system. RTL changes UI direction without mirroring anatomy.
The closest active anchor accepts only its own piece. Incorrect or outside
drops leave the tray intact and reveal a hint. Touch, mouse, tap-to-select and
screen reader actions use the same placement validation.

Snap bounce, small success sparkles and final confetti use a single short-lived
animation controller; reduced motion disables these effects.

## Audio

Every piece has an English and Arabic name and contextual selection, correct,
retry and hint sentences in the existing locale JSON files. Welcome, stage
introductions, congratulations and completion are also localized.

Voice uses the app's existing `Speech.speakAndWait` service (device TTS, or the
app's configured Azure Arabic voice). There are **no newly recorded voice
files**. An installed voice or configured cloud voice is required; a failed or
missing voice shows a visible message. Physical-device pronunciation and
speaker quality still need a listening check on the target devices.

The existing bundled `boop.wav`, `success.mp3`, `piano-d.wav` and `score.mp3`
provide distinct, low-volume pickup, correct, gentle retry and celebration
effects. Effect failure does not block speech. Latest interaction wins over
old narration, and delayed congratulations cannot interrupt a new stage or
replay. The screen pauses background music while open, inherits the app's sound
preference, offers a session mute button, stops audio when backgrounded, and
disposes its player when leaving.

## Verification

```powershell
flutter analyze --no-pub lib/features/HumanBody lib/core/catalog/default_game_catalog.dart test/human_body
flutter test --no-pub test/human_body test/catalog/grid_contents_regression_test.dart test/localization/locale_parity_test.dart
```

Tests cover both locale sessions, all 18 placements, incorrect drops,
stage gating, restart/replay, delayed narration, mute/lifecycle, unavailable
voice feedback, asset existence, coordinate transforms, and widget layouts
at 360 × 640, 780 × 390 and 800 × 1200. Full touch and mouse gesture sessions
exercise every piece in portrait and landscape.

Optional visual previews: `flutter test --no-pub test/human_body
--dart-define=BODY_PREVIEW=true` writes PNGs to `build/human_body_previews/`.
Preview mode loads local Windows Arial and Flutter Material Icons when available;
normal tests have no dependency on those font files.
