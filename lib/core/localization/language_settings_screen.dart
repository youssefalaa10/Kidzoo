import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_localizations.dart';
import 'language_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettings),
        backgroundColor: Colors.blue.shade50,
      ),
      body: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, currentLocale) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageSettings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),

                // Language selection cards
                _buildLanguageCard(
                  context,
                  title: l10n.english,
                  subtitle: l10n.english,
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () => context.read<LanguageCubit>().setLanguage(
                        const Locale('en', ''),
                      ),
                  flag: '🇺🇸',
                ),

                const SizedBox(height: 12),

                _buildLanguageCard(
                  context,
                  title: l10n.arabic,
                  subtitle: l10n.english, // Show English subtitle for Arabic
                  isSelected: currentLocale.languageCode == 'ar',
                  onTap: () => context.read<LanguageCubit>().setLanguage(
                        const Locale('ar', ''),
                      ),
                  flag: '🇸🇦',
                ),

                const SizedBox(height: 30),

                // Quick toggle button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.read<LanguageCubit>().toggleLanguage(),
                    icon: Icon(
                      currentLocale.languageCode == 'en'
                          ? Icons.language
                          : Icons.translate,
                    ),
                    label: Text(
                      currentLocale.languageCode == 'en'
                          ? l10n.switchToArabic
                          : l10n.switchToEnglish,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required String flag,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flag
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),

              const SizedBox(width: 16),

              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
