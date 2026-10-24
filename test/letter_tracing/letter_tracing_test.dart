import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/LetterTracing/arabic_tracing_data.dart';
import 'package:kidzo/features/LetterTracing/english_tracing_data.dart';
import 'package:kidzo/features/LetterTracing/letter_tracing_screen.dart';
import 'package:kidzo/features/LetterTracing/tracing_audio.dart';
import 'package:kidzo/features/LetterTracing/tracing_board.dart';
import 'package:kidzo/features/LetterTracing/tracing_cubit.dart';
import 'package:kidzo/features/LetterTracing/tracing_letter.dart';

class TestTracingAudio implements TracingAudio {
  final clips = <String>[];
  bool disposed = false;
  int stopped = 0;
  @override
  Future<bool> play(String clip, {bool success = false}) async {
    clips.add(clip);
    return true;
  }

  @override
  Future<void> stop() async {
    stopped++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class TestTracingLocalizations extends LocalizationsDelegate<AppLocalizations> {
  const TestTracingLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(
          locale,
          (jsonDecode(File('assets/lang/${locale.languageCode}.json')
                  .readAsStringSync()) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String))));
  @override
  bool shouldReload(TestTracingLocalizations old) => false;
}

void trace(TracingCubit cubit) {
  for (final stroke in cubit.strokes) {
    cubit.down(stroke.samples.first, 1);
    for (final sample in stroke.samples.skip(1)) {
      cubit.move(sample, 1);
    }
    cubit.up(1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('TRACING_PREVIEW')) return;
    for (final entry in {
      'TracingPreview': 'C:/Windows/Fonts/arial.ttf',
      'TracingNaskh': 'assets/fonts/NotoNaskhArabic-Regular.ttf',
      'MaterialIcons':
          'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(
            ByteData.sublistView(File(entry.value).readAsBytesSync())));
      await loader.load();
    }
  });
  test('all Arabic forms and both English cases have valid, completable paths',
      () async {
    for (final language in TracingLanguage.values) {
      for (final lowercase
          in language == TracingLanguage.english ? [false, true] : [false]) {
        final cubit = TracingCubit(language: language);
        expect(
            cubit.letters.length, language == TracingLanguage.arabic ? 28 : 26);
        for (var i = 0; i < cubit.letters.length; i++) {
          final letter = cubit.letters[i];
          for (final form in [LetterForm.isolated, ...letter.forms.keys]) {
            cubit.select(
                language: language, lowercase: lowercase, index: i, form: form);
            expect(cubit.state.complete, false);
            for (final stroke in cubit.strokes) {
              expect(stroke.length, greaterThan(0));
              for (final p in stroke.samples) {
                expect(p.dx, inInclusiveRange(15, 285), reason: letter.symbol);
                expect(p.dy, inInclusiveRange(15, 290), reason: letter.symbol);
              }
            }
            trace(cubit);
            expect(cubit.state.complete, true,
                reason:
                    '${letter.symbol} $lowercase $form stroke ${cubit.state.stroke} sample ${cubit.state.sample}');
            expect(cubit.progress, 1);
            expect(cubit.state.completed, contains(cubit.state.key));
          }
        }
        await cubit.close();
      }
    }
  });

  test(
      'rejects endpoint taps, backward strokes, shortcuts and second pointers; resumes after lifts',
      () async {
    final cubit = TracingCubit(language: TracingLanguage.english);
    final stroke = cubit.strokes.first;
    cubit.down(stroke.samples.last, 1);
    cubit.up(1);
    expect(cubit.state.sample, 0);
    cubit.down(stroke.samples.first, 1);
    cubit.move(stroke.samples.last, 2);
    cubit.up(2);
    expect(cubit.state.sample, 0);
    for (final p in stroke.samples.take(25)) {
      cubit.move(p, 1);
    }
    cubit.up(1);
    final checkpoint = cubit.state.sample;
    expect(checkpoint, greaterThan(10));
    cubit.down(stroke.samples[checkpoint], 1);
    for (final p in stroke.samples.skip(checkpoint)) {
      cubit.move(p, 1);
    }
    cubit.up(1);
    expect(cubit.state.stroke, 1);
    cubit.restart();
    expect(cubit.state.sample, 0);
    cubit.select(index: 14); // O: a straight chord cannot cover the oval.
    final oval = cubit.strokes.first;
    cubit.down(oval.samples.first, 1);
    cubit.move(oval.samples[oval.samples.length ~/ 2], 1);
    cubit.up(1);
    expect(cubit.state.complete, false);
    cubit.select(index: 0);
    cubit.down(cubit.strokes.first.samples.first, 1);
    for (final p in cubit.strokes.first.samples.reversed) {
      cubit.move(p, 1);
    }
    cubit.up(1);
    expect(cubit.state.complete, false);
    await cubit.close();
  });

  test(
      'Arabic dots require their own pointer contact and cancellation does not finish',
      () async {
    final cubit = TracingCubit();
    cubit.select(index: 1); // baa
    final body = cubit.strokes.first;
    cubit.down(body.samples.first, 1);
    for (final p in body.samples) {
      cubit.move(p, 1);
    }
    expect(cubit.state.needsLift, true);
    cubit.up(1);
    expect(cubit.state.complete, false);
    cubit.down(cubit.strokes.last.samples.first, 1);
    cubit.cancel(1);
    expect(cubit.state.complete, false);
    cubit.down(cubit.strokes.last.samples.first, 1);
    cubit.up(1);
    expect(cubit.state.complete, true);
    cubit.select(language: TracingLanguage.english);
    expect(cubit.state.complete, false);
    expect(cubit.state.completed.length, 1);
    await cubit.close();
  });

  test('the font license ships', () {
    expect(File('assets/fonts/OFL.txt').readAsStringSync(),
        contains('SIL OPEN FONT LICENSE'));
  });

  for (final locale in ['en', 'ar']) {
    for (final size in [
      const Size(360, 640),
      const Size(780, 390),
      const Size(800, 1200)
    ]) {
      testWidgets(
          '$locale layout, mouse/touch alignment, voices and navigation at $size',
          (tester) async {
        tester.view.reset();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final audio = TestTracingAudio();
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
                theme: ThemeData(fontFamily: 'TracingPreview'),
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  TestTracingLocalizations(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate
                ],
                home: LetterTracingScreen(audio: audio))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(audio.clips.first, '${locale}_0');
        final board = tester.widget<TracingBoard>(find.byType(TracingBoard));
        final rect = tester.getRect(find.byType(TracingBoard));
        final scale =
            (rect.width < rect.height ? rect.width : rect.height) / 320;
        final origin = rect.center - Offset(150 * scale, 150 * scale);
        final stroke = board.cubit.strokes.first;
        final gesture = await tester.startGesture(
            origin + stroke.samples.first * scale,
            kind: locale == 'en'
                ? PointerDeviceKind.mouse
                : PointerDeviceKind.touch);
        for (final p in stroke.samples.skip(1)) {
          await gesture.moveTo(origin + p * scale);
        }
        await gesture.up();
        await tester.pump();
        expect(board.cubit.state.stroke, locale == 'en' ? 1 : 0);
        if (locale == 'ar') {
          expect(board.cubit.state.complete, true);
          expect(audio.clips, contains('ar_success'));
          await tester.pump(const Duration(seconds: 6));
          await tester.pump();
          expect(board.cubit.state.index, 1);
        }
        if (const bool.fromEnvironment('TRACING_PREVIEW')) {
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            Directory('build/tracing_preview').createSync(recursive: true);
            File('build/tracing_preview/${locale}_${size.width.toInt()}.png')
                .writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(audio.disposed, true);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('render letter atlases for visual review', () async {
    if (!const bool.fromEnvironment('TRACING_PREVIEW')) return;
    final loader = FontLoader('TracingNaskh')
      ..addFont(Future.value(ByteData.sublistView(
          File('assets/fonts/NotoNaskhArabic-Regular.ttf').readAsBytesSync())));
    await loader.load();
    for (final entry in {
      'arabic': arabicTracingLetters(),
      'uppercase': englishTracingLetters(lowercase: false),
      'lowercase': englishTracingLetters(lowercase: true),
    }.entries) {
      for (final form in entry.key == 'arabic'
          ? LetterForm.values
          : [LetterForm.isolated]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
        for (var i = 0; i < entry.value.length; i++) {
          final letter = entry.value[i];
          final origin = Offset((i % 7) * 170.0, (i ~/ 7) * 190.0);
          final painter = TracingPainter(
              strokes: letter.paths(form),
              state: const TracingState(),
              origin: origin + const Offset(0, 20),
              scale: .52);
          painter.paint(canvas, const Size(170, 190));
          final label = TextPainter(
              text: TextSpan(
                  text: '${letter.symbol} · ${i + 1}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'TracingNaskh',
                      fontSize: 20)),
              textDirection: TextDirection.ltr)
            ..layout();
          label.paint(canvas, origin + const Offset(70, 0));
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(1190, 760);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/tracing_preview').createSync(recursive: true);
        File('build/tracing_preview/${entry.key}_${form.name}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    }
  });

  testWidgets(
      'switches language and case, demonstrates, mutes and stops on background',
      (tester) async {
    final audio = TestTracingAudio();
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          TestTracingLocalizations(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: LetterTracingScreen(audio: audio)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arabic · أ ب ت'));
    await tester.pumpAndSettle();
    expect(audio.clips.last, 'ar_0');
    await tester.tap(find.text('English · ABC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowercase · abc'));
    await tester.pumpAndSettle();
    final cubit = tester.widget<TracingBoard>(find.byType(TracingBoard)).cubit;
    expect(cubit.letters.first.symbol, 'a');
    expect(audio.clips.last, 'en_0');
    await tester.tap(find.text('Show me'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<TracingBoard>(find.byType(TracingBoard)).demonstration,
        isNotNull);
    expect(audio.clips.last, 'en_hint');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(audio.stopped, greaterThan(0));
    expect(tester.widget<TracingBoard>(find.byType(TracingBoard)).demonstration,
        isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.byTooltip('Turn voice off'));
    await tester.pump();
    final count = audio.clips.length;
    await tester.tap(find.byTooltip('Hear the letter'));
    await tester.pump();
    expect(audio.clips.length, count);
    await tester.tap(find.byTooltip('Turn voice on'));
    await tester.pump();
    expect(audio.clips.last, 'en_0');
    trace(cubit);
    await tester.pump();
    expect(audio.clips.last, 'en_success');
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    expect(cubit.state.index, 0);
    expect(cubit.state.complete, false);
    expect(cubit.progress, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
