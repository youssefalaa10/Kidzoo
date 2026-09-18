import 'package:flutter/widgets.dart';

/// The **only** way a board renders content text.
///
/// Boards never use a bare `Text`. Routing every script-sensitive string
/// through one widget is what makes Arabic literacy a later content change
/// rather than a rewrite: when a Naskh face, harakat sizing or shaping control
/// is needed, it lands here once instead of in every engine.
///
/// It already does the two things that are wrong by default today:
///
/// * Arabic gets a slightly larger optical size. Harakat sit above and below
///   the baseline, so a diacriticised string set at the Latin size reads
///   noticeably smaller and the marks blur together — which matters because
///   early readers need the marks, not despite their size but because of it.
/// * Direction follows the *text*, not the surrounding layout, so an Arabic
///   label inside an LTR row still renders right-to-left.
class ActivityGlyphText extends StatelessWidget {
  const ActivityGlyphText(
    this.text, {
    required this.languageCode,
    super.key,
    this.fontSize = 20,
    this.color,
    this.fontWeight = FontWeight.w700,
    this.textAlign = TextAlign.center,
    this.maxLines,
  });

  final String text;
  final String languageCode;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int? maxLines;

  /// Scripts that need the optical bump described above.
  static const Set<String> _diacriticHeavyLanguages = <String>{'ar'};

  /// Arabic is set this much larger than the nominal size.
  static const double arabicOpticalScale = 1.12;

  static bool isRightToLeft(String languageCode) => languageCode == 'ar';

  static double opticalSizeFor(String languageCode, double fontSize) =>
      _diacriticHeavyLanguages.contains(languageCode)
          ? fontSize * arabicOpticalScale
          : fontSize;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isRightToLeft(languageCode) ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: opticalSizeFor(languageCode, fontSize),
          color: color,
          fontWeight: fontWeight,
          // Diacritics need vertical room; a tight line height clips them.
          height: isRightToLeft(languageCode) ? 1.45 : 1.25,
        ),
      ),
    );
  }
}
