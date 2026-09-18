import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_planner.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_service.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/ui/adventure_runner_screen.dart';
import 'package:kidzo/features/Adventure/story/ui/story_book_view.dart';
import 'package:kidzo/features/Profile/profile_cubit.dart';
import 'package:kidzo/features/Profile/profile_state.dart';

/// The entry point for Adventure Mode: the book, and the Adventures to play.
///
/// This replaces the old Challenge level map. The difference is not cosmetic —
/// the level map was 18 hand-placed nodes over a background with no story, and
/// nothing about it could grow except by hardcoding more nodes. Here the
/// Adventures come from content, and the book is the progress meter.
class AdventureMapScreen extends StatefulWidget {
  const AdventureMapScreen({
    super.key,
    this.contentLoader,
    this.registry,
    this.reminderService,
  });

  /// Injected in tests. Defaults to the asset bundle.
  final AdventureContentLoader? contentLoader;
  final ActivityEngineRegistry? registry;

  /// Injected in tests so nothing schedules a real notification.
  final StoryReminderService? reminderService;

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  late final Future<AdventureContentBundle> _bundleFuture;
  late final ActivityEngineRegistry _registry;
  late final StoryReminderService _reminders;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? buildDefaultEngineRegistry();
    _reminders = widget.reminderService ?? LocalStoryReminderService();
    _bundleFuture = (widget.contentLoader ??
            const AdventureContentLoader(AssetAdventureContentSource()))
        .load();
  }

  /// Asks for notification permission and plans a reminder.
  ///
  /// Done when the child *leaves* Adventures rather than when they arrive:
  /// asking for a notification permission before they have seen the story is
  /// asking for something the app has not yet earned, and the planner refuses
  /// to schedule anything for a child who never started one.
  Future<void> _planReminder(int profileId, AppLocalizations l10n) async {
    final StoryDao storyDao = StoryDao(context.read<AppDatabase>());
    final StoryReminderPlanner planner = StoryReminderPlanner(
      storyDao: storyDao,
      service: _reminders,
    );
    final StoryReminderKind? kind = await planner.decide(profileId: profileId);
    if (kind == null) {
      await _reminders.cancelAll();
      return;
    }
    if (!await _reminders.requestPermission()) {
      return;
    }
    await planner.planFor(
      profileId: profileId,
      copyFor: (StoryReminderKind chosen) => StoryReminderCopy(
        title: l10n.resolve(
          chosen == StoryReminderKind.continueStory
              ? 'notificationContinueStoryTitle'
              : 'notificationStartStoryTitle',
        ),
        body: l10n.resolve(
          chosen == StoryReminderKind.continueStory
              ? 'notificationContinueStoryBody'
              : 'notificationStartStoryBody',
        ),
      ),
    );
  }

  String get _languageCode => context.read<LanguageCubit>().state.languageCode;

  int? get _profileId {
    final ProfileState state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      return state.currentProfile?.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return FutureBuilder<AdventureContentBundle>(
      future: _bundleFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<AdventureContentBundle> snapshot,
      ) {
        return KidGameShell(
          backgroundAsset: 'assets/gen/images/backgrounds/map_mob.jpg',
          builder: (BuildContext context, KidMetrics metrics) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(metrics.pagePadding),
                  child: ActivityGlyphText(
                    '${snapshot.error}',
                    languageCode: _languageCode,
                    fontSize: metrics.size(14, min: 12, max: 18),
                  ),
                ),
              );
            }

            final AdventureContentBundle bundle = snapshot.data!;
            final int? profileId = _profileId;
            if (profileId == null) {
              // No profile yet: the story is per-child, so there is nothing to
              // resume and nowhere to store progress.
              return Center(
                child: ActivityGlyphText(
                  l10n.resolve('adventuresSubtitle'),
                  languageCode: _languageCode,
                  fontSize: metrics.size(20, min: 16, max: 26),
                ),
              );
            }

            return _AdventureList(
              bundle: bundle,
              registry: _registry,
              profileId: profileId,
              storyDao: StoryDao(context.read<AppDatabase>()),
              languageCode: _languageCode,
              metrics: metrics,
              l10n: l10n,
              onAdventureClosed: () => _planReminder(profileId, l10n),
            );
          },
        );
      },
    );
  }
}

class _AdventureList extends StatefulWidget {
  const _AdventureList({
    required this.bundle,
    required this.registry,
    required this.profileId,
    required this.storyDao,
    required this.languageCode,
    required this.metrics,
    required this.l10n,
    required this.onAdventureClosed,
  });

  final AdventureContentBundle bundle;
  final ActivityEngineRegistry registry;
  final int profileId;
  final StoryDao storyDao;
  final String languageCode;
  final KidMetrics metrics;
  final AppLocalizations l10n;

  /// Called after the child comes back from an Adventure.
  final Future<void> Function() onAdventureClosed;

  @override
  State<_AdventureList> createState() => _AdventureListState();
}

class _AdventureListState extends State<_AdventureList> {
  /// Bumped after returning from an Adventure so the row and the book refresh.
  int _refreshToken = 0;

  Future<void> _openAdventure(String adventureId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => AdventureRunnerScreen(
          bundle: widget.bundle,
          registry: widget.registry,
          adventureId: adventureId,
          profileId: widget.profileId,
          storyDao: widget.storyDao,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _refreshToken++);
    // They have just played, so there is now something real to remind them
    // about. Scheduling here also means the permission prompt lands after the
    // story rather than before it.
    await widget.onAdventureClosed();
  }

  @override
  Widget build(BuildContext context) {
    final StoryArc arc = widget.bundle.primaryArc;
    final KidMetrics metrics = widget.metrics;

    return ListView(
      padding: EdgeInsets.all(metrics.pagePadding),
      children: <Widget>[
        ActivityGlyphText(
          arc.title.resolve(widget.languageCode),
          languageCode: widget.languageCode,
          fontSize: metrics.size(30, min: 22, max: 40),
          color: Colors.white,
        ),
        SizedBox(height: metrics.gap * 0.4),
        ActivityGlyphText(
          arc.premise.resolve(widget.languageCode),
          languageCode: widget.languageCode,
          fontSize: metrics.size(16, min: 13, max: 20),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        SizedBox(height: metrics.gap),
        StoryBookView(
          key: ValueKey<int>(_refreshToken),
          bundle: widget.bundle,
          storyDao: widget.storyDao,
          profileId: widget.profileId,
          languageCode: widget.languageCode,
          metrics: metrics,
          l10n: widget.l10n,
        ),
        SizedBox(height: metrics.gap),
        for (final String adventureId in arc.adventureIds)
          if (widget.bundle.adventures.containsKey(adventureId))
            Padding(
              padding: EdgeInsets.only(bottom: metrics.gap),
              child: _AdventureRow(
                key: ValueKey<String>('$adventureId-$_refreshToken'),
                adventure: widget.bundle.requireAdventure(adventureId),
                storyDao: widget.storyDao,
                profileId: widget.profileId,
                languageCode: widget.languageCode,
                metrics: metrics,
                l10n: widget.l10n,
                onOpen: () => _openAdventure(adventureId),
              ),
            ),
      ],
    );
  }
}

class _AdventureRow extends StatelessWidget {
  const _AdventureRow({
    required this.adventure,
    required this.storyDao,
    required this.profileId,
    required this.languageCode,
    required this.metrics,
    required this.l10n,
    required this.onOpen,
    super.key,
  });

  final Adventure adventure;
  final StoryDao storyDao;
  final int profileId;
  final String languageCode;
  final KidMetrics metrics;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoryChapterProgressData?>(
      future: storyDao.chapterFor(profileId, adventure.adventureId),
      builder: (
        BuildContext context,
        AsyncSnapshot<StoryChapterProgressData?> snapshot,
      ) {
        final StoryChapterProgressData? chapter = snapshot.data;
        final bool isCompleted = chapter?.isCompleted ?? false;
        final bool isInProgress =
            chapter != null && !isCompleted && chapter.currentNodeId != null;

        final String label = isCompleted
            ? l10n.resolve('adventureReplay')
            : isInProgress
                ? l10n.resolve('adventureResume')
                : l10n.resolve('adventureStart');

        return Semantics(
          button: true,
          label: adventure.title.resolve(languageCode),
          child: GestureDetector(
            onTap: () {
              KidHaptics.tap();
              onOpen();
            },
            child: Container(
              padding: EdgeInsets.all(metrics.size(18, min: 12, max: 26)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(KidUi.radiusCard),
                boxShadow: KidUi.shadow(KidUi.primary),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: metrics.size(64, min: 52, max: 80),
                    height: metrics.size(64, min: 52, max: 80),
                    decoration: BoxDecoration(
                      color: KidUi.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.play_arrow_rounded,
                      size: metrics.size(36, min: 28, max: 46),
                      color: KidUi.primary,
                    ),
                  ),
                  SizedBox(width: metrics.gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ActivityGlyphText(
                          adventure.title.resolve(languageCode),
                          languageCode: languageCode,
                          fontSize: metrics.size(20, min: 16, max: 26),
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: metrics.gap * 0.25),
                        ActivityGlyphText(
                          label,
                          languageCode: languageCode,
                          fontSize: metrics.size(15, min: 12, max: 19),
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.start,
                          color: KidUi.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
