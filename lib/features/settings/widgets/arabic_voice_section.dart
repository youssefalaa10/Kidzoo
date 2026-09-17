import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/helpers/speech.dart';
import '../../../core/helpers/tts_service.dart';
import '../../../core/helpers/tts_setup_report.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/shared/style/kid_ui.dart';

/// Settings panel for the Arabic voice.
///
/// Exists because the voice problem is not something a parent can diagnose:
/// on the device this was debugged on the system default engine
/// (`com.samsung.SMT`) had no Arabic voices at all, so Arabic came out in an
/// English accent with nothing on screen to explain why. This shows which
/// engine and voice are actually in use, whether Egyptian Arabic is installed,
/// and offers the installer and a way to hear the result.
class ArabicVoiceSection extends StatefulWidget {
  const ArabicVoiceSection({super.key});

  @override
  State<ArabicVoiceSection> createState() => _ArabicVoiceSectionState();
}

class _ArabicVoiceSectionState extends State<ArabicVoiceSection> {
  TtsSetupReport? _report;
  bool _busy = true;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool rescan = false}) async {
    setState(() => _busy = true);
    if (rescan) TtsService.invalidateVoiceCache();
    await Speech.surveyArabic();
    if (!mounted) return;
    setState(() {
      _report = Speech.report;
      _busy = false;
    });
  }

  Future<void> _install() async {
    final l10n = AppLocalizations.of(context);
    // Tell the user what to do in the system screen before sending them there;
    // Android drops you into a bare voice-data list with no context.
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.ttsInstallVoice,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.ttsInstallHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ttsOpenSettings),
          ),
        ],
      ),
    );
    if (go != true) return;

    await TtsService.openVoiceDataSettings();
    if (!mounted) return;
    // Re-detect on return: the point of sending them there was to change this.
    await _load(rescan: true);
  }

  Future<void> _test() async {
    setState(() => _speaking = true);
    final spoke = await Speech.speakSample();
    if (!mounted) return;
    setState(() => _speaking = false);
    if (!spoke) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.ttsStatusMissing)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_busy && _report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final report = _report;
    final voice = report?.selectedVoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBanner(report: report),
        const SizedBox(height: 14),
        _Row(
          label: l10n.ttsEngineLabel,
          value: report?.selectedEngine?.displayName ?? l10n.ttsNone,
        ),
        _Row(
          label: l10n.ttsVoiceLabel,
          value: voice == null
              ? l10n.ttsNone
              : '${voice.name}  (${voice.locale})',
        ),
        _Row(
          label: l10n.ttsEgyptianLabel,
          value: (report?.hasEgyptianFemale ?? false)
              ? l10n.ttsInstalledYes
              : l10n.ttsInstalledNo,
          good: report?.hasEgyptianFemale ?? false,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (Platform.isAndroid)
              _Action(
                icon: Icons.download_rounded,
                label: l10n.ttsInstallVoice,
                onTap: _install,
                filled: !(report?.hasEgyptianFemale ?? false),
              ),
            _Action(
              icon: _speaking
                  ? Icons.graphic_eq_rounded
                  : Icons.play_arrow_rounded,
              label: l10n.ttsTestVoice,
              onTap: _speaking ? null : _test,
            ),
            _Action(
              icon: Icons.refresh_rounded,
              label: l10n.ttsRefreshVoices,
              onTap: _busy ? null : () => _load(rescan: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.report});

  final TtsSetupReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quality = report?.quality ?? TtsSetupQuality.missing;

    final (String message, Color colour, IconData icon) = switch (quality) {
      TtsSetupQuality.ideal => (
          l10n.ttsStatusIdeal,
          KidUi.correct,
          Icons.check_circle_rounded
        ),
      TtsSetupQuality.cloud => (
          l10n.ttsStatusCloud,
          KidUi.primary,
          Icons.cloud_done_rounded
        ),
      TtsSetupQuality.egyptianWrongGender => (
          l10n.ttsStatusEgyptianWrongGender,
          KidUi.hint,
          Icons.info_rounded
        ),
      TtsSetupQuality.arabicNotEgyptian => (
          l10n.ttsStatusArabicNotEgyptian,
          KidUi.hint,
          Icons.info_rounded
        ),
      TtsSetupQuality.missing => (
          l10n.ttsStatusMissing,
          KidUi.wrong,
          Icons.error_rounded
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colour.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colour, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: KidUi.ink,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.good});

  final String label;
  final String value;
  final bool? good;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KidUi.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: good == null
                    ? KidUi.ink
                    : (good! ? KidUi.correct : KidUi.wrong),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = filled ? KidUi.primary : Colors.white;
    final foreground = filled ? Colors.white : KidUi.ink;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
        elevation: filled ? 3 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KidUi.radiusPill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
