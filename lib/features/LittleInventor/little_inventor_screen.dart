import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import '../PlayArt/play_art.dart';
import 'inventor_cubit.dart';

class LittleInventorScreen extends StatefulWidget {
  const LittleInventorScreen({super.key});
  @override
  State<LittleInventorScreen> createState() => _LittleInventorScreenState();
}

class _LittleInventorScreenState extends State<LittleInventorScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _engine = InventorCubit();
  final _audio = PlayAudio();
  int _feedbackIndex = 0;
  bool _finished = false;
  late final AnimationController _water;
  late final AnimationController _cross;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _water =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _cross =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _cross.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _engine.state.challenge == 2 &&
          mounted) {
        setState(() => _finished = true);
        unawaited(_audio.cue(context, 'برافو عليك! خلّصت كل الجسور!',
            'Well done! You finished every bridge!'));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_audio.cue(
            context,
            'يلا نساعد السلحفاة! اسحب القطع وابني لها كوبري تعدّي عليه.',
            'Help Turtle! Drag the pieces to build a bridge.'));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _water.stop();
      _cross.stop();
      unawaited(_audio.stop());
    } else {
      _water.repeat();
      if (_engine.state.feedback == BridgeFeedback.success &&
          _cross.value < 1) {
        _cross.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _water.dispose();
    _cross.dispose();
    _engine.close();
    _audio.dispose();
    super.dispose();
  }

  void _place(int id, int cell) {
    _engine.drop(id, cell);
    unawaited(_audio.cue(context, '', '', effect: 'sorting_laundry_pick.wav'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocListener<InventorCubit, InventorState>(
        bloc: _engine,
        listenWhen: (a, b) =>
            a.feedback != b.feedback || a.challenge != b.challenge,
        listener: (context, s) {
          if (s.feedback == BridgeFeedback.success) {
            _cross.forward(from: 0);
            unawaited(_audio.cue(
                context,
                [
                  'برافو! السلحفاة لقت طريقها!',
                  'يا سلام! الكوبري طلع جميل!',
                  'فكّرت فيها صح! يلا نشوف السلحفاة بتعدّي.',
                  'ممتاز! كل قطعة في مكانها.'
                ][_feedbackIndex++ % 4],
                'Great building! Turtle can cross!',
                effect: 'success.mp3'));
          } else if (s.feedback == BridgeFeedback.gap) {
            unawaited(_audio.cue(
                context,
                [
                  'بص على الخطوط الفاضية، لسه ناقصنا قطع.',
                  'قربنا نخلّص! شوف أنهي قطعة تركب في الفراغ.',
                  'جرّب القطعة الطويلة في مكان طويل، والصغيرة في مكان صغير.'
                ][_feedbackIndex++ % 3],
                'Fill the gaps and support your bridge.',
                effect: 'sorting_return.wav'));
          } else if (s.feedback == BridgeFeedback.noRoom) {
            unawaited(_audio.cue(
                context,
                [
                  'قرّبها من مكان فاضي وجرّب تاني.',
                  'اختار قطعة، وبعدين دوس على مكانها في الكوبري.',
                  'بص على شكل الفراغ، واختار القطعة اللي شبهه.'
                ][_feedbackIndex++ % 3],
                'Try a different space.'));
          }
          if (s.feedback != BridgeFeedback.success) _cross.reset();
        },
        child: Scaffold(
            backgroundColor: const Color(0xff387c70),
            body: SafeArea(
                child: Center(
                    child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: FittedBox(
                            child: SizedBox(
                                width: 400,
                                height: 600,
                                child:
                                    BlocBuilder<InventorCubit, InventorState>(
                                        bloc: _engine,
                                        builder: (context, s) {
                                          final unit = 220 / s.width;
                                          final baseY = s.challenge == 2
                                              ? 234.0
                                              : s.challenge == 1
                                                  ? 248.0
                                                  : 270.0;
                                          final success = s.feedback ==
                                              BridgeFeedback.success;
                                          return Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Stack(children: [
                                                const Positioned.fill(
                                                    child: Sprite(
                                                        'inventor_world',
                                                        fit: BoxFit.fill)),
                                                Positioned.fill(
                                                    child: IgnorePointer(
                                                        child: AnimatedBuilder(
                                                            animation: _water,
                                                            builder: (context,
                                                                    _) =>
                                                                CustomPaint(
                                                                    painter: _WaterPainter(
                                                                        _water
                                                                            .value))))),
                                                Positioned(
                                                    left: 10,
                                                    top: 110,
                                                    width: 119,
                                                    height: 161,
                                                    child: AnimatedBuilder(
                                                        animation: _water,
                                                        builder: (context,
                                                                child) =>
                                                            Transform.translate(
                                                                offset: Offset(
                                                                    0,
                                                                    sin(_water.value *
                                                                            pi *
                                                                            2) *
                                                                        2),
                                                                child: child),
                                                        child: const Sprite(
                                                            'inventor'))),
                                                Positioned(
                                                    left: 312,
                                                    top: 150,
                                                    width: 46,
                                                    height: 46,
                                                    child: AnimatedBuilder(
                                                        animation: _water,
                                                        builder: (context,
                                                                child) =>
                                                            Transform.translate(
                                                                offset: Offset(
                                                                    0,
                                                                    sin(_water.value *
                                                                            pi *
                                                                            2) *
                                                                        5),
                                                                child: child),
                                                        child: const Sprite(
                                                            'reward'))),
                                                AnimatedBuilder(
                                                    animation: _cross,
                                                    builder: (context,
                                                            _) =>
                                                        Positioned(
                                                            left: 310 -
                                                                _cross
                                                                        .value *
                                                                    276,
                                                            top: _walkingY(
                                                                    s.challenge,
                                                                    _cross
                                                                        .value) -
                                                                sin(_cross.value *
                                                                        pi *
                                                                        12) *
                                                                    (_cross.isAnimating
                                                                        ? 2
                                                                        : 0),
                                                            width: 78,
                                                            height: 55,
                                                            child: const Sprite(
                                                                'turtle'))),
                                                Positioned(
                                                    left: 78,
                                                    top: baseY - 12,
                                                    width: 244,
                                                    height: unit * 3 + 24,
                                                    child: _BridgeBoard(
                                                        state: s,
                                                        engine: _engine,
                                                        unit: unit,
                                                        onDrop: _place)),
                                                Positioned(
                                                    left: 16,
                                                    top: 14,
                                                    child: CandyButton(
                                                        icon:
                                                            Icons.home_rounded,
                                                        label:
                                                            l.resolve('goBack'),
                                                        onTap: () =>
                                                            Navigator.maybePop(
                                                                context),
                                                        size: 48)),
                                                Positioned(
                                                    right: 16,
                                                    top: 14,
                                                    child: CandyButton(
                                                        icon: Icons
                                                            .replay_rounded,
                                                        label: l.resolve(
                                                            'inventor_reset'),
                                                        onTap: () {
                                                          _cross.reset();
                                                          _engine.reset();
                                                        },
                                                        size: 48)),
                                                Positioned(
                                                    left: 135,
                                                    top: 22,
                                                    child: Row(
                                                        children: List.generate(
                                                            3,
                                                            (i) => Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        4),
                                                                child: Icon(
                                                                    i <= s.challenge
                                                                        ? Icons
                                                                            .star_rounded
                                                                        : Icons
                                                                            .star_outline_rounded,
                                                                    color: const Color(
                                                                        0xffffd348),
                                                                    size:
                                                                        32))))),
                                                Positioned(
                                                    left: 74,
                                                    right: 74,
                                                    top: 67,
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration: BoxDecoration(
                                                            color: const Color(
                                                                0xfffff4df),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    12)),
                                                        child: Text(
                                                            l.resolve(
                                                                s.missionKey),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)))),
                                                Positioned(
                                                    right: 16,
                                                    top: 76,
                                                    child: CandyButton(
                                                        icon: Icons
                                                            .lightbulb_outline_rounded,
                                                        label: l.resolve(
                                                            'inventor_hint'),
                                                        onTap: () {
                                                          _engine.showHint();
                                                          unawaited(_audio.cue(
                                                              context,
                                                              [
                                                                'ركّب القطعتين الطويلين فوق، والمكعبات تحت الجنبين.',
                                                                'ابني القوس: صف عريض تحت، وقطع صغيرة فوق في النص.',
                                                                'المرة دي كوبري متدرّج! ركّب القطع على درجات، والمثلث مكانه في الميل.'
                                                              ][s.challenge],
                                                              'Place long blocks across the top and supports underneath.'));
                                                        },
                                                        size: 44)),
                                                if (s.hint)
                                                  Positioned(
                                                      left: 60,
                                                      right: 60,
                                                      top: 65,
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                  8),
                                                          decoration: BoxDecoration(
                                                              color: const Color(
                                                                  0xfffff6df),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      14)),
                                                          child: Text(
                                                              l.resolve(
                                                                  'inventor_hintText'),
                                                              textAlign: TextAlign
                                                                  .center,
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0xff6b4d27))))),
                                                Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 0,
                                                    height: 185,
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .fromLTRB(14,
                                                                12, 14, 6),
                                                        decoration: BoxDecoration(
                                                            color:
                                                                const Color(
                                                                    0xfffff4df),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 3),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                  color: Colors
                                                                      .black26,
                                                                  blurRadius:
                                                                      12)
                                                            ]),
                                                        child: Column(
                                                            children: [
                                                              Expanded(
                                                                  child: GridView.count(
                                                                      physics: const NeverScrollableScrollPhysics(),
                                                                      crossAxisCount: 3,
                                                                      childAspectRatio: 1.9,
                                                                      mainAxisSpacing: 5,
                                                                      crossAxisSpacing: 12,
                                                                      children: s.availablePieces.map((piece) {
                                                                        final used = s
                                                                            .placements
                                                                            .containsKey(piece.id);
                                                                        return Draggable<int>(
                                                                            dragAnchorStrategy:
                                                                                pointerDragAnchorStrategy,
                                                                            data: piece
                                                                                .id,
                                                                            onDragStarted: () => _engine.select(piece
                                                                                .id),
                                                                            maxSimultaneousDrags: used || success
                                                                                ? 0
                                                                                : 1,
                                                                            feedback:
                                                                                Material(color: Colors.transparent, child: Transform.translate(offset: Offset(-unit * piece.length / 2, -unit * piece.height / 2), child: SizedBox(width: unit * piece.length, height: unit * piece.height, child: Sprite(piece.sprite, fit: BoxFit.fill)))),
                                                                            childWhenDragging: Opacity(opacity: .2, child: _TrayPiece(piece)),
                                                                            child: Semantics(button: true, label: '${l.resolve('inventor_piece')} ${piece.id + 1}', selected: s.selected == piece.id, child: GestureDetector(onTap: used || success ? null : () => _engine.select(piece.id), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: s.selected == piece.id ? Colors.orange : Colors.transparent, width: 3)), child: Opacity(opacity: used ? .25 : 1, child: _TrayPiece(piece))))));
                                                                      }).toList())),
                                                              SizedBox(
                                                                  height: 35,
                                                                  child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            child: Text(
                                                                                l.resolve(success
                                                                                    ? 'inventor_success'
                                                                                    : s.feedback == BridgeFeedback.gap
                                                                                        ? 'inventor_gap'
                                                                                        : 'inventor_instruction'),
                                                                                maxLines: 2,
                                                                                textAlign: TextAlign.center,
                                                                                style: const TextStyle(fontSize: 12, color: Color(0xff6b4d27)))),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        FilledButton(
                                                                            onPressed: success
                                                                                ? () {
                                                                                    if (!_cross.isAnimating) _engine.next();
                                                                                  }
                                                                                : _engine.testBridge,
                                                                            style: FilledButton.styleFrom(backgroundColor: const Color(0xff4e9d79)),
                                                                            child: Text(l.resolve(success ? 'inventor_next' : 'inventor_test'), style: const TextStyle(fontSize: 12)))
                                                                      ])),
                                                            ]))),
                                                if (_finished)
                                                  Positioned.fill(
                                                      child: ColoredBox(
                                                          color: Colors.black54,
                                                          child: Center(
                                                              child: Container(
                                                                  width: 330,
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                          24),
                                                                  decoration: BoxDecoration(
                                                                      color: const Color(
                                                                          0xfffff4df),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              24)),
                                                                  child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        const Icon(
                                                                            Icons
                                                                                .emoji_events_rounded,
                                                                            size:
                                                                                72,
                                                                            color:
                                                                                Colors.orange),
                                                                        Text(
                                                                            l.resolve(
                                                                                'inventor_finished'),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                                                        const SizedBox(
                                                                            height:
                                                                                16),
                                                                        FilledButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.maybePop(context);
                                                                            },
                                                                            child:
                                                                                Text(l.resolve('football_exit')))
                                                                      ]))))),
                                              ]));
                                        }))))))));
  }
}

class _BridgeBoard extends StatelessWidget {
  const _BridgeBoard(
      {required this.state,
      required this.engine,
      required this.unit,
      required this.onDrop});
  final InventorState state;
  final InventorCubit engine;
  final double unit;
  final void Function(int, int) onDrop;
  @override
  Widget build(BuildContext context) => Builder(
      builder: (boardContext) =>
          DragTarget<int>(onAcceptWithDetails: (details) {
            final box = boardContext.findRenderObject()! as RenderBox;
            final local =
                box.globalToLocal(details.offset) - const Offset(12, 12);
            final col = (local.dx / unit).floor().clamp(0, state.width - 1);
            final row = (local.dy / unit).floor().clamp(0, 2);
            onDrop(details.data, row * state.width + col);
          }, builder: (context, candidates, rejected) {
            final shapes = switch (state.challenge) {
              0 => {0: 0, 1: 2, 4: 4, 5: 7},
              1 => {0: 5, 1: 8, 2: 7, 3: 1, 4: 2, 5: 3},
              _ => {0: 10, 1: 3, 2: 6, 3: 8, 4: 7, 5: 9}
            };
            return Stack(children: [
              const Positioned.fill(
                  child: ColoredBox(color: Colors.transparent)),
              for (final shape in shapes.entries)
                Positioned(
                    left: 12 + (shape.value % state.width) * unit,
                    top: 12 + (shape.value ~/ state.width) * unit,
                    width: state.pieces[shape.key].length * unit,
                    height: state.pieces[shape.key].height * unit,
                    child: IgnorePointer(
                        child: CustomPaint(
                            painter: _SlotPainter(
                                state.hint ||
                                    candidates.isNotEmpty ||
                                    state.selected != null,
                                triangle: shape.key == 3)))),
              for (final cell in state.targetCells)
                Positioned(
                    left: 12 + (cell % state.width) * unit,
                    top: 12 + (cell ~/ state.width) * unit,
                    width: unit,
                    height: unit,
                    child: GestureDetector(
                        key: ValueKey('bridge_cell_$cell'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => engine.tapCell(cell),
                        child: const SizedBox.expand())),
              for (final entry in state.placements.entries)
                Positioned(
                    left: 12 + (entry.value % state.width) * unit,
                    top: 12 + (entry.value ~/ state.width) * unit,
                    width: state.pieces[entry.key].length * unit,
                    height: state.pieces[entry.key].height * unit,
                    child: GestureDetector(
                        onTap: () => engine.tapCell(entry.value),
                        child: Sprite(state.pieces[entry.key].sprite,
                            fit: BoxFit.fill))),
            ]);
          }));
}

double _walkingY(int stage, double progress) {
  if (stage == 0) return 220;
  if (stage == 1) return 237 - sin(progress * pi) * 44;
  return 184 + progress * 88;
}

class _TrayPiece extends StatelessWidget {
  const _TrayPiece(this.piece);
  final BridgePiece piece;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final unit =
            min(box.maxWidth / piece.length, box.maxHeight / piece.height);
        return Center(
            child: SizedBox(
                width: unit * piece.length,
                height: unit * piece.height,
                child: Sprite(piece.sprite, fit: BoxFit.fill)));
      });
}

class _SlotPainter extends CustomPainter {
  const _SlotPainter(this.highlight, {this.triangle = false});
  final bool triangle;
  final bool highlight;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = highlight ? Colors.yellowAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(1, 1, s.width - 2, s.height - 2);
    final path = triangle
        ? (Path()
          ..moveTo(rect.left, rect.bottom)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..close())
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4))));
    c.drawPath(path,
        Paint()..color = Colors.white.withValues(alpha: highlight ? .25 : .12));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        c.drawPath(metric.extractPath(d, min(d + 5, metric.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) =>
      highlight != old.highlight || triangle != old.triangle;
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 7; i++) {
      final x = s.width * (.34 + (i % 3) * .12),
          y = s.height * (.6 + ((t + i * .14) % 1) * .08);
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x, y),
              width: 18 + sin(t * pi * 2 + i) * 5,
              height: 3),
          Paint()..color = Colors.white.withValues(alpha: .3));
    }
  }

  @override
  bool shouldRepaint(_WaterPainter old) => t != old.t;
}
