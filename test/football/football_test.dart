import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/Football/football_cubit.dart';
import 'package:kidzo/features/Football/football_screen.dart';

import '../support/test_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final text = FontLoader('GameText')
      ..addFont(rootBundle.load('assets/fonts/Nunito/Nunito-Variable.ttf'));
    await icons.load();
    await text.load();
  });
  test('aim locks before charging; shot locks power and records only once', () {
    final engine = FootballCubit(random: Random(2));
    addTearDown(engine.close);
    engine.aim(1);
    engine.shoot();
    expect(engine.state.phase, FootballPhase.aiming);
    engine.confirmAim();
    engine.aim(-1);
    expect(engine.state.aim, 1);
    engine.tick(.5);
    engine.shoot();
    final power = engine.state.power;
    engine.shoot();
    engine.tick(1);
    engine.tick(1);
    expect(engine.state.power, power);
    expect(engine.state.results.length, 1);
    expect(engine.state.outcome, ShotOutcome.goal);
  });
  test('weak shots, overpowered shots and five-shot session resolve', () {
    final engine = FootballCubit(random: Random(0));
    addTearDown(engine.close);
    for (var i = 0; i < 5; i++) {
      engine.confirmAim();
      if (i == 1) engine.tick(pi / 3);
      engine.shoot();
      engine.tick(1);
      expect(
          engine.state.outcome, i == 1 ? ShotOutcome.wide : ShotOutcome.weak);
      engine.next();
    }
    expect(engine.state.phase, FootballPhase.finished);
    expect(engine.state.results.length, 5);
    engine.restart();
    expect(engine.state.phase, FootballPhase.aiming);
    expect(engine.state.results, isEmpty);
  });
  test('open challenge continues past five shots and gets harder', () {
    final engine = FootballCubit(random: Random(0));
    addTearDown(engine.close);
    engine.chooseMode(FootballMode.openChallenge);
    final initialGreen = engine.state.greenEnd - engine.state.greenStart;
    for (var i = 0; i < 6; i++) {
      engine.confirmAim();
      engine.tick(.5);
      engine.shoot();
      engine.tick(1);
      engine.next();
    }
    expect(engine.state.phase, FootballPhase.aiming);
    expect(engine.state.difficulty, 2);
    expect(engine.state.greenEnd - engine.state.greenStart,
        lessThan(initialGreen));
    expect(engine.state.score, greaterThanOrEqualTo(0));
  });
  test('next level carries score forward and increases difficulty', () {
    final engine = FootballCubit(random: Random(2));
    addTearDown(engine.close);
    for (var i = 0; i < 5; i++) {
      engine.aim(1);
      engine.confirmAim();
      engine.tick(.5);
      engine.shoot();
      engine.tick(1);
      engine.next();
    }
    final score = engine.state.score;
    engine.nextLevel();
    expect(engine.state.level, 2);
    expect(engine.state.score, score);
    expect(engine.state.results, isEmpty);
  });
  for (final size in [
    const Size(360, 640),
    const Size(780, 390),
    const Size(800, 1200)
  ]) {
    for (final lang in ['en', 'ar']) {
      testWidgets('controls and layout at $size in $lang', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(fontFamily: 'GameText'),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              TestAppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            home: const RepaintBoundary(
                key: ValueKey('capture'), child: FootballScreen())));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        final confirm = find.byIcon(Icons.check_rounded);
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Slider), findsNothing);
        if (size.width == 800 && lang == 'en') {
          await tester.runAsync(() async {
            for (final image in tester.widgetList<Image>(find.byType(Image))) {
              await precacheImage(image.image,
                  tester.element(find.byKey(const ValueKey('capture'))));
            }
          });
          await tester.pump(const Duration(milliseconds: 100));
          final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('capture')));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/game_previews/football.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await tester.ensureVisible(
            find.byTooltip(lang == 'en' ? 'Pause' : 'إيقاف مؤقت'));
        await tester.tap(find.byTooltip(lang == 'en' ? 'Pause' : 'إيقاف مؤقت'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
