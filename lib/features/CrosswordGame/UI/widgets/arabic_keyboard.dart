import 'package:flutter/material.dart';

class ArabicKeyboard extends StatelessWidget {
  const ArabicKeyboard({
    required this.onLetterTap,
    required this.onDelete,
    super.key,
  });

  final void Function(String) onLetterTap;
  final VoidCallback onDelete;

  static const List<List<String>> _arabicLetters = [
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح'],
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك'],
    ['ظ', 'ط', 'ذ', 'د', 'ز', 'ر', 'و', 'ة', 'ى', 'ء'],
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._arabicLetters.map((row) => _buildKeyboardRow(row)),
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> letters) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((letter) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: _buildKey(letter),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String letter) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => onLetterTap(letter),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 40,
          alignment: Alignment.center,
          child: Text(
            letter,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.backspace_outlined,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'حذف',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
