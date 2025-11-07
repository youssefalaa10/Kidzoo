class ColorModel {
  ColorModel({
    required this.colorNameEn,
    required this.colorNameAr,
    required this.colorValue,
  });

  final String colorNameEn;
  final String colorNameAr;
  final int colorValue; // Color value as int (e.g., 0xFFFF0000 for red)

  // Get color name based on current language
  String getColorName(String languageCode) {
    return languageCode == 'ar' ? colorNameAr : colorNameEn;
  }

  // All available colors
  static final List<ColorModel> allColors = [
    ColorModel(
      colorNameEn: 'Red',
      colorNameAr: 'أحمر',
      colorValue: 0xFFFF0000,
    ),
    ColorModel(
      colorNameEn: 'Blue',
      colorNameAr: 'أزرق',
      colorValue: 0xFF0000FF,
    ),
    ColorModel(
      colorNameEn: 'Green',
      colorNameAr: 'أخضر',
      colorValue: 0xFF00FF00,
    ),
    ColorModel(
      colorNameEn: 'Yellow',
      colorNameAr: 'أصفر',
      colorValue: 0xFFFFFF00,
    ),
    ColorModel(
      colorNameEn: 'Orange',
      colorNameAr: 'برتقالي',
      colorValue: 0xFFFFA500,
    ),
    ColorModel(
      colorNameEn: 'Purple',
      colorNameAr: 'بنفسجي',
      colorValue: 0xFF800080,
    ),
    ColorModel(
      colorNameEn: 'Pink',
      colorNameAr: 'وردي',
      colorValue: 0xFFFFC0CB,
    ),
    ColorModel(
      colorNameEn: 'Brown',
      colorNameAr: 'بني',
      colorValue: 0xFFA52A2A,
    ),
    ColorModel(
      colorNameEn: 'Black',
      colorNameAr: 'أسود',
      colorValue: 0xFF000000,
    ),
    ColorModel(
      colorNameEn: 'White',
      colorNameAr: 'أبيض',
      colorValue: 0xFFFFFFFF,
    ),
  ];

  // Get colors for a specific level - always return all colors
  static List<ColorModel> getColorsForLevel(int level) {
    // Return all colors regardless of level
    return allColors;
  }
}
