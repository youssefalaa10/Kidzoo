import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// A square on the board.
@immutable
class GridCell {
  const GridCell(this.column, this.row);

  final int column;
  final int row;

  GridCell shifted(int dc, int dr) => GridCell(column + dc, row + dr);

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => '($column,$row)';
}

/// Which way the vehicle is pointing, and which way a command moves it.
///
/// Rows increase downward, matching how the board is drawn, so `south` is one
/// row further down the screen. Named after compass points rather than
/// `up`/`down` because the relative command set turns *through* them, and
/// "turn left from up" is a sentence with no fixed meaning.
enum GridDirection {
  north(0, -1),
  east(1, 0),
  south(0, 1),
  west(-1, 0);

  const GridDirection(this.deltaColumn, this.deltaRow);

  final int deltaColumn;
  final int deltaRow;

  GridDirection get turnedRight =>
      GridDirection.values[(index + 1) % GridDirection.values.length];

  GridDirection get turnedLeft =>
      GridDirection.values[(index + 3) % GridDirection.values.length];

  static GridDirection parse(String raw, String path) {
    for (final GridDirection value in GridDirection.values) {
      if (value.name == raw) {
        return value;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a direction; expected one of '
      '${GridDirection.values.map((GridDirection d) => d.name).toList()}',
    );
  }
}

/// How the child tells the vehicle where to go.
///
/// Two sets rather than one, because the right answer changes with age and
/// with what is being driven. Absolute arrows ("go that way") are what a three
/// year old can already read off the screen; relative turns ("turn, then go")
/// are the step up, and the only ones that make sense for something with a
/// front — a rover, an animal, a boat. The engine simulates both, so choosing
/// between them is a line of content.
enum CommandMode { absolute, relative }

/// One instruction the child can place in a program.
enum PathCommand {
  north,
  east,
  south,
  west,
  forward,
  turnLeft,
  turnRight;

  bool get isAbsolute => index <= GridDirection.values.length - 1;

  GridDirection get asDirection {
    switch (this) {
      case PathCommand.north:
        return GridDirection.north;
      case PathCommand.east:
        return GridDirection.east;
      case PathCommand.south:
        return GridDirection.south;
      case PathCommand.west:
        return GridDirection.west;
      case PathCommand.forward:
      case PathCommand.turnLeft:
      case PathCommand.turnRight:
        throw StateError('$name is not an absolute move');
    }
  }

  static PathCommand? tryParse(String raw) {
    for (final PathCommand value in PathCommand.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  static List<PathCommand> setFor(CommandMode mode) {
    return mode == CommandMode.absolute
        ? const <PathCommand>[
            PathCommand.north,
            PathCommand.west,
            PathCommand.east,
            PathCommand.south,
          ]
        : const <PathCommand>[
            PathCommand.turnLeft,
            PathCommand.forward,
            PathCommand.turnRight,
          ];
  }
}

/// One journey: where the vehicle starts, where it has to get to, and what is
/// in the way.
@immutable
class PathRoute {
  const PathRoute({
    required this.id,
    required this.start,
    required this.startFacing,
    required this.goal,
    required this.blocked,
    required this.label,
    this.cargo,
    this.goalImage,
    this.revealLine,
  });

  final String id;
  final GridCell start;
  final GridDirection startFacing;
  final GridCell goal;

  /// Squares the vehicle cannot enter. Bumping one is not a failure — the
  /// vehicle stops and comes home, and the child tries again.
  final Set<GridCell> blocked;

  /// What the child is told this journey is for. The reason the route exists,
  /// in the story's own words.
  final LocalizedText label;

  /// What is being carried, if anything. Purely presentational, and the whole
  /// of how this engine stays domain-free: it draws whatever the pack holds.
  final PackItem? cargo;

  /// Art for the destination square.
  final String? goalImage;

  /// Spoken once the journey succeeds, so arriving *causes* the next thing.
  final LocalizedText? revealLine;
}

/// Everything `code_path` needs, parsed.
@immutable
class CodePathContent extends ActivityContent {
  const CodePathContent({
    required this.columns,
    required this.rows,
    required this.routes,
    required this.commandMode,
    required this.maxCommands,
    this.vehicleImage,
    this.accentColorValue,
  });

  final int columns;
  final int rows;
  final List<PathRoute> routes;
  final CommandMode commandMode;

  /// How long a program may get.
  ///
  /// A cap rather than a target: it stops a child filling the strip with fifty
  /// instructions and losing track of which one they are reading, and it keeps
  /// the strip a size that fits on a phone without scrolling.
  final int maxCommands;

  final String? vehicleImage;
  final int? accentColorValue;

  List<PathCommand> get commands => PathCommand.setFor(commandMode);

  Iterable<String> get assetPaths => <String>[
        if (vehicleImage != null) vehicleImage!,
        for (final PathRoute route in routes) ...<String>[
          if (route.cargo != null) route.cargo!.imageAsset,
          if (route.goalImage != null) route.goalImage!,
        ],
      ];

  bool isInside(GridCell cell) =>
      cell.column >= 0 &&
      cell.row >= 0 &&
      cell.column < columns &&
      cell.row < rows;

  bool isOpen(GridCell cell, PathRoute route) =>
      isInside(cell) && !route.blocked.contains(cell);
}

/// Where a program got to, and why it stopped.
enum RunOutcome {
  /// Every command ran and the vehicle is standing on the destination.
  arrived,

  /// Every command ran, but somewhere else.
  stoppedShort,

  /// The vehicle was told to drive into a wall or off the edge.
  blocked,
}

/// One moment of a program running, so the board can play it back.
@immutable
class RunFrame {
  const RunFrame({
    required this.cell,
    required this.facing,
    required this.commandIndex,
    this.isBump = false,
  });

  final GridCell cell;
  final GridDirection facing;

  /// Which instruction produced this frame, so the strip can light up the one
  /// being read. A child who cannot yet read a program *can* follow a
  /// highlight moving along it while the thing it describes happens.
  final int commandIndex;

  /// True when this frame is the vehicle stopping against something.
  final bool isBump;
}

/// Runs a program. Pure, and shared by the judge and the board.
///
/// One simulator rather than two is the point. A board that animated its own
/// idea of what the program did, while the cubit judged a different one, would
/// show a child arriving and then tell them they had not — which is the single
/// most confusing thing this mechanic could do.
@immutable
class PathRun {
  const PathRun({required this.frames, required this.outcome});

  final List<RunFrame> frames;
  final RunOutcome outcome;

  GridCell get finalCell => frames.last.cell;

  static PathRun execute({
    required CodePathContent content,
    required PathRoute route,
    required List<PathCommand> program,
  }) {
    GridCell cell = route.start;
    GridDirection facing = route.startFacing;
    final List<RunFrame> frames = <RunFrame>[
      RunFrame(cell: cell, facing: facing, commandIndex: -1),
    ];

    for (int index = 0; index < program.length; index++) {
      final PathCommand command = program[index];
      if (command == PathCommand.turnLeft || command == PathCommand.turnRight) {
        facing = command == PathCommand.turnLeft
            ? facing.turnedLeft
            : facing.turnedRight;
        frames.add(
            RunFrame(cell: cell, facing: facing, commandIndex: index));
        continue;
      }

      final GridDirection heading =
          command == PathCommand.forward ? facing : command.asDirection;
      // An absolute command also turns the vehicle, so it faces where it is
      // going. Anything else draws a cart sliding sideways.
      facing = heading;
      final GridCell next = cell.shifted(heading.deltaColumn, heading.deltaRow);
      if (!content.isOpen(next, route)) {
        frames.add(RunFrame(
          cell: cell,
          facing: facing,
          commandIndex: index,
          isBump: true,
        ));
        return PathRun(frames: frames, outcome: RunOutcome.blocked);
      }
      cell = next;
      frames.add(RunFrame(cell: cell, facing: facing, commandIndex: index));
    }

    return PathRun(
      frames: frames,
      outcome:
          cell == route.goal ? RunOutcome.arrived : RunOutcome.stoppedShort,
    );
  }

  /// The shortest program that gets there, or an empty list if nothing does.
  ///
  /// Used for the hint and the demonstration, never for judging: the child's
  /// own longer route is just as correct, and marking it wrong would teach
  /// that there is one blessed answer. Breadth-first over a board of at most a
  /// few dozen squares, so the cost is nothing.
  static List<PathCommand> solve({
    required CodePathContent content,
    required PathRoute route,
  }) {
    final List<PathCommand> alphabet = content.commands;
    final Map<String, List<PathCommand>> seen = <String, List<PathCommand>>{};
    String key(GridCell cell, GridDirection facing) =>
        content.commandMode == CommandMode.absolute
            ? '${cell.column},${cell.row}'
            : '${cell.column},${cell.row},${facing.name}';

    final List<_SearchNode> queue = <_SearchNode>[
      _SearchNode(route.start, route.startFacing, const <PathCommand>[]),
    ];
    seen[key(route.start, route.startFacing)] = const <PathCommand>[];

    while (queue.isNotEmpty) {
      final _SearchNode node = queue.removeAt(0);
      if (node.cell == route.goal) {
        return node.program;
      }
      if (node.program.length >= content.maxCommands) {
        continue;
      }
      for (final PathCommand command in alphabet) {
        GridCell cell = node.cell;
        GridDirection facing = node.facing;
        if (command == PathCommand.turnLeft ||
            command == PathCommand.turnRight) {
          facing = command == PathCommand.turnLeft
              ? facing.turnedLeft
              : facing.turnedRight;
        } else {
          final GridDirection heading =
              command == PathCommand.forward ? facing : command.asDirection;
          facing = heading;
          final GridCell next =
              cell.shifted(heading.deltaColumn, heading.deltaRow);
          if (!content.isOpen(next, route)) {
            continue;
          }
          cell = next;
        }
        final String stateKey = key(cell, facing);
        if (seen.containsKey(stateKey)) {
          continue;
        }
        final List<PathCommand> program = <PathCommand>[
          ...node.program,
          command,
        ];
        seen[stateKey] = program;
        queue.add(_SearchNode(cell, facing, program));
      }
    }
    return const <PathCommand>[];
  }
}

@immutable
class _SearchNode {
  const _SearchNode(this.cell, this.facing, this.program);
  final GridCell cell;
  final GridDirection facing;
  final List<PathCommand> program;
}

/// Reads a `code_path` payload.
CodePathContent parseCodePathContent(ActivitySpec spec, ItemPackResolver packs) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final List<int> grid = reader.optionalIntList('grid');
  if (grid.length != 2 || grid[0] < 2 || grid[1] < 2) {
    throw ActivityContentException(
        '$path.grid', 'expected [columns, rows], each at least 2');
  }

  final CommandMode mode = switch (reader.optionalString('commandMode')) {
    'relative' => CommandMode.relative,
    null || 'absolute' => CommandMode.absolute,
    final String other => throw ActivityContentException(
        '$path.commandMode', '"$other" is not absolute or relative'),
  };

  ItemPack? pack;
  final String? itemsRef = reader.optionalString('itemsRef');
  if (itemsRef != null) {
    pack = packs.require(itemsRef, debugPath: '$path.itemsRef');
  }

  final List<Map<String, dynamic>> rawRoutes = reader.optionalMapList('routes');
  if (rawRoutes.isEmpty) {
    throw ActivityContentException(
        '$path.routes', 'need at least one journey to make');
  }

  GridCell cellOf(JsonReader source, String key, String where) {
    final List<int> raw = source.optionalIntList(key);
    if (raw.length != 2) {
      throw ActivityContentException('$where.$key', 'expected [column, row]');
    }
    return GridCell(raw[0], raw[1]);
  }

  final List<PathRoute> routes = <PathRoute>[];
  for (int index = 0; index < rawRoutes.length; index++) {
    final Map<String, dynamic> raw = rawRoutes[index];
    final String where = '$path.routes[$index]';
    final JsonReader routeReader = JsonReader(raw, where);

    final Set<GridCell> blocked = <GridCell>{};
    final Object? rawBlocked = raw['blocked'];
    if (rawBlocked is List) {
      for (int b = 0; b < rawBlocked.length; b++) {
        final Object? pair = rawBlocked[b];
        if (pair is! List || pair.length != 2) {
          throw ActivityContentException(
              '$where.blocked[$b]', 'expected [column, row]');
        }
        blocked.add(GridCell((pair[0] as num).toInt(), (pair[1] as num).toInt()));
      }
    }

    PackItem? cargo;
    final String? cargoId = routeReader.optionalString('cargoItemId');
    if (cargoId != null) {
      if (pack == null) {
        throw ActivityContentException(
            '$where.cargoItemId', 'names an item but the payload has no itemsRef');
      }
      cargo = pack.select(<String>[cargoId], debugPath: '$where.cargoItemId')
          .first;
    }

    routes.add(PathRoute(
      id: routeReader.requireString('id'),
      start: cellOf(routeReader, 'start', where),
      startFacing: GridDirection.parse(
          routeReader.optionalString('startFacing') ?? 'north',
          '$where.startFacing'),
      goal: cellOf(routeReader, 'goal', where),
      blocked: blocked,
      label: LocalizedText.fromJson(raw['label'], debugPath: '$where.label'),
      cargo: cargo,
      goalImage: routeReader.optionalString('goalImage'),
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
    ));
  }

  final CodePathContent content = CodePathContent(
    columns: grid[0],
    rows: grid[1],
    routes: routes,
    commandMode: mode,
    maxCommands: reader.optionalInt('maxCommands') ?? 10,
    vehicleImage: reader.optionalString('vehicleImage'),
    accentColorValue: _accentValue(spec.presentation.accent),
  );

  // Every journey has to be makeable. A route with no solution is an author
  // error that would otherwise surface as a child trying forever, with the
  // demonstration itself unable to show them what to do.
  for (final PathRoute route in routes) {
    if (!content.isOpen(route.start, route)) {
      throw ActivityContentException(
          '$path.routes', 'route "${route.id}" starts on a blocked square');
    }
    if (!content.isOpen(route.goal, route)) {
      throw ActivityContentException(
          '$path.routes', 'route "${route.id}" ends on a blocked square');
    }
    if (route.start == route.goal) {
      throw ActivityContentException('$path.routes',
          'route "${route.id}" starts where it ends, so there is nothing to do');
    }
    if (PathRun.solve(content: content, route: route).isEmpty) {
      throw ActivityContentException(
        '$path.routes',
        'route "${route.id}" cannot be driven in ${content.maxCommands} '
        'commands — the walls box it in, or the cap is too low',
      );
    }
  }

  return content;
}

int? _accentValue(String? raw) {
  if (raw == null) {
    return null;
  }
  final String hex = raw.replaceFirst('#', '');
  if (hex.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }
  return int.parse('FF$hex', radix: 16);
}
