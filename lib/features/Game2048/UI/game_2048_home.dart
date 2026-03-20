import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/logic/game_cubit.dart';
import '../data/models/game_state_model.dart';
import '../../../core/localization/app_localizations.dart';
import 'game_2048_screen.dart';

class Game2048Home extends StatelessWidget {
  const Game2048Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 28,
                        ),
                        color: const Color(0xFF776E65),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '2048',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF776E65),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                  const SizedBox(height: 30),
 // Best Score Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.orange.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).bestScore,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${state.bestScore}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Action Buttons
                  FutureBuilder<bool>(
                    future: context.read<GameCubit>().hasSavedGame(),
                    builder: (context, snapshot) {
                      final hasSaved = snapshot.data ?? false;
                      return Column(
                        children: [
                          _buildActionButton(
                            context: context,
                            label: AppLocalizations.of(context).newGame,
                            icon: Icons.add_circle_outline,
                            color: Colors.blue,
                            onPressed: () {
                              final cubit = context.read<GameCubit>();
                              cubit.newGame();
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => BlocProvider.value(
                                    value: cubit,
                                    child: const Game2048Screen(),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (hasSaved) const SizedBox(height: 16),
                          if (hasSaved)
                            _buildActionButton(
                              context: context,
                              label: AppLocalizations.of(context).continueGame,
                              icon: Icons.play_arrow_rounded,
                              color: Colors.green,
                              onPressed: () async {
                                final cubit = context.read<GameCubit>();
                                await cubit.continueGame();
                                if (context.mounted) {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => BlocProvider.value(
                                        value: cubit,
                                        child: const Game2048Screen(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Statistics
                  Text(
                    AppLocalizations.of(context).statistics,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF776E65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticsGrid(context, state),
                  const SizedBox(height: 30),
                  // History Button
                  OutlinedButton.icon(
                    onPressed: () => _showGameHistory(context),
                    icon: const Icon(Icons.history),
                    label: Text(
                      AppLocalizations.of(context).viewHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF776E65),
                      side:
                          const BorderSide(color: Color(0xFF776E65), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, GameState state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.sports_esports,
          label: AppLocalizations.of(context).gamesPlayedLabel,
          value: '${state.gamesPlayed}',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.star,
          label: AppLocalizations.of(context).maxTile,
          value: '${state.maxTileAchieved}',
          color: Colors.purple,
        ),
        _buildStatCard(
          icon: Icons.access_time,
          label: AppLocalizations.of(context).totalPlayTime,
          value: _formatDuration(context, state.totalPlayTimeSeconds),
          color: Colors.teal,
        ),
        _buildStatCard(
          icon: Icons.emoji_events,
          label: AppLocalizations.of(context).wins,
          value: '${state.winCount}',
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGameHistory(BuildContext context) async {
    final history = await context.read<GameCubit>().getGameHistory();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).history,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF776E65),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noHistory,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final game = history[index];
                        return _buildHistoryItem(context, game, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, Map<String, dynamic> game, int index) {
    final won = game['won'] as bool;
    final score = game['score'] as int;
    final maxTile = game['maxTile'] as int;
    final moves = game['moves'] as int;
    final duration = game['duration'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: won ? Colors.green.shade200 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: won ? Colors.green.shade100 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                won ? '🏆' : '🎮',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).scoreLabel}: $score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context).maxTile}: $maxTile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$moves ${AppLocalizations.of(context).moves} • ${_formatDuration(context, duration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(BuildContext context, int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
