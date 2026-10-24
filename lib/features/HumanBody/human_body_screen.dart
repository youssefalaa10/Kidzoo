import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'body_audio.dart';
import 'body_board.dart';
import 'body_game_cubit.dart';
import 'body_parts.dart';

/// Composition root. The game itself receives audio and localization through
/// its constructor and has no dependency on profiles, authentication or storage.
class HumanBodyScreen extends StatefulWidget {
  const HumanBodyScreen({this.audio, super.key});
  final BodyAudio? audio;
  @override
  State<HumanBodyScreen> createState() => _HumanBodyScreenState();
}

class _HumanBodyScreenState extends State<HumanBodyScreen>
    with WidgetsBindingObserver {
  BodyGameCubit? _cubit;
  MusicCubit? _music;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cubit != null) return;
    // Optional in isolated previews/tests; the app always provides MusicCubit.
    _music = context.read<MusicCubit?>();
    unawaited(_music?.requestPause());
    final AppLocalizations strings = AppLocalizations.of(context);
    _cubit = BodyGameCubit(
      audio: widget.audio ??
          SpeechBodyAudio(
            effects: AudioPlayer(),
            languageCode: Localizations.localeOf(context).languageCode,
          ),
      text: (key) => strings.resolve(key),
      soundEnabled: _music?.state.isSoundEnabled ?? true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit!.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit?.resume();
    } else {
      _cubit?.suspend();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit?.close());
    unawaited(_music?.releasePause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: _cubit!, child: const _HumanBodyGameView());
}

class _HumanBodyGameView extends StatelessWidget {
  const _HumanBodyGameView();
  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    String text(String key) => strings.resolve(key);
    final BodyGameCubit cubit = context.read<BodyGameCubit>();
    return BlocBuilder<BodyGameCubit, BodyGameState>(
        builder: (context, state) => KidGameShell(
              fallbackColor: const Color(0xFFF6F0FF),
              maxContentWidth: 1100,
              builder: (context, metrics) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Column(children: [
                  Row(children: [
                    IconButton(
                        tooltip: text('bodyBack'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: KidUi.ink),
                    Expanded(
                        child: Text(text('learnHumanBody'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: KidUi.ink))),
                    IconButton(
                        tooltip: text(
                            state.soundEnabled ? 'bodyMute' : 'bodyUnmute'),
                        onPressed: cubit.toggleSound,
                        icon: Icon(state.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded),
                        color: KidUi.primary),
                    IconButton(
                        tooltip: text('bodyRestart'),
                        onPressed: cubit.restartStage,
                        icon: const Icon(Icons.refresh_rounded),
                        color: KidUi.primary),
                  ]),
                  BodyStageProgress(state: state, text: text),
                  const SizedBox(height: 6),
                  Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                    final bool landscape =
                        constraints.maxWidth > constraints.maxHeight * 1.35;
                    final Widget board = BodyBoard(state: state, text: text);
                    final Widget controls = BodyLearningControls(
                        state: state, text: text, compact: landscape);
                    if (landscape) {
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: board),
                            const SizedBox(width: 10),
                            SizedBox(
                                width: constraints.maxWidth < 600 ? 164 : 220,
                                child: Column(children: [
                                  controls,
                                  const SizedBox(height: 6),
                                  if (!state.stageComplete)
                                    Expanded(
                                        child: BodyPartTray(
                                            state: state,
                                            text: text,
                                            vertical: true)),
                                ])),
                          ]);
                    }
                    return Column(children: [
                      controls,
                      const SizedBox(height: 6),
                      Expanded(child: board),
                      if (!state.stageComplete) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                            height: constraints.maxHeight < 480 ? 124 : 148,
                            child: BodyPartTray(state: state, text: text)),
                      ],
                    ]);
                  })),
                ]),
              ),
            ));
  }
}

class BodyStageProgress extends StatelessWidget {
  const BodyStageProgress({required this.state, required this.text, super.key});
  final BodyGameState state;
  final BodyText text;
  @override
  Widget build(BuildContext context) => Semantics(
        label:
            '${text('bodyStage${state.stage + 1}')} ${state.placed.length} / 18',
        child: Row(children: [
          for (int i = 0; i < 3; i++) ...[
            Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.stage >= i
                        ? KidUi.primary
                        : const Color(0xFFE1D7F0)),
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: state.stage >= i ? Colors.white : KidUi.inkSoft,
                        fontWeight: FontWeight.w900))),
            if (i < 2)
              Container(width: 8, height: 3, color: const Color(0xFFE1D7F0)),
          ],
          const SizedBox(width: 10),
          Expanded(
              child: Text(text('bodyStage${state.stage + 1}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: KidUi.ink, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          SizedBox(
              width: 52,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: state.placed.length / const BodyParts().all.length,
                      minHeight: 8,
                      color: KidUi.correct,
                      backgroundColor: Colors.white))),
          const SizedBox(width: 6),
          Text('${state.placed.length}/18',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: KidUi.ink)),
        ]),
      );
}

class BodyLearningControls extends StatelessWidget {
  const BodyLearningControls(
      {required this.state,
      required this.text,
      required this.compact,
      super.key});
  final BodyGameState state;
  final BodyText text;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final BodyGameCubit cubit = context.read<BodyGameCubit>();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (state.stageComplete) ...[
        Text(
            text(state.complete
                ? 'bodyFinishedTitle'
                : 'bodyStageFinishedTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: KidUi.primary)),
        const SizedBox(height: 4),
        FilledButton.icon(
            key: const ValueKey('body-continue'),
            style: FilledButton.styleFrom(
                backgroundColor: KidUi.primary,
                minimumSize: const Size(140, 48)),
            onPressed: state.complete ? cubit.replay : cubit.nextStage,
            icon: Icon(state.complete
                ? Icons.replay_rounded
                : Icons.arrow_forward_rounded),
            label: Text(text(state.complete ? 'bodyReplay' : 'bodyNext'))),
      ] else
        BodyPromptCard(state: state, text: text, compact: compact),
      if (state.audioUnavailable && state.soundEnabled)
        Text(text('bodyVoiceUnavailable'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: KidUi.inkSoft)),
    ]);
  }
}

class BodyPromptCard extends StatelessWidget {
  const BodyPromptCard(
      {required this.state,
      required this.text,
      required this.compact,
      super.key});
  final BodyGameState state;
  final BodyText text;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final BodyGameCubit cubit = context.read<BodyGameCubit>();
    final Widget message = Semantics(
        liveRegion: true,
        child: Text(state.message.isEmpty ? text('bodyWelcome') : state.message,
            maxLines: compact ? 4 : 3,
            overflow: TextOverflow.ellipsis,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: KidUi.ink)));
    final Widget listen = IconButton(
        tooltip: text('bodyListen'),
        onPressed: cubit.repeat,
        icon: const Icon(Icons.hearing_rounded),
        color: KidUi.primary);
    final Widget hint = IconButton(
        tooltip: text('bodyShowHint'),
        onPressed: cubit.hint,
        icon: const Icon(Icons.lightbulb_rounded),
        color: const Color(0xFFB47D00));
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 8 : 3),
      child: compact
          ? Column(children: [
              message,
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [listen, hint])
            ])
          : Row(children: [listen, Expanded(child: message), hint]),
    );
  }
}
