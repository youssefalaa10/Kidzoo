import 'package:flutter/material.dart';

enum BackgroundType {
  education,
  game,
  map,
  tech,
  splash,
  jungle,
  none,
}

class BackgroundResolver {

  const BackgroundResolver(this.context, this.type);
  final BuildContext context;
  final BackgroundType type;

  /// Returns the appropriate background image path based on screen dimensions and orientation.
  /// Returns null if type is BackgroundType.none.
  String? resolveBackground() {
    if (type == BackgroundType.none) {
      return null;
    }

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isLandscape = width > height;

    String mobilePortrait;
    String mobileLandscape;
    String tabletPortrait;
    String tabletLandscape;
    String desktop;

    switch (type) {
      case BackgroundType.education:
        mobilePortrait = 'assets/gen/images/backgrounds/learn_bg_mob.png';
        mobileLandscape = 'assets/gen/images/backgrounds/learn_bg_mob.png';
        tabletPortrait = 'assets/gen/images/backgrounds/colorful_bg_tab.jpg';
        tabletLandscape = 'assets/gen/images/backgrounds/colorful_bg_tab.jpg';
        desktop = 'assets/gen/images/backgrounds/math_bg_desk.jpg';
        break;
      case BackgroundType.game:
        mobilePortrait = 'assets/gen/images/backgrounds/cloudy_bg_mob.png';
        mobileLandscape = 'assets/gen/images/backgrounds/cloudy_bg_mob.png';
        tabletPortrait = 'assets/gen/images/backgrounds/cloudy_bg_tab.png';
        tabletLandscape = 'assets/gen/images/backgrounds/cloudy_bg_tab.png';
        desktop = 'assets/gen/images/backgrounds/colorful_bg_desk.jpg';
        break;
      case BackgroundType.map:
        mobilePortrait = 'assets/gen/images/backgrounds/map_mob.jpg';
        mobileLandscape = 'assets/gen/images/backgrounds/map_mob.jpg';
        tabletPortrait = 'assets/gen/images/backgrounds/map_desk_tab.png';
        tabletLandscape = 'assets/gen/images/backgrounds/map_desk_tab.png';
        desktop = 'assets/gen/images/backgrounds/map_desk_tab.png';
        break;
      case BackgroundType.tech:
        mobilePortrait = 'assets/gen/images/backgrounds/tech_bg_mob.jpeg';
        mobileLandscape = 'assets/gen/images/backgrounds/tech_bg_mob.jpeg';
        tabletPortrait = 'assets/gen/images/backgrounds/tech_bg_desk.jpg';
        tabletLandscape = 'assets/gen/images/backgrounds/tech_bg_desk.jpg';
        desktop = 'assets/gen/images/backgrounds/tech_bg_desk.jpg';
        break;
      case BackgroundType.splash:
        mobilePortrait = 'assets/gen/images/backgrounds/cloudy_bg_mob.png';
        mobileLandscape = 'assets/gen/images/backgrounds/cloudy_bg_mob.png';
        tabletPortrait = 'assets/gen/images/backgrounds/cloudy_bg_tab.png';
        tabletLandscape = 'assets/gen/images/backgrounds/cloudy_bg_tab.png';
        desktop = 'assets/gen/images/backgrounds/colorful_bg_desk.jpg';
        break;
      case BackgroundType.jungle:
        mobilePortrait = 'assets/gen/images/backgrounds/jungle_mob.png';
        mobileLandscape = 'assets/gen/images/backgrounds/jungle_mob.png';
        tabletPortrait = 'assets/gen/images/backgrounds/jungle-tab.jpg';
        tabletLandscape = 'assets/gen/images/backgrounds/jungle-tab.jpg';
        desktop = 'assets/gen/images/backgrounds/jungle-tab.jpg';
        break;
      case BackgroundType.none:
        return null; // Handled at the top
    }

    if (width >= 900) {
      return desktop;
    } else if (width >= 600) {
      return isLandscape ? tabletLandscape : tabletPortrait;
    } else {
      return isLandscape ? mobileLandscape : mobilePortrait;
    }
  }
}
