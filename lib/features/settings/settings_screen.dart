import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/helpers/media_query.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/mixins/background_music_mixin.dart';
import '../../core/services/cubit/music_cubit.dart';
import '../../core/shared/style/image_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with BackgroundMusicMixin {
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

                          // Background Music Track Card
                          _buildSettingsCard(
                            context,
                            mq,
                            icon: Icons.album,
                            title: 'Background Music',
                            description:
                                'Choose which music track plays in the background',
                            child: _buildMusicTrackSelector(context),
                            color: Colors.deepPurple,
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

  Widget _buildMusicSettings(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<MusicCubit, MusicState>(
      builder: (context, musicState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.enableMusic,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: musicState.isMusicEnabled,
              onChanged: (value) {
                context.read<MusicCubit>().setMusicEnabled(value);
              },
              activeThumbColor: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeSlider(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<MusicCubit, MusicState>(
      builder: (context, musicState) {
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
                  '${(musicState.volume * 100).round()}%',
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
                value: musicState.volume,
                onChanged: (value) {
                  context.read<MusicCubit>().setVolume(value);
                },
                divisions: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMusicTrackSelector(BuildContext context) {
    return BlocBuilder<MusicCubit, MusicState>(
      builder: (context, musicState) {
        return Row(
          children: [
            Expanded(
              child: _buildTrackOption(
                context,
                label: 'Track 1',
                icon: '🎵',
                track: 'audio/ton.mp3',
                isSelected: musicState.musicTrack == 'audio/ton.mp3',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTrackOption(
                context,
                label: 'Track 2',
                icon: '🎶',
                track: 'audio/ton2.mp3',
                isSelected: musicState.musicTrack == 'audio/ton2.mp3',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackOption(
    BuildContext context, {
    required String label,
    required String icon,
    required String track,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => context.read<MusicCubit>().setMusicTrack(track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepPurple : Colors.grey[700],
              ),
            ),
          ],
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
