class Word {
  final String word; // e.g., "Can"
  final int missingIndex; // e.g., 1 (for the missing letter 'a')
  final List<String> options; // e.g., ["C", "A", "G", "Y"]
  final String correctLetter; // e.g., "A"

  Word({
    required this.word,
    required this.missingIndex,
    required this.options,
    required this.correctLetter,
  });
}
