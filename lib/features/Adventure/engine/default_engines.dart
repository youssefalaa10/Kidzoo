import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';

/// The engines the app ships with.
///
/// Adding one is a single line here plus a folder. That is the whole extension
/// point, and it is deliberately smaller than the old `GameSequence` switch,
/// which required edits in three places and could only produce widgets.
///
/// The list is built, not stored in a static, so a test or a future host can
/// register a different set without mutating global state.
ActivityEngineRegistry buildDefaultEngineRegistry() {
  return ActivityEngineRegistry(<ActivityEngine<ActivityContent>>[
    const CountingEngine(),
    const MultipleChoiceEngine(),
    const HiddenClueEngine(),
    const SortingEngine(),
    // Adventure 2 added three, each because no existing capability key covered
    // it: nothing here plans a route before running it, nothing lets a child
    // experiment before answering, and nothing produces a stroke. The registry
    // enforces that claim — two reusable engines sharing a
    // (domains, interactions) pair is a build failure.
    const CodePathEngine(),
    const BalanceExperimentEngine(),
    const TracePathEngine(),
    // Adventure 3 added one, for the domain the contract has declared since
    // Phase 1 with nothing behind it: `patterning`. Its key is unique because
    // the domain is, even though it shares `sorting`'s interaction — which is
    // the registry working as intended rather than a loophole. Sorting asks
    // which box a thing belongs in; this asks what is missing from a run.
    const PatternsEngine(),
    // Adventure 3 added three more, and each had to earn a new
    // `InteractionMode` to do it — which is the check working rather than
    // being worked around. `flashlight` claiming `tapInScene` alone would have
    // collided with `hidden_clue`, and `current_rider` claiming
    // `orderSequence` would have collided with `code_path`. In both cases the
    // collision would have been correct: the mode was the wrong description of
    // what the child does. `sound_sequence` is unique on both axes, because
    // nothing here had ever asked a child to remember something that is no
    // longer on screen.
    const FlashlightEngine(),
    const CurrentRiderEngine(),
    const SoundSequenceEngine(),
  ]);
}
