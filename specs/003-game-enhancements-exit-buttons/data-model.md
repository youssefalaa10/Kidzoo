# Data Models: Game Enhancements & Exit Buttons

## Entities

### `GameAssetManager`
An injected service responsible for resolving game-specific or shared asset paths (images, audio).
- **Type**: Service / Class
- **Methods**:
  - `String getImagePath(String key)`: Returns the fully qualified asset path for an image key.
  - `String getAudioPath(String key)`: Returns the fully qualified asset path for an audio key.
  - `String getIconPath(String key)`: Returns the fully qualified asset path for an icon key.

### `GameExitButton`
A reusable class-based stateless widget.
- **Type**: `StatelessWidget`
- **Fields**:
  - `VoidCallback? onExit`: Optional override for the default `Navigator.pop` behavior.
- **Dependencies**:
  - Requires `BuildContext` to read `Theme.of(context)` for styling.
  - Requires `BuildContext` to read `AppLocalizations.of(context)` for text.
  - Requires `BuildContext` to read `RepositoryProvider.of<GameAssetManager>(context)` for icons/images.
