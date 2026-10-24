import 'tracing_letter.dart';

/// Simplified Naskh handwriting skeletons. Bodies run in the letter's own
/// writing direction; dots follow the body as separate, tappable pen strokes.
/// Joined forms are individually authored (not mirrored Latin paths).
List<TracingLetter> arabicTracingLetters() {
  const bowl = 'M230 145 C245 225 65 245 65 175';
  const tooth = 'M230 135 Q240 180 205 180 L65 180';
  const toothMiddle = 'M260 180 L225 180 L225 140 Q235 180 200 180 L60 180';
  const toothFinal = 'M260 180 L230 180 C245 245 65 250 65 180';
  const jim =
      'M85 115 Q160 65 220 130 Q160 135 115 170 C10 250 170 295 225 240';
  const jimStart = 'M100 115 Q170 70 225 135 Q170 145 105 180 L60 180';
  const jimMiddle =
      'M260 180 Q230 145 225 135 Q170 70 100 115 Q165 130 225 135 Q165 145 105 180 L60 180';
  const sin =
      'M240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 C165 265 55 275 55 200';
  const sinStart =
      'M240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 Q150 180 115 180 L55 180';
  const sad =
      'M145 180 C150 115 220 100 240 140 Q265 185 145 180 C165 265 55 275 55 200';
  const sadStart = 'M130 180 C145 110 225 100 240 140 Q260 185 130 180 L55 180';
  const ain =
      'M200 100 C125 50 85 135 160 150 L215 150 C150 165 60 190 85 240 Q115 285 215 250';
  const ainStart = 'M210 100 C145 60 110 125 165 150 L225 150 Q150 180 65 180';
  const ainMiddle =
      'M260 180 L210 180 L125 120 Q175 90 220 120 L135 180 L60 180';
  const fa =
      'M225 160 C260 80 155 65 175 140 Q185 165 225 160 C240 240 60 245 65 180';
  const faStart =
      'M220 180 C265 80 155 65 175 140 Q185 165 230 160 Q230 180 195 180 L60 180';
  const qaf =
      'M225 160 C260 80 155 65 175 140 Q185 165 225 160 C255 275 70 295 70 190';
  const lam = 'M210 50 L210 195 C210 275 80 265 80 195';
  const lamStart = 'M205 50 L205 155 Q205 180 175 180 L60 180';
  const mim =
      'M210 175 C270 150 210 100 175 140 Q145 175 210 175 L110 180 Q95 180 95 210 L95 270';
  const mimStart =
      'M240 180 Q220 175 210 175 C270 150 210 100 175 140 Q145 175 210 175 L60 180';
  const nun = 'M225 145 C250 270 65 280 75 160';
  const ha = 'M215 170 C235 100 160 85 130 140 C90 220 220 225 215 170';
  const haStart =
      'M230 180 C260 110 160 70 145 125 C120 185 240 185 230 150 Q210 180 60 180';
  const haMiddle =
      'M260 180 L190 180 C120 110 125 80 165 100 C225 150 160 240 130 220 Q105 195 190 180 L60 180';
  const waw =
      'M215 170 C255 100 160 90 160 140 Q165 175 215 170 Q225 235 100 255';
  const ya =
      'M225 125 C165 80 145 155 205 170 Q240 180 215 215 C150 280 45 255 65 190';
  const kaf = 'M225 50 L225 190 Q225 235 65 225 L65 195';
  const kafStart = 'M225 65 L145 120 L210 175 Q160 185 65 180';
  const ta = 'M90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180';
  const dal = 'M150 95 Q210 120 225 180 Q160 205 95 195';
  const ra = 'M215 135 Q245 215 95 250';
  const dot = 'M155 95 L158 95';

  const twoAbove = ['M145 85 L148 85', 'M180 85 L183 85'];
  const threeAbove = ['M160 60 L163 60', 'M140 90 L143 90', 'M180 90 L183 90'];

  TracingLetter letter(String symbol, String name, String body,
      {List<String> dots = const [],
      String? initial,
      String? medial,
      String? finalBody,
      List<String>? joinedDots,
      List<String> extra = const []}) {
    final marks = joinedDots ?? dots;
    return TracingLetter(symbol: symbol, name: name, strokes: [
      body,
      ...extra,
      ...dots
    ], forms: {
      if (initial != null) LetterForm.initial: [initial, ...marks],
      if (medial != null) LetterForm.medial: [medial, ...marks],
      if (finalBody != null)
        LetterForm.finalForm: [finalBody, ...extra, ...dots],
    });
  }

  return [
    letter('ا', 'أَلِف', 'M165 55 L165 220',
        finalBody: 'M165 55 L165 180 L260 180'),
    letter('ب', 'بَاء', bowl,
        dots: ['M150 260 L153 260'],
        initial: tooth,
        medial: toothMiddle,
        finalBody: toothFinal,
        joinedDots: ['M155 225 L158 225']),
    letter('ت', 'تَاء', bowl,
        dots: twoAbove,
        initial: tooth,
        medial: toothMiddle,
        finalBody: toothFinal),
    letter('ث', 'ثَاء', bowl,
        dots: threeAbove,
        initial: tooth,
        medial: toothMiddle,
        finalBody: toothFinal),
    letter('ج', 'جِيم', jim,
        dots: ['M150 225 L153 225'],
        initial: jimStart,
        medial: jimMiddle,
        finalBody:
            'M260 180 L220 130 Q160 65 85 115 Q150 125 220 130 Q160 135 115 170 C10 250 170 295 225 240',
        joinedDots: ['M160 225 L163 225']),
    letter('ح', 'حَاء', jim,
        initial: jimStart,
        medial: jimMiddle,
        finalBody:
            'M260 180 L220 130 Q160 65 85 115 Q150 125 220 130 Q160 135 115 170 C10 250 170 295 225 240'),
    letter('خ', 'خَاء', jim,
        dots: ['M155 60 L158 60'],
        initial: jimStart,
        medial: jimMiddle,
        finalBody:
            'M260 180 L220 130 Q160 65 85 115 Q150 125 220 130 Q160 135 115 170 C10 250 170 295 225 240'),
    letter('د', 'دَال', dal,
        finalBody:
            'M150 95 Q210 120 225 180 L260 180 M225 180 Q160 205 95 195'),
    letter('ذ', 'ذَال', dal,
        dots: ['M155 50 L158 50'],
        finalBody:
            'M150 95 Q210 120 225 180 L260 180 M225 180 Q160 205 95 195'),
    letter('ر', 'رَاء', ra, finalBody: 'M260 180 L225 180 Q205 230 95 250'),
    letter('ز', 'زَاي', ra,
        dots: ['M195 80 L198 80'],
        finalBody: 'M260 180 L225 180 Q205 230 95 250'),
    letter('س', 'سِين', sin,
        initial: sinStart,
        medial:
            'M270 180 L240 180 Q250 135 240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 Q150 180 115 180 L55 180',
        finalBody:
            'M270 180 L240 180 Q250 135 240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 C165 265 55 275 55 200'),
    letter('ش', 'شِين', sin,
        dots: ['M195 60 L198 60', 'M175 90 L178 90', 'M215 90 L218 90'],
        initial: sinStart,
        medial:
            'M270 180 L240 180 Q250 135 240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 Q150 180 115 180 L55 180',
        finalBody:
            'M270 180 L240 180 Q250 135 240 135 Q250 185 210 180 Q190 180 195 145 Q195 190 160 180 Q145 175 150 150 C165 265 55 275 55 200'),
    letter('ص', 'صَاد', sad,
        initial: sadStart,
        medial:
            'M270 180 L130 180 C145 110 225 100 240 140 Q260 185 130 180 L55 180',
        finalBody:
            'M270 180 L145 180 C150 115 220 100 240 140 Q265 185 145 180 C165 265 55 275 55 200'),
    letter('ض', 'ضَاد', sad,
        dots: ['M195 65 L198 65'],
        initial: sadStart,
        medial:
            'M270 180 L130 180 C145 110 225 100 240 140 Q260 185 130 180 L55 180',
        finalBody:
            'M270 180 L145 180 C150 115 220 100 240 140 Q265 185 145 180 C165 265 55 275 55 200'),
    letter('ط', 'طَاء', ta,
        extra: ['M120 55 L120 180'],
        initial:
            'M90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180 M120 55 L120 180',
        medial:
            'M270 180 L90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180 M120 55 L120 180',
        finalBody:
            'M270 180 L90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180'),
    letter('ظ', 'ظَاء', ta,
        extra: ['M120 55 L120 180'],
        dots: ['M195 65 L198 65'],
        initial:
            'M90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180 M120 55 L120 180',
        medial:
            'M270 180 L90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180 M120 55 L120 180',
        finalBody:
            'M270 180 L90 180 C115 110 215 95 235 140 Q260 185 90 180 L60 180'),
    letter('ع', 'عَيْن', ain,
        initial: ainStart,
        medial: ainMiddle,
        finalBody:
            'M260 180 L210 180 L125 120 Q175 90 220 120 L135 180 C35 240 105 290 215 250'),
    letter('غ', 'غَيْن', ain,
        dots: ['M165 40 L168 40'],
        initial: ainStart,
        medial: ainMiddle,
        finalBody:
            'M260 180 L210 180 L125 120 Q175 90 220 120 L135 180 C35 240 105 290 215 250'),
    letter('ف', 'فَاء', fa,
        dots: ['M195 50 L198 50'],
        initial: faStart,
        medial:
            'M270 180 L220 180 C265 80 155 65 175 140 Q185 165 230 160 Q230 180 195 180 L60 180',
        finalBody:
            'M270 180 L225 160 C260 80 155 65 175 140 Q185 165 225 160 C240 240 60 245 65 180'),
    letter('ق', 'قَاف', qaf,
        dots: ['M175 50 L178 50', 'M210 50 L213 50'],
        initial: faStart,
        medial:
            'M270 180 L220 180 C265 80 155 65 175 140 Q185 165 230 160 Q230 180 195 180 L60 180',
        finalBody:
            'M270 180 L225 160 C260 80 155 65 175 140 Q185 165 225 160 C255 275 70 295 70 190'),
    letter('ك', 'كَاف', kaf,
        extra: ['M160 110 L130 140 L160 155 L125 175'],
        initial: kafStart,
        medial:
            'M270 180 L210 175 L145 120 L225 65 M145 120 L210 175 Q160 185 65 180',
        finalBody:
            'M225 50 L225 180 L270 180 M225 180 Q225 235 65 225 L65 195'),
    letter('ل', 'لَام', lam,
        initial: lamStart,
        medial: 'M270 180 L205 180 L205 50 M205 155 Q205 180 175 180 L60 180',
        finalBody:
            'M210 50 L210 180 L270 180 M210 180 L210 195 C210 275 80 265 80 195'),
    letter('م', 'مِيم', mim,
        initial: mimStart,
        medial:
            'M270 180 L210 175 C270 150 210 100 175 140 Q145 175 210 175 L60 180',
        finalBody:
            'M270 180 L210 175 C270 150 210 100 175 140 Q145 175 210 175 L110 180 Q95 180 95 210 L95 270'),
    letter('ن', 'نُون', nun,
        dots: [dot],
        initial: tooth,
        medial: toothMiddle,
        finalBody: 'M270 180 L225 180 C250 270 65 280 75 160'),
    letter('ه', 'هَاء', ha,
        initial: haStart,
        medial: haMiddle,
        finalBody:
            'M270 180 L215 180 C235 105 160 85 130 140 C90 220 220 225 215 170'),
    letter('و', 'وَاو', waw,
        finalBody:
            'M270 180 L215 170 C255 100 160 90 160 140 Q165 175 215 170 Q225 235 100 255'),
    letter('ي', 'يَاء', ya,
        dots: ['M125 285 L128 285', 'M165 285 L168 285'],
        initial: tooth,
        medial: toothMiddle,
        finalBody:
            'M270 180 L205 170 C145 155 165 80 225 125 M205 170 Q240 180 215 215 C150 280 45 255 65 190',
        joinedDots: ['M135 225 L138 225', 'M175 225 L178 225']),
  ];
}
