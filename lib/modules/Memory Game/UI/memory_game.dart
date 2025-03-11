import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  final int _numPairs = 8; // 16 cards total
  final List<String> _emojis = [
    '🦄',
    '🌈',
    '🚀',
    '🌮',
    '🎮',
    '🍕',
    '🏆',
    '🎨',
    '🦄',
    '🌈',
    '🚀',
    '🌮',
    '🎮',
    '🍕',
    '🏆',
    '🎨',
  ];

  late List<CardModel> _cards;
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  int _pairs = 0;
  int _moves = 0;
  bool _isProcessing = false;
  bool _gameStarted = false;
  bool _gameCompleted = false;
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _timeElapsed = '00:00';
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
    _initGame();
  }

  @override
  void dispose() {
    _timer.cancel();
    _gameCompletedController.dispose();
    super.dispose();
  }

  void _initGame() {
    // Make a copy of emojis and shuffle them
    _emojis.shuffle();

    // Create card models with matching pairs
    _cards = List.generate(
      _emojis.length,
      (index) => CardModel(
        id: index,
        content: _emojis[index],
        isFlipped: false,
        isMatched: false,
      ),
    );

    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
    _pairs = 0;
    _moves = 0;
    _gameStarted = false;
    _gameCompleted = false;
    _timeElapsed = '00:00';
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
    if (_isProcessing || _cards[index].isFlipped || _cards[index].isMatched) {
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
          if (_pairs == _numPairs) {
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
      } else {
        _timer.cancel();
      }
      _initGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
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
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
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
                    _buildInfoCard('Time', _timeElapsed),
                    _buildInfoCard('Moves', _moves.toString()),
                    _buildInfoCard('Pairs', '$_pairs/$_numPairs'),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (context, index) {
                          return _buildCard(
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
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🎉 Congratulations! 🎉',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'You completed the game in:',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _timeElapsed,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Moves: $_moves',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _restartGame,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Play Again',
                                    style: TextStyle(fontSize: 18),
                                  ),
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

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
            color: card.isMatched
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                color: card.isMatched
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black87,
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

  CardModel({
    required this.id,
    required this.content,
    required this.isFlipped,
    required this.isMatched,
  });
}
