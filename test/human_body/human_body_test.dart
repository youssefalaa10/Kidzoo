import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/HumanBody/body_artwork.dart';
import 'package:kidzo/features/HumanBody/body_audio.dart';
import 'package:kidzo/features/HumanBody/body_board.dart';
import 'package:kidzo/features/HumanBody/body_game_cubit.dart';
import 'package:kidzo/features/HumanBody/body_parts.dart';
import 'package:kidzo/features/HumanBody/human_body_screen.dart';

class TestBodyAudio implements BodyAudio {
  final List<String> spoken = [];
  final List<BodyAudioCue?> cues = [];
  bool available = true;
  int stops = 0;
  bool disposed = false;
  Completer<bool>? pending;
  @override
  Future<bool> say(String text, {BodyAudioCue? cue}) {
    spoken.add(text);
    cues.add(cue);
    return pending?.future ?? Future.value(available);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Map<String, String> loadStrings(String locale) =>
    (jsonDecode(File('assets/lang/$locale.json').readAsStringSync())
            as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as String));

void finishStage(BodyGameCubit cubit) {
  for (final BodyPart part in cubit.state.available) {
    expect(cubit.placeAt(part.id, part.anchors.first), isTrue,
        reason: part.id.name);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('BODY_PREVIEW')) {
      final Map<String, String> fonts = {
        'BodyPreview': 'C:/Windows/Fonts/arial.ttf',
        'MaterialIcons':
            'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      };
      for (final MapEntry<String, String> font in fonts.entries) {
        if (File(font.value).existsSync()) {
          final FontLoader loader = FontLoader(font.key)
            ..addFont(Future.value(
                ByteData.sublistView(File(font.value).readAsBytesSync())));
          await loader.load();
        }
      }
    }
  });
  for (final String locale in ['en', 'ar']) {
    group('Learning session in $locale', () {
      late TestBodyAudio audio;
      late BodyGameCubit cubit;
      final Map<String, String> strings = loadStrings(locale);
      setUp(() {
        audio = TestBodyAudio();
        cubit = BodyGameCubit(audio: audio, text: (key) => strings[key]!);
      });
      tearDown(() async {
        if (!cubit.isClosed) await cubit.close();
      });

      test(
          'starts incomplete, names every part, finishes three stages and replays',
          () async {
        cubit.start();
        expect(cubit.state.placed, isEmpty);
        expect(cubit.state.available.length, 6);
        expect(audio.spoken.single, strings['bodyWelcome']);
        for (int stage = 0; stage < 3; stage++) {
          expect(cubit.state.stage, stage);
          for (final BodyPart part in const BodyParts().forStage(stage)) {
            cubit.select(part.id);
            expect(audio.spoken.last, contains(strings[part.nameKey]));
            expect(cubit.placeAt(part.id, part.anchors.last), isTrue);
            expect(audio.spoken.last, contains(strings[part.nameKey]));
            expect(cubit.state.available.any((p) => p.id == part.id), isFalse);
          }
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.stageComplete, isTrue);
          expect(audio.cues.last, BodyAudioCue.celebrate);
          if (stage < 2) cubit.nextStage();
        }
        expect(cubit.state.complete, isTrue);
        expect(cubit.state.placed.length, 18);
        expect(audio.spoken.last, strings['bodyFinished']);
        cubit.replay();
        expect(cubit.state.stage, 0);
        expect(cubit.state.placed, isEmpty);
      });

      test('wrong spots, outside drops and duplicates never advance progress',
          () {
        cubit.nextStage();
        expect(cubit.state.stage, 0);
        cubit.select(BodyPartId.nose);
        expect(cubit.placeAt(BodyPartId.nose, const Offset(216, 112)), isFalse);
        expect(cubit.state.placed, isEmpty);
        expect(cubit.state.hintVisible, isTrue);
        expect(audio.cues.last, BodyAudioCue.retry);
        expect(audio.spoken.last, contains(strings['bodyPart_nose']));
        cubit.reject(BodyPartId.nose);
        expect(cubit.placeAt(BodyPartId.nose, const Offset(180, 143)), isTrue);
        expect(cubit.placeAt(BodyPartId.nose, const Offset(180, 143)), isFalse);
        expect(cubit.state.placed.length, 1);
        expect(cubit.placeAt(BodyPartId.hands, const Offset(43, 352)), isFalse);
      });

      test('restart retains previous stages and clears only the current stage',
          () {
        finishStage(cubit);
        cubit.nextStage();
        cubit.placeAt(BodyPartId.head, const Offset(180, 138));
        cubit.restartStage();
        expect(cubit.state.stage, 1);
        expect(cubit.state.placed.length, 6);
        expect(cubit.state.placed.contains(BodyPartId.head), isFalse);
        finishStage(cubit);
        cubit.nextStage();
        finishStage(cubit);
        cubit.restartStage();
        expect(cubit.state.placed.length, 13);
        expect(cubit.state.complete, isFalse);
      });

      test('mute, background and unavailable speech are handled', () async {
        cubit.toggleSound();
        cubit.select(BodyPartId.nose);
        expect(audio.spoken, isEmpty);
        expect(audio.stops, 1);
        audio.available = false;
        cubit.toggleSound();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.audioUnavailable, isTrue);
        cubit.suspend();
        final int count = audio.spoken.length;
        cubit.select(BodyPartId.mouth);
        expect(audio.spoken.length, count);
        cubit.resume();
        cubit.select(BodyPartId.mouth);
        expect(audio.spoken.length, count + 1);
      });

      test('late speech completion cannot celebrate after replay or disposal',
          () async {
        audio.pending = Completer<bool>();
        finishStage(cubit);
        cubit.replay();
        audio.pending!.complete(true);
        await Future<void>.delayed(Duration.zero);
        expect(audio.cues, isNot(contains(BodyAudioCue.celebrate)));
        expect(cubit.state.placed, isEmpty);
        await cubit.close();
        expect(audio.disposed, isTrue);
      });
    });
  }

  test('every target round-trips through the viewport at every supported size',
      () {
    for (final Size size in [
      const Size(336, 310),
      const Size(520, 282),
      const Size(776, 800)
    ]) {
      for (int stage = 0; stage < 3; stage++) {
        for (final bool overview in [true, false]) {
          final BodyViewport viewport =
              BodyViewport(size: size, stage: stage, overview: overview);
          for (final BodyPart part in const BodyParts().forStage(stage)) {
            for (final Offset anchor in part.anchors) {
              final Offset local = viewport.toLocal(anchor);
              expect(local.dx, inInclusiveRange(0, size.width));
              expect(local.dy, inInclusiveRange(0, size.height));
              expect(
                  (viewport.toScene(local) - anchor).distance, lessThan(.001));
              expect(
                  const BodyParts().hitTest(viewport.toScene(local),
                      const BodyParts().forStage(stage)),
                  part.id);
            }
          }
        }
      }
    }
  });

  test('all feature strings translate and every effect is bundled', () {
    final Map<String, String> english = loadStrings('en');
    final Map<String, String> arabic = loadStrings('ar');
    final Set<String> keys = english.keys
        .where((key) => key.startsWith('body') || key == 'learnHumanBody')
        .toSet();
    for (final String key in keys) {
      expect(arabic[key], isNotEmpty, reason: key);
    }
    for (final String asset in [
      'success.mp3',
      'piano-d.wav',
      'score.mp3'
    ]) {
      expect(File('assets/audio/$asset').lengthSync(), greaterThan(1000));
    }
  });

  for (final String locale in ['en', 'ar']) {
    for (final Size size in [
      const Size(360, 640),
      const Size(780, 390),
      const Size(800, 1200)
    ]) {
      testWidgets(
          '$locale $size: all stages fit and render an assembled character',
          (tester) async {
        await openGame(tester, size, locale);
        final BodyGameCubit cubit =
            tester.element(find.byType(BodyBoard)).read<BodyGameCubit>();
        for (int stage = 0; stage < 3; stage++) {
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('BODY_PREVIEW')) {
            await capture(
                tester, '${locale}_${size.width.toInt()}_stage$stage');
          }
          finishStage(cubit);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('body-continue')), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (stage < 2) {
            await tester.tap(find.byKey(const ValueKey('body-continue')));
            await tester.pumpAndSettle();
          }
        }
        final BodyCharacterPainter painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((widget) => widget.painter)
            .whereType<BodyCharacterPainter>()
            .single;
        expect(painter.placed.length, 18);
        if (const bool.fromEnvironment('BODY_PREVIEW')) {
          await capture(tester, '${locale}_${size.width.toInt()}_complete');
        }
        await tester.tap(find.byKey(const ValueKey('body-continue')));
        await tester.pumpAndSettle();
        expect(cubit.state.placed, isEmpty);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final PointerDeviceKind kind in [
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse
  ]) {
    for (final Size size in [const Size(360, 640), const Size(780, 390)]) {
      testWidgets('$kind $size: drag all 18 parts through the complete game',
          (tester) async {
        await openGame(tester, size, 'en');
        final BodyGameCubit cubit =
            tester.element(find.byType(BodyBoard)).read<BodyGameCubit>();
        for (int stage = 0; stage < 3; stage++) {
          for (final BodyPart part in const BodyParts().forStage(stage)) {
            final Finder piece =
                find.byKey(ValueKey('body-drag-${part.id.name}'));
            final TestGesture gesture =
                await tester.startGesture(tester.getCenter(piece), kind: kind);
            await tester.pump();
            await gesture.moveTo(boardTarget(tester, part.anchors.last));
            await tester.pump();
            await gesture.up();
            await tester.pumpAndSettle();
            expect(cubit.state.placed, contains(part.id));
            expect(piece, findsNothing);
            expect(tester.takeException(), isNull);
          }
          if (stage < 2) {
            await tester.tap(find.byKey(const ValueKey('body-continue')));
            await tester.pumpAndSettle();
          }
        }
        expect(cubit.state.complete, isTrue);
      });
    }
    testWidgets(
        '$kind: pointer placement, rejection, tray removal and tap alternative',
        (tester) async {
      await openGame(tester, const Size(360, 640), 'en');
      final BodyGameCubit cubit =
          tester.element(find.byType(BodyBoard)).read<BodyGameCubit>();
      final Finder drag = find.byKey(const ValueKey('body-drag-leftEye'));
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(drag), kind: kind);
      await tester.pump();
      final Offset target = boardTarget(tester, const Offset(216, 112));
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(cubit.state.placed, contains(BodyPartId.leftEye));
      expect(drag, findsNothing);
      final Finder rightEye = find.byKey(const ValueKey('body-drag-rightEye'));
      final TestGesture wrong =
          await tester.startGesture(tester.getCenter(rightEye), kind: kind);
      await wrong.moveTo(boardTarget(tester, const Offset(180, 180)));
      await tester.pump();
      await wrong.up();
      await tester.pumpAndSettle();
      expect(cubit.state.placed.length, 1);
      expect(rightEye, findsOneWidget);
      await tester.tap(rightEye);
      await tester.pump();
      await tester.tapAt(boardTarget(tester, const Offset(144, 112)));
      await tester.pumpAndSettle();
      expect(cubit.state.placed.length, 2);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> openGame(WidgetTester tester, Size size, String locale) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('body-preview'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'BodyPreview'),
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          TestBodyLocalizations(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: HumanBodyScreen(audio: TestBodyAudio()),
      )));
  await tester.pumpAndSettle();
}

Offset boardTarget(WidgetTester tester, Offset point) {
  final CustomPaint paint = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .firstWhere((widget) => widget.painter is BodyCharacterPainter);
  final BodyCharacterPainter painter = paint.painter! as BodyCharacterPainter;
  return tester.getTopLeft(find.byWidget(paint)) +
      painter.viewport.toLocal(point);
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        tester.renderObject(find.byKey(const ValueKey('body-preview')));
    final ui.Image image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/human_body_previews').createSync(recursive: true);
    File('build/human_body_previews/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

class TestBodyLocalizations extends LocalizationsDelegate<AppLocalizations> {
  const TestBodyLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
      AppLocalizations(locale, loadStrings(locale.languageCode)));
  @override
  bool shouldReload(TestBodyLocalizations old) => false;
}
