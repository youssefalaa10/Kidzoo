import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/host/activity_host_screen.dart';
import 'package:kidzo/features/Adventure/engine/host/background_resolver.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/adventure_runner_cubit.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/ui/story_beat_view.dart';

/// Plays one Adventure end to end.
///
/// Narration beats render inline; an activity node pushes [ActivityHostScreen]
/// and waits for its result. Keeping the story on one screen means the child
/// never loses the thread to a navigation stack, and it is why the book, the
/// backdrop and the progress all stay put while the activities come and go.
class AdventureRunnerScreen extends StatefulWidget {
  const AdventureRunnerScreen({
    required this.bundle,
    required this.registry,
    required this.adventureId,
    required this.profileId,
    required this.storyDao,
    super.key,
    this.narrator,
    this.soundboard,
  });

  final AdventureContentBundle bundle;
  final ActivityEngineRegistry registry;
  final String adventureId;
  final int profileId;
  final StoryDao storyDao;

  /// Injected in tests so nothing tries to speak.
  final ActivityNarrator? narrator;
  final ActivitySoundboard? soundboard;

  @override
  State<AdventureRunnerScreen> createState() => _AdventureRunnerScreenState();
}

class _AdventureRunnerScreenState extends State<AdventureRunnerScreen> {
  static const BackgroundResolver _backgrounds = BackgroundResolver();

  late final AdventureRunnerCubit _runner;
  late final ActivityNarrator _narrator;
  late final ActivitySoundboard _soundboard;

  /// Whether the activity screen is currently on top.
  ///
  /// Guards against pushing the same activity twice if a rebuild lands while
  /// the push is still in flight, and it is part of the rendered state rather
  /// than a plain flag: when the child backs out, this screen has to swap the
  /// bare backdrop for a way back in, and that needs a rebuild.
  bool _isActivityOpen = false;

  void _setActivityOpen(bool isOpen) {
    if (!mounted) {
      _isActivityOpen = isOpen;
      return;
    }
    setState(() => _isActivityOpen = isOpen);
  }

  @override
  void initState() {
    super.initState();
    _narrator = widget.narrator ?? SpeechActivityNarrator();
    _soundboard = widget.soundboard ?? AudioActivitySoundboard();
    _runner = AdventureRunnerCubit(
      bundle: widget.bundle,
      adventureId: widget.adventureId,
      profileId: widget.profileId,
      storyDao: widget.storyDao,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runner.start());
  }

  @override
  void dispose() {
    _runner.close();
    _narrator.cancel();
    _soundboard.dispose();
    super.dispose();
  }

  String get _languageCode =>
      context.read<LanguageCubit>().state.languageCode;

  ActivityServices _servicesFor() {
    return ActivityServices(
      narrator: _narrator,
      soundboard: _soundboard,
      // Seeded from the clock, not fixed: two runs of the same node should not
      // produce an identical board, or a child learns the answer's position.
      random: Random(DateTime.now().millisecondsSinceEpoch),
      attemptSink: _StoryAttemptSink(
        storyDao: widget.storyDao,
        profileId: widget.profileId,
      ),
      languageCode: _languageCode,
    );
  }

  Future<void> _openActivity(StoryNode node) async {
    if (_isActivityOpen) {
      return;
    }
    _setActivityOpen(true);
    try {
      final ActivitySpec spec = widget.bundle.requireActivity(node.activityRef!);
      final ActivityEngine<ActivityContent> engine =
          widget.registry.require(spec.engineId);
      final ActivitySession<ActivityContent> session = engine.createSession(
        spec: spec,
        services: _servicesFor(),
        packs: widget.bundle.packResolver,
        storyNodeId: node.nodeId,
      );

      ActivityResult? result;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => ActivityHostScreen(
            engine: engine,
            session: session,
            title: widget.bundle
                    .requireAdventure(widget.adventureId)
                    .title
                    .resolve(_languageCode),
            onFinished: (ActivityResult value) => result = value,
          ),
        ),
      );

      if (!mounted) {
        return;
      }
      // Cleared before the result is applied, so the frame that renders the
      // outcome already knows the activity screen has gone.
      _setActivityOpen(false);
      if (result != null) {
        await _runner.completeActivity(result!);
      }
    } on ActivityContentException catch (error) {
      if (!mounted) {
        return;
      }
      // Author error. Surface it, but never strand the child on a dead node.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      await _runner.continueStory();
    } finally {
      _setActivityOpen(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double width = MediaQuery.sizeOf(context).width;

    return BlocProvider<AdventureRunnerCubit>.value(
      value: _runner,
      child: BlocConsumer<AdventureRunnerCubit, AdventureRunnerState>(
        bloc: _runner,
        listenWhen: (AdventureRunnerState previous, AdventureRunnerState current) =>
            previous.node?.nodeId != current.node?.nodeId,
        listener: (BuildContext context, AdventureRunnerState state) {
          if (state.isOnActivity && state.node != null) {
            _openActivity(state.node!);
          }
        },
        builder: (BuildContext context, AdventureRunnerState state) {
          final String? background = _backgrounds.resolve(
            state.adventure?.backgroundType,
            width: width,
          );
          return KidGameShell(
            backgroundAsset: background,
            builder: (BuildContext context, KidMetrics metrics) {
              switch (state.status) {
                case AdventureRunnerStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case AdventureRunnerStatus.contentError:
                  return _StoryMessage(
                    metrics: metrics,
                    languageCode: _languageCode,
                    message: state.errorMessage ?? '',
                    buttonLabel: l10n.resolve('goBack', fallback: 'Back'),
                    onTap: () => Navigator.of(context).maybePop(),
                  );
                case AdventureRunnerStatus.finished:
                  return _AdventureCompleteView(
                    metrics: metrics,
                    adventure: state.adventure!,
                    languageCode: _languageCode,
                    onDone: () => Navigator.of(context).maybePop(),
                    doneLabel:
                        l10n.resolve('adventureBackToMap', fallback: 'Back'),
                  );
                case AdventureRunnerStatus.playing:
                  return _buildPlaying(context, metrics, state, l10n);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    KidMetrics metrics,
    AdventureRunnerState state,
    AppLocalizations l10n,
  ) {
    final StoryNode? node = state.node;
    if (node == null) {
      return const SizedBox.shrink();
    }
    if (node.isActivity) {
      if (_isActivityOpen) {
        // The activity screen is on top; show the backdrop rather than a
        // spinner so the transition reads as the story continuing.
        return const SizedBox.shrink();
      }
      // The child backed out of this activity, so the runner deliberately kept
      // them on the node rather than skipping the beat. Without something here
      // they would be looking at an empty backdrop with no way forward, so
      // offer the way back in. The node's own lines explain why it matters.
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.pagePadding,
              metrics.pagePadding * 0.6,
              metrics.pagePadding,
              0,
            ),
            child: _StoryProgressBar(
              metrics: metrics,
              progress: state.progress,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: StoryBeatView(
              node: node,
              languageCode: _languageCode,
              onSpeak: _narrator.speak,
              onContinue: () => _openActivity(node),
              continueLabel: l10n.resolve('adventureResume', fallback: 'Continue'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.pagePadding,
            metrics.pagePadding * 0.6,
            metrics.pagePadding,
            0,
          ),
          child: _StoryProgressBar(
            metrics: metrics,
            progress: state.progress,
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
        Expanded(
          child: StoryBeatView(
            node: node,
            languageCode: _languageCode,
            onSpeak: _narrator.speak,
            onContinue: _runner.continueStory,
            continueLabel: l10n.resolve('storyContinue', fallback: 'Next'),
          ),
        ),
      ],
    );
  }
}

/// Persists engine telemetry for the signed-in child.
class _StoryAttemptSink implements ActivityAttemptSink {
  const _StoryAttemptSink({required this.storyDao, required this.profileId});

  final StoryDao storyDao;
  final int profileId;

  @override
  Future<void> record(ActivityAttemptRecord attempt) {
    return storyDao.recordAttempt(
      profileId: profileId,
      activityId: attempt.activityId,
      stepIndex: attempt.stepIndex,
      attemptIndex: attempt.attemptIndex,
      outcome: attempt.outcome.name,
      scaffoldLevel: attempt.scaffoldLevel.name,
      elapsedMilliseconds: attempt.elapsedMilliseconds,
      storyNodeId: attempt.storyNodeId,
    );
  }
}

/// How far through the Adventure, shown as a filling bar rather than a number.
///
/// A pre-reader cannot read "3 of 8". A bar that grows is a progress meter they
/// can read spatially, which is the same reason the book itself works.
class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.metrics,
    required this.progress,
    required this.onBack,
  });

  final KidMetrics metrics;
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Back',
          child: GestureDetector(
            onTap: () {
              KidHaptics.tap();
              onBack();
            },
            child: Container(
              width: KidUi.minTouch,
              height: KidUi.minTouch,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: KidUi.shadow(KidUi.primary, strength: 0.5),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
        ),
        SizedBox(width: metrics.gap),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KidUi.radiusPill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: metrics.size(16, min: 12, max: 22),
              backgroundColor: Colors.white.withValues(alpha: 0.65),
              valueColor: const AlwaysStoppedAnimation<Color>(KidUi.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdventureCompleteView extends StatelessWidget {
  const _AdventureCompleteView({
    required this.metrics,
    required this.adventure,
    required this.languageCode,
    required this.onDone,
    required this.doneLabel,
  });

  final KidMetrics metrics;
  final Adventure adventure;
  final String languageCode;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    return _StoryMessage(
      metrics: metrics,
      languageCode: languageCode,
      message: adventure.rewardTitle.resolve(languageCode),
      buttonLabel: doneLabel,
      onTap: onDone,
      icon: Icons.auto_stories_rounded,
    );
  }
}

class _StoryMessage extends StatelessWidget {
  const _StoryMessage({
    required this.metrics,
    required this.languageCode,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
    this.icon = Icons.map_outlined,
  });

  final KidMetrics metrics;
  final String languageCode;
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(metrics.pagePadding),
        child: Container(
          padding: EdgeInsets.all(metrics.pagePadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(KidUi.radiusCard),
            boxShadow: KidUi.shadow(KidUi.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon,
                  size: metrics.size(72, min: 52, max: 96),
                  color: KidUi.primary),
              SizedBox(height: metrics.gap),
              ActivityGlyphText(
                message,
                languageCode: languageCode,
                fontSize: metrics.size(22, min: 16, max: 28),
              ),
              SizedBox(height: metrics.gap),
              GestureDetector(
                onTap: () {
                  KidHaptics.tap();
                  onTap();
                },
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: KidUi.minTouch),
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.size(32, min: 22, max: 44),
                  ),
                  decoration: BoxDecoration(
                    color: KidUi.primary,
                    borderRadius: BorderRadius.circular(KidUi.radiusPill),
                  ),
                  alignment: Alignment.center,
                  child: ActivityGlyphText(
                    buttonLabel,
                    languageCode: languageCode,
                    fontSize: metrics.size(18, min: 14, max: 24),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
