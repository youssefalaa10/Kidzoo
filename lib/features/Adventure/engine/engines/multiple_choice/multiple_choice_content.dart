import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One authored question.
///
/// A story activity almost always wants its own wording per round — "Who was
/// drinking at the river?" is a different line from "Who was up in the branches?"
/// — so questions are authored rather than generated whenever the words carry
/// story weight. Generation stays available for drill-shaped content.
@immutable
class MultipleChoiceQuestion {
  const MultipleChoiceQuestion({
    required this.id,
    required this.prompt,
    required this.correctItem,
    required this.distractorItems,
    this.revealLine = const LocalizedText.empty(),
  });

  final String id;
  final LocalizedText prompt;
  final PackItem correctItem;
  final List<PackItem> distractorItems;

  /// Spoken after a correct answer.
  ///
  /// This is what makes the activity *causal* rather than decorative: the
  /// animal does not merely get picked, it says what it saw, and that line is
  /// the clue the next beat depends on.
  final LocalizedText revealLine;

  List<PackItem> get allItems => <PackItem>[correctItem, ...distractorItems];
}

class MultipleChoiceContent extends ActivityContent {
  const MultipleChoiceContent({
    required this.questions,
    required this.optionCount,
  });

  final List<MultipleChoiceQuestion> questions;
  final int optionCount;

  Iterable<String> get assetPaths => questions
      .expand((MultipleChoiceQuestion question) => question.allItems)
      .map((PackItem item) => item.imageAsset);
}

MultipleChoiceContent parseMultipleChoiceContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(
    reader.optionalString('itemsRef') ?? 'packs/animals',
    debugPath: '$path.itemsRef',
  );
  final int optionCount = reader.optionalInt('optionCount') ?? 3;
  if (optionCount < 2) {
    throw ActivityContentException(
        '$path.optionCount', 'need at least two options');
  }

  final List<Map<String, dynamic>> rawQuestions =
      reader.optionalMapList('questions');
  if (rawQuestions.isEmpty) {
    throw ActivityContentException(
      '$path.questions',
      'multiple_choice needs authored questions; generated wording cannot '
          'carry a story beat',
    );
  }

  final List<MultipleChoiceQuestion> questions = <MultipleChoiceQuestion>[];
  for (int index = 0; index < rawQuestions.length; index++) {
    final Map<String, dynamic> raw = rawQuestions[index];
    final JsonReader questionReader =
        JsonReader(raw, '$path.questions[$index]');
    final String correctId = questionReader.requireString('correctItemId');
    final PackItem? correct = pack.findById(correctId);
    if (correct == null) {
      throw ActivityContentException(
        '$path.questions[$index].correctItemId',
        'pack "${pack.packId}" has no item "$correctId"',
      );
    }
    final List<String> distractorIds =
        questionReader.optionalStringList('distractorItemIds');
    final List<PackItem> distractors = distractorIds.isEmpty
        ? pack.items
            .where((PackItem item) => item.id != correct.id)
            .take(optionCount - 1)
            .toList(growable: false)
        : pack.select(distractorIds,
            debugPath: '$path.questions[$index].distractorItemIds');

    questions.add(MultipleChoiceQuestion(
      id: questionReader.optionalString('id') ?? 'q$index',
      prompt: LocalizedText.fromJson(raw['prompt'],
          debugPath: '$path.questions[$index].prompt'),
      correctItem: correct,
      distractorItems: distractors,
      revealLine: LocalizedText.fromJson(raw['revealLine'],
          debugPath: '$path.questions[$index].revealLine'),
    ));
  }

  return MultipleChoiceContent(
    questions: questions,
    optionCount: optionCount,
  );
}
