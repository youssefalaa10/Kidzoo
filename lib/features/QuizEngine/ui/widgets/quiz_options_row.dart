import 'package:flutter/material.dart';
import '../../data/quiz_models.dart';

class QuizOptionsRow extends StatelessWidget {
  final List<QuizOption> options;
  final void Function(QuizOption) onOptionSelected;
  final bool showFeedback;

  const QuizOptionsRow({
    super.key,
    required this.options,
    required this.onOptionSelected,
    this.showFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        Color? bgColor;
        if (showFeedback) {
          bgColor = option.isCorrect ? Colors.green : Colors.red;
        }

        return GestureDetector(
          onTap: showFeedback ? null : () => onOptionSelected(option),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.imagePath != null)
                  Image.asset(option.imagePath!, height: 60),
                if (option.imagePath != null) const SizedBox(height: 8),
                Text(
                  option.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bgColor != null ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
