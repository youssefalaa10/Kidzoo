import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/catalog/default_game_catalog.dart';
import 'package:kidzo/core/shared/widgets/kid_result_view.dart';
import 'package:kidzo/features/SortingActivities/sorting_activity_audio.dart';
import 'package:kidzo/features/SortingActivities/sorting_activity_content.dart';
import 'package:kidzo/features/SortingActivities/sorting_activity_cubit.dart';
import 'package:kidzo/features/SortingActivities/sorting_activity_screen.dart';
import 'package:kidzo/features/SortingActivities/sorting_worksheet_board.dart';

import '../support/test_localizations.dart';

class RecordingSortingAudio implements SortingActivityAudio {
  final List<String> spoken = [];
  final List<String> effects = [];
  bool disposed = false;
  int stops = 0;
  bool available = true;
  Completer<bool>? pending;
  @override
  Future<bool> say(String text, {String? effect}) {
    spoken.add(text);
    if (effect != null) effects.add(effect);
    return pending?.future ?? Future.value(available);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    stops++;
  }
}

SortingActivityContent loadContent(SortingActivityKind kind) {
  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return SortingActivityContent.fromJson(
      kind,
      load('assets/adventures/activities/helpers_${kind.name}.json'),
      load('assets/adventures/packs/helpers_${kind.name}.json'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('SORTING_PREVIEW')) {
      for (final entry in {
        'SortingPreview': 'C:/Windows/Fonts/arial.ttf',
        'MaterialIcons':
            'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      }.entries) {
        if (File(entry.value).existsSync()) {
          final loader = FontLoader(entry.key)
            ..addFont(Future.value(
                ByteData.sublistView(File(entry.value).readAsBytesSync())));
          await loader.load();
        }
      }
    }
  });

  test('three independent catalog entries open their own game directly', () {
    final catalog = buildDefaultGameCatalog();
    expect(catalog.findByActivityId('little_helpers'), isNull);
    expect(catalog.findByActivityId('tooth_food_sorting')!.screenBuilder(),
        isA<ToothFoodSortingScreen>());
    expect(catalog.findByActivityId('weather_sorting')!.screenBuilder(),
        isA<WeatherSortingScreen>());
    expect(catalog.findByActivityId('laundry_sorting')!.screenBuilder(),
        isA<LaundrySortingScreen>());
  });

  for (final kind in SortingActivityKind.values) {
    for (final locale in ['en', 'ar']) {
      testWidgets(
          '${kind.name} $locale: any-order sorting, retries, completion, replay and audio',
          (tester) async {
        final content = loadContent(kind);
        final audio = RecordingSortingAudio();
        final cubit = SortingActivityCubit(
            content: content, languageCode: locale, audio: audio);
        cubit.start();
        expect(cubit.state.placed, isEmpty);
        expect(audio.spoken.first, content.intro.resolve(locale));
        expect(cubit.place('unknown', content.destinations.first.id), isFalse);
        // Reverse order proves the child can choose every object freely.
        for (final item in content.items.reversed) {
          final correct = item.attribute('destination')!;
          final wrong =
              content.destinations.firstWhere((b) => b.id != correct).id;
          cubit.select(item.id);
          expect(cubit.state.selected, item.id);
          final before = cubit.state.placed.length;
          expect(cubit.place(item.id, wrong), isFalse);
          expect(cubit.state.placed.length, before);
          expect(cubit.state.rejected, item.id);
          expect(cubit.place(item.id, correct), isTrue);
          expect(cubit.place(item.id, correct), isFalse,
              reason: 'Duplicate placement must not advance progress');
        }
        expect(cubit.state.complete, isTrue);
        expect(cubit.state.celebrating, isFalse);
        await tester.pump(const Duration(milliseconds: 700));
        expect(cubit.state.celebrating, isTrue);
        for (final cue in ['pick', 'left', 'right', 'retry', 'complete']) {
          expect(audio.effects, contains(content.effect(cue)));
        }
        expect(audio.effects.any((path) => path.contains('boop')), isFalse);
        expect(audio.spoken.last, content.complete.resolve(locale));
        cubit.replay();
        expect(cubit.state.placed, isEmpty);
        expect(cubit.state.celebrating, isFalse);
        expect(cubit.state.selected, isNull);
        cubit.toggleSound();
        final count = audio.spoken.length;
        cubit.select(content.items.first.id);
        expect(audio.spoken.length, count);
        cubit.suspend();
        expect(
            cubit.place(content.items.first.id,
                content.items.first.attribute('destination')!),
            isFalse);
        await cubit.close();
        expect(audio.disposed, isTrue);
      });
    }

    test(
        '${kind.name}: ten objects, complete categories, valid optimized images and quiet original WAVs',
        () async {
      final content = loadContent(kind);
      expect(content.items.length, 10);
      expect(content.destinations.length, 2);
      for (final bin in content.destinations) {
        expect(
            content.items
                .where((i) => i.attribute('destination') == bin.id)
                .length,
            5);
      }
      for (final image in content.images) {
        expect(image.endsWith('.webp'), isTrue);
        final file = File(image);
        expect(file.lengthSync(), lessThan(100000));
      }
      for (final cue in ['pick', 'left', 'right', 'retry', 'complete']) {
        final wav = File('assets/${content.effect(cue)}').readAsBytesSync();
        expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
        expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
        expect(wav.length, greaterThan(1000));
      }
    });

    for (final locale in ['en', 'ar']) {
      for (final size in [
        const Size(360, 640),
        const Size(780, 390),
        const Size(800, 1200)
      ]) {
        testWidgets(
            '${kind.name} $locale $size: reference composition and decoded sprites',
            (tester) async {
          final audio = RecordingSortingAudio();
          await openScreen(tester, kind, locale, size, audio);
          expect(find.byType(Draggable<String>), findsNWidgets(10));
          expect(find.byType(DragTarget<String>), findsNWidgets(2));
          final board = tester.widget<SortingWorksheetBoard>(
              find.byType(SortingWorksheetBoard));
          expect(board.state.placed, isEmpty);
          final firstBox = tester.getRect(find
              .byKey(ValueKey('box-${board.content.destinations.first.id}')));
          final firstItem = tester.getRect(
              find.byKey(ValueKey('item-${board.content.items.first.id}')));
          final sixthItem = tester.getRect(
              find.byKey(ValueKey('item-${board.content.items[5].id}')));
          expect(firstItem.top, greaterThan(firstBox.bottom));
          expect(sixthItem.top, greaterThan(firstItem.top));
          expect(sixthItem.left, closeTo(firstItem.left, .1));
          final images = tester.widgetList<Image>(find.byType(Image));
          expect(images.length, 12,
              reason: 'Two characters plus the ten individual cutouts');
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('SORTING_PREVIEW')) {
            await capture(
                tester, '${kind.name}_${locale}_${size.width.toInt()}');
          }
          // Short landscape keeps the reference arrangement and scrolls to the tray.
          await tester.ensureVisible(
              find.byKey(ValueKey('item-${board.content.items.last.id}')));
          await tester.pump();
          expect(tester.takeException(), isNull);
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.paused);
          expect(audio.stops, greaterThan(0));
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          expect(audio.disposed, isTrue);
        });
      }
    }

    for (final pointer in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
      testWidgets(
          '${kind.name} $pointer: wrong drop returns; correct drop snaps; tap alternative and replay',
          (tester) async {
        await openScreen(
            tester, kind, 'en', const Size(800, 1200), RecordingSortingAudio());
        SortingWorksheetBoard board() =>
            tester.widget(find.byType(SortingWorksheetBoard));
        final item = board().content.items.last;
        final origin = tester.getRect(find.byKey(ValueKey('item-${item.id}')));
        final correct = item.attribute('destination')!;
        final wrong =
            board().content.destinations.firstWhere((b) => b.id != correct).id;
        Future<void> drop(String target) async {
          final start =
              tester.getCenter(find.byKey(ValueKey('item-${item.id}')));
          final end = tester.getCenter(find.byKey(ValueKey('box-$target')));
          final gesture = await tester.startGesture(start, kind: pointer);
          await gesture.moveTo(start + const Offset(0, -25));
          await tester.pump();
          await gesture.moveTo(end);
          await tester.pump();
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
        }

        await drop(wrong);
        expect(board().state.placed, isEmpty);
        final returned =
            tester.getRect(find.byKey(ValueKey('item-${item.id}')));
        expect(returned, origin);
        await drop(correct);
        expect(board().state.placed[item.id], correct);
        expect(find.byType(Draggable<String>), findsNWidgets(9));
        for (final next
            in board().content.items.where((i) => i.id != item.id)) {
          await tester.tap(find.byKey(ValueKey('item-${next.id}')));
          await tester.pump();
          await tester.tap(
              find.byKey(ValueKey('box-${next.attribute('destination')}')));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.byType(KidResultView), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        // Confetti keeps scheduling frames on its own real clock. Advance a
        // bounded set of frames for the staggered result animations instead
        // of waiting for the confetti particle system to settle.
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (const bool.fromEnvironment('SORTING_PREVIEW') &&
            pointer == PointerDeviceKind.mouse) {
          await capture(tester, '${kind.name}_complete');
        }
        await tester.tap(find.byIcon(Icons.replay_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(Draggable<String>), findsNWidgets(10));
        expect(board().state.placed, isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }

  testWidgets(
      'a missing voice cannot lose placements or complete a round; closing cancels late audio',
      (tester) async {
    final audio = RecordingSortingAudio()..available = false;
    final cubit = SortingActivityCubit(
        content: loadContent(SortingActivityKind.teeth),
        languageCode: 'ar',
        audio: audio);
    cubit.start();
    await tester.pump();
    expect(cubit.state.audioUnavailable, isTrue);
    audio.pending = Completer();
    cubit.select(cubit.content.items.first.id);
    await cubit.close();
    audio.pending!.complete(true);
    await tester.pump();
    expect(cubit.isClosed, isTrue);
    expect(cubit.state.placed, isEmpty);
  });
}

Future<void> openScreen(WidgetTester tester, SortingActivityKind kind,
    String locale, Size size, RecordingSortingAudio audio) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'SortingPreview'),
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        TestAppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: RepaintBoundary(
          key: const ValueKey('sorting-preview'),
          child: SortingActivityScreen(
              kind: kind, content: loadContent(kind), audio: audio))));
  // The screen precaches twelve images sequentially; decode on the real engine.
  for (var i = 0;
      i < 40 && find.byType(SortingWorksheetBoard).evaluate().isEmpty;
      i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(SortingWorksheetBoard), findsOneWidget);
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        tester.renderObject(find.byKey(const ValueKey('sorting-preview')));
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/sorting_previews').createSync(recursive: true);
    File('build/sorting_previews/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
