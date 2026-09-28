import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/scene_props.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// What a findable thing in the dark *is*, which decides how it behaves when
/// the beam lands on it.
///
/// Three kinds rather than a flag, because the difference is not cosmetic: a
/// [creature] is the only one that can demand a wider beam before it counts as
/// seen, and an [exit] is the only one that is required to come last.
enum DarkFindKind {
  /// An ordinary object. Lights up, holds still, waits to be touched.
  find,

  /// The big shape. Shown as a silhouette until the beam is wide enough to
  /// take it in, at which point it is revealed as something harmless.
  ///
  /// The startle is the point and so is its resolution: a shape too big to see
  /// all at once is frightening because of the *not seeing*, and the child
  /// fixes that themselves by making the light bigger. Nothing jumps out, and
  /// the reveal is always friendlier than the silhouette.
  creature,

  /// The way on. Always the last thing found, because finding it is what ends
  /// the scene.
  exit;

  static DarkFindKind parse(String raw, String path) {
    for (final DarkFindKind kind in DarkFindKind.values) {
      if (kind.name == raw) {
        return kind;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a find kind; expected one of '
      '${DarkFindKind.values.map((DarkFindKind k) => k.name).toList()}',
    );
  }
}

/// One thing waiting in the dark.
@immutable
class DarkFind {
  const DarkFind({
    required this.id,
    required this.position,
    required this.imageAsset,
    required this.label,
    required this.kind,
    this.scale = 1.0,
    this.revealLine,
    this.requiresBeamFraction,
  });

  final String id;

  /// Normalized 0..1 within the scene box, like every other authored position
  /// in this feature, so one layout works on a phone and on a tablet.
  final Offset position;

  final String imageAsset;

  /// Read out when the beam reaches it, and attached to the object as a
  /// semantics label the whole time — a child using a screen reader gets the
  /// same scene, and "the old compass" is more use than "image".
  final LocalizedText label;

  final DarkFindKind kind;

  /// Relative to the computed base size. A [DarkFindKind.creature] is drawn at
  /// several times this again, because being too big to light all at once is
  /// what makes it a shape rather than an object.
  final double scale;

  /// Spoken once this one is found.
  final LocalizedText? revealLine;

  /// The beam radius, as a fraction of the board's short side, that must be
  /// reached before this counts as lit.
  ///
  /// Only meaningful on a [DarkFindKind.creature], and the whole of the
  /// "make the light bigger" beat: the child cannot resolve the shape by
  /// aiming better, only by widening. Null means any beam will do.
  final double? requiresBeamFraction;

  bool get isCreature => kind == DarkFindKind.creature;
}

/// A dark scene explored with a light the child holds.
class FlashlightContent extends ActivityContent {
  const FlashlightContent({
    required this.finds,
    required this.beamStart,
    required this.beamFraction,
    required this.maxBeamFraction,
    required this.hitToleranceFraction,
    this.props = const <SceneProp>[],
    this.ground,
    this.sceneImage,
    this.accentColorValue,
  });

  /// In the order they are asked for. Authored rather than shuffled: the scene
  /// tells a small story — something is moving, it is friendly, here is the way
  /// on — and a shuffled order would tell it backwards about a third of the
  /// time.
  final List<DarkFind> finds;

  /// Where the light starts, normalized. Authored so the opening frame is the
  /// same on every device and in every test run.
  final Offset beamStart;

  /// The beam's starting radius as a fraction of the board's short side.
  final double beamFraction;

  /// The widest the child can open it. Bounded rather than unbounded: a beam
  /// that can be grown until it lights the whole board turns a dark scene into
  /// a bright one and there is nothing left to explore.
  final double maxBeamFraction;

  /// How close a tap must land to count, as a fraction of the short side.
  final double hitToleranceFraction;

  /// Scenery: drawn, never interactive, and just as dark as everything else
  /// until the beam finds it. This is what makes sweeping worth doing — a beam
  /// that only ever crosses empty water and answers is a cursor, not a light.
  final List<SceneProp> props;

  final SceneProp? ground;
  final String? sceneImage;
  final int? accentColorValue;

  bool get canWidenBeam => maxBeamFraction > beamFraction + 0.001;

  Iterable<String> get assetPaths => <String>[
        if (sceneImage != null) sceneImage!,
        ...finds.map((DarkFind find) => find.imageAsset),
        for (final SceneProp prop in <SceneProp>[
          ...props,
          if (ground != null) ground!,
        ])
          if (prop.image != null) prop.image!,
      ];
}

FlashlightContent parseFlashlightContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final double beamFraction = (reader.optionalInt('beamPercent') ?? 18) / 100;
  final double maxBeamFraction =
      (reader.optionalInt('maxBeamPercent') ?? 34) / 100;
  if (beamFraction < 0.06 || beamFraction > 0.5) {
    throw ActivityContentException('$path.beamPercent',
        'expected 6 to 50 percent of the board; got ${beamFraction * 100}');
  }
  if (maxBeamFraction < beamFraction || maxBeamFraction > 0.6) {
    throw ActivityContentException(
      '$path.maxBeamPercent',
      'the widest beam must be at least the starting beam and no more than 60 '
          'percent of the board, or the scene stops being dark',
    );
  }

  final List<int> rawStart = reader.optionalIntList('beamStartPercent');
  if (rawStart.length != 2) {
    throw ActivityContentException('$path.beamStartPercent',
        'expected [x, y] as whole percentages of the scene');
  }
  final Offset beamStart = Offset(rawStart[0] / 100, rawStart[1] / 100);

  final List<Map<String, dynamic>> rawFinds = reader.optionalMapList('finds');
  if (rawFinds.length < 2) {
    throw ActivityContentException(
      '$path.finds',
      'a dark scene with one thing in it is a tap target with the lights off; '
          'need at least two',
    );
  }

  final List<DarkFind> finds = <DarkFind>[];
  final Set<String> ids = <String>{};
  int creatures = 0;
  int exits = 0;

  for (int index = 0; index < rawFinds.length; index++) {
    final Map<String, dynamic> raw = rawFinds[index];
    final String where = '$path.finds[$index]';
    final JsonReader entry = JsonReader(raw, where);

    final String id = entry.requireString('id');
    if (!ids.add(id)) {
      throw ActivityContentException('$where.id', 'id "$id" is used twice');
    }

    final List<int> at = entry.optionalIntList('positionPercent');
    if (at.length != 2) {
      throw ActivityContentException('$where.positionPercent',
          'expected [x, y] as whole percentages of the scene');
    }
    // Hard bounds rather than a clamp. Objects are sized from the board's
    // *short* side, so something authored at 97% is off the edge in landscape
    // and merely tight in portrait — a bug that only appears on one device is
    // worse than one that appears on all of them, and an author told at parse
    // time can simply move it.
    for (int axis = 0; axis < 2; axis++) {
      if (at[axis] < 8 || at[axis] > 92) {
        throw ActivityContentException(
          '$where.positionPercent',
          'keep every find between 8 and 92 percent on both axes so it stays '
              'wholly on the board at every supported width; got $at',
        );
      }
    }

    final DarkFindKind kind = DarkFindKind.parse(
      entry.optionalString('kind') ?? 'find',
      '$where.kind',
    );
    if (kind == DarkFindKind.creature) {
      creatures++;
    }
    if (kind == DarkFindKind.exit) {
      exits++;
      if (index != rawFinds.length - 1) {
        throw ActivityContentException(
          '$where.kind',
          'the exit is what ends the scene, so it has to be the last find; it '
              'is number ${index + 1} of ${rawFinds.length}',
        );
      }
    }

    final double? requiresBeam =
        entry.optionalInt('requiresBeamPercent') == null
            ? null
            : entry.optionalInt('requiresBeamPercent')! / 100;
    if (requiresBeam != null) {
      if (kind != DarkFindKind.creature) {
        throw ActivityContentException(
          '$where.requiresBeamPercent',
          'only a creature can ask for a wider beam; an ordinary find that '
              'cannot be lit by the starting beam just looks broken',
        );
      }
      if (requiresBeam <= beamFraction || requiresBeam > maxBeamFraction) {
        throw ActivityContentException(
          '$where.requiresBeamPercent',
          'must sit above the starting beam and within the widest one '
              '(${beamFraction * 100}..${maxBeamFraction * 100}), or widening is '
              'either unnecessary or impossible; got ${requiresBeam * 100}',
        );
      }
    }

    finds.add(DarkFind(
      id: id,
      position: Offset(at[0] / 100, at[1] / 100),
      imageAsset: entry.requireString('image'),
      label: LocalizedText.fromJson(raw['label'], debugPath: '$where.label'),
      kind: kind,
      scale: entry.optionalDouble('scale') ?? 1.0,
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
      requiresBeamFraction: requiresBeam,
    ));
  }

  if (creatures > 1) {
    throw ActivityContentException(
      '$path.finds',
      'two big shapes in one dark scene is two startles, and the second one is '
          'not a surprise — it is a pattern the child now expects',
    );
  }
  if (exits > 1) {
    throw ActivityContentException(
        '$path.finds', 'a scene has one way on, not $exits');
  }

  // Two finds on top of each other cannot be told apart by aim, so the second
  // one is unanswerable however well the child plays.
  final double tolerance =
      reader.optionalDouble('hitToleranceFraction') ?? 0.12;
  for (int a = 0; a < finds.length; a++) {
    for (int b = a + 1; b < finds.length; b++) {
      if ((finds[a].position - finds[b].position).distance < tolerance) {
        throw ActivityContentException(
          '$path.finds',
          '"${finds[a].id}" and "${finds[b].id}" are closer together than the '
              'hit tolerance, so a tap meant for one lands on both',
        );
      }
    }
  }

  // Unused today and parsed anyway: a later scene may want real art behind the
  // dark, and an author should not have to add the field to the model first.
  final String? itemsRef = reader.optionalString('itemsRef');
  if (itemsRef != null) {
    packs.require(itemsRef, debugPath: '$path.itemsRef');
  }

  final String? groundShape = reader.optionalString('ground');

  return FlashlightContent(
    finds: List<DarkFind>.unmodifiable(finds),
    beamStart: beamStart,
    beamFraction: beamFraction,
    maxBeamFraction: maxBeamFraction,
    hitToleranceFraction: tolerance,
    props: _readProps(reader.optionalMapList('props'), '$path.props'),
    ground: groundShape == null
        ? null
        : SceneProp(
            position: const Offset(0.5, 0.86),
            shape: _shapeNamed(groundShape, '$path.ground'),
          ),
    sceneImage:
        reader.optionalString('sceneImage') ?? spec.presentation.sceneImage,
    accentColorValue: _accentValue(spec.presentation.accent),
  );
}

List<SceneProp> _readProps(List<Map<String, dynamic>> raw, String path) {
  final List<SceneProp> props = <SceneProp>[];
  for (int index = 0; index < raw.length; index++) {
    final JsonReader entry = JsonReader(raw[index], '$path[$index]');
    final List<int> at = entry.optionalIntList('positionPercent');
    if (at.length != 2) {
      throw ActivityContentException('$path[$index].positionPercent',
          'expected [x, y] as whole percentages of the scene');
    }
    final String? image = entry.optionalString('image');
    final String? shape = entry.optionalString('shape');
    if (image == null && shape == null) {
      throw ActivityContentException(
          '$path[$index]', 'needs either an image path or a shape name');
    }
    props.add(SceneProp(
      position: Offset(at[0] / 100, at[1] / 100),
      shape: shape == null ? null : _shapeNamed(shape, '$path[$index].shape'),
      image: image,
      scale: entry.optionalDouble('scale') ?? 1.0,
      turns: (entry.optionalDouble('turn') ?? 0) / 360,
      flip: raw[index]['flip'] == true,
    ));
  }
  return props;
}

ScenePropShape _shapeNamed(String name, String path) {
  for (final ScenePropShape shape in ScenePropShape.values) {
    if (shape.name == name) {
      return shape;
    }
  }
  throw ActivityContentException(
    path,
    '"$name" is not a scene shape; expected one of '
    '${ScenePropShape.values.map((ScenePropShape s) => s.name).toList()}',
  );
}

int? _accentValue(String? hex) {
  if (hex == null) {
    return null;
  }
  final int? rgb = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}
