import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'balloon_art.dart';
import 'balloon_audio.dart';
import 'balloon_cubit.dart';

class BalloonPopScreen extends StatefulWidget {
  const BalloonPopScreen({super.key, this.audio, this.cubit});
  final BalloonAudio? audio;
  final BalloonCubit? cubit;
  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonPopScreenState extends State<BalloonPopScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BalloonCubit _game = widget.cubit ?? BalloonCubit();
  late final Ticker _ticker;
  late BalloonAudio _audio;
  MusicCubit? _music;
  StreamSubscription<MusicState>? _soundSubscription;
  Duration? _lastFrame;
  bool _initialized = false, _muted = false, _foreground = true;
  bool _autoPaused = false;
  double _feedbackAt = -10;
  String? _feedback;
  double _feedbackUntil = 0;
  String t(String key) => AppLocalizations.of(context).resolve('balloon_$key');
  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  String get _prefix => _arabic ? 'ar' : 'en';
  bool get _soundEnabled =>
      !_muted && _foreground && (_music?.state.isSoundEnabled ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final previous = _lastFrame;
      _lastFrame = elapsed;
      if (previous != null) {
        _game.tick((elapsed - previous).inMicroseconds / 1000000);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _music = context.read<MusicCubit?>();
    unawaited(_music?.requestPause());
    _audio = widget.audio ?? TtsBalloonAudio(enabled: () => _soundEnabled);
    _soundSubscription = _music?.stream.listen((state) {
      if (!state.isSoundEnabled) unawaited(_audio.stop());
      if (mounted) setState(() {});
    });
    // The start button also supplies a browser user gesture for web audio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _say(['${_prefix}_welcome']);
    });
  }

  void _say(List<String> clips) {
    if (_soundEnabled) unawaited(_audio.speak(clips));
  }

  void _effect(String clip) {
    if (_soundEnabled) unawaited(_audio.effect(clip));
  }

  String get _promptClip => _game.state.educational
      ? '${_game.state.mode == BalloonMode.arabic ? 'ar' : _prefix}_${_game.state.mode.name}_${_game.state.target}'
      : '${_prefix}_${_game.state.challenge ? 'challenge' : 'free'}';
  String _prompt(BalloonState state) {
    if (state.challenge) return t('challengePrompt');
    if (!state.educational) return t('freePrompt');
    final value = switch (state.mode) {
      BalloonMode.colors =>
        (_arabic ? balloonArabicColors : balloonColorNames)[state.target],
      BalloonMode.numbers => '${state.target + 1}',
      BalloonMode.english => String.fromCharCode(65 + state.target),
      BalloonMode.arabic => balloonArabicLetters[state.target],
      _ => '',
    };
    return t(state.mode == BalloonMode.colors
            ? 'colorPrompt'
            : state.mode == BalloonMode.numbers
                ? 'numberPrompt'
                : 'letterPrompt')
        .replaceAll('{value}', value);
  }

  void _start() {
    _feedback = null;
    _feedbackAt = -10;
    _game.start();
    _lastFrame = null;
    if (!_ticker.isActive) _ticker.start();
    _effect('reward.wav');
    _say(['${_prefix}_welcome', _promptClip]);
  }

  void _pause() {
    final paused = !_game.state.paused;
    _game.setPaused(paused);
    _lastFrame = null;
    if (paused) {
      _ticker.stop();
      unawaited(_audio.stop());
    } else {
      _ticker.start();
      _say([_promptClip]);
    }
  }

  void _menu() {
    _ticker.stop();
    _lastFrame = null;
    unawaited(_audio.stop());
    _game.menu();
  }

  void _pop(int id) {
    final previousWave = _game.state.wave;
    final previousMultiplier = _game.state.multiplier;
    final result = _game.pop(id);
    if (result == PopResult.ignored) return;
    KidHaptics.tap();
    _effect('pop.wav');
    final state = _game.state;
    if (state.challenge) {
      _feedback = '+${10 * state.multiplier}  ·  ×${state.multiplier}';
      _feedbackUntil = state.elapsed + .9;
      if (state.wave > previousWave) {
        _effect('reward.wav');
        _say(['${_prefix}_challenge_wave']);
      } else if (state.multiplier > previousMultiplier &&
          state.multiplier == 5) {
        _say(['${_prefix}_challenge_combo']);
      }
      return;
    }
    if (result == PopResult.complete) {
      return; // Completion listener owns the party.
    }
    if (result == PopResult.correct) {
      _feedback = t('correct');
      _feedbackUntil = state.elapsed + 1.5;
      _say(['${_prefix}_correct', _promptClip]);
    } else if (result == PopResult.guidance &&
        state.elapsed - _feedbackAt > 3) {
      _feedbackAt = state.elapsed;
      _feedback = t('guidance');
      _feedbackUntil = state.elapsed + 2.5;
      _say(['${_prefix}_guidance', _promptClip]);
    } else if (result == PopResult.playful && state.score % 5 == 0) {
      _say(['${_prefix}_correct']);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _autoPaused =
          _game.state.phase == BalloonPhase.playing && !_game.state.paused;
      if (_autoPaused) _game.setPaused(true);
      _ticker.stop();
      _lastFrame = null;
      if (_initialized) unawaited(_audio.stop());
    } else if (_autoPaused) {
      // Explicit resume prevents balloons moving before the child returns.
      _autoPaused = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    unawaited(_soundSubscription?.cancel());
    unawaited(_audio.dispose());
    unawaited(_music?.releasePause());
    if (widget.cubit == null) unawaited(_game.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<BalloonCubit, BalloonState>(
        bloc: _game,
        buildWhen: (before, after) =>
            before.phase != after.phase ||
            before.mode != after.mode ||
            before.score != after.score ||
            before.streak != after.streak ||
            before.target != after.target ||
            before.paused != after.paused ||
            before.elapsed.floor() != after.elapsed.floor() ||
            before.bursts.length != after.bursts.length,
        listenWhen: (before, after) => before.phase != after.phase,
        listener: (context, state) {
          if (state.phase == BalloonPhase.complete) {
            _ticker.stop();
            _effect('celebrate.wav');
            _say([
              '${_prefix}_${state.challenge ? 'challenge_complete' : 'complete'}'
            ]);
          }
        },
        builder: (context, state) => KidGameShell(
            maxContentWidth: 1600,
            fallbackColor: const Color(0xFFC6F1FA),
            builder: (context, metrics) =>
                Stack(fit: StackFit.expand, children: [
                  const RepaintBoundary(
                      child: CustomPaint(painter: BalloonParkPainter())),
                  Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Row(children: [
                          _ParkButton(
                              label: t('back'),
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).pop()),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(t('title'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      color: KidUi.ink))),
                          if (state.phase == BalloonPhase.playing) ...[
                            _ParkButton(
                                label: t('pause'),
                                icon: state.paused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                onTap: _pause),
                            const SizedBox(width: 8),
                          ],
                          _ParkButton(
                              label: t('mute'),
                              icon: _soundEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              onTap: () {
                                setState(() => _muted = !_muted);
                                if (!_soundEnabled) {
                                  unawaited(_audio.stop());
                                } else {
                                  _say([
                                    state.phase == BalloonPhase.playing
                                        ? _promptClip
                                        : '${_prefix}_welcome'
                                  ]);
                                }
                              }),
                        ])),
                    if (state.phase == BalloonPhase.playing) ...[
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 3),
                          child: Row(children: [
                            Expanded(
                                child: Material(
                                    color: Colors.white.withValues(alpha: .95),
                                    borderRadius: BorderRadius.circular(24),
                                    child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () => _say([_promptClip]),
                                        child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(children: [
                                              const Icon(Icons.hearing_rounded,
                                                  color: KidUi.primary,
                                                  size: 26),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(_prompt(state),
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: KidUi.ink))),
                                              if (state.mode ==
                                                  BalloonMode.colors)
                                                Container(
                                                    width: 27,
                                                    height: 27,
                                                    decoration: BoxDecoration(
                                                        color: balloonColors[
                                                            state.target],
                                                        shape:
                                                            BoxShape.circle)),
                                            ]))))),
                            const SizedBox(width: 8),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3C7),
                                    borderRadius: BorderRadius.circular(22)),
                                child: Text(
                                    state.challenge
                                        ? '${state.score}'
                                        : '${state.score}/${state.goal}',
                                    style: const TextStyle(
                                        color: KidUi.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900))),
                          ])),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 5),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BlocBuilder<BalloonCubit, BalloonState>(
                                  bloc: _game,
                                  builder: (context, progress) =>
                                      LinearProgressIndicator(
                                          value: progress.challenge
                                              ? progress.comboRemaining / 2.5
                                              : progress.score / progress.goal,
                                          minHeight: 9,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: .7),
                                          color: const Color(0xFFFFBD55))))),
                      if (state.challenge)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(children: [
                              Expanded(
                                  child: Text(
                                      t('challengeStatus')
                                          .replaceAll('{wave}', '${state.wave}')
                                          .replaceAll(
                                              '{combo}', '${state.multiplier}')
                                          .replaceAll(
                                              '{pops}', '${state.pops}'),
                                      style: const TextStyle(
                                          color: KidUi.ink,
                                          fontWeight: FontWeight.w800))),
                              TextButton.icon(
                                  onPressed: _game.finishChallenge,
                                  icon: const Icon(Icons.emoji_events_rounded),
                                  label: Text(t('finish'))),
                            ])),
                    ],
                    Expanded(
                        child: state.phase == BalloonPhase.playing
                            ? Stack(fit: StackFit.expand, children: [
                                BlocBuilder<BalloonCubit, BalloonState>(
                                    bloc: _game,
                                    builder: (context, frame) =>
                                        _BalloonPlayfield(
                                            state: frame, onPop: _pop)),
                                if (_feedback != null &&
                                    state.elapsed < _feedbackUntil)
                                  IgnorePointer(
                                      child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                  color: KidUi.cream,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          24)),
                                              child: Text(_feedback!,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: KidUi.ink))))),
                                if (state.paused)
                                  ColoredBox(
                                      color:
                                          Colors.white.withValues(alpha: .72),
                                      child: Center(
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                            Text(t('paused'),
                                                style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                    color: KidUi.ink)),
                                            const SizedBox(height: 18),
                                            _ParkAction(
                                                label: t('resume'),
                                                icon: Icons.play_arrow_rounded,
                                                onTap: _pause),
                                            TextButton(
                                                onPressed: _menu,
                                                child: Text(t('modes'))),
                                          ]))),
                              ])
                            : Center(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 24),
                                    child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 580),
                                        child: Container(
                                            padding: const EdgeInsets.all(22),
                                            decoration: BoxDecoration(
                                                color: KidUi.cream
                                                    .withValues(alpha: .97),
                                                borderRadius:
                                                    BorderRadius.circular(36),
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 4),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Color(0x22648F8A),
                                                      blurRadius: 25,
                                                      offset: Offset(0, 12))
                                                ]),
                                            child: state.phase ==
                                                    BalloonPhase.complete
                                                ? _BalloonCompletion(
                                                    score: state.score,
                                                    title: t('hooray'),
                                                    message: t(state.challenge
                                                            ? 'challengeSummary'
                                                            : 'complete')
                                                        .replaceAll(
                                                            '{score}', '${state.score}')
                                                        .replaceAll('{pops}', '${state.pops}')
                                                        .replaceAll('{wave}', '${state.wave}'),
                                                    replay: t('replay'),
                                                    modes: t('modes'),
                                                    onReplay: _start,
                                                    onModes: _menu)
                                                : Column(mainAxisSize: MainAxisSize.min, children: [
                                                    const _BalloonBouquet(),
                                                    Text(t('welcome'),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: KidUi.ink,
                                                            height: 1.1)),
                                                    const SizedBox(height: 8),
                                                    Text(t('intro'),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                KidUi.inkSoft,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    const SizedBox(height: 20),
                                                    Wrap(
                                                        spacing: 8,
                                                        runSpacing: 10,
                                                        alignment: WrapAlignment
                                                            .center,
                                                        children: BalloonMode
                                                            .values
                                                            .map((mode) =>
                                                                _BalloonModeButton(
                                                                    label: t(mode
                                                                        .name),
                                                                    mode: mode,
                                                                    selected:
                                                                        state.mode ==
                                                                            mode,
                                                                    onTap: () {
                                                                      _game.select(
                                                                          mode);
                                                                      unawaited(
                                                                          _audio
                                                                              .effect('reward.wav'));
                                                                    }))
                                                            .toList()),
                                                    const SizedBox(height: 18),
                                                    Text(
                                                        t(state.challenge
                                                            ? 'challengeHint'
                                                            : state.educational
                                                                ? 'learningHint'
                                                                : 'freeHint'),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            color:
                                                                KidUi.inkSoft,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    const SizedBox(height: 16),
                                                    _ParkAction(
                                                        label: t('play'),
                                                        icon: Icons
                                                            .play_arrow_rounded,
                                                        onTap: _start),
                                                  ])))))),
                  ]),
                ])),
      );
}

class _BalloonPlayfield extends StatelessWidget {
  const _BalloonPlayfield({required this.state, required this.onPop});
  final BalloonState state;
  final ValueChanged<int> onPop;
  @override
  Widget build(BuildContext context) =>
      ClipRect(child: LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * .19).clamp(84.0, 118.0);
        return Stack(clipBehavior: Clip.none, children: [
          for (final b in state.balloons)
            Positioned(
                key: ValueKey(b.id),
                left: (b.horizontal * constraints.maxWidth - width * b.size / 2)
                    .clamp(
                        0.0,
                        (constraints.maxWidth - width * b.size)
                            .clamp(0.0, double.infinity)),
                top: constraints.maxHeight +
                    12 -
                    b.progress * (constraints.maxHeight + width * 1.6),
                width: width * b.size,
                height: width * b.size * 1.45,
                child: _BalloonTarget(
                    balloon: b, mode: state.mode, onTap: () => onPop(b.id))),
          Positioned.fill(
              child: IgnorePointer(
                  child: CustomPaint(
                      painter: BalloonBurstPainter(state.bursts, width)))),
        ]);
      }));
}

class _BalloonTarget extends StatelessWidget {
  const _BalloonTarget(
      {required this.balloon, required this.mode, required this.onTap});
  final FloatingBalloon balloon;
  final BalloonMode mode;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = balloon.label(mode);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Stack(fit: StackFit.expand, children: [
      IgnorePointer(
          child: CustomPaint(
              painter: BalloonPainter(
                  color: balloonColors[balloon.color], face: label.isEmpty))),
      Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: .74,
                  child: Semantics(
                      button: true,
                      excludeSemantics: true,
                      onTap: onTap,
                      label: label.isEmpty
                          ? (arabic
                              ? balloonArabicColors
                              : balloonColorNames)[balloon.color]
                          : label,
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTap,
                          child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Center(
                                  child: Text(label,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: KidUi.ink,
                                          shadows: [
                                            Shadow(
                                                color: Colors.white54,
                                                offset: Offset(0, 2))
                                          ]))))))))),
    ]);
  }
}

class _ParkButton extends StatelessWidget {
  const _ParkButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filled(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: KidUi.ink,
          minimumSize: const Size(52, 52)));
}

class _ParkAction extends StatelessWidget {
  const _ParkAction(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 30),
      label: Text(label,
          style: TextStyle(
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily)),
      style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8962D9),
          foregroundColor: Colors.white,
          minimumSize: const Size(210, 64),
          textStyle: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily),
          elevation: 4,
          shadowColor: const Color(0x668962D9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))));
}

class _BalloonModeButton extends StatelessWidget {
  const _BalloonModeButton(
      {required this.label,
      required this.mode,
      required this.selected,
      required this.onTap});
  final String label;
  final BalloonMode mode;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final symbol = switch (mode) {
      BalloonMode.free => '★',
      BalloonMode.colors => '●',
      BalloonMode.numbers => '123',
      BalloonMode.english => 'ABC',
      BalloonMode.arabic => 'أ ب',
      BalloonMode.challenge => '∞',
    };
    return Semantics(
        selected: selected,
        child: Material(
            color: selected ? const Color(0xFFEDE5FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                    width: 124,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFF8962D9)
                                : const Color(0xFFE6E5E8),
                            width: 2)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (mode == BalloonMode.free)
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFF637D), size: 30)
                      else
                        Text(symbol,
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: balloonColors[mode.index])),
                      const SizedBox(height: 3),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: KidUi.ink)),
                    ])))));
  }
}

class _BalloonBouquet extends StatelessWidget {
  const _BalloonBouquet();
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 110,
      width: 225,
      child: Stack(children: [
        Positioned(
            left: 10,
            top: 14,
            width: 65,
            height: 94,
            child: Transform.rotate(
                angle: -.18,
                child: const CustomPaint(
                    painter: BalloonPainter(color: Color(0xFFFF637D))))),
        const Positioned(
            left: 76,
            top: 0,
            width: 76,
            height: 110,
            child:
                CustomPaint(painter: BalloonPainter(color: Color(0xFFFFCD45)))),
        Positioned(
            left: 150,
            top: 14,
            width: 65,
            height: 94,
            child: Transform.rotate(
                angle: .18,
                child: const CustomPaint(
                    painter: BalloonPainter(color: Color(0xFF39BCE8))))),
      ]));
}

class _BalloonCompletion extends StatelessWidget {
  const _BalloonCompletion(
      {required this.score,
      required this.title,
      required this.message,
      required this.replay,
      required this.modes,
      required this.onReplay,
      required this.onModes});
  final int score;
  final String title, message, replay, modes;
  final VoidCallback onReplay, onModes;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const _BalloonBouquet(),
        TweenAnimationBuilder<double>(
            tween: Tween(begin: .5, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: const Text('★ ★ ★',
                style: TextStyle(fontSize: 46, color: Color(0xFFFFBE40)))),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w900, color: KidUi.ink)),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                color: KidUi.inkSoft,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        _ParkAction(label: replay, icon: Icons.replay_rounded, onTap: onReplay),
        const SizedBox(height: 12),
        TextButton(
            onPressed: onModes,
            child: Text(modes,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800))),
      ]);
}
