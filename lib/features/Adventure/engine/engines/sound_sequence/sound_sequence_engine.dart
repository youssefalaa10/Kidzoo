import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_cubit.dart';

/// Hear a sequence, hold it, give it back.
///
/// **Why this is not `patterns`.** That engine shows a rule and asks the child
/// to apply it somewhere they can see: the strip stays on screen the whole
/// time, nothing has to be remembered, and the skill is reading a structure.
/// Here there is no structure to read and nothing left to look at — the rhythm
/// has already stopped by the time the child answers, and a rhythm with a
/// repeated beat has no rule at all, only an order. `patterns` asks *what
/// belongs here*; this asks *what came first*. The first is patterning, the
/// second is serial recall, and no content on `patterns` produces it because
/// `patterns` never takes the question away.
///
/// That is why the domain is [LearningDomain.memory] and the mode is
/// [InteractionMode.echoRhythm]. Declaring `orderSequence` would say the child
/// is arranging something that is in front of them, which is the one thing
/// they are not doing.
///
/// Every beat is shown as well as sounded, and the board is winnable with the
/// volume at zero. That is a hard requirement rather than a nicety: an
/// activity that silently stops being answerable on a muted phone is broken
/// for a large share of the times it is opened.
///
/// The engine names no subject. A voice is a pack item, a tone asset and a
/// label; a round is a list of voice ids. Sea creatures, birds, bells, drums
/// and a doorbell are the same file with different art.
class SoundSequenceEngine extends ActivityEngine<SoundSequenceContent> {
  const SoundSequenceEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'sound_sequence',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.memory},
        interactionModes: <InteractionMode>{InteractionMode.echoRhythm},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef', isRequired: true),
          ContentParameter.list('voices',
              isRequired: true,
              description: 'three to six, each with id, itemId for the '
                  'picture, an audio path for its tone, and a label read in '
                  'place of the sound'),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each with id, a sequence of voice ids, its own '
                  'wording and an optional revealLine. A round may not use '
                  'every voice, or tapping all of them could answer it'),
          ContentParameter.integer('beatMilliseconds',
              minValue: 300,
              maxValue: 1200,
              description: 'how long one beat lasts while the gate plays. The '
                  'errorless dial: a slower rhythm is the same question with '
                  'more room to hear it, whereas a shorter one is a different '
                  'question'),
        ],
        adaptationAxis: 'beatMilliseconds',
        // Pictures, tones and authored labels. Nothing glyph-shaped and
        // nothing that mirrors wrongly, so it is honestly bilingual.
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  SoundSequenceContent parseContent(
          ActivitySpec spec, ItemPackResolver packs) =>
      parseSoundSequenceContent(spec, packs);

  @override
  Iterable<String> assetsFor(SoundSequenceContent content) =>
      content.assetPaths;

  @override
  ActivityCubit<SoundSequenceContent, dynamic> createCubit(
    ActivitySession<SoundSequenceContent> session,
  ) =>
      SoundSequenceCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! SoundSequenceStep) {
        return const SizedBox.shrink();
      }
      return SoundSequenceBoard(step: step, state: state, submit: submit);
    };
  }
}
