import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

/// A narration beat: the companion says something, the child taps on.
///
/// Lines are revealed one at a time rather than all at once. A wall of text a
/// pre-reader cannot read is not a story, it is a pause; one short spoken line
/// with a tap between each keeps the child in the loop instead of waiting for
/// the app to finish talking at them.
class StoryBeatView extends StatefulWidget {
  const StoryBeatView({
    required this.node,
    required this.languageCode,
    required this.onSpeak,
    required this.onContinue,
    required this.continueLabel,
    required this.nextLabel,
    required this.replayLabel,
    super.key,
    this.accent = KidUi.primary,
  });

  final StoryNode node;
  final String languageCode;

  /// Speaks a line. Injected rather than called directly so this widget stays
  /// testable without a TTS engine.
  final Future<void> Function(String line) onSpeak;

  final VoidCallback onContinue;

  /// What the button says on the **last** line of the beat: the thing that
  /// happens next, which differs between a story beat and an activity node.
  final String continueLabel;

  /// What it says on every other line. Always a real word.
  ///
  /// It used to say `...`, and three dots is not an instruction. A child who
  /// cannot read still learns the *shape* of the word that means "go on", and
  /// gets it read to them by a parent exactly once; they can learn nothing at
  /// all from an ellipsis, and an adult reading over their shoulder cannot tell
  /// them whether it means "wait, it is loading" or "tap me".
  final String nextLabel;

  /// Spoken-line replay. Labelled for screen readers only; the control itself
  /// is an icon, because its meaning is the sound it makes.
  final String replayLabel;

  final Color accent;

  @override
  State<StoryBeatView> createState() => _StoryBeatViewState();
}

class _StoryBeatViewState extends State<StoryBeatView> {
  int _visibleLineIndex = 0;

  /// Set the instant the last line is tapped through.
  ///
  /// A four-year-old taps the same spot three times in half a second. Without
  /// this the beat fired `onContinue` on every one of those taps, which for a
  /// story beat meant skipping two beats and for an activity node meant racing
  /// two pushes of the same activity screen.
  bool _hasHandedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentLine());
  }

  @override
  void didUpdateWidget(StoryBeatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.nodeId != widget.node.nodeId) {
      setState(() {
        _visibleLineIndex = 0;
        _hasHandedOff = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentLine());
    }
  }

  void _speakCurrentLine() {
    if (!mounted || _visibleLineIndex >= widget.node.lines.length) {
      return;
    }
    final String line =
        widget.node.lines[_visibleLineIndex].resolve(widget.languageCode);
    if (line.isNotEmpty) {
      // Not awaited: the beat must stay tappable while it is talking. The
      // narrator's latest-wins rule is what keeps that from overlapping.
      widget.onSpeak(line);
    }
  }

  bool get _isOnLastLine => _visibleLineIndex >= widget.node.lines.length - 1;

  void _advance() {
    if (_hasHandedOff) {
      return;
    }
    KidHaptics.tap();
    if (_isOnLastLine) {
      _hasHandedOff = true;
      widget.onContinue();
      return;
    }
    setState(() => _visibleLineIndex++);
    _speakCurrentLine();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        final List<LocalizedText> lines = widget.node.lines;

        return GestureDetector(
          // The whole beat is tappable, not just a button. A four-year-old
          // aiming for a small "next" is a four-year-old who gets stuck. The
          // button is still there — it is what tells them tapping is the thing
          // to do — but it is a label on the gesture, not the only target.
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Padding(
            padding: EdgeInsets.all(metrics.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.node.speakerArt != null)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: metrics.gap),
                      child: Image.asset(
                        widget.node.speakerArt!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(metrics.size(20, min: 14, max: 30)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(KidUi.radiusCard),
                    boxShadow: KidUi.shadow(widget.accent),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int index = 0;
                          index <= _visibleLineIndex && index < lines.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(bottom: metrics.gap * 0.4),
                          child: ActivityGlyphText(
                            lines[index].resolve(widget.languageCode),
                            languageCode: widget.languageCode,
                            fontSize: metrics.size(22, min: 16, max: 28),
                            color: KidUi.ink,
                          ),
                        ),
                      SizedBox(height: metrics.gap * 0.4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _ReplayButton(
                            metrics: metrics,
                            accent: widget.accent,
                            label: widget.replayLabel,
                            onTap: _speakCurrentLine,
                          ),
                          SizedBox(width: metrics.gap * 0.6),
                          Flexible(
                            child: _ContinueButton(
                              metrics: metrics,
                              label: _isOnLastLine
                                  ? widget.continueLabel
                                  : widget.nextLabel,
                              accent: widget.accent,
                              languageCode: widget.languageCode,
                              onTap: _advance,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Says the current line again.
///
/// Audio is primary for a pre-reader, and a line they missed is a line they
/// cannot get back without one of these. Cheap to provide and the same control
/// the activity host already puts on its prompt banner, so it behaves the same
/// way in both halves of an Adventure.
class _ReplayButton extends StatelessWidget {
  const _ReplayButton({
    required this.metrics,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final KidMetrics metrics;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double size = metrics.size(KidUi.minTouch, min: 56, max: 88);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          KidHaptics.tap();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(
            Icons.volume_up_rounded,
            size: size * 0.5,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.metrics,
    required this.label,
    required this.accent,
    required this.languageCode,
    required this.onTap,
  });

  final KidMetrics metrics;
  final String label;
  final Color accent;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRtl = ActivityGlyphText.isRightToLeft(languageCode);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: metrics.size(KidUi.minTouch, min: 56, max: 88),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: metrics.size(26, min: 18, max: 34),
            vertical: metrics.size(12, min: 8, max: 16),
          ),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(KidUi.radiusPill),
            boxShadow: KidUi.shadow(accent, strength: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: ActivityGlyphText(
                  label,
                  languageCode: languageCode,
                  fontSize: metrics.size(18, min: 14, max: 24),
                  color: Colors.white,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: metrics.gap * 0.3),
              // The arrow follows the reading direction, so "onward" points
              // the way the child's eye already travels.
              Icon(
                isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: metrics.size(22, min: 18, max: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
