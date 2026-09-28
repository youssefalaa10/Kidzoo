import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/badges/badge_service.dart';
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
import 'package:kidzo/features/Adventure/story/ui/journey_trail.dart';
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
///
/// One bead is one **story**. Opening it plays that Adventure from its first
/// line to its last — narration, activities, resolution — without ever coming
/// back here in between, and only finishing the whole thing marks it done and
/// opens the next. The activities inside a story are not map nodes, because
/// they are not places the child can go to.
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

            final AdventureContentBundle? bundle = snapshot.data;
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
              bundle: bundle!,
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

  final ScrollController _scroll = ScrollController();

  /// The trail is scrolled to the current bead rather than to the top.
  ///
  /// With the first story finished, the top of the map is a stop the child has
  /// already played; landing there asks them to work out where they are before
  /// they can do anything. Jump the first time, glide afterwards, so coming
  /// back from a story *shows* the map changing.
  bool _hasCentredOnCurrent = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
    // Read before the await: the badge stack is provided app-wide, and
    // reaching for it after an async gap risks a context that has moved on.
    final BadgeService? badgeService =
        context.read<BadgeService?>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => AdventureRunnerScreen(
          bundle: widget.bundle,
          registry: widget.registry,
          adventureId: adventureId,
          profileId: widget.profileId,
          storyDao: widget.storyDao,
          badgeService: badgeService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    // Something on the map may have just opened, so let the next build find it.
    _hasCentredOnCurrent = false;
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
        // The motif the content authored. Nothing read this before, so every
        // unwritten place wore the same padlock; a shopfront, a wave and a
        // spark say "somewhere is coming" without saying what happens there.
        icon: destination.icon,
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
        // A live `currentNodeId` means there is something to continue — whether
        // or not the story has ever been finished. Excluding completed
        // chapters here used to hide the one case where the label mattered
        // most: a child part-way through a *replay*, who was told "Again" and
        // then restarted from the first line.
        final Set<String> started = chapters
            .where((StoryChapterProgressData chapter) =>
                chapter.currentNodeId != null)
            .map((StoryChapterProgressData chapter) => chapter.adventureId)
            .toSet();

        if (snapshot.connectionState == ConnectionState.done) {
          _noteUnlocks(completed);
        }
        final List<MapStop> stops = _stopsFor(completed);
        final double headerInset = metrics.size(96, min: 78, max: 126);

        _scheduleCentreOnCurrent(stops, metrics, headerInset);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: JourneyTrail(
                stops: stops,
                languageCode: widget.languageCode,
                metrics: metrics,
                controller: _scroll,
                topInset: headerInset + metrics.gap,
                justUnlockedStopId: _justUnlockedStopId,
                statusLabelFor: (MapStop stop) =>
                    _statusLabelFor(stop, started.contains(stop.id)),
                onOpen: (MapStop stop) => _openAdventure(stop.id),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _JourneyHeader(
                title: arc.title.resolve(widget.languageCode),
                languageCode: widget.languageCode,
                metrics: metrics,
                pagesFound: completed.length,
                pagesTotal: stops.length,
                bookLabel: widget.l10n.resolve('storyBook', fallback: 'Book'),
                onBack: () => Navigator.of(context).maybePop(),
                onOpenBook: () => _showBook(arc),
              ),
            ),
          ],
        );
      },
    );
  }

  /// What a bead says about itself when a child asks.
  ///
  /// Opening a bead with a story in progress *continues* it, with no
  /// confirmation in between. A four-year-old cannot read "Do you want to
  /// resume?", and a modal that asks them to choose between two words they
  /// cannot read is a wall, not a safeguard — so the label is the whole of the
  /// affordance and the tap does the obvious thing.
  String _statusLabelFor(MapStop stop, bool isInProgress) {
    switch (stop.state) {
      case MapStopState.completed:
        return isInProgress
            ? widget.l10n.resolve('adventureResume', fallback: 'Continue')
            : widget.l10n.resolve('adventureReplay', fallback: 'Again');
      case MapStopState.open:
        return isInProgress
            ? widget.l10n.resolve('adventureResume', fallback: 'Continue')
            : widget.l10n.resolve('adventureStart', fallback: 'Start');
      case MapStopState.locked:
        return widget.l10n.resolve('adventureLocked', fallback: 'Not yet');
      case MapStopState.comingSoon:
        return widget.l10n.resolve('adventureComingSoon',
            fallback: 'Coming soon');
    }
  }

  /// Puts the bead the child should play next on screen, once per arrival.
  void _scheduleCentreOnCurrent(
    List<MapStop> stops,
    KidMetrics metrics,
    double headerInset,
  ) {
    if (_hasCentredOnCurrent) {
      return;
    }
    final int index = stops.indexWhere(
      (MapStop stop) => stop.state == MapStopState.open,
    );
    if (index < 0) {
      _hasCentredOnCurrent = true;
      return;
    }
    _hasCentredOnCurrent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      final double target = JourneyTrail.offsetFor(
        index: index,
        metrics: metrics,
        viewportHeight: _scroll.position.viewportDimension,
        topInset: headerInset + metrics.gap,
      ).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// The book, and the premise, on demand.
  ///
  /// Both used to sit above the trail and cost most of a phone screen before
  /// the child could see where they were. They are still one tap away — and the
  /// book badge in the header keeps the count visible the whole time, which is
  /// the part that actually needed to be permanent.
  void _showBook(StoryArc arc) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final KidMetrics sheetMetrics = KidMetrics.of(constraints);
              return Container(
                margin: EdgeInsets.all(sheetMetrics.pagePadding),
                padding: EdgeInsets.all(sheetMetrics.pagePadding),
                decoration: BoxDecoration(
                  color: KidUi.cream,
                  borderRadius: BorderRadius.circular(KidUi.radiusCard),
                  boxShadow: KidUi.shadow(KidUi.primary),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ActivityGlyphText(
                        arc.premise.resolve(widget.languageCode),
                        languageCode: widget.languageCode,
                        fontSize: sheetMetrics.size(16, min: 13, max: 20),
                        fontWeight: FontWeight.w600,
                        color: KidUi.ink,
                      ),
                      SizedBox(height: sheetMetrics.gap),
                      StoryBookView(
                        bundle: widget.bundle,
                        storyDao: widget.storyDao,
                        profileId: widget.profileId,
                        languageCode: widget.languageCode,
                        metrics: sheetMetrics,
                        l10n: widget.l10n,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// The one permanent piece of chrome on the map.
///
/// Back, where the child is, and how much of the book is home. Everything else
/// the old header carried — the premise paragraph, the book itself — moved
/// behind the badge, because the map is the thing worth the screen.
class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.title,
    required this.languageCode,
    required this.metrics,
    required this.pagesFound,
    required this.pagesTotal,
    required this.bookLabel,
    required this.onBack,
    required this.onOpenBook,
  });

  final String title;
  final String languageCode;
  final KidMetrics metrics;
  final int pagesFound;
  final int pagesTotal;
  final String bookLabel;
  final VoidCallback onBack;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    final double button = metrics.size(54, min: 46, max: 68);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.pagePadding,
          vertical: metrics.gap * 0.5,
        ),
        child: Container(
          padding: EdgeInsets.all(metrics.size(8, min: 6, max: 12)),
          decoration: BoxDecoration(
            color: KidUi.ink.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(KidUi.radiusPill),
          ),
          child: Row(
            children: <Widget>[
              _HeaderButton(
                size: button,
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                onTap: onBack,
              ),
              SizedBox(width: metrics.gap * 0.5),
              Expanded(
                child: ActivityGlyphText(
                  title,
                  languageCode: languageCode,
                  fontSize: metrics.size(19, min: 15, max: 25),
                  color: Colors.white,
                  maxLines: 1,
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(width: metrics.gap * 0.5),
              Semantics(
                button: true,
                label: '$bookLabel $pagesFound / $pagesTotal',
                child: GestureDetector(
                  onTap: () {
                    KidHaptics.tap();
                    onOpenBook();
                  },
                  child: Container(
                    height: button,
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.size(12, min: 9, max: 16),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(KidUi.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.auto_stories_rounded,
                          size: button * 0.46,
                          color: KidUi.primary,
                        ),
                        SizedBox(width: metrics.gap * 0.25),
                        ActivityGlyphText(
                          '$pagesFound/$pagesTotal',
                          languageCode: languageCode,
                          fontSize: metrics.size(15, min: 12, max: 19),
                          color: KidUi.ink,
                          maxLines: 1,
                        ),
                      ],
                    ),
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.size,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: size * 0.5, color: KidUi.ink),
        ),
      ),
    );
  }
}
