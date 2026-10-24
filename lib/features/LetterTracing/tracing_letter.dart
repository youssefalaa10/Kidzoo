import 'dart:ui';

enum TracingLanguage { arabic, english }

enum LetterForm { isolated, initial, medial, finalForm }

/// Authored handwriting centre-lines, in a shared 300 × 300 writing square.
/// The same paths drive the hollow ribbon, guides, demonstration and hit test.
class TracingLetter {
  TracingLetter(
      {required this.symbol,
      required this.name,
      required this.strokes,
      this.forms = const {}});
  final String symbol;
  final String name;
  final List<String> strokes;
  final Map<LetterForm, List<String>> forms;

  List<TraceStroke> paths(LetterForm form) => (forms[form] ?? strokes)
      .expand(
          (s) => s.split(RegExp(r'(?=M)')).where((s) => s.trim().isNotEmpty))
      .map(TraceStroke.new)
      .toList(growable: false);
}

class TraceStroke {
  TraceStroke(String source) {
    final tokens = RegExp(r'[MLQC]|-?\d+(?:\.\d+)?')
        .allMatches(source)
        .map((m) => m[0]!)
        .toList();
    var i = 0;
    double number() => double.parse(tokens[i++]);
    path = Path();
    while (i < tokens.length) {
      switch (tokens[i++]) {
        case 'M':
          path.moveTo(number(), number());
        case 'L':
          path.lineTo(number(), number());
        case 'Q':
          path.quadraticBezierTo(number(), number(), number(), number());
        case 'C':
          path.cubicTo(
              number(), number(), number(), number(), number(), number());
        default:
          throw FormatException('Invalid tracing path: $source');
      }
    }
    final metric = path.computeMetrics().single;
    length = metric.length;
    final count = (length / 3).ceil().clamp(1, 1000);
    samples = List.generate(count + 1,
        (i) => metric.getTangentForOffset(length * i / count)!.position);
  }
  late final Path path;
  late final double length;
  late final List<Offset> samples;
}
