import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_cubit.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_feedback_scope.dart';

/// Hear the rhythm, then give it back.
///
/// Every beat is played **and** shown. That is not a courtesy to the hard of
/// hearing alone: the app has a mute switch, children play it in cars and
/// waiting rooms, and an activity that silently becomes unanswerable when the
/// volume is down is broken for a large share of the times it is opened. So
/// the gate flashes each voice as it sings it, and the whole round is solvable
/// with the sound off.
class SoundSequenceBoard extends StatefulWidget {
  const SoundSequenceBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final SoundSequenceStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<SoundSequenceBoard> createState() => _SoundSequenceBoardState();
}

class _SoundSequenceBoardState extends State<SoundSequenceBoard> {
  /// What the child has tapped so far this round.
  final List<String> _given = <String>[];

  /// The voice the gate is singing right now while it plays, or null.
  String? _singing;

  /// True while the gate is playing. The voices are not tappable then — a tap
  /// landing during the demonstration would be counted as part of an answer
  /// the child has not started giving.
  bool _playing = false;

  Timer? _beatTimer;

  /// How far the gate is open, as it is being drawn.
  late double _gateOpen;

  @override
  void initState() {
    super.initState();
    _gateOpen = widget.step.gateOpenAtStart;
    // The gate sings as soon as the round arrives. A replay button that has to
    // be found and pressed before anything happens is a step a four-year-old
    // does not know is required.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SoundSequenceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.step.stepId != widget.step.stepId) {
      _beatTimer?.cancel();
      setState(() {
        _given.clear();
        _singing = null;
        _playing = false;
        _gateOpen = widget.step.gateOpenAtStart;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
      return;
    }

    final AttemptOutcome? now = widget.state.lastOutcome;
    final AttemptOutcome? before = oldWidget.state.lastOutcome;
    if (now == before) {
      return;
    }
    if (now == AttemptOutcome.correct) {
      setState(() => _gateOpen = widget.step.gateOpenWhenDone);
      return;
    }
    if (now == AttemptOutcome.wrongItem ||
        now == AttemptOutcome.wrongSlotButRightItem) {
      // The gate eases shut rather than slamming, the taps are cleared, and
      // the rhythm comes round again. There is no red, no buzzer and nothing
      // that reads as being told off: the child hears the question a second
      // time, which is the actual help they need.
      setState(() {
        _given.clear();
        _gateOpen = widget.step.gateOpenAtStart;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  /// Plays the rhythm: one voice lit and sounded per beat.
  void _play() {
    if (!mounted || _playing) {
      return;
    }
    final List<String> sequence = widget.step.round.sequence;
    // The ladder slows the rhythm down rather than shortening it. A shorter
    // rhythm is a different question; a slower one is the same question with
    // more room to hear it.
    final int beat = switch (widget.state.scaffoldLevel) {
      ScaffoldLevel.initial => widget.step.beatMilliseconds,
      ScaffoldLevel.gentleRetry =>
        (widget.step.beatMilliseconds * 1.15).round(),
      ScaffoldLevel.narrowed => (widget.step.beatMilliseconds * 1.3).round(),
      ScaffoldLevel.modelled => (widget.step.beatMilliseconds * 1.5).round(),
    };

    setState(() {
      _playing = true;
      _given.clear();
    });

    int index = 0;
    void tick() {
      if (!mounted) {
        return;
      }
      if (index >= sequence.length) {
        setState(() {
          _playing = false;
          _singing = null;
        });
        return;
      }
      final String voiceId = sequence[index];
      setState(() => _singing = voiceId);
      _sing(voiceId);
      index++;
      _beatTimer = Timer(Duration(milliseconds: beat), tick);
    }

    tick();
  }

  /// Sounds one voice, if there is anything to sound it with.
  ///
  /// Every branch here is a no-op that still leaves the round winnable: no
  /// host (a board pumped straight by a widget test), no audio device, a muted
  /// phone, or an asset that is not bundled. The flash has already happened by
  /// the time this is called, and the flash is the part the round depends on.
  void _sing(String voiceId) {
    final SoundVoice? voice = _voice(voiceId);
    if (voice == null) {
      return;
    }
    ActivityFeedbackScope.maybeOf(context)?.soundboard.playAsset(
          voice.audioAsset,
        );
  }

  SoundVoice? _voice(String id) {
    for (final SoundVoice voice in widget.step.voices) {
      if (voice.id == id) {
        return voice;
      }
    }
    return null;
  }

  bool get _isLive => !widget.state.isBoardLocked && !_playing;

  void _tap(SoundVoice voice) {
    if (!_isLive || _given.length >= widget.step.round.length) {
      return;
    }
    _sing(voice.id);
    setState(() {
      _singing = voice.id;
      _given.add(voice.id);
    });
    // The flash has to outlive the tap or a fast child sees nothing.
    Timer(const Duration(milliseconds: 180), () {
      if (mounted && _singing == voice.id) {
        setState(() => _singing = null);
      }
    });

    if (_given.length == widget.step.round.length) {
      widget.submit(SequenceAttempt(List<String>.unmodifiable(_given)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String language = widget.state.languageCode;
    final Color accent = widget.step.accentColorValue == null
        ? KidUi.primary
        : Color(widget.step.accentColorValue!);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;

        // The voices are measured against the width they actually have, with
        // the gaps counted in, rather than against a guess. One row always:
        // wrapping the voices would move a creature between rounds, which is
        // the one thing this board promised not to do.
        final int count = widget.step.voices.length;
        const double gap = 10;
        final double voiceSize = math.min(
          KidUi.minTouchYoung,
          math.min(
            (width - gap * (count + 1)) / count,
            height * 0.34,
          ),
        );
        final double beatSize = math.min(14, voiceSize * 0.16);
        final double replaySize = math.min(KidUi.minTouch, height * 0.14);

        // Every other row is measured before the gate is given what is left,
        // rather than the gate taking a share of the height and the rest
        // hoping to fit. Approximating this as "height minus about seventy"
        // overflowed 780x390 by eight pixels — which is the whole reason the
        // arithmetic is written out instead of estimated.
        final double spent = voiceSize + beatSize + replaySize + gap * 3;
        final double gateHeight =
            math.max(48, math.min(height - spent, height * 0.42));

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: math.min(width, gateHeight * 1.9),
              height: gateHeight,
              child: _Gate(
                open: _gateOpen,
                accent: accent,
                pulsing: _playing,
              ),
            ),
            const SizedBox(height: gap),
            _BeatTrack(
              total: widget.step.round.length,
              filled: _given.length,
              accent: accent,
              size: beatSize,
            ),
            const SizedBox(height: gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final SoundVoice voice in widget.step.voices) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                    child: _VoiceButton(
                      voice: voice,
                      size: voiceSize,
                      accent: accent,
                      singing: _singing == voice.id,
                      enabled: _isLive,
                      hinted: widget.state.isDemonstrating &&
                          widget.state.view?.highlightOptionId == voice.id,
                      label: voice.label.resolve(language),
                      onTap: () => _tap(voice),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: gap),
            _ReplayButton(
              accent: accent,
              // Replaying is always free and never an attempt. A child who
              // needs to hear it five times has not made five mistakes, and
              // charging them for listening would teach exactly the wrong
              // lesson about what to do when you did not catch something.
              enabled: !_playing && !widget.state.isBoardLocked,
              size: replaySize,
              onPressed: _play,
            ),
          ],
        );
      },
    );
  }
}

/// How many beats are in, how many are left. Dots, not a number: the child is
/// tracking a position in a sequence, and four dots with two filled says that
/// directly to someone who cannot read "2/4".
class _BeatTrack extends StatelessWidget {
  const _BeatTrack({
    required this.total,
    required this.filled,
    required this.accent,
    required this.size,
  });

  final int total;
  final int filled;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled of $total beats',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 0; index < total; index++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.3),
              child: AnimatedContainer(
                duration: KidUi.fast,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < filled
                      ? KidUi.hint
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The reef gate. Two leaves that part as rhythms are answered and stay parted.
class _Gate extends StatelessWidget {
  const _Gate({
    required this.open,
    required this.accent,
    required this.pulsing,
  });

  /// 0 shut, 1 fully open.
  final double open;

  final Color accent;

  /// True while the rhythm is being played, so the gap breathes in time and
  /// the sound has a visible source.
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'the gate',
      value: open <= 0
          ? 'closed'
          : open >= 1
              ? 'open'
              : 'opening',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double height = box.maxHeight;
          final double width = box.maxWidth;
          final double travel =
              width * 0.42 * Curves.easeOutCubic.transform(open);

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // The light beyond the gate, which is the reason to open it.
              AnimatedOpacity(
                opacity: (0.25 + open * 0.75).clamp(0.0, 1.0),
                duration: KidUi.medium,
                child: Container(
                  width: width * 0.3,
                  height: height * 0.92,
                  decoration: BoxDecoration(
                    color: KidUi.hint.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(width * 0.1),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: KidUi.hint.withValues(alpha: 0.5 * (0.3 + open)),
                        blurRadius: width * 0.25,
                        spreadRadius: width * 0.02,
                      ),
                    ],
                  ),
                ),
              ),
              for (final int side in <int>[-1, 1])
                AnimatedPositioned(
                  duration: KidUi.medium,
                  curve: Curves.easeOutCubic,
                  left: side < 0 ? -travel : null,
                  right: side > 0 ? -travel : null,
                  child: AnimatedScale(
                    scale: pulsing ? 1.015 : 1,
                    duration: KidUi.fast,
                    child: Container(
                      width: width * 0.5,
                      height: height,
                      decoration: BoxDecoration(
                        color: Color.lerp(accent, Colors.black, 0.35) ?? accent,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(side < 0 ? 8 : width * 0.16),
                          right: Radius.circular(side < 0 ? width * 0.16 : 8),
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One creature, waiting to be asked for its note.
class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.voice,
    required this.size,
    required this.accent,
    required this.singing,
    required this.enabled,
    required this.hinted,
    required this.label,
    required this.onTap,
  });

  final SoundVoice voice;
  final double size;
  final Color accent;
  final bool singing;
  final bool enabled;
  final bool hinted;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          scale: singing ? 1.12 : 1,
          duration: KidUi.fast,
          child: AnimatedContainer(
            duration: KidUi.fast,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: singing ? 0.95 : (enabled ? 0.7 : 0.4)),
              borderRadius: BorderRadius.circular(size * 0.26),
              border: Border.all(
                color: singing || hinted
                    ? KidUi.hint
                    : accent.withValues(alpha: 0.45),
                width: singing || hinted ? 4 : 2,
              ),
              boxShadow: singing || hinted
                  ? <BoxShadow>[
                      BoxShadow(
                        color: KidUi.hint.withValues(alpha: 0.6),
                        blurRadius: size * 0.35,
                        spreadRadius: size * 0.03,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Image.asset(voice.item.imageAsset, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Play it again". Always available, never an attempt.
class _ReplayButton extends StatelessWidget {
  const _ReplayButton({
    required this.accent,
    required this.enabled,
    required this.size,
    required this.onPressed,
  });

  final Color accent;
  final bool enabled;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'hear the rhythm again',
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: KidUi.fast,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: KidUi.shadow(accent, strength: 0.6),
            ),
            child: Icon(
              Icons.replay_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
