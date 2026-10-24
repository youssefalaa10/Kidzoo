import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'tracing_audio.dart';
import 'tracing_board.dart';
import 'tracing_cubit.dart';
import 'tracing_letter.dart';

class LetterTracingScreen extends StatefulWidget {
  const LetterTracingScreen({super.key, this.audio, this.initialLanguage});
  final TracingAudio? audio;
  final TracingLanguage? initialLanguage;
  @override
  State<LetterTracingScreen> createState() => _LetterTracingScreenState();
}

class _LetterTracingScreenState extends State<LetterTracingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TracingCubit? _cubit;
  late TracingAudio _audio;
  MusicCubit? _music;
  late final AnimationController _demo;
  Timer? _advance;
  final _lettersScroll = ScrollController();
  bool _muted = false;
  bool _voiceUnavailable = false;
  bool _begun = false;
  bool _foreground = true;
  DateTime? _lastHint;
  int _audioRevision = 0;
  String get _prefix =>
      _cubit!.state.language == TracingLanguage.arabic ? 'ar' : 'en';
  String text(String key) => AppLocalizations.of(context).resolve(key);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _demo = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2300));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cubit != null) return;
    _music = context.read<MusicCubit?>();
    unawaited(_music?.requestPause());
    _audio = widget.audio ??
        TtsTracingAudio(
            appLanguageCode: Localizations.localeOf(context).languageCode,
            enabled: () =>
                !_muted &&
                _foreground &&
                (_music?.state.isSoundEnabled ?? true));
    _cubit = TracingCubit(
        language: widget.initialLanguage ??
            (Localizations.localeOf(context).languageCode == 'ar'
                ? TracingLanguage.arabic
                : TracingLanguage.english));
    scheduleMicrotask(() {
      if (mounted) _name();
    });
  }

  Future<void> _say(String clip, {bool success = false}) async {
    final revision = ++_audioRevision;
    if (!_foreground || _muted || !(_music?.state.isSoundEnabled ?? true)) {
      return;
    }
    final available = await _audio.play(clip, success: success);
    if (mounted &&
        revision == _audioRevision &&
        _voiceUnavailable == available) {
      setState(() => _voiceUnavailable = !available);
    }
  }

  void _name() => unawaited(_say('${_prefix}_${_cubit!.state.index}'));
  void _select(
      {TracingLanguage? language,
      bool? lowercase,
      int? index,
      LetterForm? form}) {
    _advance?.cancel();
    _demo.stop();
    _demo.reset();
    _begun = false;
    _lastHint = null;
    _cubit!.select(
        language: language, lowercase: lowercase, index: index, form: form);
    _name();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lettersScroll.hasClients) return;
      unawaited(_lettersScroll.animateTo(
          (_cubit!.state.index * 57.0 - 57)
              .clamp(0.0, _lettersScroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut));
    });
  }

  void _next() {
    final cubit = _cubit!;
    _select(index: (cubit.state.index + 1) % cubit.letters.length);
  }

  void _begin() {
    if (_begun || _cubit!.state.complete) return;
    _begun = true;
    unawaited(_say('${_prefix}_begin'));
  }

  void _demonstrate() {
    _cubit!.suspend();
    _lastHint = DateTime.now();
    _demo.forward(from: 0);
    unawaited(_say('${_prefix}_hint'));
  }

  void _listen(BuildContext context, TracingState state) {
    if (state.complete) {
      _demo.stop();
      _demo.reset();
      unawaited(_say('${_prefix}_success', success: true));
      if (state.index < _cubit!.letters.length - 1) {
        _advance?.cancel();
        _advance = Timer(const Duration(seconds: 6), () {
          if (mounted && _foreground) _next();
        });
      }
    } else if (state.misses > 0 &&
        state.misses % 3 == 0 &&
        (_lastHint == null ||
            DateTime.now().difference(_lastHint!).inSeconds > 8)) {
      _demonstrate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _audioRevision++;
      _advance?.cancel();
      _demo.stop();
      _demo.reset();
      _cubit?.suspend();
      unawaited(_audio.stop());
    } else {
      _name();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _advance?.cancel();
    _demo.dispose();
    _lettersScroll.dispose();
    unawaited(_audio.dispose());
    unawaited(_cubit?.close());
    unawaited(_music?.releasePause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit!;
    return BlocConsumer<TracingCubit, TracingState>(
        bloc: cubit,
        listenWhen: (previous, current) =>
            (!previous.complete && current.complete) ||
            previous.misses != current.misses,
        listener: _listen,
        builder: (context, state) {
          final letter = cubit.letters[state.index];
          final arabic = state.language == TracingLanguage.arabic;
          final formKeys = [LetterForm.isolated, ...letter.forms.keys];
          final formLabels = {
            LetterForm.isolated: text('tracingIsolated'),
            LetterForm.initial: text('tracingInitial'),
            LetterForm.medial: text('tracingMedial'),
            LetterForm.finalForm: text('tracingFinal'),
          };
          final formSymbol = switch (state.form) {
            LetterForm.isolated => letter.symbol,
            LetterForm.initial => '${letter.symbol}ـ',
            LetterForm.medial => 'ـ${letter.symbol}ـ',
            LetterForm.finalForm => 'ـ${letter.symbol}',
          };
          return KidGameShell(
              fallbackColor: const Color(0xfffa6079),
              maxContentWidth: 1100,
              builder: (context, metrics) =>
                  LayoutBuilder(builder: (context, box) {
                    final compact = box.maxHeight < 500;
                    final board = Container(
                      key: const ValueKey('tracing-card'),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x18213c59),
                                blurRadius: 12,
                                offset: Offset(0, 6))
                          ]),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(children: [
                        PositionedDirectional(
                            top: 10,
                            start: 14,
                            child: Text(formSymbol,
                                style: TextStyle(
                                    fontSize: compact ? 30 : 38,
                                    fontFamily: arabic ? 'TracingNaskh' : null,
                                    color: const Color(0xff147d94),
                                    fontWeight: FontWeight.bold))),
                        Positioned.fill(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 36, 14, 12),
                                child: AnimatedBuilder(
                                    animation: _demo,
                                    builder: (context, child) => TracingBoard(
                                        cubit: cubit,
                                        state: state,
                                        onBegin: _begin,
                                        label:
                                            '${text('letterTracing')} ${letter.symbol}. ${text('tracingInstruction')}',
                                        demonstration: _demo.isAnimating
                                            ? _demo.value
                                            : null)))),
                        if (state.complete)
                          PositionedDirectional(
                              top: 10,
                              end: 12,
                              child: Semantics(
                                  liveRegion: true,
                                  child: Chip(
                                      avatar: const Icon(Icons.stars_rounded,
                                          color: Color(0xffe8a000)),
                                      label: Text(text('tracingWellDone')),
                                      backgroundColor:
                                          const Color(0xfffff0b0)))),
                      ]),
                    );
                    final controls = TracingControls(
                        completed: state.complete,
                        onErase: () =>
                            _select(index: state.index, form: state.form),
                        onDemo: _demonstrate,
                        onNext: state.complete ? _next : null,
                        erase: text('tracingErase'),
                        demo: text('tracingShow'),
                        next: text('tracingNext'));
                    final options = SizedBox(
                        height: 42,
                        child: arabic
                            ? TracingChoiceBar<LetterForm>(
                                values: formKeys,
                                labels: formKeys
                                    .map((f) => formLabels[f]!)
                                    .toList(),
                                selected: state.form,
                                onSelected: (form) =>
                                    _select(index: state.index, form: form))
                            : TracingChoiceBar<bool>(
                                values: const [
                                    false,
                                    true
                                  ],
                                labels: [
                                    text('tracingUppercase'),
                                    text('tracingLowercase')
                                  ],
                                selected: state.lowercase,
                                onSelected: (value) => _select(
                                    lowercase: value, index: state.index)));
                    final alphabet = SizedBox(
                        height: 54,
                        child: Directionality(
                            textDirection:
                                arabic ? TextDirection.rtl : TextDirection.ltr,
                            child: ListView.separated(
                                controller: _lettersScroll,
                                scrollDirection: Axis.horizontal,
                                itemCount: cubit.letters.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 7),
                                itemBuilder: (context, index) {
                                  final key =
                                      '${state.language.name}:${state.lowercase}:$index:${state.form.name}';
                                  return Semantics(
                                      selected: index == state.index,
                                      label: cubit.letters[index].name,
                                      child: SizedBox(
                                          width: 50,
                                          child: Material(
                                              color: index == state.index
                                                  ? const Color(0xffffd34d)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  onTap: () =>
                                                      _select(index: index),
                                                  child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Text(
                                                            cubit.letters[index]
                                                                .symbol,
                                                            style: TextStyle(
                                                                fontSize: 27,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontFamily: arabic
                                                                    ? 'TracingNaskh'
                                                                    : null,
                                                                color: const Color(
                                                                    0xff147d94))),
                                                        if (state.completed
                                                            .contains(key))
                                                          const Positioned(
                                                              right: 1,
                                                              top: 1,
                                                              child: Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  size: 14,
                                                                  color: Color(
                                                                      0xff147d94))),
                                                      ])))));
                                })));
                    return Padding(
                        padding: EdgeInsets.all(compact ? 8 : 14),
                        child: Column(children: [
                          SizedBox(
                              height: 48,
                              child: Row(children: [
                                TracingIconButton(
                                    icon: Icons.arrow_back_rounded,
                                    label: text('back'),
                                    onPressed: () =>
                                        Navigator.of(context).maybePop()),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      Text(text('letterTracing'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 5),
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                              value: cubit.progress,
                                              minHeight: 7,
                                              color: const Color(0xffffd34d),
                                              backgroundColor: Colors.white30)),
                                    ])),
                                const SizedBox(width: 8),
                                TracingIconButton(
                                    icon: _muted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    label: text(_muted
                                        ? 'tracingUnmute'
                                        : 'tracingMute'),
                                    onPressed: () {
                                      setState(() => _muted = !_muted);
                                      if (_muted) {
                                        _audioRevision++;
                                        unawaited(_audio.stop());
                                      } else {
                                        _name();
                                      }
                                    }),
                                TracingIconButton(
                                    icon: Icons.replay_rounded,
                                    label: text('tracingListen'),
                                    onPressed: _name),
                              ])),
                          const SizedBox(height: 6),
                          SizedBox(
                              height: 44,
                              child: Row(children: [
                                Expanded(
                                    child: TracingChoiceBar<TracingLanguage>(
                                        values: TracingLanguage.values,
                                        labels: [
                                          text('tracingArabic'),
                                          text('tracingEnglish')
                                        ],
                                        selected: state.language,
                                        onSelected: (value) =>
                                            _select(language: value))),
                                const SizedBox(width: 8),
                                Text(
                                    '${state.index + 1} / ${cubit.letters.length}',
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ])),
                          const SizedBox(height: 4),
                          if (!compact) options,
                          const SizedBox(height: 6),
                          Expanded(
                              child: compact
                                  ? Row(children: [
                                      Expanded(child: board),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                          width: 176,
                                          child: SingleChildScrollView(
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                options,
                                                const SizedBox(height: 8),
                                                Text(
                                                    text(state.complete
                                                        ? 'tracingWellDone'
                                                        : 'tracingInstruction'),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                controls,
                                                const SizedBox(height: 8),
                                                alphabet,
                                              ]))),
                                    ])
                                  : board),
                          if (!compact) ...[
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                        text(_voiceUnavailable
                                            ? 'tracingAudioUnavailable'
                                            : state.complete
                                                ? 'tracingWellDone'
                                                : state.needsLift
                                                    ? 'tracingLift'
                                                    : 'tracingInstruction'),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700)))),
                            controls,
                          ],
                          const SizedBox(height: 6),
                          if (!compact) alphabet,
                        ]));
                  }));
        });
  }
}

class TracingIconButton extends StatelessWidget {
  const TracingIconButton(
      {required this.icon,
      required this.label,
      required this.onPressed,
      super.key});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff147d94),
          minimumSize: const Size(44, 44)),
      icon: Icon(icon));
}

class TracingChoiceBar<T> extends StatelessWidget {
  const TracingChoiceBar(
      {required this.values,
      required this.labels,
      required this.selected,
      required this.onSelected,
      super.key});
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => Row(
      children: List.generate(
          values.length,
          (i) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                      selected: values[i] == selected,
                      child: TextButton(
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              backgroundColor: selected == values[i]
                                  ? const Color(0xffffd34d)
                                  : Colors.white,
                              foregroundColor: const Color(0xff17576b),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: () => onSelected(values[i]),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(labels[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)))))))));
}

class TracingControls extends StatelessWidget {
  const TracingControls(
      {required this.completed,
      required this.onErase,
      required this.onDemo,
      required this.onNext,
      required this.erase,
      required this.demo,
      required this.next,
      super.key});
  final bool completed;
  final VoidCallback onErase;
  final VoidCallback onDemo;
  final VoidCallback? onNext;
  final String erase, demo, next;
  @override
  Widget build(BuildContext context) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            FilledButton.icon(
                onPressed: onErase,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(erase),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff147d94),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12))),
            FilledButton.icon(
                onPressed: completed ? onNext : onDemo,
                icon: Icon(completed
                    ? Icons.arrow_forward_rounded
                    : Icons.gesture_rounded),
                label: Text(completed ? next : demo),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: const Color(0xffffd34d),
                    foregroundColor: const Color(0xff17576b))),
          ]);
}
