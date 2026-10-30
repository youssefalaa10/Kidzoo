// Run once per capture: flutter test tool/capture_ipad_screenshots.dart
// --dart-define=SHOT_LANGUAGE=ar --dart-define=SHOT_SCREEN=education
// Flutter widget renders, not captures from an iPad or iOS Simulator.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/features/AppCategory/education_screen.dart';
import 'package:kidzo/features/AppCategory/games_screen.dart';

class _SilentMusic extends Cubit<MusicState> implements MusicCubit {
  _SilentMusic() : super(const MusicState(isSoundEnabled: false));
  @override
  Future<void> requestPause() async {}
  @override
  Future<void> releasePause() async {}
  @override
  Future<void> resumeMusic() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    final font = File(
        'C:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf');
    if (font.existsSync()) {
      await (FontLoader('Roboto')
            ..addFont(
                Future.value(ByteData.sublistView(font.readAsBytesSync()))))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(File(
                  'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytesSync()))))
        .load();
    await (FontLoader('TracingNaskh')
          ..addFont(Future.value(ByteData.sublistView(
              File('assets/fonts/NotoNaskhArabic-Regular.ttf')
                  .readAsBytesSync()))))
        .load();
  });
  for (final language in [
    const String.fromEnvironment('SHOT_LANGUAGE', defaultValue: 'ar')
  ]) {
    for (final screen in [
      const String.fromEnvironment('SHOT_SCREEN', defaultValue: 'education')
    ]) {
      testWidgets('Render $language $screen at iPad 13-inch size',
          (tester) async {
        tester.view.physicalSize = const Size(2064, 2752);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        final music = _SilentMusic();
        addTearDown(music.close);
        await tester.pumpWidget(MaterialApp(
          key: ValueKey('$language-$screen'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              platform: TargetPlatform.iOS,
              fontFamily: 'Roboto',
              fontFamilyFallback: const ['TracingNaskh']),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RepaintBoundary(
            key: key,
            child: BlocProvider<MusicCubit>.value(
                value: music,
                child: screen == 'education'
                    ? const EducationScreen()
                    : const GamesScreen()),
          ),
        ));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, key.currentContext!);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final out = Directory('build/ipad_store_previews')
            ..createSync(recursive: true);
          File('${out.path}/kidzo-ipad-13-$screen-$language-2064x2752.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
