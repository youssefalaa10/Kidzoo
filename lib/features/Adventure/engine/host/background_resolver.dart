import 'package:flutter/widgets.dart';

/// Turns a content-declared `backgroundType` into an asset, picking the phone
/// or tablet plate for the current width.
///
/// Content names a *place* ("jungle", "market"), never a file. That is what
/// lets the same activity run in a different Adventure by changing one string,
/// and it keeps tablet art a delivery detail rather than something every
/// author has to remember.
class BackgroundResolver {
  const BackgroundResolver();

  static const String _dir = 'assets/gen/images/backgrounds';

  static const Map<String, _BackgroundPlates> _plates =
      <String, _BackgroundPlates>{
    'jungle': _BackgroundPlates('$_dir/jungle_mob.png', '$_dir/jungle-tab.jpg'),
    'market': _BackgroundPlates(
        '$_dir/colorful_bg_mob.png', '$_dir/colorful_bg_tab.jpg'),
    'ocean':
        _BackgroundPlates('$_dir/cloudy_bg_mob.png', '$_dir/cloudy_bg_tab.png'),
    'star': _BackgroundPlates('$_dir/tech_bg_mob.jpeg', '$_dir/tech_bg_desk.jpg'),
    'learning':
        _BackgroundPlates('$_dir/learn_bg_mob.png', '$_dir/learn_bg_desk.jpg'),
    'map': _BackgroundPlates('$_dir/map_mob.jpg', '$_dir/map_desk_tab.png'),
    'board': _BackgroundPlates('$_dir/board_mob.jpg', '$_dir/board_tab.jpg'),
  };

  /// Every plate, so the content test can assert each one exists on disk.
  static Iterable<String> get allAssets => _plates.values
      .expand((_BackgroundPlates plate) => <String>[plate.phone, plate.tablet]);

  static Iterable<String> get knownTypes => _plates.keys;

  /// Resolves to an asset, or null when [backgroundType] is unknown — the host
  /// then falls back to a flat colour rather than crashing on a typo.
  String? resolve(String? backgroundType, {required double width}) {
    if (backgroundType == null) {
      return null;
    }
    final _BackgroundPlates? plate = _plates[backgroundType];
    if (plate == null) {
      return null;
    }
    return width >= 600 ? plate.tablet : plate.phone;
  }

  String? resolveFor(String? backgroundType, BuildContext context) =>
      resolve(backgroundType, width: MediaQuery.sizeOf(context).width);
}

@immutable
class _BackgroundPlates {
  const _BackgroundPlates(this.phone, this.tablet);
  final String phone;
  final String tablet;
}
