import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/background_resolver.dart';
import '../../core/shared/style/image_manager.dart';
import '../../core/shared/style/kid_ui.dart';
import '../Alphabets/bloc/alphabet_bloc.dart';
import '../Profile/profile_cubit.dart';
import '../Profile/profile_setup_screen.dart';
import '../Profile/profile_state.dart';
import '../home/UI/character.dart';

/// Opening screen.
///
/// The old version stacked a static image, two labels and a spinner. It now
/// runs one continuous entrance - the icon settles in, the words follow it, and
/// a soft progress bar replaces the spinner - and it holds that entrance to the
/// end even when the profile loads instantly, so the app never flashes past.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Drives the one-shot entrance.
  late final AnimationController _entrance;

  /// Drives the endless idle float and shimmer.
  late final AnimationController _idle;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconTurn;
  late final Animation<double> _haloFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _progressFade;

  /// Where to go once both the entrance has played and the profile has loaded.
  WidgetBuilder? _pendingDestination;
  bool _navigated = false;

  static const Duration _entranceDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(vsync: this, duration: _entranceDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _tryNavigate();
      });
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    Animation<double> curve(double begin, double end, Curve c) =>
        CurvedAnimation(
            parent: _entrance, curve: Interval(begin, end, curve: c));

    // The icon lands first, with a little overshoot so it feels dropped in
    // rather than faded in.
    _iconScale = Tween<double>(begin: 0.4, end: 1).animate(
      curve(0, 0.55, Curves.easeOutBack),
    );
    _iconTurn = Tween<double>(begin: -0.06, end: 0).animate(
      curve(0, 0.6, Curves.easeOutCubic),
    );
    _haloFade = curve(0.1, 0.6, Curves.easeOut);
    _titleFade = curve(0.35, 0.7, Curves.easeOut);
    _titleSlide = Tween<double>(begin: 24, end: 0).animate(
      curve(0.35, 0.75, Curves.easeOutCubic),
    );
    _subtitleFade = curve(0.5, 0.85, Curves.easeOut);
    _progressFade = curve(0.65, 1, Curves.easeOut);

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Navigates only once the entrance has finished *and* a destination is
  /// known, so a fast profile load cannot cut the animation off mid-way.
  void _tryNavigate() {
    if (_navigated || !mounted) return;
    final destination = _pendingDestination;
    if (destination == null || !_entrance.isCompleted) return;

    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, _) => destination(context),
        transitionsBuilder: (context, animation, _, child) {
          final eased =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1).animate(eased),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background =
        BackgroundResolver(context, BackgroundType.splash).resolveBackground();

    return Scaffold(
      backgroundColor: const Color(0xFF5E7BB9),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is! ProfileLoaded) return;
          _pendingDestination = state.currentProfile == null
              ? (_) => const ProfileSetupScreen()
              : (_) => BlocProvider(
                    create: (context) => AlphabetBloc(),
                    child: const CharacterSelectionScreen(),
                  );
          _tryNavigate();
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF5E7BB9),
            image: background != null
                ? DecorationImage(
                    image: AssetImage(background),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Darkens the busy photo just enough for white text to read
              // cleanly against it at any size.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final m = KidMetrics.of(constraints);
                    final iconSize =
                        (math.min(m.width, m.height) * 0.34).clamp(96.0, 220.0);

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: EdgeInsets.all(m.pagePadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AnimatedMark(
                                entrance: _entrance,
                                idle: _idle,
                                scale: _iconScale,
                                turn: _iconTurn,
                                haloFade: _haloFade,
                                size: iconSize,
                              ),
                              SizedBox(height: m.gap * 1.8),
                              _FadeSlide(
                                fade: _titleFade,
                                offsetY: _titleSlide,
                                child: Text(
                                  l10n.splashTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: m.size(34, min: 24, max: 44),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: KidUi.textHalo,
                                  ),
                                ),
                              ),
                              SizedBox(height: m.gap * 0.6),
                              FadeTransition(
                                opacity: _subtitleFade,
                                child: Text(
                                  l10n.splashSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: m.size(17, min: 13, max: 22),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shadows: KidUi.textHalo,
                                  ),
                                ),
                              ),
                              SizedBox(height: m.gap * 2.2),
                              FadeTransition(
                                opacity: _progressFade,
                                child: _LoadingBar(
                                  width: (m.width * 0.45).clamp(120.0, 240.0),
                                  animation: _idle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app icon, dropped in and then breathing gently.
class _AnimatedMark extends StatelessWidget {
  const _AnimatedMark({
    required this.entrance,
    required this.idle,
    required this.scale,
    required this.turn,
    required this.haloFade,
    required this.size,
  });

  final AnimationController entrance;
  final AnimationController idle;
  final Animation<double> scale;
  final Animation<double> turn;
  final Animation<double> haloFade;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entrance, idle]),
      builder: (context, child) {
        final breathe = Curves.easeInOut.transform(idle.value);
        // The float only starts once the icon has landed, so the entrance and
        // the idle loop never fight each other.
        final settled = entrance.isCompleted ? 1.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, -breathe * 8 * settled),
          child: Transform.rotate(
            angle: turn.value * math.pi,
            child: Transform.scale(
              scale: scale.value * (1 + breathe * 0.02 * settled),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: haloFade.value * (0.35 + breathe * 0.25),
                    child: Container(
                      width: size * 1.45,
                      height: size * 1.45,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.15, 1],
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          ImageManager.appIcon,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Icon(
            Icons.pets_rounded,
            size: size * 0.55,
            color: KidUi.primary,
          ),
        ),
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.fade,
    required this.offsetY,
    required this.child,
  });

  final Animation<double> fade;
  final Animation<double> offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([fade, offsetY]),
      builder: (context, inner) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset: Offset(0, offsetY.value),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}

/// A sliding highlight instead of a spinner: it reads as "getting ready"
/// rather than "something is stuck".
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.width, required this.animation});

  final double width;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const height = 8.0;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.25),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(animation.value);
              return Align(
                alignment: Alignment(-1 + t * 2, 0),
                child: Container(
                  width: width * 0.45,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
