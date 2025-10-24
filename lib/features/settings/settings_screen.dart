import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../core/helpers/media_query.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/shared/style/image_manager.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Stack(
        children: [
          // Background image (same as games screen)
          Image.asset(
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fitHeight,
            ImageManager.homeBackground,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: mq.height(2)),
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_outlined,
                          size: 30,
                          color: Colors.purple[800],
                        ),
                      ),
                      HeaderSection(
                        mq: mq,
                        title: l10n.funSettings,
                        textColor: Colors.purple[800]!,
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height(3)),
                  // Settings content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Language Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.language,
                            title: l10n.language,
                            description: l10n.languageDescription,
                            child: _buildLanguageSelector(context, l10n),
                            color: Colors.blue,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Sound Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.volume_up,
                            title: l10n.sound,
                            description: l10n.soundDescription,
                            child: _buildSoundSettings(context, l10n),
                            color: Colors.green,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Music Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.music_note,
                            title: l10n.music,
                            description: l10n.musicDescription,
                            child: _buildMusicSettings(context, l10n),
                            color: Colors.orange,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Notifications Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.notifications,
                            title: l10n.notifications,
                            description: l10n.notificationsDescription,
                            child: _buildNotificationSettings(context, l10n),
                            color: Colors.red,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Theme Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.palette,
                            title: l10n.theme,
                            description: l10n.themeDescription,
                            child: _buildThemeSelector(context, l10n),
                            color: Colors.purple,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Brightness Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.brightness_6,
                            title: l10n.brightness,
                            description: l10n.brightnessDescription,
                            child: _buildBrightnessSelector(context, l10n),
                            color: Colors.amber,
                          ),
                          SizedBox(height: mq.height(2)),

                          // Volume Settings Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.volume_down,
                            title: l10n.volume,
                            description: l10n.volumeDescription,
                            child: _buildVolumeSlider(context, l10n),
                            color: Colors.teal,
                          ),
                          SizedBox(height: mq.height(3)),

                          // Action Buttons
                          _buildActionButtons(context, mq, l10n),
                          SizedBox(height: mq.height(2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    CustomMQ mq, {
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(mq.width(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: mq.width(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: mq.width(4.5),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: mq.height(0.5)),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: mq.width(3.2),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: mq.height(2)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, currentLocale) {
        return Row(
          children: [
            Expanded(
              child: _buildLanguageOption(
                context,
                l10n.english,
                '🇺🇸',
                currentLocale.languageCode == 'en',
                () => context.read<LanguageCubit>().setLanguage(
                      const Locale('en', ''),
                    ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: _buildLanguageOption(
                context,
                l10n.arabic,
                '🇸🇦',
                currentLocale.languageCode == 'ar',
                () => context.read<LanguageCubit>().setLanguage(
                      const Locale('ar', ''),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String flag,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              language,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSettings(BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.enableSound,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: settings.soundEnabled,
              onChanged: (value) => settings.setSoundEnabled(value),
              activeThumbColor: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMusicSettings(BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.enableMusic,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: settings.musicEnabled,
              onChanged: (value) => settings.setMusicEnabled(value),
              activeThumbColor: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationSettings(
      BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.enableNotifications,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: settings.notificationsEnabled,
              onChanged: (value) => settings.setNotificationsEnabled(value),
              activeThumbColor: Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Wrap(
          spacing: 8,
          children: [
            _buildThemeOption(
                l10n.light, 'light', Icons.light_mode, settings.selectedTheme),
            _buildThemeOption(
                l10n.dark, 'dark', Icons.dark_mode, settings.selectedTheme),
            _buildThemeOption(l10n.system, 'system',
                Icons.settings_system_daydream, settings.selectedTheme),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
      String label, String value, IconData icon, String selectedTheme) {
    final isSelected = selectedTheme == value;
    return GestureDetector(
      onTap: () => Provider.of<SettingsProvider>(context, listen: false)
          .setSelectedTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.purple : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.purple : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessSelector(BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Wrap(
          spacing: 8,
          children: [
            _buildBrightnessOption(l10n.low, 'low', Icons.brightness_2,
                settings.selectedBrightness),
            _buildBrightnessOption(l10n.medium, 'medium', Icons.brightness_4,
                settings.selectedBrightness),
            _buildBrightnessOption(l10n.high, 'high', Icons.brightness_7,
                settings.selectedBrightness),
            _buildBrightnessOption(l10n.auto, 'auto', Icons.brightness_auto,
                settings.selectedBrightness),
          ],
        );
      },
    );
  }

  Widget _buildBrightnessOption(
      String label, String value, IconData icon, String selectedBrightness) {
    final isSelected = selectedBrightness == value;
    return GestureDetector(
      onTap: () => Provider.of<SettingsProvider>(context, listen: false)
          .setSelectedBrightness(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.amber : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.amber : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(BuildContext context, AppLocalizations l10n) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.adjustVolume,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(settings.volume * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.teal,
                inactiveTrackColor: Colors.teal.withValues(alpha: 0.2),
                thumbColor: Colors.teal,
                overlayColor: Colors.teal.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: settings.volume,
                onChanged: (value) => settings.setVolume(value),
                divisions: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext context, CustomMQ mq, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: Text(l10n.saveSettings),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: mq.height(2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        SizedBox(width: mq.width(3)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.resetSettings),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: mq.height(2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    Provider.of<SettingsProvider>(context, listen: false).saveSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).settingsSaved),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _resetSettings() {
    Provider.of<SettingsProvider>(context, listen: false).resetSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).settingsReset),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    required this.mq,
    super.key,
    this.title = 'Welcome to KidZoo!',
    this.textColor = const Color(0xFF6A1B9A), // Purple by default
  });
  final CustomMQ mq;
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: mq.width(7),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: mq.height(1)),
        Container(
          width: mq.width(20),
          height: mq.height(0.8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(mq.width(1)),
          ),
        ),
      ],
    );
  }
}
