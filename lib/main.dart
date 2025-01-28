import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(PongGame());

class PongGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NameInputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NameInputScreen extends StatefulWidget {
  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController nameController = TextEditingController();

  void startGame() {
    if (nameController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PongScreen(playerName: nameController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Insira seu nome",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Seu nome",
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startGame,
              child: Text("Começar"),
            ),
          ],
        ),
      ),
    );
  }
}

class PongScreen extends StatefulWidget {
  final String playerName;

  PongScreen({required this.playerName});

  @override
  _PongScreenState createState() => _PongScreenState();
}

class _PongScreenState extends State<PongScreen> {
  late double ballX = 0.0;
  late double ballY = 0.0;
  double ballXDirection = 1;
  double ballYDirection = 1;
  double ballSpeed = 0.01;
  late double batWidth;
  final double batHeight = 20;
  double playerBatPosition = 0.0;
  double opponentBatPosition = 0.0;
  Timer? timer;
  bool isPlaying = false;
  int playerScore = 0;
  int opponentScore = 0;
  List<Offset> obstacles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    timer?.cancel();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          playerBatPosition -= 0.1;
          if (playerBatPosition < -1) playerBatPosition = -1;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          playerBatPosition += 0.1;
          if (playerBatPosition > 1) playerBatPosition = 1;
        }
      });
    }
  }

  void startGame() {
    if (!isPlaying) {
      isPlaying = true;
      timer = Timer.periodic(Duration(milliseconds: 16), (Timer timer) {
        updateBallPosition();
        updateOpponentPosition();
      });
    }
  }

  void pauseGame() {
    if (isPlaying) {
      isPlaying = false;
      timer?.cancel();
    }
  }

  void updateBallPosition() {
    setState(() {
      ballX += ballSpeed * ballXDirection;
      ballY += ballSpeed * ballYDirection;

      // Detect collision with walls
      if (ballX <= -1 || ballX >= 1) {
        ballXDirection *= -1;
      }

      // Detect collision with player's bat
      final double batHalfWidth = batWidth / MediaQuery.of(context).size.width;
      if (ballY >= 0.9 &&
          ballY <= 0.95 &&
          ballX >= playerBatPosition - batHalfWidth &&
          ballX <= playerBatPosition + batHalfWidth &&
          ballYDirection > 0) {
        ballYDirection *= -1;
        ballY = 0.89; // Ensure ball bounces just above the bat
      }

      // Detect collision with opponent's bat
      if (ballY <= -0.9 &&
          ballY >= -0.95 &&
          ballX >= opponentBatPosition - batHalfWidth &&
          ballX <= opponentBatPosition + batHalfWidth &&
          ballYDirection < 0) {
        ballYDirection *= -1;
        ballY = -0.89; // Ensure ball bounces just below the bat
      }

      // Detect collision with obstacles
      obstacles.removeWhere((obstacle) {
        if ((ballX - obstacle.dx).abs() < 0.05 &&
            (ballY - obstacle.dy).abs() < 0.05) {
          ballXDirection *= -1;
          ballYDirection *= -1;
          return true;
        }
        return false;
      });

      // Update score if ball passes beyond the player's or opponent's bat
      if (ballY >= 1) {
        opponentScore++;
        checkDifficulty();
        resetBallPosition(false);
      } else if (ballY <= -1) {
        playerScore++;
        checkDifficulty();
        resetBallPosition(false);
      }
    });
  }

  void updateOpponentPosition() {
    setState(() {
      if (opponentBatPosition < ballX) {
        opponentBatPosition += 0.03; // Adjust speed for smooth movement
      } else if (opponentBatPosition > ballX) {
        opponentBatPosition -= 0.03;
      }

      if (opponentBatPosition < -1) opponentBatPosition = -1;
      if (opponentBatPosition > 1) opponentBatPosition = 1;
    });
  }

  void resetBallPosition(bool restart) {
    ballX = 0.0;
    ballY = 0.0;
    ballXDirection = random.nextBool() ? 1 : -1;
    ballYDirection = random.nextBool() ? 1 : -1;
  }

  void checkDifficulty() {
    // Increase speed and generate obstacles every 3 points
    if ((playerScore + opponentScore) % 3 == 0) {
      ballSpeed += 0.005; // Accelerate ball
      generateObstacles();
    }
  }

  void generateObstacles() {
    obstacles = List.generate(5, (index) {
      double x = random.nextDouble() * 2 - 1;
      double y = random.nextDouble() * 1.6 - 0.8;
      return Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double gameWidth = MediaQuery.of(context).size.width * 0.8;
    final double gameHeight = MediaQuery.of(context).size.height * 0.8;
    batWidth = gameWidth * 0.25;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Score Display
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '${widget.playerName}: $playerScore   Oponente: $opponentScore',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Container(
              width: gameWidth,
              height: gameHeight,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Stack(
                children: [
                  // Ball
                  Align(
                    alignment: Alignment(ballX, ballY),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Obstacles
                  ...obstacles.map((obstacle) => Align(
                        alignment: Alignment(obstacle.dx, obstacle.dy),
                        child: Container(
                          width: 30,
                          height: 30,
                          color: Colors.red,
                        ),
                      )),

                  // Player's Bat
                  Align(
                    alignment: Alignment(playerBatPosition, 0.95),
                    child: Container(
                      width: batWidth,
                      height: batHeight,
                      color: Colors.white,
                    ),
                  ),

                  // Opponent's Bat
                  Align(
                    alignment: Alignment(opponentBatPosition, -0.95),
                    child: Container(
                      width: batWidth,
                      height: batHeight,
                      color: Colors.white,
                    ),
                  ),

                  // Start and Pause Buttons
                  Align(
                    alignment: Alignment(0, 0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: startGame,
                          child: Text("Iniciar"),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: pauseGame,
                          child: Text("Pausar"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
