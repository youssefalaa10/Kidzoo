import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
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
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward_overlay.dart';
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

class _AdventureRunnerScreenState extends State<AdventureRunnerScreen>
    with WidgetsBindingObserver {
  static const BackgroundResolver _backgrounds = BackgroundResolver();

  late final AdventureRunnerCubit _runner;
  late final ActivityNarrator _narrator;
  late final ActivitySoundboard _soundboard;

  /// Where a recovered page flies to. Read off the real widget rather than
  /// guessed at, so the animation lands on the book the child then sees.
  final GlobalKey _bookKey = GlobalKey();

  /// Whether the activity screen is currently on top.
  ///
  /// Guards against pushing the same activity twice if a rebuild lands while
  /// the push is still in flight, and it is part of the rendered state rather
  /// than a plain flag: when the child backs out, this screen has to swap the
  /// bare backdrop for a way back in, and that needs a rebuild.
  bool _isActivityOpen = false;

  /// The reward currently being celebrated, if any.
  AdventureReward? _celebrating;

  /// Bumped when a page lands in the book, so the book badge can react.
  int _pagesInBook = 0;

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
    WidgetsBinding.instance.addObserver(this);
    _narrator = widget.narrator ?? SpeechActivityNarrator();
    // Honours the app's own sound switch. Without this the Adventure was the
    // one place in the app that ignored it — which went unnoticed while the
    // only sounds were short reactions, and stopped being ignorable once an
    // activity's question was itself a sequence of tones.
    _soundboard = widget.soundboard ??
        AudioActivitySoundboard(
          isEnabled: () => context.read<MusicCubit>().state.isSoundEnabled,
        );
    _runner = AdventureRunnerCubit(
      bundle: widget.bundle,
      adventureId: widget.adventureId,
      profileId: widget.profileId,
      storyDao: widget.storyDao,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runner.start());
  }

  /// Stops talking when the app goes away.
  ///
  /// Without this, a child who is handed the phone back — or who takes a call,
  /// or whose parent switches apps — comes back to a half-finished sentence
  /// from a beat they may no longer be on, or to two voices once the beat they
  /// *are* on starts speaking. Backgrounding is not a rare path at this age; it
  /// is most of how a session ends.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      _narrator.cancel();
      // Secondary only. The resume point is already written on entering every
      // node, so nothing here is load-bearing — which is the point: the app
      // being killed outright is the case that actually happens, and it never
      // reaches a lifecycle callback.
      unawaited(_runner.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runner.close();
    _narrator.cancel();
    _soundboard.dispose();
    super.dispose();
  }

  String get _languageCode => context.read<LanguageCubit>().state.languageCode;

  ActivityServices _servicesFor(int seed) {
    return ActivityServices(
      narrator: _narrator,
      soundboard: _soundboard,
      // Seeded from the clock for a fresh run, so two runs of the same node do
      // not produce an identical board and a child cannot learn the answer's
      // position — but from the **stored** seed when resuming, because "step
      // three" only means anything alongside the seed that decided what step
      // three is.
      random: Random(seed),
      attemptSink: _StoryAttemptSink(
        storyDao: widget.storyDao,
        profileId: widget.profileId,
      ),
      checkpointSink: _StoryCheckpointSink(
        storyDao: widget.storyDao,
        profileId: widget.profileId,
        adventureId: widget.adventureId,
      ),
      languageCode: _languageCode,
    );
  }

  /// A fresh seed for a run that is not resuming.
  ///
  /// Masked to stay inside the positive 32-bit range `Random` accepts, and
  /// small enough to round-trip through JSON without surprises.
  static int _freshSeed() =>
      DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  Future<void> _openActivity(
    StoryNode node, {
    ActivityCheckpoint? resume,
  }) async {
    if (_isActivityOpen) {
      return;
    }
    _setActivityOpen(true);
    // A no-op on the ordinary path now: `StoryBeatView` will not hand off until
    // the line it is on has finished, so there is nothing left in the air to
    // cut. It stays for the paths that do not come through a finished beat —
    // re-entry after backing out, and a resume that lands straight on an
    // activity node — where the activity is about to speak its own prompt and
    // must not do so over anything else.
    await _narrator.cancel();
    if (!mounted) {
      return;
    }
    try {
      final ActivitySpec spec =
          widget.bundle.requireActivity(node.activityRef!);
      final ActivityEngine<ActivityContent> engine =
          widget.registry.require(spec.engineId);
      final int seed = resume?.seed ?? _freshSeed();
      final ActivitySession<ActivityContent> session = engine.createSession(
        spec: spec,
        services: _servicesFor(seed),
        packs: widget.bundle.packResolver,
        storyNodeId: node.nodeId,
        seed: seed,
        resume: resume,
      );
      final AppLocalizations l10n = AppLocalizations.of(context);

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
            // Present, and that is what switches the host's result screen from
            // the free-play one — two equal buttons, one of them labelled
            // "Play again" while actually leaving — to a single button that
            // says what really happens next: the story carries on.
            continueLabel: l10n.resolve('storyContinue', fallback: 'Next'),
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
        await _runner.completeActivity(result!, fromNodeId: node.nodeId);
      }
    } on ActivityContentException catch (error) {
      if (!mounted) {
        return;
      }
      // Author error. Surface it, but never strand the child on a dead node.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      await _runner.continueStory(fromNodeId: node.nodeId);
    } finally {
      _setActivityOpen(false);
    }
  }

  /// Works out where the book badge is, in the overlay's coordinates.
  Offset? _bookDestination() {
    final BuildContext? bookContext = _bookKey.currentContext;
    final RenderBox? book = bookContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay = context.findRenderObject() as RenderBox?;
    if (book == null || overlay == null || !book.hasSize) {
      return null;
    }
    return overlay.globalToLocal(
      book.localToGlobal(book.size.center(Offset.zero)),
    );
  }

  void _startCelebration(AdventureRunnerState state) {
    final String? rewardId = state.justEarnedRewardId;
    final Adventure? adventure = state.adventure;
    if (rewardId == null || adventure == null || _celebrating != null) {
      return;
    }
    // Silence whatever the activity left in the air before the beat that
    // introduces the page starts speaking over it. The beat's own lines are
    // the right soundtrack for the flight, so this clears the way for them
    // rather than replacing them.
    _narrator.cancel();
    setState(() {
      _celebrating = AdventureReward(
        rewardId: rewardId,
        adventureId: adventure.adventureId,
        title: adventure.rewardTitle,
        art: adventure.rewardArt,
        accentValue: adventure.accentColorValue,
      );
    });
  }

  void _endCelebration() {
    if (_celebrating == null) {
      return;
    }
    setState(() {
      _celebrating = null;
      _pagesInBook++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double width = MediaQuery.sizeOf(context).width;

    return BlocProvider<AdventureRunnerCubit>.value(
      value: _runner,
      child: BlocConsumer<AdventureRunnerCubit, AdventureRunnerState>(
        bloc: _runner,
        listenWhen:
            (AdventureRunnerState previous, AdventureRunnerState current) =>
                previous.node?.nodeId != current.node?.nodeId,
        listener: (BuildContext context, AdventureRunnerState state) {
          if (state.justEarnedRewardId != null) {
            _startCelebration(state);
          }
          if (state.isOnActivity && state.node != null) {
            _openActivity(state.node!, resume: state.activityResume);
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
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _buildBody(context, metrics, state, l10n),
                  ),
                  if (_celebrating != null)
                    Positioned.fill(
                      child: AdventureRewardOverlay(
                        reward: _celebrating!,
                        languageCode: _languageCode,
                        destination: _bookDestination(),
                        caption: l10n.resolve('adventurePageHome',
                            fallback: 'A page came home!'),
                        onDone: _endCelebration,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    KidMetrics metrics,
    AdventureRunnerState state,
    AppLocalizations l10n,
  ) {
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
          title: l10n.resolve('adventureFinishedTitle',
              fallback: 'The page is back in the book'),
          doneLabel: l10n.resolve('adventureBackToMap', fallback: 'Back'),
        );
      case AdventureRunnerStatus.playing:
        return _buildPlaying(context, metrics, state, l10n);
    }
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

    // An activity node with its screen on top shows the backdrop, so the
    // transition reads as the story continuing rather than as a spinner.
    if (node.isActivity && _isActivityOpen) {
      return const SizedBox.shrink();
    }

    // For an activity node the child has backed out of, the runner deliberately
    // kept them on the node rather than skipping the beat. Without something
    // here they would be looking at an empty backdrop with no way forward, so
    // the node's own lines explain why it matters and the button goes back in.
    final bool isReentry = node.isActivity;

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
            bookKey: _bookKey,
            pagesInBook: _pagesInBook,
            accent: _accentOf(state.adventure),
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
        Expanded(
          child: StoryBeatView(
            // Keyed on the node so a beat's own state — which line is showing,
            // whether it has handed off — cannot survive into the next beat.
            key: ValueKey<String>(node.nodeId),
            node: node,
            languageCode: _languageCode,
            accent: _accentOf(state.adventure),
            onSpeak: _narrator.speak,
            onContinue: isReentry
                ? () => _openActivity(node, resume: state.activityResume)
                // Tagged with the node the beat belongs to, so a narration
                // future resolving after the story has moved cannot advance a
                // beat the child never saw.
                : () => _runner.continueStory(fromNodeId: node.nodeId),
            continueLabel: isReentry
                ? l10n.resolve('storyBeginActivity', fallback: "Let's play")
                : l10n.resolve('storyContinue', fallback: 'Next'),
            nextLabel: l10n.resolve('storyContinue', fallback: 'Next'),
            replayLabel:
                l10n.resolve('storyReplayLine', fallback: 'Say it again'),
          ),
        ),
      ],
    );
  }

  Color _accentOf(Adventure? adventure) {
    final int? value = adventure?.accentColorValue;
    return value == null ? KidUi.primary : Color(value);
  }
}

/// Persists the in-flight activity's position for the signed-in child.
///
/// One row on the chapter the activity belongs to, overwritten at every step
/// boundary, deleted when the run ends. Scoped by profile like everything else
/// in the story layer, so two children on one tablet never resume into each
/// other's game.
class _StoryCheckpointSink implements ActivityCheckpointSink {
  const _StoryCheckpointSink({
    required this.storyDao,
    required this.profileId,
    required this.adventureId,
  });

  final StoryDao storyDao;
  final int profileId;
  final String adventureId;

  @override
  Future<void> save(ActivityCheckpoint checkpoint) {
    return storyDao.saveActivityCheckpoint(
      profileId: profileId,
      adventureId: adventureId,
      checkpoint: checkpoint,
    );
  }

  @override
  Future<void> clear() {
    return storyDao.clearActivityCheckpoint(
      profileId: profileId,
      adventureId: adventureId,
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
    required this.bookKey,
    required this.pagesInBook,
    required this.accent,
    required this.onBack,
  });

  final KidMetrics metrics;
  final double progress;

  /// Identifies the book badge so a recovered page can fly to it.
  final GlobalKey bookKey;

  final int pagesInBook;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final double badge = metrics.size(KidUi.minTouch, min: 56, max: 88);

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
              width: badge,
              height: badge,
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
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        SizedBox(width: metrics.gap),
        // The book, on screen throughout. It is the destination the recovered
        // page flies into, and it has to be visible *before* the flight for
        // that flight to mean anything.
        AnimatedScale(
          key: bookKey,
          duration: KidUi.celebrate,
          curve: Curves.elasticOut,
          scale: pagesInBook > 0 ? 1.12 : 1,
          child: Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(
              color: pagesInBook > 0
                  ? accent
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: KidUi.shadow(accent, strength: 0.6),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: pagesInBook > 0 ? Colors.white : accent,
              size: badge * 0.5,
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
    required this.title,
    required this.doneLabel,
  });

  final KidMetrics metrics;
  final Adventure adventure;
  final String languageCode;
  final VoidCallback onDone;
  final String title;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    return _StoryMessage(
      metrics: metrics,
      languageCode: languageCode,
      message: title,
      subtitle: adventure.rewardTitle.resolve(languageCode),
      // The page the child actually recovered, not a generic glyph. Ending on
      // the same picture that flew into the book is what ties the whole
      // Adventure to one object.
      art: adventure.rewardArt,
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
    this.subtitle,
    this.art,
    this.icon = Icons.map_outlined,
  });

  final KidMetrics metrics;
  final String languageCode;
  final String message;
  final String? subtitle;
  final String? art;
  final String buttonLabel;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double artSize = metrics.size(140, min: 96, max: 190);

    return Center(
      child: SingleChildScrollView(
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
              if (art != null)
                Image.asset(art!, width: artSize, height: artSize)
              else
                Icon(icon,
                    size: metrics.size(72, min: 52, max: 96),
                    color: KidUi.primary),
              SizedBox(height: metrics.gap),
              ActivityGlyphText(
                message,
                languageCode: languageCode,
                fontSize: metrics.size(22, min: 16, max: 28),
              ),
              if (subtitle != null) ...<Widget>[
                SizedBox(height: metrics.gap * 0.3),
                ActivityGlyphText(
                  subtitle!,
                  languageCode: languageCode,
                  fontSize: metrics.size(17, min: 13, max: 21),
                  color: KidUi.inkSoft,
                ),
              ],
              SizedBox(height: metrics.gap),
              GestureDetector(
                onTap: () {
                  KidHaptics.tap();
                  onTap();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: KidUi.minTouch),
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
