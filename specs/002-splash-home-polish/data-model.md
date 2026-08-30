# Data Model & State Transitions: Splash & Home Polish

## State Management Models

This feature primarily deals with UI configuration rather than persistent entity data models. The existing `OptionItem` class will be heavily utilized to supply dynamic values.

### `OptionItem` (Existing structure reinforced)
- `icon`: String path referencing `ImageManager`.
- `title`: Translated string from `AppLocalizations`.
- `screen`: The target `Widget` builder.
- `flipImage`: Backside image reference from `ImageManager`.

### Localizations (`en.json` / `ar.json` equivalent)
New keys must be added or existing keys utilized for:
- Splash Screen Title
- Splash Screen Subtitle
- New Game Categories ("Vehicles", "Fruits", "Vegetables")

No new Drift database tables are required for this polish pass.
