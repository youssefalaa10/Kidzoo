# Little Helpers

Open **Education → Little Helpers** to choose food, weather, or laundry sorting.
These activities target preschool classification and everyday self-care. Food
categories mean everyday foods versus sugary treats, rather than calling foods
bad. Yogurt is explicitly plain; cereal is explicitly sweetened.

All three use the existing SortingEngine and ActivityHostScreen: one object at
a time, drag or tap the object then its destination, visible accumulated items,
gentle hints, completion narration, stars, and replay with a new shuffle. They
use the existing local-profile application flow; this repository has no account
authentication service to integrate with.

## Audio

The existing SpeechActivityNarrator reads the bilingual initial instruction,
each subsequent object name, bin labels on inspection, hints, and completion.
Replay-prompt/help uses the host's existing narration path. This is runtime TTS,
not a bundled voice recording; Arabic requires the voice setup already supported
by the app. Background music is paused while an activity is open.

| Event | Audio |
| --- | --- |
| Tap or pick up a draggable object | Existing `boop.wav` |
| Correct food placement | Original soft two-tone sparkle, `helpers_teeth.wav` |
| Correct weather placement | Original short rain-like patter, `helpers_weather.wav` |
| Correct clothing placement | Original cloth-like rustle, `helpers_laundry.wav` |
| Incorrect placement | Existing gentle feedback through the shared engine |
| Finish | Existing celebration plus the activity's spoken encouragement |
| Leave | Cancel narration and dispose the activity's sound player |

One effect player replaces the preceding effect; the existing sound setting is
checked on every playback. No external asset licenses or new Flutter dependencies
are required.

## Asset source and checks

`tool/generate_little_helpers.cjs` contains the original vector artwork, seeded
PCM sound synthesis, and bilingual content source. To regenerate, install `sharp`
in a temporary tools directory and pass its module path to the script. Generated
PNG/WAV/JSON files are committed directly and regeneration is not needed to run.

Tests cover incorrect and correct placements, every item through completion in
both languages, actual tap and drag gestures, asset presence, WAV headers,
catalog entries, content rules, and board layouts at phone/landscape/tablet sizes.
Device speaker quality, installed TTS voices, and physical touchscreen feel still
need a device playthrough.
