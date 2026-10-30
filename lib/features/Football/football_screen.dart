import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import '../PlayArt/play_art.dart';
import 'football_cubit.dart';

class FootballScreen extends StatefulWidget {
  const FootballScreen({super.key});
  @override
  State<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _engine = FootballCubit();
  final _audio = PlayAudio();
  late final Ticker _ticker;
  Duration? _last;
  bool _paused = false;
  bool _powerTipSpoken = false;
  double _keeperStart = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((time) {
      final last = _last;
      _last = time;
      if (!_paused && last != null) {
        _engine.tick(((time - last).inMicroseconds / 1e6).clamp(0, .05));
      }
    })
      ..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_audio.cue(
            context,
            'يلا نلعب كورة! اختار زاوية التسديدة، وبعدين ثبّت الاتجاه.',
            'Choose a corner, then lock your aim.'));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(() => _paused = true);
      unawaited(_audio.stop());
    }
    _last = null;
  }

  void _shoot() {
    _keeperStart = _engine.state.keeper;
    _engine.shoot();
  }

  Future<void> _chooseMode(AppLocalizations l) async {
    setState(() => _paused = true);
    unawaited(_audio.stop());
    final mode = await showDialog<FootballMode>(
        context: context,
        builder: (dialog) =>
            SimpleDialog(title: Text(l.resolve('football_mode')), children: [
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialog, FootballMode.levels),
                  child: Text(l.resolve('football_levels'))),
              SimpleDialogOption(
                  onPressed: () =>
                      Navigator.pop(dialog, FootballMode.openChallenge),
                  child: const Text('Open Challenge ∞')),
            ]));
    if (!mounted) return;
    if (mode != null) _engine.chooseMode(mode);
    setState(() {
      _paused = false;
      _last = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _engine.close();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocListener<FootballCubit, FootballState>(
        bloc: _engine,
        listenWhen: (a, b) => a.phase != b.phase,
        listener: (context, s) {
          if (s.phase == FootballPhase.charging && !_powerTipSpoken) {
            _powerTipSpoken = true;
            unawaited(_audio.cue(context, 'استنى المؤشر في الأخضر، واضغط شوت!',
                'Wait for green, then shoot!'));
          } else if (s.phase == FootballPhase.finished) {
            unawaited(_audio.cue(
                context,
                s.goals >= 3
                    ? 'عاش يا بطل! كسبت الجولة!'
                    : 'خلصنا الخمس تسديدات! جرّب تاني وحسّن نتيجتك.',
                s.goals >= 3
                    ? 'You won this round!'
                    : 'Round complete! Try to beat your score.'));
          } else if (s.phase == FootballPhase.result) {
            final goal = s.outcome == ShotOutcome.goal;
            unawaited(_audio.cue(
                context,
                goal ? 'جووول! عاش يا بطل!' : 'محاولة حلوة! جرّب تاني.',
                goal ? 'Goal! Great shot!' : 'Nice try! Try again.',
                effect: goal ? 'score.mp3' : 'sorting_return.wav'));
          }
        },
        child: Scaffold(
            backgroundColor: const Color(0xff163f41),
            body: SafeArea(
                child: Center(
                    child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: LayoutBuilder(builder: (context, bounds) {
                          return FittedBox(
                              child: SizedBox(
                                  width: 400,
                                  height: 600,
                                  child:
                                      BlocBuilder<FootballCubit, FootballState>(
                                          bloc: _engine,
                                          builder: (context, s) {
                                            final aiming =
                                                s.phase == FootballPhase.aiming;
                                            final charging = s.phase ==
                                                FootballPhase.charging;
                                            final flying =
                                                s.phase == FootballPhase.flying;
                                            final result =
                                                s.phase == FootballPhase.result;
                                            final finished = s.phase ==
                                                FootballPhase.finished;
                                            final t = Curves.easeOut
                                                .transform(s.flight);
                                            final target = Offset(
                                                200 + s.aim * 135,
                                                s.outcome == ShotOutcome.wide
                                                    ? 90
                                                    : s.outcome ==
                                                            ShotOutcome.weak
                                                        ? 320
                                                        : 222 - s.power * 48);
                                            final ball = Offset.lerp(
                                                    const Offset(215, 409),
                                                    target,
                                                    t)! +
                                                Offset(0, -sin(pi * t) * 35);
                                            final keeper = flying || result
                                                ? _keeperStart +
                                                    (s.keeper - _keeperStart) *
                                                        Curves.easeOut
                                                            .transform(
                                                                (s.flight * 2)
                                                                    .clamp(
                                                                        0, 1))
                                                : s.keeper;
                                            return Directionality(
                                                textDirection:
                                                    TextDirection.ltr,
                                                child: Stack(children: [
                                                  const Positioned.fill(
                                                      child: Sprite(
                                                          'football_world',
                                                          fit: BoxFit.fill)),
                                                  Positioned(
                                                      left: 151 + keeper * 106,
                                                      top: 145,
                                                      width: 100,
                                                      height: 95,
                                                      child: Transform.rotate(
                                                          angle: flying || result
                                                              ? s.keeper *
                                                                  t *
                                                                  .7
                                                              : sin(s.clock *
                                                                      3) *
                                                                  .025,
                                                          child: const Sprite(
                                                              'keeper'))),
                                                  Positioned(
                                                      left: 29 +
                                                          (flying
                                                              ? sin(s.flight *
                                                                      pi) *
                                                                  12
                                                              : 0),
                                                      top: 266,
                                                      width: 159,
                                                      height: 230,
                                                      child: Transform.rotate(
                                                          angle: flying
                                                              ? sin(s.flight *
                                                                      pi) *
                                                                  .09
                                                              : 0,
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: const Sprite(
                                                              'striker'))),
                                                  if (aiming || charging)
                                                    Positioned.fill(
                                                        child: IgnorePointer(
                                                            child: CustomPaint(
                                                                painter:
                                                                    _AimPainter(
                                                                        s.aim)))),
                                                  Positioned(
                                                      left: (flying || result
                                                              ? ball.dx
                                                              : 215) -
                                                          (flying || result
                                                              ? 28 - t * 17
                                                              : 28),
                                                      top: (flying || result
                                                              ? ball.dy
                                                              : 409) -
                                                          (flying || result
                                                              ? 28 - t * 17
                                                              : 28),
                                                      width: flying || result
                                                          ? 56 - t * 34
                                                          : 56,
                                                      height: flying || result
                                                          ? 56 - t * 34
                                                          : 56,
                                                      child: Transform.rotate(
                                                          angle:
                                                              s.flight * pi * 3,
                                                          child: const Sprite(
                                                              'ball'))),
                                                  if (aiming && !_paused)
                                                    Positioned(
                                                        left: 48,
                                                        top: 120,
                                                        width: 304,
                                                        height: 135,
                                                        child: GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onPanUpdate: (d) =>
                                                                _engine.aim(
                                                                    (d.localPosition.dx -
                                                                            152) /
                                                                        135),
                                                            onTapDown: (d) =>
                                                                _engine.aim(
                                                                    (d.localPosition.dx -
                                                                            152) /
                                                                        135))),
                                                  Positioned(
                                                      left: 14,
                                                      top: 10,
                                                      child: CandyButton(
                                                          icon: Icons
                                                              .arrow_back_rounded,
                                                          label: l.resolve(
                                                              'goBack'),
                                                          onTap: () => Navigator
                                                              .maybePop(
                                                                  context),
                                                          size: 48)),
                                                  Positioned(
                                                      right: 14,
                                                      top: 10,
                                                      child: CandyButton(
                                                          icon: _paused
                                                              ? Icons
                                                                  .play_arrow_rounded
                                                              : Icons
                                                                  .pause_rounded,
                                                          label: l.resolve(_paused
                                                              ? 'football_resume'
                                                              : 'football_pause'),
                                                          size: 48,
                                                          onTap: () {
                                                            setState(() {
                                                              _paused =
                                                                  !_paused;
                                                              _last = null;
                                                            });
                                                            if (_paused) {
                                                              unawaited(_audio
                                                                  .stop());
                                                            }
                                                          })),
                                                  Positioned(
                                                      left: 80,
                                                      top: 10,
                                                      width: 240,
                                                      child: Column(children: [
                                                        Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        5),
                                                            decoration: BoxDecoration(
                                                                color: const Color(
                                                                    0xff074ca7),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        22),
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .lightBlueAccent,
                                                                    width: 2)),
                                                            child: Text(
                                                                '${l.resolve('football_score')}: ${s.score}  •  ${l.resolve('football_level')} ${s.difficulty}',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900))),
                                                        TextButton(
                                                            onPressed: () =>
                                                                _chooseMode(l),
                                                            child: Text(
                                                                s.mode ==
                                                                        FootballMode
                                                                            .openChallenge
                                                                    ? 'Open Challenge ∞'
                                                                    : l.resolve(
                                                                        'football_levels'),
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: 12,
                                                                    shadows: [
                                                                      Shadow(
                                                                          blurRadius:
                                                                              4)
                                                                    ])))
                                                      ])),
                                                  Positioned(
                                                      left: 20,
                                                      right: 20,
                                                      bottom: 114,
                                                      child: IgnorePointer(
                                                          child: Text(
                                                              l.resolve(finished
                                                                  ? 'football_finished'
                                                                  : result
                                                                      ? 'football_${s.outcome!.name}'
                                                                      : charging
                                                                          ? 'football_powerHelp'
                                                                          : 'football_aimHelp'),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  shadows: [
                                                                    Shadow(
                                                                        blurRadius:
                                                                            5)
                                                                  ])))),
                                                  if (!finished)
                                                    Positioned(
                                                        left: 15,
                                                        bottom: 39,
                                                        width: 266,
                                                        height: 42,
                                                        child: charging ||
                                                                flying ||
                                                                result
                                                            ? CustomPaint(
                                                                painter: _PowerPainter(
                                                                    s.power,
                                                                    s
                                                                        .greenStart,
                                                                    s.greenEnd))
                                                            : Slider(
                                                                value: s.aim,
                                                                min: -1,
                                                                activeColor: Colors
                                                                    .cyanAccent,
                                                                inactiveColor:
                                                                    Colors
                                                                        .white60,
                                                                onChanged: _paused
                                                                    ? null
                                                                    : _engine
                                                                        .aim)),
                                                  Positioned(
                                                      right: 12,
                                                      bottom: 18,
                                                      child: CandyButton(
                                                          icon: finished
                                                              ? Icons
                                                                  .replay_rounded
                                                              : result
                                                                  ? Icons
                                                                      .arrow_forward_rounded
                                                                  : aiming
                                                                      ? Icons
                                                                          .check_rounded
                                                                      : Icons
                                                                          .sports_soccer_rounded,
                                                          label: l.resolve(finished
                                                              ? 'football_nextLevel'
                                                              : result
                                                                  ? 'football_next'
                                                                  : aiming
                                                                      ? 'football_confirm'
                                                                      : 'football_shoot'),
                                                          orange: true,
                                                          size: 98,
                                                          onTap: _paused || flying
                                                              ? null
                                                              : finished
                                                                  ? _engine.nextLevel
                                                                  : result
                                                                      ? _engine.next
                                                                      : aiming
                                                                          ? _engine.confirmAim
                                                                          : _shoot)),
                                                  if (finished)
                                                    Positioned.fill(
                                                        child: ColoredBox(
                                                            color:
                                                                Colors.black54,
                                                            child: Center(
                                                                child:
                                                                    Container(
                                                                        width:
                                                                            340,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                        decoration: BoxDecoration(
                                                                            color: const Color(
                                                                                0xfffff2d5),
                                                                            borderRadius: BorderRadius.circular(
                                                                                24)),
                                                                        child: Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Icon(s.goals >= 3 ? Icons.emoji_events_rounded : Icons.sports_soccer_rounded, size: 64, color: Colors.orange),
                                                                              Text(l.resolve(s.goals >= 3 ? 'football_win' : 'football_roundOver'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                                                              const SizedBox(height: 10),
                                                                              Text('${s.goals} / 5  •  ${l.resolve('football_score')}: ${s.score}', style: const TextStyle(fontSize: 20)),
                                                                              const SizedBox(height: 18),
                                                                              SizedBox(width: double.infinity, child: FilledButton(onPressed: _engine.nextLevel, child: Text(l.resolve('football_continue')))),
                                                                              TextButton(onPressed: () => Navigator.maybePop(context), child: Text(l.resolve('football_exit')))
                                                                            ]))))),
                                                  if (_paused)
                                                    Positioned.fill(
                                                        child: ColoredBox(
                                                            color:
                                                                Colors.black54,
                                                            child: Center(
                                                                child:
                                                                    CandyButton(
                                                                        icon: Icons
                                                                            .play_arrow_rounded,
                                                                        label: l.resolve(
                                                                            'football_resume'),
                                                                        size:
                                                                            90,
                                                                        onTap: () =>
                                                                            setState(() {
                                                                              _paused = false;
                                                                              _last = null;
                                                                            }))))),
                                                ]));
                                          })));
                        }))))));
  }
}

class _AimPainter extends CustomPainter {
  const _AimPainter(this.aim);
  final double aim;
  @override
  void paint(Canvas c, Size s) {
    final start = Offset(s.width * .5375, s.height * .68),
        end = Offset(s.width * (.5 + aim * .3375), s.height * .225);
    final direction = (end - start) / ((end - start).distance),
        normal = Offset(-direction.dy, direction.dx);
    final neck = end - direction * 26;
    final arrow = Path()
      ..moveTo((start - normal * 4).dx, (start - normal * 4).dy)
      ..quadraticBezierTo(neck.dx - normal.dx * 9, neck.dy - normal.dy * 9,
          neck.dx - normal.dx * 9, neck.dy - normal.dy * 9)
      ..lineTo((neck - normal * 23).dx, (neck - normal * 23).dy)
      ..lineTo(end.dx, end.dy)
      ..lineTo((neck + normal * 23).dx, (neck + normal * 23).dy)
      ..lineTo((neck + normal * 9).dx, (neck + normal * 9).dy)
      ..lineTo((start + normal * 4).dx, (start + normal * 4).dy)
      ..close();
    c.drawPath(
        arrow,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    c.drawPath(
        arrow,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.cyanAccent.withValues(alpha: .12),
                Colors.white.withValues(alpha: .95)
              ]).createShader(arrow.getBounds()));
    c.drawPath(
        arrow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white70);
  }

  @override
  bool shouldRepaint(_AimPainter old) => old.aim != aim;
}

class _PowerPainter extends CustomPainter {
  const _PowerPainter(this.power, this.greenStart, this.greenEnd);
  final double power, greenStart, greenEnd;
  @override
  void paint(Canvas c, Size s) {
    final shell =
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24));
    c.drawRRect(shell, Paint()..color = const Color(0xff1756b1));
    c.drawRRect(
        shell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.lightBlueAccent);
    final rect = Rect.fromLTWH(5, 5, s.width - 10, s.height - 10);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    c.drawRect(rect, Paint()..color = const Color(0xffffd24a));
    c.drawRect(
        Rect.fromLTRB(rect.left + rect.width * greenStart, rect.top,
            rect.left + rect.width * greenEnd, rect.bottom),
        Paint()..color = const Color(0xff48d876));
    c.drawRect(
        Rect.fromLTRB(rect.left + rect.width * greenEnd, rect.top, rect.right,
            rect.bottom),
        Paint()..color = const Color(0xffed4d55));
    for (var i = 1; i < 16; i++) {
      final x = rect.left + rect.width * i / 16;
      c.drawLine(
          Offset(x, rect.top),
          Offset(x, rect.bottom),
          Paint()
            ..color = Colors.black12
            ..strokeWidth = 1.5);
    }
    c.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * .35),
        Paint()..color = Colors.white24);
    c.restore();
    final x = rect.left + power * rect.width;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 3, 2, 6, s.height - 4), const Radius.circular(4)),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PowerPainter old) =>
      old.power != power ||
      old.greenStart != greenStart ||
      old.greenEnd != greenEnd;
}
