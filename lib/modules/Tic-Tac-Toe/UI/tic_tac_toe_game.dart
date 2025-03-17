import 'package:flutter/material.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  TicTacToeGameState createState() => TicTacToeGameState();
}

class TicTacToeGameState extends State<TicTacToeGame> with TickerProviderStateMixin {
  // Game state
  List<List<String>> board = List.generate(3, (_) => List.filled(3, ''));
  bool xTurn = true;
  String gameStatus = 'Player X\'s Turn';
  int xScore = 0;
  int oScore = 0;
  int drawScore = 0;
  
  // Animation controllers
  late AnimationController _boardController;
  late AnimationController _winController;
  late AnimationController _symbolController;
  List<List<AnimationController>> cellControllers = [];
  
  // Animations
  late Animation<double> _boardAnimation;
  late Animation<double> _winAnimation;
  late Animation<double> symbolAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize board animation
    _boardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _boardAnimation = CurvedAnimation(
      parent: _boardController,
      curve: Curves.easeOutBack,
    );
    
    // Initialize win animation
    _winController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _winAnimation = CurvedAnimation(
      parent: _winController,
      curve: Curves.elasticOut,
    );
    
    // Initialize symbol animation
    _symbolController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    symbolAnimation = CurvedAnimation(
      parent: _symbolController,
      curve: Curves.easeOutCubic,
    );
    
    // Initialize cell controllers
    for (int i = 0; i < 3; i++) {
      List<AnimationController> row = [];
      for (int j = 0; j < 3; j++) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        );
        row.add(controller);
      }
      cellControllers.add(row);
    }
    
    // Start initial animation
    _boardController.forward();
  }
  
  @override
  void dispose() {
    _boardController.dispose();
    _winController.dispose();
    _symbolController.dispose();
    
    for (var row in cellControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    
    super.dispose();
  }
  
  void resetGame() {
    setState(() {
      board = List.generate(3, (_) => List.filled(3, ''));
      xTurn = true;
      gameStatus = 'Player X\'s Turn';
      
      // Reset cell animations
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          cellControllers[i][j].reset();
        }
      }
      
      _winController.reset();
      _symbolController.reset();
    });
  }
  
  void makeMove(int row, int col) {
    if (board[row][col] != '' || checkWinner() != null) {
      return;
    }
    
    setState(() {
      board[row][col] = xTurn ? 'X' : 'O';
      cellControllers[row][col].forward();
      
      String? winner = checkWinner();
      if (winner != null) {
        if (winner == 'X') {
          gameStatus = 'Player X Wins!';
          xScore++;
          _winController.forward();
        } else if (winner == 'O') {
          gameStatus = 'Player O Wins!';
          oScore++;
          _winController.forward();
        } else {
          gameStatus = 'It\'s a Draw!';
          drawScore++;
        }
      } else {
        xTurn = !xTurn;
        gameStatus = xTurn ? 'Player X\'s Turn' : 'Player O\'s Turn';
      }
    });
  }
  
  String? checkWinner() {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (board[i][0] != '' && board[i][0] == board[i][1] && board[i][1] == board[i][2]) {
        return board[i][0];
      }
    }
    
    // Check columns
    for (int j = 0; j < 3; j++) {
      if (board[0][j] != '' && board[0][j] == board[1][j] && board[1][j] == board[2][j]) {
        return board[0][j];
      }
    }
    
    // Check diagonals
    if (board[0][0] != '' && board[0][0] == board[1][1] && board[1][1] == board[2][2]) {
      return board[0][0];
    }
    
    if (board[0][2] != '' && board[0][2] == board[1][1] && board[1][1] == board[2][0]) {
      return board[0][2];
    }
    
    // Check for draw
    bool boardFull = true;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          boardFull = false;
          break;
        }
      }
    }
    
    if (boardFull) {
      return 'Draw';
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // Determine cell size based on screen dimensions
    final cellSize = isLandscape
        ? (screenHeight * 0.22).clamp(60.0, 100.0)
        : (screenWidth * 0.25).clamp(60.0, 100.0);
    
    // Calculate font sizes based on screen size
    final titleFontSize = (screenWidth * 0.07).clamp(18.0, 32.0);
    final statusFontSize = (screenWidth * 0.05).clamp(16.0, 24.0);
    final scoreFontSize = (screenWidth * 0.04).clamp(14.0, 20.0);
    final scoreValueFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(
                cellSize, 
                titleFontSize, 
                statusFontSize, 
                scoreFontSize, 
                scoreValueFontSize
              )
            : _buildPortraitLayout(
                cellSize, 
                titleFontSize, 
                statusFontSize, 
                scoreFontSize, 
                scoreValueFontSize
              ),
      ),
    );
  }
  
  Widget _buildPortraitLayout(
    double cellSize,
    double titleFontSize,
    double statusFontSize,
    double scoreFontSize,
    double scoreValueFontSize,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game Title with Glow
              _buildGameTitle(titleFontSize),
              SizedBox(height: cellSize * 0.2),
              
              // Score Board
              _buildScoreBoard(scoreFontSize, scoreValueFontSize),
              SizedBox(height: cellSize * 0.2),
              
              // Game Status
              _buildGameStatus(statusFontSize),
              SizedBox(height: cellSize * 0.3),
              
              // Game Board
              _buildGameBoard(cellSize),
              SizedBox(height: cellSize * 0.4),
              
              // Reset Button
              _buildResetButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLandscapeLayout(
    double cellSize,
    double titleFontSize,
    double statusFontSize,
    double scoreFontSize,
    double scoreValueFontSize,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column with Game Board
              Expanded(
                flex: 5,
                child: _buildGameBoard(cellSize),
              ),
              
              const SizedBox(width: 16),
              
              // Right Column with Controls and Info
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGameTitle(titleFontSize * 0.8),
                    SizedBox(height: cellSize * 0.15),
                    _buildScoreBoard(scoreFontSize, scoreValueFontSize),
                    SizedBox(height: cellSize * 0.15),
                    _buildGameStatus(statusFontSize),
                    SizedBox(height: cellSize * 0.2),
                    _buildResetButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameTitle(double fontSize) {
    return Text(
      'EPIC TIC TAC TOE',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildScoreBoard(double textSize, double valueSize) {
    return AnimatedBuilder(
      animation: _winAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_winAnimation.value * 0.1),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: textSize * 0.5,
              horizontal: textSize * 1.0,
            ),
            margin: EdgeInsets.symmetric(horizontal: textSize * 0.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreColumn('Player X', xScore, Colors.red, textSize, valueSize),
                _buildScoreColumn('Draws', drawScore, Colors.grey, textSize, valueSize),
                _buildScoreColumn('Player O', oScore, Colors.blue, textSize, valueSize),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGameStatus(double fontSize) {
    return Text(
      gameStatus,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: gameStatus.contains('X') 
          ? Colors.red 
          : gameStatus.contains('O') 
            ? Colors.blue 
            : Colors.black,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildGameBoard(double cellSize) {
    return Center(
      child: AnimatedBuilder(
        animation: _boardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _boardAnimation.value,
            child: Container(
              padding: EdgeInsets.all(cellSize * 0.12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cellSize * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (col) {
                      return _buildCell(row, col, cellSize);
                    }),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: resetGame,
      icon: const Icon(Icons.refresh),
      label: const Text('New Game'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
      ),
    );
  }
  
  Widget _buildScoreColumn(String label, int score, Color color, double textSize, double valueSize) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: textSize * 0.3),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCell(int row, int col, double cellSize) {
    final symbolSize = cellSize * 0.6;
    
    return AnimatedBuilder(
      animation: cellControllers[row][col],
      builder: (context, child) {
        return GestureDetector(
          onTap: () => makeMove(row, col),
          child: Container(
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.all(cellSize * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cellSize * 0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: board[row][col] != '' 
                ? Transform.scale(
                    scale: cellControllers[row][col].value,
                    child: _buildSymbol(board[row][col], Size(symbolSize, symbolSize)),
                  )
                : null,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSymbol(String symbol, Size size) {
    if (symbol == 'X') {
      return CustomPaint(
        size: size,
        painter: XPainter(),
      );
    } else {
      return CustomPaint(
        size: size,
        painter: OPainter(),
      );
    }
  }
}

class XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        colors: [Colors.red, Colors.orange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        colors: [Colors.blue, Colors.cyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}