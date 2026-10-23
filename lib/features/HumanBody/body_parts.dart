import 'package:flutter/material.dart';

enum BodyPartId {
  leftEye,
  rightEye,
  nose,
  mouth,
  leftEar,
  rightEar,
  head,
  hair,
  neck,
  shoulders,
  arms,
  hands,
  fingers,
  stomach,
  legs,
  knees,
  feet,
  toes,
}

/// All geometry uses a 360 × 560 character canvas, irrespective of locale.
/// Left/right always refer to the character, who is facing the child.
class BodyPart {
  const BodyPart(this.id, this.stage, this.anchors, this.artBounds);
  final BodyPartId id;
  final int stage;
  final List<Offset> anchors;
  final Rect artBounds;
  String get nameKey => 'bodyPart_${id.name}';
}

class BodyParts {
  const BodyParts();
  List<BodyPart> get all => const [
        BodyPart(BodyPartId.leftEye, 0, [Offset(216, 112)],
            Rect.fromLTWH(199, 93, 34, 39)),
        BodyPart(BodyPartId.rightEye, 0, [Offset(144, 112)],
            Rect.fromLTWH(127, 93, 34, 39)),
        BodyPart(BodyPartId.nose, 0, [Offset(180, 143)],
            Rect.fromLTWH(166, 132, 28, 24)),
        BodyPart(BodyPartId.mouth, 0, [Offset(180, 180)],
            Rect.fromLTWH(154, 167, 52, 29)),
        BodyPart(BodyPartId.leftEar, 0, [Offset(275, 123)],
            Rect.fromLTWH(260, 100, 30, 46)),
        BodyPart(BodyPartId.rightEar, 0, [Offset(85, 123)],
            Rect.fromLTWH(70, 100, 30, 46)),
        BodyPart(BodyPartId.head, 1, [Offset(180, 138)],
            Rect.fromLTWH(92, 39, 176, 174)),
        BodyPart(BodyPartId.hair, 1, [Offset(180, 40)],
            Rect.fromLTWH(90, 13, 180, 70)),
        BodyPart(BodyPartId.neck, 1, [Offset(180, 225)],
            Rect.fromLTWH(157, 205, 46, 43)),
        BodyPart(BodyPartId.shoulders, 1, [Offset(180, 266)],
            Rect.fromLTWH(105, 243, 150, 44)),
        BodyPart(BodyPartId.arms, 1, [Offset(78, 303), Offset(282, 303)],
            Rect.fromLTWH(48, 270, 264, 74)),
        BodyPart(BodyPartId.hands, 1, [Offset(43, 352), Offset(317, 352)],
            Rect.fromLTWH(24, 330, 312, 45)),
        BodyPart(BodyPartId.fingers, 1, [Offset(34, 392), Offset(326, 392)],
            Rect.fromLTWH(14, 368, 332, 42)),
        BodyPart(BodyPartId.stomach, 2, [Offset(180, 328)],
            Rect.fromLTWH(119, 281, 122, 91)),
        BodyPart(BodyPartId.legs, 2, [Offset(145, 416), Offset(215, 416)],
            Rect.fromLTWH(122, 369, 116, 126)),
        BodyPart(BodyPartId.knees, 2, [Offset(145, 460), Offset(215, 460)],
            Rect.fromLTWH(126, 444, 108, 32)),
        BodyPart(BodyPartId.feet, 2, [Offset(137, 512), Offset(223, 512)],
            Rect.fromLTWH(102, 493, 156, 37)),
        BodyPart(BodyPartId.toes, 2, [Offset(119, 540), Offset(241, 540)],
            Rect.fromLTWH(98, 529, 164, 22)),
      ];

  BodyPart find(BodyPartId id) => all.firstWhere((part) => part.id == id);
  List<BodyPart> forStage(int stage) =>
      all.where((part) => part.stage == stage).toList();

  /// Resolve the closest active anchor so adjacent eyes, knees and hands never
  /// accept one another. Paired parts accept a drop on either side.
  BodyPartId? hitTest(Offset point, Iterable<BodyPart> available) {
    double distance = 39;
    BodyPartId? nearest;
    for (final BodyPart part in available) {
      for (final Offset anchor in part.anchors) {
        final double candidate = (point - anchor).distance;
        if (candidate < distance) {
          distance = candidate;
          nearest = part.id;
        }
      }
    }
    return nearest;
  }
}

/// One transform is shared by drawing, hover feedback and pointer hit testing.
class BodyViewport {
  BodyViewport(
      {required this.size, required this.stage, this.overview = false});
  final Size size;
  final int stage;
  final bool overview;
  Rect get scene => overview || stage == 2
      ? const Rect.fromLTWH(0, 0, 360, 560)
      : stage == 0
          ? const Rect.fromLTWH(42, 0, 276, 265)
          : const Rect.fromLTWH(0, 0, 360, 420);
  double get scale => (size.width / scene.width < size.height / scene.height)
      ? size.width / scene.width
      : size.height / scene.height;
  Offset get origin =>
      Offset((size.width - scene.width * scale) / 2,
          (size.height - scene.height * scale) / 2) -
      scene.topLeft * scale;
  Offset toScene(Offset local) => (local - origin) / scale;
  Offset toLocal(Offset point) => origin + point * scale;
}
