import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum GameLevel {
  easy,
  medium,
  hard,
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
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
  GameLevel _currentLevel = GameLevel.easy;

  // Timer variables
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _timeElapsed = '00:00';

  // Animation controllers
  late AnimationController _gameCompletedController;
  late Animation<double> _gameCompletedAnimation;

  @override
  void initState() {
    super.initState();
    _gameCompletedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gameCompletedAnimation = CurvedAnimation(
      parent: _gameCompletedController,
      curve: Curves.easeInOut,
    );
    _initGame(_currentLevel);
  }

  @override
  void dispose() {
    _timer.cancel();
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
    List<String> gameEmojis = [];
    List<String> shuffledEmojis = List.from(_allEmojis)..shuffle();

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

    if (_gameStarted) {
      _timer.cancel();
    }
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
        _checkForMatch();
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
            _timer.cancel();
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
      } else if (_gameStarted) {
        _timer.cancel();
      }
      _initGame(_currentLevel);
    });
  }

  void _changeLevel(GameLevel level) {
    setState(() {
      _stopwatch.reset();
      if (_gameCompleted) {
        _gameCompletedController.reset();
      } else if (_gameStarted) {
        _timer.cancel();
      }
      _initGame(level);
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

  int _getMainAxisCount() {
    switch (_currentLevel) {
      case GameLevel.easy:
        return 3; // 3x3 grid
      case GameLevel.medium:
        return 4; // 4x4 grid
      case GameLevel.hard:
        return 5; // 4x5 grid
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F8FF), Color(0xFFE6F2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Memory Game',
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
              // Level selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLevelButton('Easy', GameLevel.easy),
                    const SizedBox(width: 12),
                    _buildLevelButton('Medium', GameLevel.medium),
                    const SizedBox(width: 12),
                    _buildLevelButton('Hard', GameLevel.hard),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Game stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard('Time', _timeElapsed),
                    _buildInfoCard('Moves', _moves.toString()),
                    _buildInfoCard('Pairs', '$_pairs/$_totalPairs'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                          mainAxisExtent: (MediaQuery.of(context).size.width -
                                  (16 + (_getCrossAxisCount() - 1) * 8)) /
                              _getCrossAxisCount(),
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
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🎉 Congratulations! 🎉',
                                  style: TextStyle(
                                    color: Colors.blueGrey[800],
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'You completed the game in:',
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
                                  'Total Moves: $_moves',
                                  style: TextStyle(
                                    color: Colors.blueGrey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _restartGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[400],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Play Again',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        GameLevel nextLevel;
                                        switch (_currentLevel) {
                                          case GameLevel.easy:
                                            nextLevel = GameLevel.medium;
                                            break;
                                          case GameLevel.medium:
                                            nextLevel = GameLevel.hard;
                                            break;
                                          case GameLevel.hard:
                                            nextLevel = GameLevel.easy;
                                            break;
                                        }
                                        _changeLevel(nextLevel);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[400],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Next Level',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(String label, GameLevel level) {
    final bool isSelected = _currentLevel == level;

    return ElevatedButton(
      onPressed: () => _changeLevel(level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[400] : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.blue[400],
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: Colors.blue[400]!,
            width: 1,
          ),
        ),
      ),
      child: Text(label),
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
            color: Colors.blue.withOpacity(0.1),
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
                color: Colors.black.withOpacity(0.1),
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
                : Border.all(color: Colors.blue[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final bool isMatched;

  const AnimatedFlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.isMatched,
  });

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
  final int id;
  final String content;
  bool isFlipped;
  bool isMatched;
  bool isEmpty;

  CardModel({
    required this.id,
    required this.content,
    required this.isFlipped,
    required this.isMatched,
    this.isEmpty = false,
  });
}
