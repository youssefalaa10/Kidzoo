import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';

import 'components/circle_rotator.dart';
import 'components/color_switcher.dart';
import 'components/ground.dart';
import 'components/player.dart';
import 'components/star_component.dart';

class ColorSwitchGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  ColorSwitchGame() : super();
  late Player myPlayer;
  TextComponent? colorNameText;
  TextComponent? scoreText;
  TextComponent? startText;

  final AudioPlayer sfxPlayer = AudioPlayer();

  /// Called by the screen when the start overlay is tapped
  VoidCallback? onGameStarted;

  /// Called when the player color changes (localized color name).
  void Function(String colorName)? onPlayerColorChanged;

  bool isGameOver = false;
  bool isStarted = false;
  int score = 0;

  List<Color> gameColors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
  ];

  static const List<Color> _advancedColors = [
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  String _getColorName(BuildContext context, Color color) {
    final l10n = AppLocalizations.of(context);
    if (color == Colors.redAccent) return l10n.red;
    if (color == Colors.greenAccent) return l10n.green;
    if (color == Colors.blueAccent) return l10n.blue;
    if (color == Colors.yellowAccent) return l10n.yellow;
    if (color == Colors.cyanAccent) return l10n.cyan;
    if (color == Colors.purpleAccent) return l10n.purple;
    if (color == Colors.orangeAccent) return l10n.orange;
    if (color == Colors.pinkAccent) return l10n.pink;
    return 'Unknown';
  }

  @override
  Color backgroundColor() => const Color(0xff222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add ground
    world.add(Ground(position: Vector2(size.x / 2, size.y - 50)));

    // Add player
    myPlayer = Player(position: Vector2(size.x / 2, size.y - 100));
    world.add(myPlayer);

    // Initial color
    final initialColors = gameColors.toList()..shuffle();
    myPlayer.color = initialColors.first;

    // UI overlays
    if (buildContext != null) {
      final l10n = AppLocalizations.of(buildContext!);
      colorNameText = TextComponent(
        text: _getColorName(buildContext!, myPlayer.color),
        position: Vector2(size.x / 2, 50),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: TextStyle(
            color: myPlayer.color,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      add(colorNameText!);

      scoreText = TextComponent(
        text: '${l10n.scoreLabel}: $score',
        position: Vector2(20, 50),
        anchor: Anchor.topLeft,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      add(scoreText!);

      startText = TextComponent(
        text: '...', // placeholder – real start is the Flutter overlay
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.transparent, // hidden; the Flutter overlay takes over
            fontSize: 48,
          ),
        ),
      );
      add(startText!);
    }

    generateGameComponents();
  }

  String _lastSpokenColor = '';

  void updateColorName() {
    try {
      if (!isLoaded || colorNameText == null) return;
      final name = _getColorName(buildContext!, myPlayer.color);
      colorNameText!.text = name;
      colorNameText!.textRenderer = TextPaint(
        style: TextStyle(
          color: myPlayer.color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      );
      if (name != _lastSpokenColor) {
        _lastSpokenColor = name;
        if (isStarted && !isGameOver) {
          onPlayerColorChanged?.call(name);
        }
      }
    } catch (_) {}
  }

  /// Called by [ColorSwitchScreen] when the start overlay is dismissed
  void startGame() {
    if (isStarted) return;
    isStarted = true;
    startText?.removeFromParent();
    myPlayer.jump();
    onGameStarted?.call();
    updateColorName();
  }

  void incrementScore() {
    score++;

    if (buildContext != null) {
      final isSoundEnabled =
          buildContext!.read<MusicCubit>().state.isSoundEnabled;
      if (isSoundEnabled) {
        sfxPlayer.play(AssetSource('audio/score.mp3'));
      }
    }

    if (score == 10) {
      _switchToAdvancedColors();
    }

    if (scoreText != null && buildContext != null) {
      scoreText!.text =
          '${AppLocalizations.of(buildContext!).scoreLabel}: $score';
    }
  }

  /// Transitions gameplay to advanced colors:
  /// - Updates the gameColors palette.
  /// - Rebuilds all existing CircleRotators with new colors.
  /// - Reassigns the player to a color from the new palette.
  void _switchToAdvancedColors() {
    gameColors = List.from(_advancedColors);

    // Rebuild all existing CircleRotators so they show advanced colors
    final rotators = world.children.whereType<CircleRotator>().toList();
    for (final rotator in rotators) {
      rotator.removeFromParent();
      world.add(CircleRotator(
        position: rotator.position,
        size: Vector2(200, 200),
      ));
    }

    // Assign player a valid advanced color immediately
    final shuffled = List<Color>.from(_advancedColors)..shuffle();
    myPlayer.color = shuffled.first;
    _lastSpokenColor = '';
    updateColorName();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isStarted) return;
    final cameraY = camera.viewfinder.position.y;
    final playerY = myPlayer.position.y;

    if (playerY < cameraY + size.y / 2) {
      camera.viewfinder.position = Vector2(0, playerY - size.y / 2);
    }

    if (playerY > camera.viewfinder.position.y + size.y) {
      gameOver();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    if (!isStarted) {
      // First tap handled by the Flutter overlay (startGame()).
      // Guard here in case the overlay was skipped.
      startGame();
    } else {
      myPlayer.jump();
    }
    super.onTapDown(event);
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();

    showDialog<void>(
      barrierDismissible: false,
      context: buildContext!,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.orange.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.of(context).gameOver,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              '${AppLocalizations.of(context).scoreLabel}: $score',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).playAgain,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    isGameOver = false;
    isStarted = false;
    _lastSpokenColor = '';
    score = 0;
    gameColors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.yellowAccent,
    ];
    if (scoreText != null && buildContext != null) {
      scoreText!.text = '${AppLocalizations.of(buildContext!).scoreLabel}: 0';
    }

    final rotators = world.children.whereType<CircleRotator>().toList();
    for (var r in rotators) {
      r.removeFromParent();
    }

    final switchers = world.children.whereType<ColorSwitcher>().toList();
    for (var s in switchers) {
      s.removeFromParent();
    }

    final stars = world.children.whereType<StarComponent>().toList();
    for (var s in stars) {
      s.removeFromParent();
    }

    myPlayer.resetPosition();
    camera.viewfinder.position = Vector2(0, 0);
    generateGameComponents();

    isStarted = false;
    isGameOver = false;

    if (startText != null) {
      add(startText!);
    }

    resumeEngine();
  }

  double lastComponentY = 100;

  void generateGameComponents() {
    lastComponentY = size.y - 350;
    for (int i = 0; i < 5; i++) {
      _generateBlock(lastComponentY);
      lastComponentY -= 400;
    }
  }

  void checkAndGenerateMore() {
    if (myPlayer.position.y < lastComponentY + 800) {
      for (int i = 0; i < 5; i++) {
        _generateBlock(lastComponentY - 400);
        lastComponentY -= 400;
      }
    }
  }

  void _generateBlock(double yPos) {
    world.add(CircleRotator(
      position: Vector2(size.x / 2, yPos),
      size: Vector2(200, 200),
    ));

    world.add(StarComponent(
      position: Vector2(size.x / 2, yPos),
    ));

    world.add(ColorSwitcher(
      position: Vector2(size.x / 2, yPos - 200),
    ));
  }
}
