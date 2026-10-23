import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/host/activity_host_screen.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

class LittleHelpersScreen extends StatefulWidget {
  const LittleHelpersScreen({super.key});
  @override
  State<LittleHelpersScreen> createState() => _LittleHelpersScreenState();
}

class _LittleHelpersScreenState extends State<LittleHelpersScreen> {
  bool _opening = false;
  String? _error;

  Future<void> _open(String id, String title) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    final music = context.read<MusicCubit>();
    final language = Localizations.localeOf(context).languageCode;
    await music.requestPause();
    try {
      final spec = ActivitySpec.fromJson(jsonDecode(await rootBundle
              .loadString('assets/adventures/activities/helpers_$id.json'))
          as Map<String, dynamic>);
      final pack = ItemPack.fromJson(jsonDecode(await rootBundle.loadString(
          'assets/adventures/packs/helpers_$id.json')) as Map<String, dynamic>);
      bool replay;
      do {
        replay = false;
        if (!mounted) break;
        final narrator = SpeechActivityNarrator();
        final sounds =
            _HelperSounds(id, isEnabled: () => music.state.isSoundEnabled);
        try {
          const engine = SortingEngine();
          final session = engine.createSession(
              spec: spec,
              services: ActivityServices(
                  narrator: narrator,
                  soundboard: sounds,
                  random: Random(),
                  languageCode: language),
              packs: MapItemPackResolver({pack.packId: pack}));
          replay = await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (routeContext) => ActivityHostScreen(
                    engine: engine,
                    session: session,
                    title: title,
                    onReplay: () => Navigator.of(routeContext).pop(true)),
              )) ??
              false;
        } finally {
          await narrator.cancel();
          await sounds.dispose();
        }
      } while (replay && mounted);
    } catch (error) {
      debugPrint('Little Helpers could not open: $error');
      if (mounted) {
        setState(() => _error = language == 'ar'
            ? 'جرب تفتح اللعبة تاني.'
            : 'Please try opening the game again.');
      }
    } finally {
      await music.releasePause();
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final activities = [
      ('teeth', ar ? 'أسنان سعيدة' : 'Happy teeth', 'tooth'),
      ('weather', ar ? 'أصحاب الطقس' : 'Weather helpers', 'sun'),
      ('laundry', ar ? 'أصحاب الغسيل' : 'Laundry helpers', 'washer'),
    ];
    return KidGameShell(
        builder: (context, metrics) => ListView(
              padding: EdgeInsets.all(metrics.pagePadding),
              children: [
                Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton.filledTonal(
                        iconSize: 32,
                        tooltip: ar ? 'رجوع' : 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded))),
                const SizedBox(height: 16),
                Text(ar ? 'المساعد الصغير' : 'Little Helpers',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: KidUi.primary)),
                const SizedBox(height: 12),
                Text(
                    ar
                        ? 'اختار صورة ويلا نرتب!'
                        : 'Pick a picture. Let’s sort!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20)),
                if (_opening) const LinearProgressIndicator(),
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
                for (final activity in activities)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _opening
                            ? null
                            : () => _open(activity.$1, activity.$2),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Image.asset(
                                  'assets/gen/images/helpers/${activity.$3}.png',
                                  width: 92,
                                  height: 100),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Text(activity.$2,
                                      style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold))),
                              const Icon(Icons.play_circle_fill_rounded,
                                  color: KidUi.primary, size: 40),
                            ])),
                      ),
                    ),
                  ),
              ],
            ));
  }
}

/// One player prevents rapid repeated actions from stacking effects.
class _HelperSounds extends AudioActivitySoundboard {
  _HelperSounds(this.theme, {super.isEnabled});
  final String theme;
  @override
  Future<void> play(ActivitySound sound) => sound == ActivitySound.success
      ? playAsset('audio/helpers_$theme.wav')
      : super.play(sound);
}
