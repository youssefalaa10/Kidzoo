import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/LittleInventor/inventor_cubit.dart';
import 'package:kidzo/features/LittleInventor/little_inventor_screen.dart';

import '../support/test_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (call) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global/events'),
        (call) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (call) async => null);
      }
      return null;
    });
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final text = FontLoader('GameText')
      ..addFont(rootBundle.load('assets/fonts/Nunito/Nunito-Variable.ttf'));
    await icons.load();
    await text.load();
  });
  test('rejects overlap, reuse and pieces extending past a bank', () {
    final engine = InventorCubit();
    addTearDown(engine.close);
    engine.place(0, 0);
    engine.place(1, 1);
    expect(engine.state.placements, {0: 0});
    expect(engine.state.feedback, BridgeFeedback.noRoom);
    engine.place(0, 2);
    expect(engine.state.placements, {0: 0});
    engine.place(1, 3);
    expect(engine.state.placements, {0: 0});
    engine.testBridge();
    expect(engine.state.feedback, BridgeFeedback.gap);
  });
  test('centre drops cannot strand the two long planks', () {
    final engine = InventorCubit();
    addTearDown(engine.close);
    engine.drop(0, 1);
    expect(engine.state.placements[0], 0);
    engine.drop(1, 2);
    expect(engine.state.placements[1], 2);
    engine.drop(4, 4);
    engine.drop(5, 7);
    engine.testBridge();
    expect(engine.state.feedback, BridgeFeedback.success);
  });
  test('all challenges are solvable and completion cycles back to start', () {
    final engine = InventorCubit();
    addTearDown(engine.close);
    for (var round = 0; round < 3; round++) {
      expect(engine.state.challenge, round);
      final solution = switch (round) {
        0 => {0: 0, 1: 2, 4: 4, 5: 7},
        1 => {0: 5, 1: 8, 2: 7, 3: 1, 4: 2, 5: 3},
        _ => {0: 10, 1: 3, 2: 6, 3: 8, 4: 7, 5: 9},
      };
      for (final piece in solution.entries) {
        engine.place(piece.key, piece.value);
      }
      engine.testBridge();
      expect(engine.state.feedback, BridgeFeedback.success);
      engine.tapCell(0);
      expect(engine.state.placements, isNotEmpty);
      engine.next();
    }
    expect(engine.state.challenge, 0);
    expect(engine.state.placements, isEmpty);
  });
  test('placed pieces can be recovered and reset clears feedback and hints',
      () {
    final engine = InventorCubit();
    addTearDown(engine.close);
    engine.place(0, 0);
    engine.tapCell(1);
    expect(engine.state.placements, isEmpty);
    engine.showHint();
    engine.testBridge();
    engine.next();
    expect(engine.state.challenge, 0);
    engine.reset();
    expect(engine.state.hint, false);
    expect(engine.state.feedback, BridgeFeedback.building);
  });
  testWidgets('all bridge layouts can be built through touch controls',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'GameText'),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          TestAppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: const RepaintBoundary(
            key: ValueKey('stages'), child: LittleInventorScreen())));
    await tester.pump(const Duration(milliseconds: 100));
    for (var stage = 0; stage < 3; stage++) {
      final model = InventorState(challenge: stage);
      final solution = switch (stage) {
        0 => {0: 0, 1: 2, 4: 4, 5: 7},
        1 => {0: 5, 1: 8, 2: 7, 3: 1, 4: 2, 5: 3},
        _ => {0: 10, 1: 3, 2: 6, 3: 8, 4: 7, 5: 9}
      };
      final ids = model.availablePieces.map((p) => p.id).toList();

      for (final piece in solution.entries) {
        await tester
            .tap(find.byType(Draggable<int>).at(ids.indexOf(piece.key)));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('bridge_cell_${piece.value}')));
        await tester.pump();
      }
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image,
              tester.element(find.byKey(const ValueKey('stages'))));
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('stages')));
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file =
            File('build/game_previews/inventor_stage_${stage + 1}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      if (stage == 2) {
        expect(find.text('You finished every bridge!'), findsOneWidget);
      } else {
        expect(find.text('Next bridge'), findsOneWidget);
        await tester.tap(find.byType(FilledButton).last);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  for (final size in [
    const Size(360, 640),
    const Size(780, 390),
    const Size(800, 1200)
  ]) {
    for (final language in ['ar', 'en']) {
      testWidgets('layout and hints at $size in $language', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: 'GameText'),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            TestAppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          home: const RepaintBoundary(
              key: ValueKey('capture'), child: LittleInventorScreen()),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (size.width == 800 && language == 'en') {
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
            final file = File('build/game_previews/inventor.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        if (size.width == 360 && language == 'en') {
          final piece = find.byType(Draggable<int>).first;
          final slot = find.byType(DragTarget<int>).first;
          await tester.dragFrom(tester.getCenter(piece),
              tester.getCenter(slot) - tester.getCenter(piece));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byTooltip(language == 'en' ? 'Hint' : 'تلميح'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(LittleInventorScreen), findsOneWidget);
      });
    }
  }
}
