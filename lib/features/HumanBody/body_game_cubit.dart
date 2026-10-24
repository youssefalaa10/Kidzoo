import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'body_audio.dart';
import 'body_parts.dart';

typedef BodyText = String Function(String key);

class BodyGameState {
  BodyGameState(
      {this.stage = 0,
      Set<BodyPartId> placed = const {},
      this.selected,
      this.lastPlaced,
      this.message = '',
      this.soundEnabled = true,
      this.audioUnavailable = false,
      this.revision = 0,
      this.hintVisible = false})
      : placed = Set.unmodifiable(placed);
  final int stage;
  final Set<BodyPartId> placed;
  final BodyPartId? selected;
  final BodyPartId? lastPlaced;
  final String message;
  final bool soundEnabled;
  final bool audioUnavailable;
  final int revision;
  final bool hintVisible;
  List<BodyPart> get available => const BodyParts()
      .forStage(stage)
      .where((part) => !placed.contains(part.id))
      .toList();
  int get stageCount => const BodyParts()
      .forStage(stage)
      .where((part) => placed.contains(part.id))
      .length;
  bool get stageComplete => available.isEmpty;
  bool get complete => stage == 2 && stageComplete;

  BodyGameState copyWith(
          {int? stage,
          Set<BodyPartId>? placed,
          BodyPartId? selected,
          BodyPartId? lastPlaced,
          String? message,
          bool? soundEnabled,
          bool? audioUnavailable,
          bool? hintVisible}) =>
      BodyGameState(
          stage: stage ?? this.stage,
          placed: placed ?? this.placed,
          selected: selected,
          lastPlaced: lastPlaced,
          message: message ?? this.message,
          soundEnabled: soundEnabled ?? this.soundEnabled,
          audioUnavailable: audioUnavailable ?? this.audioUnavailable,
          revision: revision + 1,
          hintVisible: hintVisible ?? false);
}

class BodyGameCubit extends Cubit<BodyGameState> {
  BodyGameCubit(
      {required BodyAudio audio,
      required BodyText text,
      bool soundEnabled = true})
      : _audio = audio,
        _text = text,
        super(BodyGameState(soundEnabled: soundEnabled));
  final BodyAudio _audio;
  final BodyText _text;
  int _narrationRevision = 0;
  bool _suspended = false;

  String _partLine(String key, BodyPartId id) => _text(key)
      .replaceAll('{part}', _text(const BodyParts().find(id).nameKey));

  void start() {
    emit(state.copyWith(message: _text('bodyWelcome')));
    unawaited(_announce(state.message));
  }

  void select(BodyPartId id, {bool forDrag = false}) {
    if (_suspended || !state.available.any((part) => part.id == id)) return;
    emit(state.copyWith(
        selected: id,
        hintVisible: !forDrag,
        message: _partLine('bodyFind', id)));
    unawaited(_announce(state.message));
  }

  bool placeAt(BodyPartId id, Offset point) {
    if (_suspended || !state.available.any((part) => part.id == id)) {
      return false;
    }
    if (const BodyParts().hitTest(point, state.available) != id) {
      reject(id);
      return false;
    }
    emit(state.copyWith(
        placed: {...state.placed, id},
        lastPlaced: id,
        message: _partLine('bodyCorrect', id)));
    final bool finishedStage = state.stageComplete;
    final String celebration =
        _text(state.complete ? 'bodyFinished' : 'bodyStageFinished');
    unawaited(_announce(state.message,
        cue: BodyAudioCue.correct,
        followUp: finishedStage ? celebration : null));
    return true;
  }

  void reject(BodyPartId id) {
    if (_suspended || !state.available.any((part) => part.id == id)) return;
    emit(state.copyWith(
        selected: id, hintVisible: true, message: _partLine('bodyRetry', id)));
    unawaited(_announce(state.message, cue: BodyAudioCue.retry));
  }

  void hint() {
    if (_suspended || state.stageComplete) return;
    final BodyPartId id = state.selected ?? state.available.first.id;
    emit(state.copyWith(
        selected: id, hintVisible: true, message: _partLine('bodyHint', id)));
    unawaited(_announce(state.message));
  }

  void nextStage() {
    if (!state.stageComplete || state.complete) return;
    emit(state.copyWith(
        stage: state.stage + 1,
        message: _text('bodyStage${state.stage + 2}Intro')));
    unawaited(_announce(state.message));
  }

  void restartStage() {
    final Set<BodyPartId> retained = state.placed
        .where((id) => const BodyParts().find(id).stage < state.stage)
        .toSet();
    emit(state.copyWith(
        placed: retained, message: _text('bodyStage${state.stage + 1}Intro')));
    unawaited(_announce(state.message));
  }

  void replay() {
    emit(BodyGameState(
        soundEnabled: state.soundEnabled, revision: state.revision + 1));
    start();
  }

  void repeat() => unawaited(_announce(state.message));

  void toggleSound() {
    emit(state.copyWith(
        soundEnabled: !state.soundEnabled, selected: state.selected));
    _narrationRevision++;
    if (state.soundEnabled) {
      repeat();
    } else {
      unawaited(_audio.stop());
    }
  }

  void suspend() {
    _suspended = true;
    _narrationRevision++;
    unawaited(_audio.stop());
  }

  void resume() {
    _suspended = false;
  }

  Future<void> _announce(String line,
      {BodyAudioCue? cue, String? followUp}) async {
    final int revision = ++_narrationRevision;
    if (!state.soundEnabled || _suspended || isClosed) return;
    bool spoken = false;
    try {
      spoken = await _audio.say(line, cue: cue);
    } catch (_) {/* Captions remain available when an OS audio device fails. */}
    if (isClosed || revision != _narrationRevision || _suspended) return;
    emit(state.copyWith(
        selected: state.selected,
        lastPlaced: state.lastPlaced,
        hintVisible: state.hintVisible,
        audioUnavailable: !spoken));
    if (followUp != null) {
      emit(state.copyWith(message: followUp, lastPlaced: state.lastPlaced));
      await _announce(followUp, cue: BodyAudioCue.celebrate);
    }
  }

  @override
  Future<void> close() async {
    _narrationRevision++;
    await super.close();
    await _audio.dispose();
  }
}
