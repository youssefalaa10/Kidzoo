import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

/// The interactive middle of an activity — and **only** the middle.
///
/// A board never builds a `Scaffold`, an `AppBar`, a background or a result
/// view. Those belong to `ActivityHostScreen`, which owns all chrome so that a
/// child moving between activities keeps one mental model. Architecture tests
/// grep `engine/engines/**` for `Scaffold`, `AppBar`, `MediaQuery.of` and
/// `Color(0x` precisely so an engine cannot quietly grow its own screen, which
/// is how the previous quiz engine ended up written and never used.
abstract class ActivityBoard extends StatelessWidget {
  const ActivityBoard({super.key});
}

/// Builds a board for a given state. Engines return one of these rather than a
/// widget directly, so the host controls when and where it is mounted.
typedef ActivityBoardBuilder = Widget Function(
  BuildContext context,
  ActivityState state,
  ActivityAttemptCallback submit,
);

/// How a board hands an attempt back to the cubit.
typedef ActivityAttemptCallback = void Function(ActivityAttempt attempt);

/// A content-driven activity mechanic.
///
/// The contract deliberately has no `buildScreen`. An engine parses content,
/// declares its assets, makes a cubit and makes a board. Everything else — the
/// shell, narration ordering, the no-fail ladder, scoring, persistence — is the
/// base cubit's and the host's.
abstract class ActivityEngine<TContent extends ActivityContent> {
  const ActivityEngine();

  ActivityEngineDescriptor get descriptor;

  String get engineId => descriptor.engineId;

  /// Parses this engine's slice of an activity file.
  ///
  /// [packs] resolves an `itemsRef` such as `packs/animals` into real items,
  /// which is what keeps an engine domain-free: `counting` counts whatever the
  /// pack contains and never names an animal, a fruit or a star.
  ///
  /// Throws [ActivityContentException] naming the JSON path. Content errors are
  /// author errors, and an author needs to be told *where*.
  TContent parseContent(ActivitySpec spec, ItemPackResolver packs);

  /// Asset paths the host should precache before the first frame, so a card
  /// does not pop in after the prompt has already named it.
  Iterable<String> assetsFor(TContent content) => const <String>[];

  ActivityCubit<TContent, dynamic> createCubit(
    ActivitySession<TContent> session,
  );

  /// The board factory. Returns a widget that renders [ActivityState] and
  /// reports attempts back through the supplied callback.
  ActivityBoardBuilder createBoard();

  /// Convenience used by the host and by tests: parse, then build a session.
  ///
  /// [seed] is what `services.random` was built from. It is passed separately
  /// because a `Random` cannot be asked for its seed, and step-level resume is
  /// only exact if the same seed reproduces the same board.
  ActivitySession<TContent> createSession({
    required ActivitySpec spec,
    required ActivityServices services,
    required ItemPackResolver packs,
    String? storyNodeId,
    int seed = 0,
    ActivityCheckpoint? resume,
  }) {
    return ActivitySession<TContent>(
      spec: spec,
      content: parseContent(spec, packs),
      services: services,
      engineId: descriptor.engineId,
      engineSchemaVersion: descriptor.schemaVersion,
      storyNodeId: storyNodeId,
      seed: seed,
      resume: resume,
    );
  }
}
