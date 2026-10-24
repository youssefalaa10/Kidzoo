import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'arabic_tracing_data.dart';
import 'english_tracing_data.dart';
import 'tracing_letter.dart';

class TracingState {
  const TracingState(
      {this.language = TracingLanguage.arabic,
      this.lowercase = false,
      this.index = 0,
      this.form = LetterForm.isolated,
      this.stroke = 0,
      this.sample = 0,
      this.complete = false,
      this.misses = 0,
      this.completed = const {},
      this.needsLift = false});
  final TracingLanguage language;
  final bool lowercase;
  final int index;
  final LetterForm form;
  final int stroke;
  final int sample;
  final bool complete;
  final int misses;
  final Set<String> completed;
  final bool needsLift;
  String get key => '${language.name}:$lowercase:$index:${form.name}';
}

/// Sequential coverage prevents scribbles, taps on the end, backward tracing
/// and teleporting between disconnected sections from completing a letter.
/// A wide corridor and resumable checkpoints make pen lifts forgiving.
class TracingCubit extends Cubit<TracingState> {
  TracingCubit({TracingLanguage language = TracingLanguage.arabic})
      : super(TracingState(language: language)) {
    _load(state);
  }
  late List<TracingLetter> letters;
  late List<TraceStroke> strokes;
  Offset? _previous;
  bool _drawing = false;
  int? _pointer;
  double get progress => state.complete
      ? 1
      : (state.stroke +
              state.sample / (strokes[state.stroke].samples.length - 1)) /
          strokes.length;

  void _load(TracingState selected) {
    letters = selected.language == TracingLanguage.arabic
        ? arabicTracingLetters()
        : englishTracingLetters(lowercase: selected.lowercase);
    strokes = letters[selected.index].paths(selected.form);
    _drawing = false;
    _previous = null;
    _pointer = null;
  }

  void select(
      {TracingLanguage? language,
      bool? lowercase,
      int? index,
      LetterForm? form}) {
    final targetLanguage = language ?? state.language;
    final targetLowercase = targetLanguage == TracingLanguage.english &&
        (lowercase ?? state.lowercase);
    final targetLetters = targetLanguage == TracingLanguage.arabic
        ? arabicTracingLetters()
        : englishTracingLetters(lowercase: targetLowercase);
    final targetIndex = (index ?? 0).clamp(0, targetLetters.length - 1);
    final requestedForm = form ??
        (targetLanguage == state.language ? state.form : LetterForm.isolated);
    final target = TracingState(
        language: targetLanguage,
        lowercase: targetLowercase,
        index: targetIndex,
        form: targetLetters[targetIndex].forms.containsKey(requestedForm)
            ? requestedForm
            : LetterForm.isolated,
        completed: state.completed);
    _load(target);
    emit(target);
  }

  TracingState _copy(
          {int? stroke,
          int? sample,
          bool? complete,
          int? misses,
          bool? needsLift,
          Set<String>? completed}) =>
      TracingState(
          language: state.language,
          lowercase: state.lowercase,
          index: state.index,
          form: state.form,
          stroke: stroke ?? state.stroke,
          sample: sample ?? state.sample,
          complete: complete ?? state.complete,
          misses: misses ?? state.misses,
          completed: completed ?? state.completed,
          needsLift: needsLift ?? state.needsLift);

  void restart() => select(index: state.index, form: state.form);

  void suspend() {
    _pointer = null;
    _drawing = false;
    _previous = null;
    emit(_copy(needsLift: false));
  }

  void down(Offset position, int pointer) {
    if (state.complete || _pointer != null) return;
    _pointer = pointer;
    final stroke = strokes[state.stroke];
    if ((position - stroke.samples[state.sample]).distance > 23) {
      emit(_copy(misses: state.misses + 1));
      return;
    }
    _drawing = true;
    _previous = position;
    if (stroke.length <= 8) {
      emit(_copy(sample: stroke.samples.length - 1, needsLift: true));
    }
  }

  void move(Offset position, int pointer) {
    if (!_drawing || _pointer != pointer || state.complete || state.needsLift) {
      return;
    }
    final previous = _previous!;
    _previous = position;
    // Resample fast pointer movement; every intermediate point must follow
    // the corridor. There is no frame-rate-dependent distance threshold.
    final count = ((position - previous).distance / 3).ceil().clamp(1, 300);
    final samples = strokes[state.stroke].samples;
    var current = state.sample;
    var missed = false;
    for (var n = 1; n <= count; n++) {
      final point = Offset.lerp(previous, position, n / count)!;
      if ((point - samples[current]).distance > 28) {
        missed = true;
        break;
      }
      var best = current;
      var distance = (point - samples[current]).distance;
      for (var j = current + 1; j < samples.length && j <= current + 7; j++) {
        final candidate = (point - samples[j]).distance;
        if (candidate < distance) {
          best = j;
          distance = candidate;
        }
      }
      current = best;
    }
    final done = current >= samples.length - 3 &&
        (position - samples.last).distance < 23;
    emit(_copy(
        sample: done ? samples.length - 1 : current,
        needsLift: done,
        misses: state.misses + (missed ? 1 : 0)));
    if (missed) {
      _drawing = false;
      _previous = null;
    }
  }

  void up(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    _drawing = false;
    _previous = null;
    if (!state.needsLift) return;
    if (state.stroke == strokes.length - 1) {
      emit(_copy(
          complete: true,
          needsLift: false,
          completed: {...state.completed, state.key}));
    } else {
      emit(_copy(stroke: state.stroke + 1, sample: 0, needsLift: false));
    }
  }

  void cancel(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    _drawing = false;
    _previous = null;
    // A platform cancellation must never award completion.
    emit(_copy(needsLift: false));
  }
}
