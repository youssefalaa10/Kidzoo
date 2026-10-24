# Letter Trails

Standalone Education catalog entry: `letter_tracing`. The existing Alphabet
activity is independent. UI strings come from `assets/lang/{en,ar}.json`; the
practice language can be changed independently of the app language.

## Content and interaction

- 28 Arabic letters, isolated and applicable beginning/middle/end forms.
  ا د ذ ر ز و do not connect to the following letter, so they expose only
  isolated and final practice. Joining strokes are part of the form paths.
- 26 English uppercase and 26 lowercase letters. Lowercase a/g use the
  single-storey handwriting forms.
- Original simplified Naskh and English school-print centre-line vectors are
  authored in the two data files. Every path string is an ordered pen stroke;
  each `M` starts a separate contact. Dots are short, tappable strokes after
  the main body. The bundled Noto Naskh Arabic font supplies the reference
  glyph and selectors, not a substitute for the tracing geometry.
- One normalized 300 × 300 coordinate space drives the outline, dashed guide,
  numbered checkpoints, direction arrows, demonstration and pointer matching.
  Arabic paths are never reversed by the UI's RTL layout.
- Ordered sample coverage, a forgiving 23–28-unit corridor and interpolation
  of sparse pointer events support mouse and touch. Children can lift and
  resume at the yellow checkpoint. A stroke must finish before its dots or
  following strokes are accepted. A cancelled contact never completes a letter.
- After success the next letter opens in six seconds, with an immediate Next
  control. Erase restarts the current form. Alphabet checkmarks last for the
  current route session. The final letter remains available for celebration.

## Audio and assets

Letter names and encouragement use Kidzo's shared text-to-speech service. The
service selects the best available Arabic voice, prioritizing Egyptian Arabic;
success also uses Kidzo's existing `audio/success.mp3` effect.

The route pauses background music, respects the sound preference, exposes a
local mute control, and stops narration when backgrounded or disposed. Replay
can retry a failed playback; a localized visible caption reports failure.
Noto Naskh Arabic is bundled under the SIL Open Font License in
`assets/fonts/OFL.txt`.

## Verification

```
flutter test test/letter_tracing test/catalog/grid_contents_regression_test.dart
flutter analyze lib/features/LetterTracing lib/core/catalog/default_game_catalog.dart
```

The tests trace all 152 letter/form combinations, reject invalid tracing,
exercise independent dots and pointer cancellation, check narration selection,
and exercise mouse/touch coordinates, narration and automatic advancement at
360×640, 780×390 and 800×1200 in both UI languages. Optional Windows previews:

```
flutter test test/letter_tracing --dart-define=TRACING_PREVIEW=true
```

This writes screenshots and vector atlases to `build/tracing_preview/`.
