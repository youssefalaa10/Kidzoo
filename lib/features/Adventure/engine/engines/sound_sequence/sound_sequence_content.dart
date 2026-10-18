import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One thing that can make a noise.
///
/// A voice is a picture, a sound and a name. All three are load-bearing: the
/// picture is what the child taps, the sound is what they are matching, and
/// the name is what a child using a screen reader gets instead of the sound.
/// A voice missing any of them is a voice some child cannot use.
@immutable
class SoundVoice {
  const SoundVoice({
    required this.id,
    required this.item,
    required this.audioAsset,
    required this.label,
  });

  final String id;

  /// Where the picture comes from. Resolved through the pack, so the engine
  /// never learns what any of these creatures are.
  final PackItem item;

  /// The tone this voice sings, as a path under `assets/`.
  ///
  /// Content names it rather than the engine choosing, because *which* sound
  /// plays is the content of the question here, not the app reacting to an
  /// answer — the closed [ActivitySound] set is for the latter and would need
  /// a new enum value per voice.
  final String audioAsset;

  /// Read aloud in place of the sound. Not a nicety: a rhythm activity that
  /// only exists as audio is unusable muted, and this is what the visual
  /// fallback is labelled with.
  final LocalizedText label;
}

/// One rhythm to hear and give back.
@immutable
class SoundRound {
  const SoundRound({
    required this.id,
    required this.sequence,
    required this.prompt,
    this.revealLine,
  });

  final String id;

  /// Voice ids, in the order they are played.
  final List<String> sequence;

  final LocalizedText prompt;
  final LocalizedText? revealLine;

  int get length => sequence.length;

  /// The voices this round never uses. At least one has to exist, or the round
  /// can be answered by tapping everything on screen in any order that happens
  /// to be right — and with three voices and a three-beat rhythm, guessing is
  /// a real strategy rather than a theoretical one.
  Set<String> unusedFrom(Iterable<String> allVoiceIds) =>
      allVoiceIds.toSet().difference(sequence.toSet());
}

class SoundSequenceContent extends ActivityContent {
  const SoundSequenceContent({
    required this.voices,
    required this.rounds,
    required this.beatMilliseconds,
    this.accentColorValue,
  });

  final List<SoundVoice> voices;
  final List<SoundRound> rounds;

  /// How long one beat of the rhythm lasts while the gate is playing it.
  ///
  /// Slow by adult standards on purpose. A rhythm played at speech tempo is
  /// gone before a four-year-old has finished looking at the first thing that
  /// lit up, and what they are being asked to hold is the *order*, which needs
  /// each beat to be a separate event rather than part of a run.
  final int beatMilliseconds;

  final int? accentColorValue;

  SoundVoice? voiceById(String id) {
    for (final SoundVoice voice in voices) {
      if (voice.id == id) {
        return voice;
      }
    }
    return null;
  }

  Iterable<String> get assetPaths =>
      voices.map((SoundVoice voice) => voice.item.imageAsset);
}

SoundSequenceContent parseSoundSequenceContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(
    reader.requireString('itemsRef'),
    debugPath: '$path.itemsRef',
  );

  final List<Map<String, dynamic>> rawVoices = reader.optionalMapList('voices');
  if (rawVoices.length < 3) {
    throw ActivityContentException(
      '$path.voices',
      'fewer than three voices and a rhythm is a coin toss; got '
          '${rawVoices.length}',
    );
  }
  if (rawVoices.length > 6) {
    throw ActivityContentException(
      '$path.voices',
      'more than six things to choose between is a search task wearing a '
          'rhythm costume; got ${rawVoices.length}',
    );
  }

  final List<SoundVoice> voices = <SoundVoice>[];
  final Set<String> voiceIds = <String>{};
  final Set<String> tones = <String>{};

  for (int index = 0; index < rawVoices.length; index++) {
    final String where = '$path.voices[$index]';
    final JsonReader entry = JsonReader(rawVoices[index], where);

    final String id = entry.requireString('id');
    if (!voiceIds.add(id)) {
      throw ActivityContentException('$where.id', 'voice id "$id" is reused');
    }

    final String itemId = entry.requireString('itemId');
    final PackItem? item = pack.findById(itemId);
    if (item == null) {
      throw ActivityContentException(
        '$where.itemId',
        'pack "${pack.packId}" has no item "$itemId"',
      );
    }

    final String audio = entry.requireString('audio');
    // Two voices on one tone are indistinguishable with the screen off, so the
    // round would be unanswerable for exactly the child the audio is for.
    if (!tones.add(audio)) {
      throw ActivityContentException(
        '$where.audio',
        'another voice already sings "$audio"; two voices with one tone cannot '
            'be told apart by ear',
      );
    }

    voices.add(SoundVoice(
      id: id,
      item: item,
      audioAsset: audio,
      label: LocalizedText.fromJson(rawVoices[index]['label'],
          debugPath: '$where.label'),
    ));
  }

  final int beat = reader.optionalInt('beatMilliseconds') ?? 620;
  if (beat < 300 || beat > 1200) {
    throw ActivityContentException(
      '$path.beatMilliseconds',
      'a beat is 300 to 1200ms. Faster and the order is gone before a child '
          'has looked at it; slower and they stop hearing it as one rhythm',
    );
  }

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException('$path.rounds', 'need at least one rhythm');
  }

  final List<SoundRound> rounds = <SoundRound>[];
  final Set<String> ids = <String>{};
  final Set<String> signatures = <String>{};

  for (int index = 0; index < rawRounds.length; index++) {
    final String where = '$path.rounds[$index]';
    final JsonReader entry = JsonReader(rawRounds[index], where);

    final String id = entry.requireString('id');
    if (!ids.add(id)) {
      throw ActivityContentException('$where.id', 'round id "$id" is reused');
    }

    final List<String> sequence = entry.requireStringList('sequence');
    if (sequence.length < 2 || sequence.length > 6) {
      throw ActivityContentException(
        '$where.sequence',
        'a rhythm is two to six beats; got ${sequence.length}. Six is already '
            'past what most children of this age hold in order',
      );
    }
    for (final String voiceId in sequence) {
      if (!voiceIds.contains(voiceId)) {
        throw ActivityContentException(
          '$where.sequence',
          'no voice "$voiceId"; this activity has '
              '${(voiceIds.toList()..sort())}',
        );
      }
    }

    final SoundRound round = SoundRound(
      id: id,
      sequence: List<String>.unmodifiable(sequence),
      prompt: LocalizedText.fromJson(rawRounds[index]['prompt'],
          debugPath: '$where.prompt'),
      revealLine: rawRounds[index]['revealLine'] == null
          ? null
          : LocalizedText.fromJson(rawRounds[index]['revealLine'],
              debugPath: '$where.revealLine'),
    );

    // The check that stops "tap everything" from being a strategy. With no
    // spare voice, a child who taps all of them in the displayed order is
    // right whenever the rhythm happens to be that order, and they will find
    // that out by accident long before they find out what the activity is for.
    if (round.unusedFrom(voiceIds).isEmpty) {
      throw ActivityContentException(
        '$where.sequence',
        'this rhythm uses every voice on screen, so tapping all of them can '
            'answer it; leave at least one out',
      );
    }

    final String signature = sequence.join('-');
    if (!signatures.add(signature)) {
      throw ActivityContentException(
        where,
        'another round plays this exact rhythm; hearing it twice reads to a '
        'child as the gate getting stuck rather than as a second question',
      );
    }

    rounds.add(round);
  }

  return SoundSequenceContent(
    voices: List<SoundVoice>.unmodifiable(voices),
    rounds: List<SoundRound>.unmodifiable(rounds),
    beatMilliseconds: beat,
    accentColorValue: _accentValue(spec.presentation.accent),
  );
}

int? _accentValue(String? hex) {
  if (hex == null) {
    return null;
  }
  final int? rgb = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}
