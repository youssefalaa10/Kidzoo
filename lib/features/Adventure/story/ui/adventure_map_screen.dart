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
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/ui/adventure_runner_screen.dart';
import 'package:kidzo/features/Adventure/story/ui/map_stop_tile.dart';
import 'package:kidzo/features/Adventure/story/ui/story_book_view.dart';
import 'package:kidzo/features/Profile/profile_cubit.dart';
import 'package:kidzo/features/Profile/profile_state.dart';

/// The entry point for Adventure Mode: the book, and the journey.
///
/// This replaces the old Challenge level map. The difference is not cosmetic —
/// the level map was 18 hand-placed nodes over a background with no story, and
/// nothing about it could grow except by hardcoding more nodes. Here the stops
/// come from content, and the book is the progress meter.
///
/// It is still a **map**, and deliberately so. A flat list of Adventures says
/// "here is what is available"; a path of stops says "here is where you are and
/// here is where this goes", which is the thing that makes a child want the
/// next one. The locked stops carry a name and nothing more until the Adventure
/// before them is finished — enough to promise a journey, not enough to spend
/// the surprise.
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

            return _AdventureJourney(
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

/// The map itself: the book, then the stops in order.
class _AdventureJourney extends StatefulWidget {
  const _AdventureJourney({
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
  State<_AdventureJourney> createState() => _AdventureJourneyState();
}

class _AdventureJourneyState extends State<_AdventureJourney> {
  /// Bumped after returning from an Adventure so the stops and the book refresh.
  int _refreshToken = 0;

  /// Which Adventure ids were already finished when this screen last rendered.
  ///
  /// Kept so the screen can tell "finished a while ago" from "finished just
  /// now". Only the second one earns an unlock animation, and the difference
  /// matters: a stop that celebrates every time the child walks past it stops
  /// meaning anything the second time.
  Set<String>? _knownCompleted;

  /// The stop to play the unlock animation on, once.
  String? _justUnlockedStopId;

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

  /// Works out each stop's state from what the child has actually finished.
  List<MapStop> _stopsFor(Set<String> completed) {
    final StoryArc arc = widget.bundle.primaryArc;
    final List<MapStop> stops = <MapStop>[];

    // A stop is open when every playable stop before it is done. That rule,
    // rather than a stored "highest unlocked" counter, is what the old level
    // map got wrong: a counter drifts out of step with the content the moment
    // an Adventure is inserted, reordered or replayed.
    bool isNextOpen = true;
    for (final String adventureId in arc.adventureIds) {
      final Adventure? adventure = widget.bundle.adventures[adventureId];
      if (adventure == null) {
        continue;
      }
      final bool isCompleted = completed.contains(adventureId);
      stops.add(MapStop(
        id: adventureId,
        title: adventure.title,
        teaser: const LocalizedText.empty(),
        accentValue: adventure.accentColorValue,
        art: adventure.rewardArt,
        state: isCompleted
            ? MapStopState.completed
            : isNextOpen
                ? MapStopState.open
                : MapStopState.locked,
      ));
      if (!isCompleted) {
        isNextOpen = false;
      }
    }

    // Everything after the playable content is a place, not an Adventure. Its
    // one teaser line appears only once the child has reached the end of what
    // exists — before that it is a silhouette with a name.
    final bool hasFinishedEverythingPlayable =
        arc.adventureIds.every(completed.contains);
    for (int index = 0; index < arc.upcoming.length; index++) {
      final UpcomingDestination destination = arc.upcoming[index];
      stops.add(MapStop(
        id: destination.id,
        title: destination.title,
        // Only the very next place gets its line, and only once the road to it
        // is clear. Two teasers at once reads as a menu of things the child
        // cannot have.
        teaser: hasFinishedEverythingPlayable && index == 0
            ? destination.peek
            : const LocalizedText.empty(),
        state: MapStopState.comingSoon,
      ));
    }
    return stops;
  }

  /// Detects the moment a stop opens, so it can be animated exactly once.
  void _noteUnlocks(Set<String> completed) {
    final Set<String>? previous = _knownCompleted;
    _knownCompleted = completed;
    if (previous == null || completed.length <= previous.length) {
      return;
    }
    final List<MapStop> stops = _stopsFor(completed);
    for (final MapStop stop in stops) {
      if (stop.state == MapStopState.open ||
          stop.state == MapStopState.comingSoon) {
        // The first stop that is not already finished is the one that just
        // became reachable.
        _justUnlockedStopId = stop.id;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final StoryArc arc = widget.bundle.primaryArc;
    final KidMetrics metrics = widget.metrics;

    return FutureBuilder<List<StoryChapterProgressData>>(
      key: ValueKey<int>(_refreshToken),
      future: widget.storyDao.chaptersFor(widget.profileId),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<StoryChapterProgressData>> snapshot,
      ) {
        final List<StoryChapterProgressData> chapters =
            snapshot.data ?? const <StoryChapterProgressData>[];
        final Set<String> completed = chapters
            .where((StoryChapterProgressData chapter) => chapter.isCompleted)
            .map((StoryChapterProgressData chapter) => chapter.adventureId)
            .toSet();
        final Set<String> started = chapters
            .where((StoryChapterProgressData chapter) =>
                !chapter.isCompleted && chapter.currentNodeId != null)
            .map((StoryChapterProgressData chapter) => chapter.adventureId)
            .toSet();

        if (snapshot.connectionState == ConnectionState.done) {
          _noteUnlocks(completed);
        }
        final List<MapStop> stops = _stopsFor(completed);

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
            SizedBox(height: metrics.gap * 1.2),
            ActivityGlyphText(
              widget.l10n.resolve('adventureJourney', fallback: 'Your journey'),
              languageCode: widget.languageCode,
              fontSize: metrics.size(20, min: 16, max: 26),
              color: Colors.white,
              textAlign: TextAlign.start,
            ),
            SizedBox(height: metrics.gap * 0.6),
            for (int index = 0; index < stops.length; index++)
              MapStopTile(
                stop: stops[index],
                isLast: index == stops.length - 1,
                isJustUnlocked: stops[index].id == _justUnlockedStopId,
                isInProgress: started.contains(stops[index].id),
                languageCode: widget.languageCode,
                metrics: metrics,
                l10n: widget.l10n,
                onOpen: stops[index].state == MapStopState.comingSoon ||
                        stops[index].state == MapStopState.locked
                    ? null
                    : () => _openAdventure(stops[index].id),
              ),
          ],
        );
      },
    );
  }
}
