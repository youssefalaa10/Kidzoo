import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_service.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/host/activity_host_screen.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/ui/adventure_map_screen.dart';
import 'package:kidzo/features/Adventure/story/ui/adventure_runner_screen.dart';
import 'package:kidzo/features/Adventure/story/ui/journey_trail.dart';
import 'package:kidzo/features/Profile/profile_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/disk_content_source.dart';

/// A story is one place the child goes, not a series of round trips.
///
/// The map shows one bead per **story**. Opening it has to play that story
/// straight through — narration, activity, narration, activity — without ever
/// dropping the child back on the map in between, because the map bead means
/// "this whole story" and finishing it is what marks the bead done.
///
/// The structure that guarantees this is that [AdventureRunnerScreen] pushes
/// [ActivityHostScreen] **on top of itself** and waits, so the story screen
/// underneath keeps the backdrop, the book and the progress bar alive the whole
/// time. That is easy to break by accident and invisible in a cubit test, which
/// is why it is pinned here with a navigator observer.
class _RouteLog extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];
  final List<Route<dynamic>> popped = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
  }
}

class _SynchronousLocalizations
    extends LocalizationsDelegate<AppLocalizations> {
  const _SynchronousLocalizations(this.value);

  final AppLocalizations value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(value);

  @override
  bool shouldReload(_SynchronousLocalizations old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;
  late AppLocalizations englishL10n;
  late PreloadedAdventureContentSource content;
  late AppDatabase database;
  late StoryDao dao;
  late int profileId;
  late ProfileCubit profiles;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    content = await PreloadedAdventureContentSource.load();
    bundle = await AdventureContentLoader(content).load();
    englishL10n = AppLocalizations(
      const Locale('en', ''),
      (json.decode(File('assets/lang/en.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((String key, dynamic value) =>
              MapEntry<String, String>(key, '$value')),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
    // Loaded here rather than by the widget: the profile read is real async,
    // and a screen still waiting on it has nothing to lay out.
    profiles = ProfileCubit(ProfileDao(database));
    await profiles.checkProfile();
  });

  tearDown(() async {
    await profiles.close();
    await database.close();
  });

  testWidgets('an activity opens on top of the story, never in place of it',
      (WidgetTester tester) async {
    final _RouteLog routes = _RouteLog();

    await tester.pumpWidget(
      BlocProvider<LanguageCubit>(
        create: (_) => LanguageCubit(),
        child: MaterialApp(
          locale: const Locale('en', ''),
          navigatorObservers: <NavigatorObserver>[routes],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            _SynchronousLocalizations(englishL10n),
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdventureRunnerScreen(
            bundle: bundle,
            registry: registry,
            adventureId: 'jungle',
            profileId: profileId,
            storyDao: dao,
            // Nothing speaks, and narration resolves at once, so the beat
            // unlocks without the test having to drive a clock.
            narrator: RecordingActivityNarrator(),
            soundboard: RecordingActivitySoundboard(),
          ),
        ),
      ),
    );

    // Not pumpAndSettle: the story screen animates continuously.
    for (int frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final int pushesToOpenTheStory = routes.pushed.length;
    expect(find.byType(AdventureRunnerScreen), findsOneWidget);

    // Tap through the opening beat and into the first activity.
    for (int tap = 0; tap < 3; tap++) {
      final Finder next = find.text(
        englishL10n.resolve('storyContinue', fallback: 'Next'),
      );
      if (next.evaluate().isEmpty) {
        break;
      }
      await tester.tap(next.first);
      for (int frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      if (find.byType(ActivityHostScreen).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(ActivityHostScreen), findsOneWidget,
        reason: 'the first activity of the jungle should be on screen');

    expect(routes.pushed.length, pushesToOpenTheStory + 1,
        reason: 'exactly one route for the activity, pushed over the story');

    expect(routes.popped, isEmpty,
        reason: 'nothing was popped, so the child never passed back through '
            'the map on the way from a beat to the activity it introduced');

    expect(
      find.byType(AdventureRunnerScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'the story screen is still alive underneath, which is what keeps '
          'the backdrop, the book and the progress bar continuous',
    );
  });

  testWidgets('a story is marked finished only once it is played to the end',
      (WidgetTester tester) async {
    // The unlock rule the map depends on. A chapter row that is written early
    // would open the next bead before the child had recovered the page.
    expect(await dao.chapterFor(profileId, 'jungle'), isNull);

    await dao.saveResumePoint(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'jungle.n6',
    );
    final StoryChapterProgressData? midway =
        await dao.chapterFor(profileId, 'jungle');

    expect(midway, isNotNull);
    expect(midway!.isCompleted, isFalse,
        reason: 'reaching the last activity is not finishing the story');

    await dao.markChapterCompleted(
      profileId: profileId,
      adventureId: 'jungle',
    );
    expect((await dao.chapterFor(profileId, 'jungle'))!.isCompleted, isTrue);
  });

  group('The map screen itself', () {
    const List<Size> testSizes = <Size>[
      Size(360, 640), // small phone, portrait
      Size(780, 390), // phone, landscape
      Size(800, 1200), // tablet
    ];

    Widget mapUnderTest() {
      return MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
          BlocProvider<ProfileCubit>.value(value: profiles),
        ],
        child: RepositoryProvider<AppDatabase>.value(
          value: database,
          child: MaterialApp(
            locale: const Locale('en', ''),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              _SynchronousLocalizations(englishL10n),
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdventureMapScreen(
              contentLoader: AdventureContentLoader(content),
              registry: registry,
              reminderService: RecordingStoryReminderService(),
            ),
          ),
        ),
      );
    }

    /// Pumps the map until it has something to draw.
    Future<void> pumpMap(WidgetTester tester) async {
      await tester.pumpWidget(mapUnderTest());
      // Only the profile read is still real async, and SQLite in memory
      // answers within a frame or two.
      for (int frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('lays out at every size without overflowing',
        (WidgetTester tester) async {
      // A hand-painted trail is exactly the kind of thing that looks right on
      // the one device it was built against and overflows everywhere else.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final Size size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await pumpMap(tester);

        expect(tester.takeException(), isNull, reason: 'the map broke at $size');
        expect(find.byType(JourneyTrail), findsOneWidget,
            reason: 'the trail should be on screen at $size');
      }
    });

    testWidgets('shows one bead per story, and the book as a count',
        (WidgetTester tester) async {
      await pumpMap(tester);

      final JourneyTrail trail =
          tester.widget<JourneyTrail>(find.byType(JourneyTrail));

      // One playable Adventure plus three places that are not written yet.
      // Crucially *not* one bead per activity: the jungle has four activities
      // and eight nodes, and contributes exactly one stop.
      expect(trail.stops.length, 4);
      expect(trail.stops.first.id, 'jungle');
      expect(trail.stops.first.state, MapStopState.open);
      expect(
        trail.stops.skip(1).map((MapStop stop) => stop.id),
        <String>['market', 'ocean', 'stars'],
      );
      expect(
        trail.stops.skip(1).every(
            (MapStop stop) => stop.state == MapStopState.comingSoon),
        isTrue,
      );

      // The header keeps the one number worth keeping permanently on screen.
      expect(find.text('0/4'), findsOneWidget);
      expect(find.text('The Lost Pages'), findsOneWidget);

      // And the premise paragraph is no longer spending the top of the map.
      expect(find.textContaining('blew away into different worlds'),
          findsNothing);
    });
  });
}

