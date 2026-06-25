import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/base/protected_game_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/widgets/fluid_container.dart';

enum GameLevel {
  easy,
  medium,
  hard,
}

class MemoryGameScreen extends ProtectedGameScreen {
  const MemoryGameScreen({required super.level, super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ProtectedGameScreenState<MemoryGameScreen>
    with TickerProviderStateMixin {
  // Define emojis for all levels
  final List<String> _allEmojis = [
    '🦄',
    '🌈',
    '🚀',
    '🌮',
    '🎮',
    '🍕',
    '🏆',
    '🎨',
    '🐱',
    '🐶',
    '🐼',
    '🦊',
    '🦁',
    '🐯',
    '🐵',
    '🐸',
    '🍎',
    '🍌',
    '🍓',
    '🥑',
    '🌽',
    '🥕',
    '🍉',
    '🍇',
  ];

  // Game state variables
  late List<CardModel> _cards;
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  int _pairs = 0;
  int _totalPairs = 0;
  int _moves = 0;
  bool _isProcessing = false;
  bool _gameStarted = false;
  bool _gameCompleted = false;
  late GameLevel _currentLevel;

  // Timer variables
  late Stopwatch _stopwatch;
  Timer? _timer;
  String _timeElapsed = '00:00';

  // Animation controllers
  late AnimationController _gameCompletedController;
  late Animation<double> _gameCompletedAnimation;

  @override
  void onGameInit() {
    _gameCompletedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gameCompletedAnimation = CurvedAnimation(
      parent: _gameCompletedController,
      curve: Curves.easeInOut,
    );

    // Set difficulty based on the level passed from constructor
    switch (widget.level) {
      case 1:
        _currentLevel = GameLevel.easy;
        break;
      case 2:
        _currentLevel = GameLevel.medium;
        break;
      default:
        _currentLevel = GameLevel.hard;
        break;
    }

    _initGame(_currentLevel);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameCompletedController.dispose();
    super.dispose();
  }

  void _initGame(GameLevel level) {
    // Set number of pairs based on difficulty level
    int numPairs;
    switch (level) {
      case GameLevel.easy:
        numPairs = 4; // 8 cards (3x3 grid - 9 spots with 1 empty)
        break;
      case GameLevel.medium:
        numPairs = 8; // 16 cards (4x4 grid)
        break;
      case GameLevel.hard:
        numPairs = 10; // 20 cards (4x5 grid)
        break;
    }

    _currentLevel = level;
    _totalPairs = numPairs;

    // Create a list with the needed number of emojis, each appearing twice
    final List<String> gameEmojis = [];
    final List<String> shuffledEmojis = List.from(_allEmojis)..shuffle();

    for (int i = 0; i < numPairs; i++) {
      gameEmojis.add(shuffledEmojis[i]);
      gameEmojis.add(shuffledEmojis[i]);
    }

    // For easy level, add an empty spot if needed
    if (level == GameLevel.easy && gameEmojis.length < 9) {
      gameEmojis.add('');
    }

    // Shuffle the final list of emojis
    gameEmojis.shuffle();

    // Create card models with matching pairs
    _cards = List.generate(
      gameEmojis.length,
      (index) => CardModel(
        id: index,
        content: gameEmojis[index],
        isFlipped: false,
        isMatched: false,
        isEmpty: gameEmojis[index].isEmpty,
      ),
    );

    // Reset game state
    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
    _pairs = 0;
    _moves = 0;
    _gameStarted = false;
    _gameCompleted = false;
    _timeElapsed = '00:00';

    _timer?.cancel();
    _stopwatch = Stopwatch();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final int minutes = _stopwatch.elapsed.inMinutes;
      final int seconds = _stopwatch.elapsed.inSeconds % 60;
      setState(() {
        _timeElapsed =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _flipCard(int index) {
    if (_isProcessing ||
        _cards[index].isFlipped ||
        _cards[index].isMatched ||
        _cards[index].isEmpty) {
      return;
    }

    if (!_gameStarted) {
      _gameStarted = true;
      _startTimer();
    }

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _secondFlippedIndex = index;
      _moves++;
      _isProcessing = true;

      // Check for a match
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _checkForMatch();
        }
      });
    }
  }

  void _checkForMatch() {
    if (_firstFlippedIndex != null && _secondFlippedIndex != null) {
      if (_cards[_firstFlippedIndex!].content ==
          _cards[_secondFlippedIndex!].content) {
        // Match found
        setState(() {
          _cards[_firstFlippedIndex!].isMatched = true;
          _cards[_secondFlippedIndex!].isMatched = true;
          _pairs++;

          // Check if game is completed
          if (_pairs == _totalPairs) {
            _gameCompleted = true;
            _stopwatch.stop();
            _timer?.cancel();
            _gameCompletedController.forward();
          }
        });
      } else {
        // No match
        setState(() {
          _cards[_firstFlippedIndex!].isFlipped = false;
          _cards[_secondFlippedIndex!].isFlipped = false;
        });
      }

      // Reset for next turn
      _firstFlippedIndex = null;
      _secondFlippedIndex = null;
      _isProcessing = false;
    }
  }

  void _restartGame() {
    setState(() {
      _stopwatch.reset();
      if (_gameCompleted) {
        _gameCompletedController.reset();
      }
      _timer?.cancel();
      _initGame(_currentLevel);
    });
  }

  int _getCrossAxisCount() {
    switch (_currentLevel) {
      case GameLevel.easy:
        return 3; // 3x3 grid
      case GameLevel.medium:
        return 4; // 4x4 grid
      case GameLevel.hard:
        return 4; // 4x5 grid
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: Container(
        child: SafeArea(
          child: FluidContainer(
            padding: EdgeInsets.zero,
            child: isLandscape ? _buildLandscapeLayout(l10n) : _buildPortraitLayout(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.memoryGame,
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blueGrey[800]),
                onPressed: _restartGame,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard(l10n.time, _timeElapsed),
              _buildInfoCard(l10n.moves, _moves.toString()),
              _buildInfoCard(l10n.pairs, '$_pairs/$_totalPairs'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _buildGridAndCompletion(l10n),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildGridAndCompletion(l10n),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.memoryGame,
                    style: TextStyle(
                      color: Colors.blueGrey[800],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.blueGrey[800]),
                    onPressed: _restartGame,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(l10n.time, _timeElapsed),
                  _buildInfoCard(l10n.moves, _moves.toString()),
                  _buildInfoCard(l10n.pairs, '$_pairs/$_totalPairs'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridAndCompletion(AppLocalizations l10n) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              return _cards[index].isEmpty
                  ? Container() // Empty space for easy level
                  : _buildCard(
                      _cards[index], () => _flipCard(index));
            },
          ),
        ),
        if (_gameCompleted)
          FadeTransition(
            opacity: _gameCompletedAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.memoryGameCongrats,
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.memoryGameTimeResult,
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timeElapsed,
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.totalMovesLabel(_moves),
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ElevatedButton(
                              onPressed: _restartGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                l10n.playAgain,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () {
                                // Return to level map with completion status
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                l10n.continueText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.blueGrey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(CardModel card, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedFlipCard(
        isFlipped: card.isFlipped,
        isMatched: card.isMatched,
        front: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[300]!, Colors.blue[500]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        back: Container(
          decoration: BoxDecoration(
            color: card.isMatched ? Colors.green[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: card.isMatched
                ? Border.all(color: Colors.green[400]!, width: 2)
                : Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              card.content,
              style: TextStyle(
                fontSize: 32,
                color:
                    card.isMatched ? Colors.green[800] : Colors.blueGrey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedFlipCard extends StatefulWidget {
  const AnimatedFlipCard({
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.isMatched,
    super.key,
  });
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final bool isMatched;

  @override
  State<AnimatedFlipCard> createState() => _AnimatedFlipCardState();
}

class _AnimatedFlipCardState extends State<AnimatedFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontRotation;
  late Animation<double> _backRotation;
  late Animation<double> _matchedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _frontRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(pi / 2),
        weight: 50,
      ),
    ]).animate(_controller);

    _backRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(pi / 2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: pi / 2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _matchedAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }

    if (widget.isMatched && !oldWidget.isMatched) {
      _controller.forward(from: 0.5).then((_) {
        if (widget.isFlipped) {
          _controller.value = 1.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Front
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_frontRotation.value),
              alignment: Alignment.center,
              child: widget.isMatched
                  ? Transform.scale(
                      scale: _matchedAnimation.value,
                      child: widget.front,
                    )
                  : widget.front,
            ),

            // Back
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_backRotation.value),
              alignment: Alignment.center,
              child: widget.back,
            ),
          ],
        );
      },
    );
  }
}

class CardModel {
  CardModel({
    required this.id,
    required this.content,
    required this.isFlipped,
    required this.isMatched,
    this.isEmpty = false,
  });
  final int id;
  final String content;
  bool isFlipped;
  bool isMatched;
  bool isEmpty;
}
