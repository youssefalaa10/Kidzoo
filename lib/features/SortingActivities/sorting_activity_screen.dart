import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/core/shared/widgets/kid_result_view.dart';
import 'sorting_activity_audio.dart';
import 'sorting_activity_content.dart';
import 'sorting_activity_cubit.dart';
import 'sorting_worksheet_board.dart';

class ToothFoodSortingScreen extends StatelessWidget {
  const ToothFoodSortingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SortingActivityScreen(kind: SortingActivityKind.teeth);
}

class WeatherSortingScreen extends StatelessWidget {
  const WeatherSortingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SortingActivityScreen(kind: SortingActivityKind.weather);
}

class LaundrySortingScreen extends StatelessWidget {
  const LaundrySortingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SortingActivityScreen(kind: SortingActivityKind.laundry);
}

/// Route-scoped composition. No combined game or intervening activity menu.
class SortingActivityScreen extends StatefulWidget {
  const SortingActivityScreen(
      {required this.kind, this.content, this.audio, super.key});
  final SortingActivityKind kind;
  final SortingActivityContent? content;
  final SortingActivityAudio? audio;
  @override
  State<SortingActivityScreen> createState() => _SortingActivityScreenState();
}

class _SortingActivityScreenState extends State<SortingActivityScreen>
    with WidgetsBindingObserver {
  SortingActivityCubit? _cubit;
  MusicCubit? _music;
  bool _loading = false;
  bool _attemptedLoad = false;
  String? _error;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attemptedLoad) return;
    _attemptedLoad = true;
    _music = context.read<MusicCubit?>();
    unawaited(_music?.requestPause());
    unawaited(_load());
  }

  Future<void> _load() async {
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content =
          widget.content ?? await SortingActivityContent.load(widget.kind);
      if (!mounted) return;
      final cubit = SortingActivityCubit(
          content: content,
          languageCode: language,
          soundEnabled: _music?.state.isSoundEnabled ?? true,
          audio: widget.audio ??
              SpeechSortingActivityAudio(
                  effects: AudioPlayer(),
                  isEnabled: () => _music?.state.isSoundEnabled ?? true));
      _cubit = cubit;
      // Decode before displaying draggable pieces; all filenames are validated
      // from disk too. A missing device decoder surfaces a retryable load error.
      for (final image in content.images) {
        if (!mounted) return;
        Object? imageError;
        await precacheImage(AssetImage(image), context,
            onError: (error, stack) => imageError = error);
        if (imageError != null) {
          throw StateError('Could not load $image: $imageError');
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (_lifecycle == AppLifecycleState.resumed) {
        cubit.start();
      } else {
        cubit.suspend();
      }
    } catch (error) {
      debugPrint('Sorting activity load: $error');
      final cubit = _cubit;
      _cubit = null;
      await cubit?.close();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      if (!_loading) _cubit?.resume();
    } else {
      _cubit?.suspend();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final cubit = _cubit;
    _cubit = null;
    unawaited(cubit?.close());
    unawaited(_music?.releasePause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = _cubit;
    if (_loading || cubit == null) {
      return KidGameShell(
          fallbackColor: Colors.white,
          builder: (context, metrics) => Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l10n.resolve('sortingLoadError'),
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: _load,
                          child: Text(l10n.resolve('sortingRetry'))),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.resolve('sortingBack'))),
                    ])));
    }
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) cubit.suspend();
      },
      child: BlocBuilder<SortingActivityCubit, SortingActivityState>(
        bloc: cubit,
        builder: (context, state) => KidGameShell(
            fallbackColor: Colors.white,
            maxContentWidth: 1100,
            builder: (context, metrics) => state.celebrating
                ? ColoredBox(
                    color: KidUi.primary,
                    child: KidResultView(
                        key: ValueKey(widget.kind),
                        metrics: metrics,
                        score: 10,
                        maxScore: 10,
                        title:
                            cubit.content.complete.resolve(cubit.languageCode),
                        onPlayAgain: cubit.replay,
                        onExit: () => Navigator.of(context).pop()))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(children: [
                      SizedBox(
                          height: 52,
                          child: Row(children: [
                            IconButton(
                                tooltip: l10n.resolve('sortingBack'),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: KidUi.ink)),
                            Expanded(
                                child: Text(l10n.resolve(widget.kind.titleKey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: KidUi.ink))),
                            Semantics(
                                liveRegion: true,
                                child: Text('${state.placed.length} / 10',
                                    textDirection: TextDirection.ltr,
                                    key: const ValueKey('sorting-progress'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: KidUi.ink))),
                            IconButton(
                                tooltip: l10n.resolve(state.soundEnabled
                                    ? 'sortingMute'
                                    : 'sortingUnmute'),
                                onPressed: cubit.toggleSound,
                                icon: Icon(
                                    state.soundEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: KidUi.primary)),
                          ])),
                      SizedBox(
                          height: 40,
                          child: Row(children: [
                            IconButton(
                                tooltip: l10n.resolve('sortingListen'),
                                onPressed: cubit.repeat,
                                icon: const Icon(
                                    Icons.record_voice_over_rounded,
                                    size: 21,
                                    color: KidUi.primary)),
                            Expanded(
                                child: Text(state.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13, color: KidUi.inkSoft))),
                            if (state.audioUnavailable)
                              Tooltip(
                                  message:
                                      l10n.resolve('sortingVoiceUnavailable'),
                                  child: const Icon(
                                      Icons.closed_caption_outlined,
                                      size: 20)),
                          ])),
                      Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                        // Keep the source's vertical composition even in landscape.
                        // Scroll rather than squeezing ten touch targets to tiny dots.
                        final width = math.min(
                            constraints.maxWidth,
                            math.max(
                                340.0,
                                math.min(
                                    740.0, constraints.maxHeight * 700 / 970)));
                        return SingleChildScrollView(
                            key: const ValueKey('sorting-scroll'),
                            child: Center(
                                child: SizedBox(
                                    width: width,
                                    child: SortingWorksheetBoard(
                                        content: cubit.content,
                                        state: state,
                                        languageCode: cubit.languageCode,
                                        onSelect: cubit.select,
                                        onPlace: cubit.place,
                                        onInspect: cubit.inspect))));
                      })),
                    ]),
                  )),
      ),
    );
  }
}
