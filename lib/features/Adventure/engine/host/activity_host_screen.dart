import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/core/shared/widgets/kid_result_view.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/host/background_resolver.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_feedback_scope.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_stage.dart';

/// The one screen every activity runs inside.
///
/// It owns **all** chrome: shell, background, top bar, prompt banner, help
/// button, result view, precache and the content-error card. An engine
/// contributes only the board in the middle.
///
/// That split is the correction to the previous attempt. `QuizEngineScreen`
/// tried to share the *board* — a fixed layout with no extension points — so
/// its one real consumer wrote 280 lines of its own layout and ignored it.
/// Sharing the chrome instead means a new engine inherits everything that makes
/// an activity feel like Kidzo, and can still look like whatever it needs to.
class ActivityHostScreen extends StatefulWidget {
  const ActivityHostScreen({
    required this.engine,
    required this.session,
    required this.title,
    super.key,
    this.onFinished,
    this.continueLabel,
    this.heroAsset,
  });

  final ActivityEngine<ActivityContent> engine;
  final ActivitySession<ActivityContent> session;
  final String title;

  /// Called with the result when the child finishes or leaves. The story layer
  /// uses this to advance the beat; free play uses it to pop.
  final void Function(ActivityResult result)? onFinished;

  /// Label on the result view's primary button. In a story this continues the
  /// narrative rather than replaying the activity.
  final String? continueLabel;

  final String? heroAsset;

  @override
  State<ActivityHostScreen> createState() => _ActivityHostScreenState();
}

class _ActivityHostScreenState extends State<ActivityHostScreen>
    with WidgetsBindingObserver {
  static const BackgroundResolver _backgrounds = BackgroundResolver();

  late final ActivityCubit<ActivityContent, dynamic> _cubit;
  late final ActivityBoardBuilder _board;
  bool _hasPrecached = false;
  bool _hasReportedResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = widget.engine.createCubit(widget.session);
    _board = widget.engine.createBoard();
    // Kicked off after the first frame so the shell paints immediately rather
    // than holding on the first narration.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPrecached) {
      return;
    }
    _hasPrecached = true;
    // Precache here, not in initState: a card popping in after the prompt has
    // already named it reads as the app being broken.
    for (final String asset in widget.engine.assetsFor(widget.session.content)) {
      precacheImage(AssetImage(asset), context).catchError((Object _) {
        // A missing asset is caught by the content test; at runtime it must not
        // take the activity down.
      });
    }
  }

  /// Silences narration the moment the app stops being in front of the child.
  ///
  /// An activity talks more than a story beat does — prompt, hint, reveal — so
  /// it is the likelier place to leave a sentence hanging in the air across a
  /// backgrounding and have it collide with whatever speaks on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      widget.session.services.narrator.cancel();
      // Secondary safety only: the step the child is on was already persisted
      // when they reached it. This just carries across the score and hints
      // earned *inside* a step that a backgrounding interrupts.
      unawaited(_cubit.flushCheckpoint());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  String get _languageCode => widget.session.services.languageCode;

  void _handleFinished(ActivityResult result) {
    if (_hasReportedResult) {
      return;
    }
    _hasReportedResult = true;
    widget.onFinished?.call(result);
  }

  Future<bool> _confirmExit() async {
    await _cubit.abandon();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final String? background = _backgrounds.resolve(
      widget.session.spec.presentation.backgroundType,
      width: width,
    );

    return BlocProvider<ActivityCubit<ActivityContent, dynamic>>.value(
      value: _cubit,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? _) async {
          if (didPop) {
            return;
          }
          await _confirmExit();
          if (!mounted) {
            return;
          }
          Navigator.of(this.context).pop();
        },
        child: KidGameShell(
          backgroundAsset: background,
          builder: (BuildContext context, KidMetrics metrics) {
            return BlocConsumer<ActivityCubit<ActivityContent, dynamic>,
                ActivityState>(
              listenWhen: (ActivityState previous, ActivityState current) =>
                  previous.status != current.status,
              listener: (BuildContext context, ActivityState state) {
                if (state.status == ActivityStatus.finished) {
                  _handleFinished(state.result);
                }
              },
              builder: (BuildContext context, ActivityState state) {
                switch (state.status) {
                  case ActivityStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ActivityStatus.contentError:
                    return _ContentErrorCard(
                      metrics: metrics,
                      message: state.errorMessage ?? 'unknown content problem',
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  case ActivityStatus.finished:
                    return _buildResult(context, metrics, state);
                  case ActivityStatus.running:
                    return _buildRunning(context, metrics, state);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRunning(
    BuildContext context,
    KidMetrics metrics,
    ActivityState state,
  ) {
    final ActivityStepView? view = state.view;
    final String prompt = view?.prompt.resolve(_languageCode) ?? '';

    return Padding(
      padding: EdgeInsets.all(metrics.pagePadding),
      child: Column(
        children: <Widget>[
          KidTopBar(
            metrics: metrics,
            current: state.stepIndex + 1,
            total: state.stepCount,
            score: state.result.score,
            onBack: () async {
              await _confirmExit();
              if (!mounted) {
                return;
              }
              Navigator.of(this.context).pop();
            },
            onReplayPrompt: state.isBoardLocked
                ? null
                : () => _cubit.submit(const HelpRequestedAttempt()),
          ),
          SizedBox(height: metrics.gap),
          // The banner is the prompt's written form; tapping it repeats the
          // spoken one, because audio is primary for a pre-reader and text is
          // decoration.
          _PromptBanner(
            metrics: metrics,
            text: prompt,
            languageCode: _languageCode,
            // The thing being built, if this activity is building one. It rides
            // in the banner's row rather than a band of its own, so it costs no
            // vertical space on the layouts that have none to give.
            stage: widget.session.spec.presentation.stage,
            stageProgress: state.progress,
            onSpeak: state.isBoardLocked
                ? null
                : () => _cubit.submit(const HelpRequestedAttempt()),
          ),
          SizedBox(height: metrics.gap),
          Expanded(
            child: AbsorbPointer(
              absorbing: state.isBoardLocked,
              child: ActivityFeedbackScope(
                soundboard: widget.session.services.soundboard,
                child: _board(
                  context,
                  state,
                  (ActivityAttempt attempt) => _cubit.submit(attempt),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    KidMetrics metrics,
    ActivityState state,
  ) {
    final String? continueLabel = widget.continueLabel;
    if (continueLabel != null) {
      // Inside a story. The free-play result view offers "Play again" and
      // "Exit", and in this context **both of them popped back to the story** —
      // so the prominent button was labelled with something it did not do, and
      // the child was asked to choose between two buttons that were the same
      // button. One button, saying the one thing that happens.
      return _StoryResultView(
        metrics: metrics,
        score: state.result.score,
        maxScore: state.result.maxScore,
        title: widget.title,
        continueLabel: continueLabel,
        languageCode: _languageCode,
        onContinue: () => Navigator.of(context).maybePop(),
      );
    }
    return KidResultView(
      metrics: metrics,
      score: state.result.score,
      maxScore: state.result.maxScore,
      title: widget.title,
      onPlayAgain: () => Navigator.of(context).maybePop(),
      onExit: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The end of an activity that is part of a story.
///
/// Stars, because finishing should feel like finishing, and then exactly one
/// way onward. Nothing here offers a replay: the story has already moved, and
/// a child who replays a beat the narrative has passed ends up in a loop with
/// no visible way out of it.
class _StoryResultView extends StatelessWidget {
  const _StoryResultView({
    required this.metrics,
    required this.score,
    required this.maxScore,
    required this.title,
    required this.continueLabel,
    required this.languageCode,
    required this.onContinue,
  });

  final KidMetrics metrics;
  final int score;
  final int maxScore;
  final String title;
  final String continueLabel;
  final String languageCode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final int stars = KidResultView.starsFor(score, maxScore);
    final double starSize = metrics.size(64, min: 42, max: 88);
    final bool isRtl = ActivityGlyphText.isRightToLeft(languageCode);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(metrics.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int index = 0; index < 3; index++)
                  Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: starSize * (index == 1 ? 1.2 : 1),
                    color: index < stars ? KidUi.hint : Colors.white70,
                  ),
              ],
            ),
            SizedBox(height: metrics.gap),
            ActivityGlyphText(
              title,
              languageCode: languageCode,
              fontSize: metrics.size(28, min: 20, max: 36),
              color: Colors.white,
            ),
            SizedBox(height: metrics.gap * 1.4),
            Semantics(
              button: true,
              label: continueLabel,
              child: GestureDetector(
                onTap: () {
                  KidHaptics.tap();
                  onContinue();
                },
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: metrics.size(KidUi.minTouch, min: 56, max: 88),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.size(34, min: 24, max: 48),
                  ),
                  decoration: BoxDecoration(
                    color: KidUi.correct,
                    borderRadius: BorderRadius.circular(KidUi.radiusPill),
                    boxShadow: KidUi.shadow(KidUi.correct),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ActivityGlyphText(
                        continueLabel,
                        languageCode: languageCode,
                        fontSize: metrics.size(22, min: 16, max: 28),
                        color: Colors.white,
                        maxLines: 1,
                      ),
                      SizedBox(width: metrics.gap * 0.4),
                      Icon(
                        isRtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: metrics.size(24, min: 18, max: 30),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps [KidPromptBanner] so content text goes through [ActivityGlyphText].
class _PromptBanner extends StatelessWidget {
  const _PromptBanner({
    required this.metrics,
    required this.text,
    required this.languageCode,
    this.stage,
    this.stageProgress = 0,
    this.onSpeak,
  });

  final KidMetrics metrics;
  final String text;
  final String languageCode;
  final ActivityStageSpec? stage;
  final double stageProgress;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onSpeak != null,
      label: text,
      child: GestureDetector(
        onTap: onSpeak == null
            ? null
            : () {
                KidHaptics.tap();
                onSpeak!();
              },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.size(18, min: 12, max: 26),
            vertical: metrics.size(14, min: 10, max: 20),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(KidUi.radiusCard),
            boxShadow: KidUi.shadow(KidUi.primary, strength: 0.6),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.volume_up_rounded,
                size: metrics.size(30, min: 24, max: 40),
                color: KidUi.primary,
              ),
              SizedBox(width: metrics.gap * 0.6),
              Expanded(
                child: ActivityGlyphText(
                  text,
                  languageCode: languageCode,
                  fontSize: metrics.size(22, min: 16, max: 28),
                  textAlign: TextAlign.start,
                  color: KidUi.ink,
                ),
              ),
              if (stage != null) ...<Widget>[
                SizedBox(width: metrics.gap * 0.6),
                ActivityStage(
                  spec: stage!,
                  progress: stageProgress,
                  size: metrics.size(56, min: 44, max: 84),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when content is malformed. An author error should be legible, not a
/// red screen of Flutter internals, and the child should still be able to leave.
class _ContentErrorCard extends StatelessWidget {
  const _ContentErrorCard({
    required this.metrics,
    required this.message,
    required this.onBack,
  });

  final KidMetrics metrics;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(metrics.pagePadding),
        child: Container(
          padding: EdgeInsets.all(metrics.pagePadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(KidUi.radiusCard),
            boxShadow: KidUi.shadow(KidUi.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.map_outlined,
                  size: metrics.size(64, min: 48, max: 84),
                  color: KidUi.primary),
              SizedBox(height: metrics.gap),
              Text(
                'This part of the story is still being drawn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: metrics.size(20, min: 16, max: 26),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: metrics.gap * 0.5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: metrics.size(12, min: 10, max: 14),
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: metrics.gap),
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(metrics.size(160), KidUi.minTouch),
                  backgroundColor: KidUi.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KidUi.radiusPill),
                  ),
                ),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
