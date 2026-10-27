import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/settings/privacy_policy_screen.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('Policy loads offline in $language and remains readable',
        (tester) async {
      tester.view.physicalSize = const Size(780, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const PrivacyPolicyScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.text(language == 'ar' ? 'سياسة الخصوصية' : 'Privacy policy'),
          findsOneWidget);
      expect(find.textContaining('iOS'), findsWidgets);
      expect(Directionality.of(tester.element(find.byType(SelectionArea))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(find.textContaining('annotex.work@gmail.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
