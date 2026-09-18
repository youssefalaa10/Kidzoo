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
    super.key,
    this.accent = KidUi.primary,
  });

  final StoryNode node;
  final String languageCode;

  /// Speaks a line. Injected rather than called directly so this widget stays
  /// testable without a TTS engine.
  final Future<void> Function(String line) onSpeak;

  final VoidCallback onContinue;
  final String continueLabel;
  final Color accent;

  @override
  State<StoryBeatView> createState() => _StoryBeatViewState();
}

class _StoryBeatViewState extends State<StoryBeatView> {
  int _visibleLineIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentLine());
  }

  @override
  void didUpdateWidget(StoryBeatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.nodeId != widget.node.nodeId) {
      setState(() => _visibleLineIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentLine());
    }
  }

  void _speakCurrentLine() {
    if (_visibleLineIndex >= widget.node.lines.length) {
      return;
    }
    final String line =
        widget.node.lines[_visibleLineIndex].resolve(widget.languageCode);
    if (line.isNotEmpty) {
      widget.onSpeak(line);
    }
  }

  bool get _isOnLastLine => _visibleLineIndex >= widget.node.lines.length - 1;

  void _advance() {
    KidHaptics.tap();
    if (_isOnLastLine) {
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
          // aiming for a small "next" is a four-year-old who gets stuck.
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
                          child: AnimatedOpacity(
                            duration: KidUi.medium,
                            opacity: 1,
                            child: ActivityGlyphText(
                              lines[index].resolve(widget.languageCode),
                              languageCode: widget.languageCode,
                              fontSize: metrics.size(22, min: 16, max: 28),
                              color: KidUi.ink,
                            ),
                          ),
                        ),
                      SizedBox(height: metrics.gap * 0.4),
                      _ContinueHint(
                        metrics: metrics,
                        label: _isOnLastLine ? widget.continueLabel : '...',
                        accent: widget.accent,
                        languageCode: widget.languageCode,
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

class _ContinueHint extends StatelessWidget {
  const _ContinueHint({
    required this.metrics,
    required this.label,
    required this.accent,
    required this.languageCode,
  });

  final KidMetrics metrics;
  final String label;
  final Color accent;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: KidUi.minTouch),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.size(26, min: 18, max: 34),
        vertical: metrics.size(12, min: 8, max: 16),
      ),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
      ),
      alignment: Alignment.center,
      child: ActivityGlyphText(
        label,
        languageCode: languageCode,
        fontSize: metrics.size(18, min: 14, max: 24),
        color: Colors.white,
      ),
    );
  }
}
