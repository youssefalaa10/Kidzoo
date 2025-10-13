import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/logic/crossword_cubit.dart';
import '../data/logic/crossword_state.dart';
import '../data/models/crossword_models.dart';
import 'widgets/arabic_keyboard.dart';
import 'widgets/crossword_grid.dart';

class CrosswordGameScreen extends StatelessWidget {
  const CrosswordGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: BlocBuilder<CrosswordCubit, CrosswordGameState>(
            builder: (context, state) {
              return Text(
                state.puzzle.title,
                style: GoogleFonts.cairo(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.lightbulb, color: Colors.orange),
                onPressed: () => context.read<CrosswordCubit>().giveHint(),
                tooltip: 'تلميح مجاني',
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => context.read<CrosswordCubit>().checkWord(),
                tooltip: 'تحقق',
              ),
            ),
          ],
        ),
        body: BlocConsumer<CrosswordCubit, CrosswordGameState>(
          listener: (context, state) {
            if (state.isCompleted) {
              _showCompletionDialog(context, state);
            }
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: state.message!.contains('صحيح')
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Score and info bar
                _buildInfoBar(state),
                // Clue display
                if (state.currentClue != null)
                  _buildCluePanel(state.currentClue!),
                const SizedBox(height: 8),
                // Crossword grid
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: CrosswordGrid(
                        grid: state.grid,
                        selectedRow: state.selectedRow,
                        selectedCol: state.selectedCol,
                        highlightedCells: state.highlightedCells,
                        onCellTap: (row, col) =>
                            context.read<CrosswordCubit>().selectCell(row, col),
                      ),
                    ),
                  ),
                ),
                // Arabic keyboard
                SafeArea(
                  child: ArabicKeyboard(
                    onLetterTap: (letter) =>
                        context.read<CrosswordCubit>().enterLetter(letter),
                    onDelete: () =>
                        context.read<CrosswordCubit>().deleteLetter(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBar(CrosswordGameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(
            icon: Icons.star,
            label: 'النقاط',
            value: '${state.score}',
            color: Colors.amber.shade700,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildInfoItem(
            icon: Icons.lightbulb_outline,
            label: 'التلميحات',
            value: '${state.hintsUsed}',
            color: Colors.orange.shade600,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildInfoItem(
            icon: Icons.timer_outlined,
            label: 'الوقت',
            value: _formatTime(state.timeSpent),
            color: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCluePanel(CrosswordClue clue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${clue.num}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          clue.isAcross ? 'أفقي →' : 'عمودي ↓',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(
                            '${clue.length} حروف',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clue.clue,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (btnContext) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        btnContext.read<CrosswordCubit>().autoFillWord(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: Text(
                      'املأ الكلمة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog(BuildContext context, CrosswordGameState state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Text(
                '🎊 🎉 🌟',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 70),
              const SizedBox(height: 12),
              Text(
                'رائع جداً!',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مبروك! أنت بطل! 🏆',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أكملت اللغز بنجاح!',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.star,
                      'النقاط النهائية',
                      '${state.score}',
                      Colors.amber.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      Icons.timer,
                      'الوقت',
                      _formatTime(state.timeSpent),
                      Colors.blue.shade600,
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      Icons.lightbulb,
                      state.hintsUsed < 3
                          ? 'قليل من التلميحات! ممتاز! 💡'
                          : 'التلميحات المستخدمة',
                      '${state.hintsUsed}',
                      state.hintsUsed < 3
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Back to level map
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'التالي',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
