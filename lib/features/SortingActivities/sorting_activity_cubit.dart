import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'sorting_activity_audio.dart';
import 'sorting_activity_content.dart';

class SortingActivityState {
  SortingActivityState(
      {Map<String, String> placed = const {},
      this.selected,
      this.rejected,
      this.lastPlaced,
      this.revision = 0,
      this.message = '',
      this.soundEnabled = true,
      this.audioUnavailable = false,
      this.celebrating = false})
      : placed = Map.unmodifiable(placed);
  final Map<String, String> placed;
  final String? selected;
  final String? rejected;
  final String? lastPlaced;
  final int revision;
  final String message;
  final bool soundEnabled;
  final bool audioUnavailable;
  final bool celebrating;
  bool get complete => placed.length == 10;

  SortingActivityState copyWith(
          {Map<String, String>? placed,
          String? selected,
          String? rejected,
          String? lastPlaced,
          String? message,
          bool? soundEnabled,
          bool? audioUnavailable,
          bool? celebrating}) =>
      SortingActivityState(
          placed: placed ?? this.placed,
          selected: selected,
          rejected: rejected,
          lastPlaced: lastPlaced,
          revision: revision + 1,
          message: message ?? this.message,
          soundEnabled: soundEnabled ?? this.soundEnabled,
          audioUnavailable: audioUnavailable ?? this.audioUnavailable,
          celebrating: celebrating ?? this.celebrating);
}

class SortingActivityCubit extends Cubit<SortingActivityState> {
  SortingActivityCubit(
      {required this.content,
      required this.languageCode,
      required SortingActivityAudio audio,
      bool soundEnabled = true})
      : _audio = audio,
        super(SortingActivityState(soundEnabled: soundEnabled));
  final SortingActivityContent content;
  final String languageCode;
  final SortingActivityAudio _audio;
  Timer? _celebration;
  bool _suspended = false;
  int _voiceRevision = 0;
  bool _hasStarted = false;

  PackItem? _available(String id) {
    if (_suspended ||
        isClosed ||
        state.complete ||
        state.placed.containsKey(id)) {
      return null;
    }
    for (final item in content.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void start() {
    _hasStarted = true;
    emit(state.copyWith(message: content.prompt.resolve(languageCode)));
    unawaited(_announce(content.intro.resolve(languageCode)));
  }

  void select(String id) {
    final item = _available(id);
    if (item == null) return;
    emit(state.copyWith(
        selected: id, message: item.label.resolve(languageCode)));
    unawaited(_announce(state.message, effect: content.effect('pick')));
  }

  /// A freely chosen item and destination, never an implicit "current item".
  bool place(String id, String destination) {
    final item = _available(id);
    if (item == null || !content.destinations.any((b) => b.id == destination)) {
      return false;
    }
    if (item.attribute('destination') != destination) {
      emit(state.copyWith(
          rejected: id, message: content.retry.resolve(languageCode)));
      unawaited(_announce(state.message, effect: content.effect('retry')));
      return false;
    }
    final index = content.destinations.indexWhere((b) => b.id == destination);
    emit(state.copyWith(
        placed: {...state.placed, id: destination},
        lastPlaced: id,
        message: content.destinations[index].feedback.resolve(languageCode)));
    unawaited(_announce(state.message,
        effect: content.effect(index == 0 ? 'left' : 'right')));
    if (state.complete) {
      // Let the last picture snap into its box before showing the celebration.
      _celebration = Timer(const Duration(milliseconds: 650), _finish);
    }
    return true;
  }

  void _finish() {
    if (isClosed || !state.complete || _suspended) return;
    emit(state.copyWith(
        celebrating: true, message: content.complete.resolve(languageCode)));
    unawaited(_announce(state.message, effect: content.effect('complete')));
  }

  void inspect(int index) {
    if (_suspended || state.complete) return;
    final selected = state.selected;
    if (selected != null) {
      place(selected, content.destinations[index].id);
      return;
    }
    final label = content.destinations[index].label.resolve(languageCode);
    emit(state.copyWith(message: label));
    unawaited(_announce(label));
  }

  void repeat() => unawaited(_announce(content.intro.resolve(languageCode)));

  void replay() {
    _celebration?.cancel();
    _voiceRevision++;
    emit(SortingActivityState(
        soundEnabled: state.soundEnabled, revision: state.revision + 1));
    start();
  }

  void toggleSound() {
    emit(state.copyWith(
        selected: state.selected, soundEnabled: !state.soundEnabled));
    _voiceRevision++;
    if (state.soundEnabled) {
      repeat();
    } else {
      unawaited(_audio.stop());
    }
  }

  void suspend() {
    _suspended = true;
    _voiceRevision++;
    _celebration?.cancel();
    unawaited(_audio.stop());
  }

  void resume() {
    _suspended = false;
    if (!_hasStarted) start();
    if (state.complete && !state.celebrating) _finish();
  }

  Future<void> _announce(String text, {String? effect}) async {
    final revision = ++_voiceRevision;
    if (!state.soundEnabled || _suspended || isClosed) return;
    bool available = false;
    try {
      available = await _audio.say(text, effect: effect);
    } catch (_) {/* Captions remain usable. */}
    if (isClosed || _suspended || revision != _voiceRevision) return;
    emit(state.copyWith(
        selected: state.selected,
        rejected: state.rejected,
        lastPlaced: state.lastPlaced,
        audioUnavailable: !available));
  }

  @override
  Future<void> close() async {
    _voiceRevision++;
    _celebration?.cancel();
    await super.close();
    await _audio.dispose();
  }
}
