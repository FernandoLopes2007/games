import 'dart:io';
import 'dart:async';
import 'dart:math';

// Variáveis Globais de Estado
const int width = 40;
const int height = 20;
final random = Random();

int paddleWidth = 10;
double paddleX = (width / 2) - (paddleWidth / 2);
const int paddleY = height - 2;

double ballX = width / 2;
double ballY = height - 5;
double ballDirX = 0.3;
double ballDirY = -0.3;

List<List<int>> bricks = [];
List<Map<String, double>> powerUps = [];
int powerTimer = 0;
int score = 0;
bool isGameOver = false;
Timer? gameTimer;

void main() {
  // Configuração inicial do terminal
  stdin.echoMode = false;
  stdin.lineMode = false;
  stdout.write('\x1B[?25l'); // Esconde cursor

  resetGame();

  // Escuta o teclado globalmente
  stdin.listen((List<int> codes) {
    if (codes.isEmpty) return;
    var key = codes.first;

    if (isGameOver) {
      if (key == 114 || key == 82) { // 'r' ou 'R'
        resetGame();
      } else if (key == 113 || key == 81) { // 'q' ou 'Q'
        exitGame();
      }
    } else {
      if ((key == 119 || key == 97) && paddleX > 1) paddleX -= 3; 
      if ((key == 115 || key == 100) && paddleX < width - paddleWidth - 1) paddleX += 3;
      if (key == 113) exitGame();
    }
  });
}

void resetGame() {
  // Reinicia todas as variáveis
  paddleWidth = 10;
  paddleX = (width / 2) - (paddleWidth / 2);
  ballX = width / 2;
  ballY = height - 5;
  ballDirX = 0.3;
  ballDirY = -0.3;
  score = 0;
  powerTimer = 0;
  powerUps = [];
  isGameOver = false;

  // Recria os blocos
  bricks = List.generate(5, (y) => List.generate(width, (x) => 1));

  // Inicia ou Reinicia o Timer
  gameTimer?.cancel();
  gameTimer = Timer.periodic(Duration(milliseconds: 40), (t) => updateGame());
}

void exitGame() {
  stdout.write('\x1B[?25h\x1B[0m\x1B[2J\x1B[H'); // Mostra cursor e limpa tudo
  print('Valeu por jogar! Até a próxima.');
  exit(0);
}

void updateGame() {
  if (isGameOver) return;

  ballX += ballDirX;
  ballY += ballDirY;

  // Colisões Paredes
  if (ballX <= 0 || ballX >= width - 1) ballDirX *= -1;
  if (ballY <= 0) ballDirY *= -1;

  // Colisão Blocos
  int gridY = ballY.round();
  int gridX = ballX.round();
  if (gridY >= 0 && gridY < bricks.length && gridX >= 0 && gridX < width) {
    if (bricks[gridY][gridX] > 0) {
      bricks[gridY][gridX] = 0;
      ballDirY *= -1;
      score += 15;
      if (random.nextDouble() > 0.88) {
        powerUps.add({'x': gridX.toDouble(), 'y': gridY.toDouble()});
      }
    }
  }

  // Lógica Power-ups
  for (var i = powerUps.length - 1; i >= 0; i--) {
    powerUps[i]['y'] = powerUps[i]['y']! + 0.2;
    if (powerUps[i]['y']!.round() == paddleY && 
        powerUps[i]['x']!.round() >= paddleX && 
        powerUps[i]['x']!.round() < paddleX + paddleWidth) {
      paddleWidth = 18;
      powerTimer = 150;
      powerUps.removeAt(i);
    } else if (powerUps[i]['y']! >= height) {
      powerUps.removeAt(i);
    }
  }

  if (powerTimer > 0) {
    powerTimer--;
    if (powerTimer == 0) paddleWidth = 10;
  }

  // Colisão Barra
  if (ballY.round() == paddleY && ballX.round() >= paddleX && ballX.round() < paddleX + paddleWidth) {
    ballDirY = -0.35;
    ballDirX += (ballX - (paddleX + paddleWidth / 2)) * 0.1;
  }

  // Verificar Perda
  if (ballY >= height) {
    isGameOver = true;
  }

  render();
}

void render() {
  StringBuffer buffer = StringBuffer();
  buffer.write('\x1B[H'); 
  
  String status = isGameOver ? '\x1B[1;31m GAME OVER! \x1B[0m' : '\x1B[1;36m BREAKOUT \x1B[0m';
  buffer.writeln('$status \x1B[1;33m SCORE: $score \x1B[0m');
  buffer.writeln('\x1B[34m╔' + '═' * width + '╗\x1B[0m');

  for (int y = 0; y < height; y++) {
    buffer.write('\x1B[34m║\x1B[0m');
    for (int x = 0; x < width; x++) {
      if (x == ballX.round() && y == ballY.round() && !isGameOver) {
        buffer.write('\x1B[1;33m●\x1B[0m');
      } else if (powerUps.any((p) => p['x']!.round() == x && p['y']!.round() == y)) {
        buffer.write('\x1B[1;35mP\x1B[0m');
      } else if (y < bricks.length && bricks[y][x] > 0) {
        buffer.write(y < 2 ? '\x1B[31m#\x1B[0m' : '\x1B[32m#\x1B[0m');
      } else if (y == paddleY && x >= paddleX.round() && x < paddleX.round() + paddleWidth) {
        buffer.write(powerTimer > 0 ? '\x1B[1;32m█\x1B[0m' : '\x1B[1;36m═\x1B[0m');
      } else {
        buffer.write(' ');
      }
    }
    buffer.writeln('\x1B[34m║\x1B[0m');
  }

  buffer.writeln('\x1B[34m╚' + '═' * width + '╝\x1B[0m');
  
  if (isGameOver) {
    buffer.writeln('\x1B[1;37m  PRESSIONE [R] PARA RECOMEÇAR OU [Q] SAIR \x1B[0m');
  } else {
    buffer.writeln('\x1B[90m [W] ESQ  [S] DIR  [Q] SAIR \x1B[0m');
  }
  
  stdout.write(buffer.toString());
}
