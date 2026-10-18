import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/settings/widgets/arabic_voice_section.dart';

void main() {
  testWidgets(
    'Arabic voice settings hides the refresh button and removes the banned Arabic words',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ArabicVoiceSection()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('افحص تاني'), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.textContaining('حريمي'), findsNothing);
      expect(find.textContaining('مصري'), findsNothing);
      expect(find.text('جرّب الصوت'), findsOneWidget);
    },
  );
}
