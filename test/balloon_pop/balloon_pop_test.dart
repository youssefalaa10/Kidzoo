import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/features/BalloonPop/balloon_audio.dart';
import 'package:kidzo/features/BalloonPop/balloon_cubit.dart';
import 'package:kidzo/features/BalloonPop/balloon_pop_screen.dart';

class FakeBalloonAudio implements BalloonAudio {
  final voices = <String>[];
  final effects = <String>[];
  int stops = 0;
  bool disposed = false;
  @override
  Future<void> speak(List<String> clips) async => voices.addAll(clips);
  @override
  Future<void> effect(String name) async => effects.add(name);
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeBalloonMusic extends Cubit<MusicState> implements MusicCubit {
  FakeBalloonMusic() : super(const MusicState(isSoundEnabled: false));
  int pauses = 0, releases = 0;
  void sound(bool enabled) => emit(state.copyWith(isSoundEnabled: enabled));
  @override
  Future<void> requestPause() async {
    pauses++;
  }

  @override
  Future<void> releasePause() async {
    releases++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class BalloonTestLocalizations extends LocalizationsDelegate<AppLocalizations> {
  const BalloonTestLocalizations();
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
  bool shouldReload(BalloonTestLocalizations old) => false;
}

void advance(BalloonCubit game, double seconds) {
  for (var i = 0; i < seconds * 60; i++) {
    game.tick(1 / 60);
  }
}

Widget app(BalloonCubit game, FakeBalloonAudio audio,
        {String language = 'en',
        GlobalKey? preview,
        bool withNavigation = false}) =>
    MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          BalloonTestLocalizations(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        theme: ThemeData(fontFamily: 'BalloonPreview'),
        home: withNavigation
            ? Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => BalloonPopScreen(
                                    cubit: game, audio: audio))),
                        child: const Text('Open game'))))
            : RepaintBoundary(
                key: preview,
                child: BalloonPopScreen(cubit: game, audio: audio)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('BALLOON_PREVIEW')) return;
    for (final font in {
      'BalloonPreview': 'C:/Windows/Fonts/arial.ttf',
      'MaterialIcons':
          'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    }.entries) {
      await (FontLoader(font.key)
            ..addFont(Future.value(
                ByteData.sublistView(File(font.value).readAsBytesSync()))))
          .load();
    }
  });

  test('drift, bounded spawning, missed balloon cleanup and pause', () async {
    final game = BalloonCubit(random: Random(7));
    game.start();
    final first = game.state.balloons.first;
    expect(first.progress, 0);
    advance(game, 2);
    final moved = game.state.balloons.first;
    expect(moved.progress, greaterThan(first.progress));
    expect(moved.horizontal, isNot(closeTo(first.horizontal, .001)));
    expect(game.state.balloons.map((b) => b.duration).toSet().length,
        greaterThan(1));
    final elapsed = game.state.elapsed;
    game.setPaused(true);
    advance(game, 5);
    expect(game.state.elapsed, elapsed);
    expect(game.pop(moved.id), PopResult.ignored);
    game.setPaused(false);
    for (var i = 0; i < 2400; i++) {
      game.tick(1 / 60);
      expect(game.state.balloons.length, lessThanOrEqualTo(9));
    }
    expect(game.state.balloons.any((b) => b.id == first.id), false);
    expect(game.state.score, 0);
    advance(game, 22);
    expect(game.state.phase, BalloonPhase.complete);
    game.start();
    expect(game.state.elapsed, 0);
    expect(game.state.score, 0);
    expect(game.state.balloons.length, 1);
    await game.close();
  });

  for (final mode in BalloonMode.values
      .where((m) => m != BalloonMode.free && m != BalloonMode.challenge)) {
    test(
        '$mode validates targets, guides without penalty, completes and rejects repeat taps',
        () async {
      final game = BalloonCubit(random: Random(31));
      game.select(mode);
      game.start();
      expect(game.matches(game.state.balloons.first), true);
      advance(game, 7);
      final wrong = game.state.balloons.firstWhere((b) => !game.matches(b));
      final oldTarget = game.state.target;
      expect(game.pop(wrong.id), PopResult.guidance);
      expect(game.state.score, 0);
      expect(game.state.target, oldTarget);
      expect(game.pop(wrong.id), PopResult.ignored);
      for (var i = 0; i < 8; i++) {
        for (var attempts = 0;
            !game.state.balloons.any(game.matches) && attempts < 120;
            attempts++) {
          game.tick(.06);
        }
        final correct = game.state.balloons.firstWhere(game.matches);
        final result = game.pop(correct.id);
        expect(result, i == 7 ? PopResult.complete : PopResult.correct);
        expect(game.pop(correct.id), PopResult.ignored);
        expect(game.state.score, i + 1);
      }
      expect(game.state.phase, BalloonPhase.complete);
      expect(game.state.bursts, isNotEmpty);
      game.start();
      expect(game.state.score, 0);
      expect(game.state.bursts, isEmpty);
      await game.close();
    });
  }

  test('all bundled voice and effect paths exist and contain audio', () {
    for (final effect in ['pop.wav', 'reward.wav', 'celebrate.wav']) {
      expect(
          File('assets/audio/balloon/$effect').lengthSync(), greaterThan(1000));
    }
  });

  for (final size in [
    const Size(360, 640),
    const Size(780, 390),
    const Size(800, 1200)
  ]) {
    for (final language in ['en', 'ar']) {
      testWidgets('ready and playing fit $size $language', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = BalloonCubit(random: Random(3));
        final audio = FakeBalloonAudio();
        await tester.pumpWidget(app(game, audio, language: language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final play = find.text(language == 'en' ? 'Let us pop!' : 'يلا نفرقع!');
        await tester.ensureVisible(play);
        await tester.tap(play);
        await tester.pump();
        for (var i = 0; i < 90; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(game.state.phase, BalloonPhase.playing);
        expect(tester.takeException(), isNull);
        expect(audio.voices, contains('${language}_free'));
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(audio.disposed, true);
        await game.close();
      });
    }
  }

  testWidgets(
      'mouse pop, mute, pause, lifecycle, completion, replay and navigation',
      (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = BalloonCubit(random: Random(4));
    final audio = FakeBalloonAudio();
    await tester.pumpWidget(app(game, audio, withNavigation: true));
    await tester.tap(find.text('Open game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let us pop!'));
    await tester.pump();
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final first = game.state.balloons.first;
    final target = find.bySemanticsLabel(balloonColorNames[first.color]).first;
    await tester.tap(target, kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(game.state.score, 1);
    expect(audio.effects, contains('pop.wav'));
    await tester.tap(find.byTooltip('Sound on or off'));
    await tester.pump();
    final voiceCount = audio.voices.length;
    await tester.tap(find.byIcon(Icons.hearing_rounded));
    await tester.pump();
    expect(audio.voices.length, voiceCount);
    expect(audio.stops, greaterThan(0));
    await tester.tap(find.byTooltip('Pause or resume'));
    await tester.pump();
    final elapsed = game.state.elapsed;
    await tester.pump(const Duration(seconds: 4));
    expect(game.state.elapsed, elapsed);
    await tester.tap(find.text('Keep playing'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(game.state.paused, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Keep playing'));
    await tester.pump();
    // Drive time deterministically, without waiting a real minute.
    advance(game, 61);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You made a party!'), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(game.state.score, 0);
    expect(game.state.phase, BalloonPhase.playing);
    await tester.tap(find.byTooltip('Back to Games'));
    await tester.pumpAndSettle();
    expect(find.text('Open game'), findsOneWidget);
    expect(audio.disposed, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(audio.disposed, true);
    await game.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Arabic instructions, correct feedback and gentle guidance match selections',
      (tester) async {
    final game = BalloonCubit(random: Random(3))..select(BalloonMode.arabic);
    final audio = FakeBalloonAudio();
    await tester.pumpWidget(app(game, audio, language: 'ar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('يلا نفرقع!'));
    await tester.tap(find.text('يلا نفرقع!'));
    await tester.pump();
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final oldTarget = game.state.target;
    expect(audio.voices, contains('ar_arabic_$oldTarget'));
    await tester.tap(find
        .bySemanticsLabel(balloonArabicLetters[oldTarget])
        .hitTestable()
        .first);
    await tester.pump();
    expect(game.state.score, 1);
    expect(audio.voices, contains('ar_correct'));
    expect(audio.voices.last, 'ar_arabic_${game.state.target}');
    for (var i = 0; i < 180; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final wrong = game.state.balloons
        .firstWhere((b) => !game.matches(b) && b.progress > .12);
    final score = game.state.score;
    await tester.tap(find
        .bySemanticsLabel(balloonArabicLetters[wrong.value])
        .hitTestable()
        .first);
    await tester.pump();
    expect(game.state.score, score);
    expect(audio.voices, contains('ar_guidance'));
    expect(audio.voices.last, 'ar_arabic_${game.state.target}');
    await tester.pumpWidget(const SizedBox());
    await game.close();
  });

  testWidgets(
      'global sound setting suppresses voice and effects and releases music pause',
      (tester) async {
    final game = BalloonCubit(random: Random(2));
    final audio = FakeBalloonAudio();
    final music = FakeBalloonMusic();
    await tester.pumpWidget(
        BlocProvider<MusicCubit>.value(value: music, child: app(game, audio)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Let us pop!'));
    await tester.tap(find.text('Let us pop!'));
    await tester.pump();
    expect(audio.voices, isEmpty);
    expect(audio.effects, isEmpty);
    expect(music.pauses, 1);
    music.sound(true);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.hearing_rounded));
    await tester.pump();
    expect(audio.voices, contains('en_free'));
    music.sound(false);
    await tester.pump();
    expect(audio.stops, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(music.releases, 1);
    expect(audio.disposed, true);
    await music.close();
    await game.close();
  });

  test('challenge keeps scoring beyond normal rounds and caps speed and combos',
      () async {
    final game = BalloonCubit(random: Random(9))..select(BalloonMode.challenge);
    game.start();
    expect(game.state.educational, false);
    for (var i = 0; i < 120; i++) {
      while (game.state.balloons.isEmpty) {
        game.tick(.06);
      }
      final id = game.state.balloons.first.id;
      final before = game.state.score;
      expect(game.pop(id), PopResult.playful);
      expect(game.state.score - before, 10 * game.state.multiplier);
      expect(game.pop(id), PopResult.ignored);
      expect(game.state.multiplier, lessThanOrEqualTo(5));
      if (i == 19) {
        expect(game.state.score, 540);
      }
    }
    expect(game.state.pops, 120);
    expect(game.state.wave, 8);
    expect(game.state.multiplier, 5);
    while (game.state.balloons.isEmpty) {
      game.tick(.06);
    }
    expect(game.state.balloons.first.duration, lessThanOrEqualTo(5.31));
    final score = game.state.score;
    game.setPaused(true);
    advance(game, 5);
    expect(game.state.multiplier, 5);
    game.setPaused(false);
    advance(game, 3);
    expect(game.state.multiplier, 1);
    expect(game.state.score, score);
    advance(game, 120);
    expect(game.state.phase, BalloonPhase.playing);
    expect(game.state.balloons.length, lessThanOrEqualTo(9));
    game.finishChallenge();
    expect(game.state.phase, BalloonPhase.complete);
    expect(game.pop(game.state.balloons.first.id), PopResult.ignored);
    game.start();
    expect(game.state.score, 0);
    expect(game.state.streak, 0);
    expect(game.state.wave, 1);
    expect(game.state.balloons.first.duration, greaterThanOrEqualTo(7.5));
    await game.close();
  });

  for (final size in [
    const Size(360, 640),
    const Size(780, 390),
    const Size(800, 1200)
  ]) {
    for (final language in ['en', 'ar']) {
      testWidgets('open challenge HUD, finish and replay at $size $language',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = BalloonCubit(random: Random(7))
          ..select(BalloonMode.challenge);
        final audio = FakeBalloonAudio();
        await tester.pumpWidget(app(game, audio, language: language));
        await tester.pumpAndSettle();
        final play = find.text(language == 'en' ? 'Let us pop!' : 'يلا نفرقع!');
        await tester.ensureVisible(play);
        await tester.tap(play);
        await tester.pump();
        for (var i = 0; i < 190; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(audio.voices, contains('${language}_challenge'));
        await tester.tap(find
            .bySemanticsLabel(RegExp(
                '^(${(language == 'en' ? balloonColorNames : balloonArabicColors).join('|')})'
                r'$'))
            .hitTestable()
            .first);
        await tester.pump();
        expect(game.state.score, 10);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(language == 'en' ? 'Finish' : 'إنهاء'));
        await tester.pumpAndSettle();
        expect(game.state.phase, BalloonPhase.complete);
        expect(audio.voices, contains('${language}_challenge_complete'));
        final replay =
            find.text(language == 'en' ? 'Play again' : 'العب مجددًا');
        await tester.ensureVisible(replay);
        await tester.tap(replay);
        await tester.pump();
        expect(game.state.phase, BalloonPhase.playing);
        expect(game.state.score, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await game.close();
      });
    }
  }

  testWidgets('preview', (tester) async {
    if (!const bool.fromEnvironment('BALLOON_PREVIEW')) return;
    tester.view.physicalSize = const Size(1000, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final game = BalloonCubit(random: Random(17));
    final audio = FakeBalloonAudio();
    await tester.pumpWidget(app(game, audio, preview: key));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File('build/balloon-$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    await capture('start');
    await tester.tap(find.text('Let us pop!'));
    await tester.pump();
    for (var i = 0; i < 360; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await capture('playing');
    await tester.tap(find.byTooltip('Pause or resume'));
    await tester.pump();
    await tester.tap(find.text('Choose a mode'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open Challenge'));
    await tester.tap(find.text('Open Challenge'));
    await tester.pump();
    await tester.ensureVisible(find.text('Let us pop!'));
    await tester.tap(find.text('Let us pop!'));
    await tester.pump();
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await capture('challenge');
    await tester.pumpWidget(const SizedBox());
    await game.close();
  });
}
