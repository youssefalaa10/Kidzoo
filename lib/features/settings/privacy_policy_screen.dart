import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

/// Bundled policy stays readable offline and never sends a child to a browser.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = l10n.locale.languageCode == 'ar' ? 'ar' : 'en';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resolve('privacyPolicy'))),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context)
            .loadString('assets/privacy/$language.json'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.resolve('privacyPolicyLoadError')),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final policy = jsonDecode(snapshot.data!) as Map<String, dynamic>;
          final sections = (policy['sections'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final theme = Theme.of(context).textTheme;
          return SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(policy['date'] as String, style: theme.labelLarge),
                  const SizedBox(height: 16),
                  Text(policy['intro'] as String),
                  for (final section in sections) ...[
                    const SizedBox(height: 24),
                    Text(section['title'] as String, style: theme.titleMedium),
                    const SizedBox(height: 8),
                    Text(section['text'] as String),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
