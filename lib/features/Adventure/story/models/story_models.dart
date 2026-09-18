import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// The dramatic shape every Adventure must declare.
///
/// This is a **content contract**, not a guideline, and it is enforced by test.
/// Without it "story mode" decays into a themed list of drills — which is
/// exactly what the Challenge map already was. Requiring a chapter to name its
/// beats forces the author to answer "why is this activity here?" before the
/// activity exists.
enum StoryBeat {
  openingProblem,
  discovery,
  obstacle,
  progress,
  climax,
  resolution,
  clueOnward;

  static StoryBeat parse(String raw, String path) {
    for (final StoryBeat beat in StoryBeat.values) {
      if (beat.name == raw) {
        return beat;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a beat; expected one of '
      '${StoryBeat.values.map((StoryBeat b) => b.name).toList()}',
    );
  }

  /// The order a chapter must declare. Obstacles may repeat; everything else
  /// appears exactly once, in this sequence.
  static const List<StoryBeat> requiredSequence = <StoryBeat>[
    StoryBeat.openingProblem,
    StoryBeat.discovery,
    StoryBeat.obstacle,
    StoryBeat.progress,
    StoryBeat.climax,
    StoryBeat.resolution,
    StoryBeat.clueOnward,
  ];
}

enum StoryNodeKind { storyBeat, activity }

/// One moment in an Adventure: either something that happens, or something the
/// child does.
@immutable
class StoryNode {
  const StoryNode({
    required this.nodeId,
    required this.beat,
    required this.kind,
    required this.lines,
    this.activityRef,
    this.speakerArt,
    this.sceneArt,
    this.rewardId,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json, String path) {
    final JsonReader reader = JsonReader(json, path);
    final String rawKind = reader.optionalString('type') ?? 'storyBeat';
    final StoryNodeKind kind = rawKind == 'activity'
        ? StoryNodeKind.activity
        : StoryNodeKind.storyBeat;
    final String nodeId = reader.requireString('nodeId');

    final List<LocalizedText> lines = (json['lines'] as List<dynamic>? ??
            <dynamic>[])
        .map((Object? line) =>
            LocalizedText.fromJson(line, debugPath: '$path.lines'))
        .toList(growable: false);

    if (kind == StoryNodeKind.activity && !reader.has('activityRef')) {
      throw ActivityContentException(
          '$path.activityRef', 'an activity node must name its activity');
    }
    if (kind == StoryNodeKind.storyBeat && lines.isEmpty) {
      throw ActivityContentException(
          '$path.lines', 'a story beat with nothing to say is a dead node');
    }

    return StoryNode(
      nodeId: nodeId,
      beat: StoryBeat.parse(reader.requireString('beat'), '$path.beat'),
      kind: kind,
      lines: lines,
      activityRef: reader.optionalString('activityRef'),
      speakerArt: reader.optionalString('speakerArt'),
      sceneArt: reader.optionalString('sceneArt'),
      rewardId: reader.optionalString('rewardId'),
    );
  }

  final String nodeId;
  final StoryBeat beat;
  final StoryNodeKind kind;

  /// Spoken and shown in order. Budgeted deliberately: a child who has to
  /// listen for a minute before touching anything stops listening.
  final List<LocalizedText> lines;

  final String? activityRef;
  final String? speakerArt;
  final String? sceneArt;

  /// Set on the node that hands over the recovered page.
  final String? rewardId;

  bool get isActivity => kind == StoryNodeKind.activity;
}

/// One Adventure: a self-contained tale ending with a page recovered.
@immutable
class Adventure {
  const Adventure({
    required this.adventureId,
    required this.title,
    required this.backgroundType,
    required this.nodes,
    required this.rewardId,
    required this.rewardTitle,
    this.accent,
  });

  factory Adventure.fromJson(Map<String, dynamic> json, String sourcePath) {
    final JsonReader reader = JsonReader(json, sourcePath);
    final String adventureId = reader.requireString('adventureId');
    final List<Map<String, dynamic>> rawNodes = reader.optionalMapList('nodes');
    if (rawNodes.isEmpty) {
      throw ActivityContentException('$sourcePath.nodes', 'no nodes');
    }
    final List<StoryNode> nodes = <StoryNode>[];
    for (int index = 0; index < rawNodes.length; index++) {
      nodes.add(StoryNode.fromJson(
          rawNodes[index], '$sourcePath.nodes[$index]'));
    }
    return Adventure(
      adventureId: adventureId,
      title: LocalizedText.fromJson(json['title'],
          debugPath: '$sourcePath.title'),
      backgroundType: reader.optionalString('backgroundType') ?? 'jungle',
      nodes: nodes,
      rewardId: reader.requireString('rewardId'),
      rewardTitle: LocalizedText.fromJson(json['rewardTitle'],
          debugPath: '$sourcePath.rewardTitle'),
      accent: reader.optionalString('accent'),
    );
  }

  final String adventureId;
  final LocalizedText title;
  final String backgroundType;
  final List<StoryNode> nodes;

  /// The page this Adventure returns to the book.
  final String rewardId;
  final LocalizedText rewardTitle;

  /// An `#RRGGBB` accent, or null. Kept as the authored string and parsed by
  /// [accentColorValue] so a typo degrades to the default rather than throwing
  /// somewhere in the widget tree.
  final String? accent;

  /// The accent as an ARGB value, or null when absent or malformed.
  int? get accentColorValue {
    final String? raw = accent;
    if (raw == null) {
      return null;
    }
    final String hex = raw.replaceFirst('#', '');
    if (hex.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return null;
    }
    return int.parse('FF$hex', radix: 16);
  }

  int get activityCount =>
      nodes.where((StoryNode node) => node.isActivity).length;

  StoryNode? nodeById(String nodeId) {
    for (final StoryNode node in nodes) {
      if (node.nodeId == nodeId) {
        return node;
      }
    }
    return null;
  }

  int indexOfNode(String nodeId) =>
      nodes.indexWhere((StoryNode node) => node.nodeId == nodeId);

  /// The beats actually present, in order of first appearance.
  List<StoryBeat> get declaredBeats {
    final List<StoryBeat> seen = <StoryBeat>[];
    for (final StoryNode node in nodes) {
      if (seen.isEmpty || seen.last != node.beat) {
        if (!seen.contains(node.beat)) {
          seen.add(node.beat);
        }
      }
    }
    return seen;
  }
}

/// A season: several Adventures under one premise.
@immutable
class StoryArc {
  const StoryArc({
    required this.arcId,
    required this.title,
    required this.premise,
    required this.adventureIds,
    required this.companionName,
    required this.bookName,
  });

  factory StoryArc.fromJson(Map<String, dynamic> json, String sourcePath) {
    final JsonReader reader = JsonReader(json, sourcePath);
    return StoryArc(
      arcId: reader.requireString('arcId'),
      title: LocalizedText.fromJson(json['title'],
          debugPath: '$sourcePath.title'),
      premise: LocalizedText.fromJson(json['premise'],
          debugPath: '$sourcePath.premise'),
      adventureIds: reader.requireStringList('adventures'),
      companionName: LocalizedText.fromJson(json['companionName'],
          debugPath: '$sourcePath.companionName'),
      bookName: LocalizedText.fromJson(json['bookName'],
          debugPath: '$sourcePath.bookName'),
    );
  }

  final String arcId;
  final LocalizedText title;
  final LocalizedText premise;
  final List<String> adventureIds;

  /// Named in content rather than in code, because these two words appear in
  /// nearly every narration line and renaming them must never be a code change.
  final LocalizedText companionName;
  final LocalizedText bookName;
}
