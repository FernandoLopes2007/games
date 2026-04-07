import 'dart:io';
import 'dart:async';
import 'dart:math';

void main() {
  const int width = 40;
  const int height = 15;
  final random = Random();
  
  double ballX = width / 2;
  double ballY = height / 2;
  double ballDirX = 0.8; 
  double ballDirY = 0.4;

  int paddleHeight = 3;
  int leftPaddleY = height ~/ 2 - 1; // Você (W/S)
  double rightPaddleY = (height / 2) - 1; // Bot

  int scoreLeft = 0;
  int scoreRight = 0;

  // Configuração do Terminal
  stdin.echoMode = false;
  stdin.lineMode = false;

  // ESCUTA AS TECLAS W E S
  stdin.listen((List<int> codes) {
    if (codes.isEmpty) return;
    var key = codes.first;
    
    // 119 = 'w', 115 = 's'
    if (key == 119 && leftPaddleY > 0) leftPaddleY--; 
    if (key == 115 && leftPaddleY < height - paddleHeight) leftPaddleY++; 
    
    // 113 = 'q' para sair
    if (key == 113) {
      stdout.write('\x1B[?25h'); // Devolve o cursor ao sistema
      exit(0);
    }
  });

  // Esconde o cursor
  stdout.write('\x1B[?25l');

  Timer.periodic(Duration(milliseconds: 33), (timer) {
    // --- Lógica do Bot (Lado Direito) ---
    double paddleCenter = rightPaddleY + (paddleHeight / 2);
    if (ballX > width / 2) {
      bool confundiu = random.nextDouble() > 0.90; // 10% de chance de errar
      double speed = confundiu ? -0.15 : 0.22; 

      if (paddleCenter < ballY && rightPaddleY < height - paddleHeight) {
        rightPaddleY += speed;
      } else if (paddleCenter > ballY && rightPaddleY > 0) {
        rightPaddleY -= speed;
      }
    }

    // --- Física da Bola ---
    ballX += ballDirX;
    ballY += ballDirY;

    // Colisão teto/chão
    if (ballY <= 0 || ballY >= height - 1) ballDirY *= -1;

    // Colisão Paddle Esquerdo (VOCÊ)
    if (ballX.round() <= 1 && ballY.round() >= leftPaddleY && ballY.round() < leftPaddleY + paddleHeight) {
      ballDirX *= -1.05;
      ballX = 1.1;
    }
    
    // Colisão Paddle Direito (BOT)
    if (ballX.round() >= width - 2 && ballY.round() >= rightPaddleY.round() && ballY.round() < rightPaddleY.round() + paddleHeight) {
      ballDirX *= -1.05;
      ballX = (width - 2.1);
    }

    // Pontuação
    if (ballX <= 0) {
      scoreRight++;
      ballX = width / 2; ballDirX = 0.8;
    } else if (ballX >= width) {
      scoreLeft++;
      ballX = width / 2; ballDirX = -0.8;
    }

    render(width, height, ballX.round(), ballY.round(), leftPaddleY, rightPaddleY.round(), paddleHeight, scoreLeft, scoreRight);
  });
}

void render(int w, int h, int bx, int by, int lp, int rp, int ph, int sl, int sr) {
  StringBuffer buffer = StringBuffer();
  buffer.write('\x1B[H'); // Move cursor para o início
  
  buffer.writeln('--- PING PONG DART ---');
  buffer.writeln('VOCÊ: $sl  |  BOT: $sr');
  buffer.writeln('+' + '-' * w + '+');

  for (int y = 0; y < h; y++) {
    buffer.write('|');
    for (int x = 0; x < w; x++) {
      if (x == bx && y == by) {
        buffer.write('O'); 
      } else if (x == 0 && y >= lp && y < lp + ph) {
        buffer.write('█'); // Seu paddle
      } else if (x == w - 1 && y >= rp && y < rp + ph) {
        buffer.write('▒'); // Paddle do bot
      } else {
        buffer.write(' ');
      }
    }
    buffer.writeln('|');
  }

  buffer.writeln('+' + '-' * w + '+');
  buffer.writeln('Use W e S para mover | Q para Sair');
  stdout.write(buffer.toString());
}
