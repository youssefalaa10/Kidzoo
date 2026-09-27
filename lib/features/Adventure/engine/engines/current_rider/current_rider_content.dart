import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// A cell on the board. Integer, because everything here is a grid and a
/// floating-point position would invite a physics engine in through the door.
@immutable
class Cell {
  const Cell(this.column, this.row);

  final int column;
  final int row;

  Cell step(Drift flow) => Cell(column + flow.dx, row + flow.dy);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => '($column,$row)';
}

/// Which way water pushes.
///
/// Named for the motion rather than for `Flow`, which is a Flutter widget: an
/// engine that shadows a framework name makes every file that imports both
/// choose a prefix.
///
/// Four directions, not eight. A diagonal current is harder to predict and
/// harder to draw as an arrow a four-year-old reads at a glance, and the
/// planning skill the activity is after does not need it.
enum Drift {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Drift(this.dx, this.dy);

  final int dx;
  final int dy;

  static Drift parse(String raw, String path) {
    for (final Drift flow in Drift.values) {
      if (flow.name == raw) {
        return flow;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a direction; expected one of '
      '${Drift.values.map((Drift f) => f.name).toList()}',
    );
  }
}

/// A current the child can turn.
///
/// The gate is the only thing on the board that changes, which is what makes
/// the board predictable: everything else is where it was last time, so the
/// child can reason about one variable rather than about a whole scene.
@immutable
class CurrentGate {
  const CurrentGate({
    required this.id,
    required this.cell,
    required this.choices,
    required this.initialIndex,
    required this.label,
  });

  final String id;
  final Cell cell;

  /// The directions this gate can be turned to, in the order tapping cycles
  /// through them. Two or three: a gate with four choices takes four taps to
  /// get back to where it started, which is long enough that a child loses
  /// track of what they have already tried.
  final List<Drift> choices;

  final int initialIndex;
  final LocalizedText label;

  Drift get initial => choices[initialIndex];
}

/// How one run of the current ended.
enum RideOutcome {
  /// Reached the destination.
  arrived,

  /// Went into a rock, or off the edge of the board. Gently returned, never a
  /// game over.
  blocked,

  /// Went round and round. A layout can produce this and it is not the child's
  /// fault, so it ends the same way being blocked does.
  circled,
}

/// What happened when the current was released: where the rider went, and how
/// it finished. Pure data from a pure function, so the rules can be tested as
/// a table and the board can animate the very same path the cubit judged.
@immutable
class Ride {
  const Ride({required this.path, required this.outcome});

  /// Every cell passed through, starting with the start cell.
  final List<Cell> path;

  final RideOutcome outcome;

  bool get arrived => outcome == RideOutcome.arrived;

  /// The last cell that was safe to be in — where the rider is put back if the
  /// run did not work out.
  Cell get lastSafe => path.length < 2 ? path.first : path[path.length - 2];
}

/// One board: a start, a destination, some rocks and some gates.
@immutable
class CurrentRound {
  const CurrentRound({
    required this.id,
    required this.columns,
    required this.rows,
    required this.start,
    required this.startFlow,
    required this.goal,
    required this.rocks,
    required this.gates,
    required this.prompt,
    this.revealLine,
  });

  final String id;
  final int columns;
  final int rows;
  final Cell start;

  /// The direction the rider leaves the start in, before any gate has had a
  /// say. Authored so the first move is never a surprise.
  final Drift startFlow;

  final Cell goal;
  final List<Cell> rocks;
  final List<CurrentGate> gates;
  final LocalizedText prompt;
  final LocalizedText? revealLine;

  bool contains(Cell cell) =>
      cell.column >= 0 &&
      cell.row >= 0 &&
      cell.column < columns &&
      cell.row < rows;

  /// The gate standing on [cell], or null.
  CurrentGate? gateAt(Cell cell) {
    for (final CurrentGate gate in gates) {
      if (gate.cell == cell) {
        return gate;
      }
    }
    return null;
  }

  /// The configuration the board starts in.
  Map<String, Drift> get initialSetting => <String, Drift>{
        for (final CurrentGate gate in gates) gate.id: gate.initial,
      };

  /// Runs the current and reports where it went. **Pure.**
  ///
  /// The whole model, and deliberately small enough to state in a sentence:
  /// the rider drifts in a straight line until it crosses a gate, the gate
  /// turns it, and it drifts on. No speed, no momentum, no collision response
  /// — the three things that would make it unpredictable, which is the
  /// opposite of what a planning activity needs. A child can trace the path
  /// with a finger before pressing anything, and that tracing is the learning.
  Ride ride(Map<String, Drift> setting) {
    final List<Cell> path = <Cell>[start];
    Cell at = start;
    Drift heading = startFlow;

    // The cap is a loop guard, not a difficulty knob: a configuration that
    // sends the rider round a square forever is a real possibility on any
    // board with two gates, and it has to end as gently as hitting a rock.
    final int maxSteps = columns * rows * 4;

    for (int step = 0; step < maxSteps; step++) {
      final CurrentGate? gate = gateAt(at);
      if (gate != null) {
        heading = setting[gate.id] ?? gate.initial;
      }
      final Cell next = at.step(heading);
      if (!contains(next) || rocks.contains(next)) {
        return Ride(path: path, outcome: RideOutcome.blocked);
      }
      path.add(next);
      at = next;
      if (at == goal) {
        return Ride(path: path, outcome: RideOutcome.arrived);
      }
    }
    return Ride(path: path, outcome: RideOutcome.circled);
  }

  /// Every configuration of the gates, in a stable order.
  ///
  /// Small by construction — at most three gates of at most three choices, so
  /// twenty-seven — which is what makes it honest to check reachability by
  /// trying all of them rather than by reasoning about it.
  List<Map<String, Drift>> get allSettings {
    List<Map<String, Drift>> settings = <Map<String, Drift>>[<String, Drift>{}];
    for (final CurrentGate gate in gates) {
      final List<Map<String, Drift>> next = <Map<String, Drift>>[];
      for (final Map<String, Drift> partial in settings) {
        for (final Drift choice in gate.choices) {
          next.add(<String, Drift>{...partial, gate.id: choice});
        }
      }
      settings = next;
    }
    return settings;
  }

  /// The settings that get there. Empty means the board cannot be solved.
  List<Map<String, Drift>> get solutions => allSettings
      .where((Map<String, Drift> setting) => ride(setting).arrived)
      .toList(growable: false);

  /// Which gate to turn next, given how the child has set them so far.
  ///
  /// Pure, and asked by the board rather than by the cubit, because the answer
  /// depends on the live setting and the cubit does not have one — `judge` is
  /// pure, so nothing remembers the last attempt. Pointing at a gate the child
  /// has already put right would be a hint that is simply wrong, which is
  /// worse than no hint.
  ///
  /// Picks the solution closest to where they are, so the help offered is
  /// always the smallest change that finishes the job rather than a restart.
  String? gateToTurn(Map<String, Drift> current) {
    final List<Map<String, Drift>> options = solutions;
    if (options.isEmpty || gates.isEmpty) {
      return null;
    }
    Map<String, Drift> nearest = options.first;
    int fewest = gates.length + 1;
    for (final Map<String, Drift> solution in options) {
      int differences = 0;
      for (final CurrentGate gate in gates) {
        if (solution[gate.id] != current[gate.id]) {
          differences++;
        }
      }
      if (differences < fewest) {
        fewest = differences;
        nearest = solution;
      }
    }
    for (final CurrentGate gate in gates) {
      if (nearest[gate.id] != current[gate.id]) {
        return gate.id;
      }
    }
    // Already on a winning setting and still asking for help: point at the
    // first gate so the glow has somewhere to go, rather than returning null
    // and leaving the modelled rung with nothing to show.
    return gates.first.id;
  }
}

class CurrentRiderContent extends ActivityContent {
  const CurrentRiderContent({
    required this.rounds,
    required this.riderImage,
    required this.goalImage,
    required this.rockImage,
    this.accentColorValue,
  });

  final List<CurrentRound> rounds;

  /// Who is being carried. An asset path from content, so the engine never
  /// learns what a turtle is.
  final String riderImage;

  final String goalImage;
  final String rockImage;
  final int? accentColorValue;

  Iterable<String> get assetPaths => <String>{riderImage, goalImage, rockImage};
}

CurrentRiderContent parseCurrentRiderContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(
    reader.requireString('itemsRef'),
    debugPath: '$path.itemsRef',
  );

  String imageOf(String key, String fallbackItemId) {
    final String? direct = reader.optionalString(key);
    if (direct != null) {
      return direct;
    }
    final String itemId =
        reader.optionalString('${key}ItemId') ?? fallbackItemId;
    final PackItem? item = pack.findById(itemId);
    if (item == null) {
      throw ActivityContentException(
        '$path.$key',
        'no image given and pack "${pack.packId}" has no item "$itemId"',
      );
    }
    return item.imageAsset;
  }

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException(
      '$path.rounds',
      'need at least one board; a generated one cannot carry a story beat',
    );
  }

  final List<CurrentRound> rounds = <CurrentRound>[];
  final Set<String> ids = <String>{};

  for (int index = 0; index < rawRounds.length; index++) {
    final Map<String, dynamic> raw = rawRounds[index];
    final String where = '$path.rounds[$index]';
    final JsonReader round = JsonReader(raw, where);

    final String id = round.requireString('id');
    if (!ids.add(id)) {
      throw ActivityContentException('$where.id', 'round id "$id" is reused');
    }

    final int columns = round.requireInt('columns');
    final int rows = round.requireInt('rows');
    // Bounded on both sides. Below three there is no route to plan; above six
    // the cells are under 50dp on a 360dp phone, which is smaller than a child
    // can reliably hit and smaller than an arrow can be read at.
    if (columns < 3 || columns > 6 || rows < 3 || rows > 6) {
      throw ActivityContentException(
        where,
        'a board is 3 to 6 cells each way; got ${columns}x$rows. Bigger than '
        'that and the cells are too small to aim at on a 360dp phone',
      );
    }

    Cell readCell(String key) {
      final List<int> at = round.optionalIntList(key);
      if (at.length != 2) {
        throw ActivityContentException('$where.$key', 'expected [column, row]');
      }
      final Cell cell = Cell(at[0], at[1]);
      if (at[0] < 0 || at[1] < 0 || at[0] >= columns || at[1] >= rows) {
        throw ActivityContentException(
          '$where.$key',
          '$cell is outside a ${columns}x$rows board',
        );
      }
      return cell;
    }

    final Cell start = readCell('start');
    final Cell goal = readCell('goal');
    if (start == goal) {
      throw ActivityContentException(
          '$where.goal', 'the destination is the start, so there is no trip');
    }

    // Rocks are authored as a flat list of [column, row] pairs rather than as
    // objects: they carry nothing but a position, and an object per rock would
    // be four lines of JSON to say two numbers.
    final List<Cell> rocks = <Cell>[];
    final Object? rawRocks = raw['rocks'];
    if (rawRocks is List) {
      for (int r = 0; r < rawRocks.length; r++) {
        final Object? pair = rawRocks[r];
        if (pair is! List || pair.length != 2) {
          throw ActivityContentException(
              '$where.rocks[$r]', 'expected [column, row]');
        }
        final Cell cell =
            Cell((pair[0] as num).toInt(), (pair[1] as num).toInt());
        if (cell.column < 0 ||
            cell.row < 0 ||
            cell.column >= columns ||
            cell.row >= rows) {
          throw ActivityContentException(
              '$where.rocks[$r]', '$cell is outside a ${columns}x$rows board');
        }
        if (cell == start || cell == goal) {
          throw ActivityContentException('$where.rocks[$r]',
              'a rock is standing on the ${cell == start ? 'start' : 'destination'}');
        }
        if (rocks.contains(cell)) {
          throw ActivityContentException(
              '$where.rocks[$r]', 'two rocks on $cell');
        }
        rocks.add(cell);
      }
    }

    final List<Map<String, dynamic>> rawGates = round.optionalMapList('gates');
    if (rawGates.isEmpty || rawGates.length > 3) {
      throw ActivityContentException(
        '$where.gates',
        'one to three gates. None is not a puzzle, and a fourth pushes the '
            'configurations past what a child can hold in their head',
      );
    }

    final List<CurrentGate> gates = <CurrentGate>[];
    final Set<String> gateIds = <String>{};
    for (int g = 0; g < rawGates.length; g++) {
      final String gwhere = '$where.gates[$g]';
      final JsonReader gate = JsonReader(rawGates[g], gwhere);
      final String gateId = gate.requireString('id');
      if (!gateIds.add(gateId)) {
        throw ActivityContentException(
            '$gwhere.id', 'gate id "$gateId" reused');
      }

      final List<int> at = gate.optionalIntList('cell');
      if (at.length != 2) {
        throw ActivityContentException(
            '$gwhere.cell', 'expected [column, row]');
      }
      final Cell cell = Cell(at[0], at[1]);
      if (cell.column < 0 ||
          cell.row < 0 ||
          cell.column >= columns ||
          cell.row >= rows) {
        throw ActivityContentException(
            '$gwhere.cell', '$cell is outside a ${columns}x$rows board');
      }
      if (rocks.contains(cell) || cell == goal) {
        throw ActivityContentException('$gwhere.cell',
            'a gate is standing on ${rocks.contains(cell) ? 'a rock' : 'the destination'}');
      }
      for (final CurrentGate other in gates) {
        if (other.cell == cell) {
          throw ActivityContentException(
              '$gwhere.cell', 'gate "${other.id}" is already on $cell');
        }
      }

      final List<String> rawChoices = gate.requireStringList('choices');
      if (rawChoices.length < 2 || rawChoices.length > 3) {
        throw ActivityContentException(
          '$gwhere.choices',
          'a gate turns between two or three directions; got '
              '${rawChoices.length}. One is scenery and four is a dial',
        );
      }
      final List<Drift> choices = rawChoices
          .map((String name) => Drift.parse(name, '$gwhere.choices'))
          .toList(growable: false);
      if (choices.toSet().length != choices.length) {
        throw ActivityContentException(
            '$gwhere.choices', 'the same direction is listed twice');
      }

      final int initialIndex = gate.optionalInt('initialIndex') ?? 0;
      if (initialIndex < 0 || initialIndex >= choices.length) {
        throw ActivityContentException('$gwhere.initialIndex',
            'no choice number $initialIndex; there are ${choices.length}');
      }

      gates.add(CurrentGate(
        id: gateId,
        cell: cell,
        choices: choices,
        initialIndex: initialIndex,
        label: LocalizedText.fromJson(rawGates[g]['label'],
            debugPath: '$gwhere.label'),
      ));
    }

    final CurrentRound parsed = CurrentRound(
      id: id,
      columns: columns,
      rows: rows,
      start: start,
      startFlow:
          Drift.parse(round.requireString('startFlow'), '$where.startFlow'),
      goal: goal,
      rocks: List<Cell>.unmodifiable(rocks),
      gates: List<CurrentGate>.unmodifiable(gates),
      prompt: LocalizedText.fromJson(raw['prompt'], debugPath: '$where.prompt'),
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
    );

    // The two checks that make this engine safe to author against, and the
    // reason the simulation lives in content rather than in the board.
    //
    // A board nobody can solve is not a hard board — it is a child pressing
    // the button over and over while the turtle bumps into the same rock,
    // until the no-fail ladder gives up and credits the step out of pity.
    // Finding that in a test run is worth far more than finding it in a
    // play test, so it fails at parse time.
    if (parsed.solutions.isEmpty) {
      throw ActivityContentException(
        where,
        'no setting of these gates reaches $goal. The board is unsolvable, so '
        'the child can only be carried through it by the no-fail ladder',
      );
    }
    // And a board that is already solved asks nothing: the child presses the
    // one button on screen and is congratulated for it.
    if (parsed.ride(parsed.initialSetting).arrived) {
      throw ActivityContentException(
        where,
        'the gates already point at $goal before the child touches anything',
      );
    }

    rounds.add(parsed);
  }

  return CurrentRiderContent(
    rounds: List<CurrentRound>.unmodifiable(rounds),
    riderImage: imageOf('riderImage', 'turtle'),
    goalImage: imageOf('goalImage', 'compass'),
    rockImage: imageOf('rockImage', 'reef_stone'),
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
