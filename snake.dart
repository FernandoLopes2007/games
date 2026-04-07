import 'dart:io';
import 'dart:async';
import 'dart:math';

class Point {
  int x, y;
  Point(this.x, this.y);
  @override
  bool operator ==(Object other) => other is Point && x == other.x && y == other.y;
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

void main() async {
  try { stdin.lineMode = false; stdin.echoMode = false; } catch (_) {}

  final rand = Random();
  const int w = 30, h = 15;
  
  List<Point> snake = [Point(15, 7), Point(14, 7)];
  Point dir = Point(0, 0);
  Point enemy = Point(0, 0);
  List<Point> fruits = [Point(rand.nextInt(w), rand.nextInt(h))];
  Point? powerUp; // O item raro
  
  int score = 0;
  int combo = 1;
  int berserkTimer = 0; // Se > 0, você pode comer o fantasma!
  int frames = 0;

  stdin.asBroadcastStream().listen((bytes) {
    int k = bytes.last;
    if ((k == 119 || k == 87) && dir.y == 0) dir = Point(0, -1);
    if ((k == 115 || k == 83) && dir.y == 0) dir = Point(0, 1);
    if ((k == 97 || k == 65) && dir.x == 0) dir = Point(-1, 0);
    if ((k == 100 || k == 68) && dir.x == 0) dir = Point(1, 0);
    if (k == 113) { stdout.write('\x1B[0m'); exit(0); }
  });

  Timer.periodic(Duration(milliseconds: 100), (timer) {
    if (dir.x == 0 && dir.y == 0) return;

    frames++;
    if (berserkTimer > 0) berserkTimer--;

    Point head = snake.first;
    Point next = Point((head.x + dir.x) % w, (head.y + dir.y) % h);
    if (next.x < 0) next.x = w - 1; if (next.y < 0) next.y = h - 1;

    // IA do Inimigo (Foge se você estiver em Berserk, Persegue se não)
    if (frames % 2 == 0) {
      bool fugir = berserkTimer > 0;
      if (fugir) {
        if (enemy.x < head.x) enemy.x--; else if (enemy.x > head.x) enemy.x++;
        if (enemy.y < head.y) enemy.y--; else if (enemy.y > head.y) enemy.y++;
      } else {
        if (enemy.x < head.x) enemy.x++; else if (enemy.x > head.x) enemy.x--;
        if (enemy.y < head.y) enemy.y++; else if (enemy.y > head.y) enemy.y--;
      }
      // Garante que o inimigo não saia do mapa ao fugir
      enemy.x = enemy.x.clamp(0, w - 1);
      enemy.y = enemy.y.clamp(0, h - 1);
    }

    // Colisão com o Próprio Corpo
    if (snake.contains(next)) {
      timer.cancel();
      print('\x1B[31m\n  GAME OVER: VOCÊ SE ATROPELOU!\x1B[0m');
      exit(0);
    }

    // Colisão com Inimigo
    if (next == enemy) {
      if (berserkTimer > 0) {
        score += 100; // PONTUAÇÃO GORDA
        enemy = Point(rand.nextInt(w), rand.nextInt(h)); // Respawn inimigo
        berserkTimer = 0; // Acaba o efeito
      } else {
        timer.cancel();
        print('\x1B[31m\n  GAME OVER: O FANTASMA TE PEGOU!\x1B[0m');
        exit(0);
      }
    }

    snake.insert(0, next);

    // Lógica de Power-up (Nasce a cada 200 frames)
    if (frames % 200 == 0) powerUp = Point(rand.nextInt(w), rand.nextInt(h));
    if (next == powerUp) {
      berserkTimer = 50; // 5 segundos de poder (50 frames * 100ms)
      powerUp = null;
    }

    // Lógica de Frutas
    bool comeu = false;
    for (int i = 0; i < fruits.length; i++) {
      if (next == fruits[i]) {
        score += 10 * combo;
        fruits.removeAt(i);
        fruits.add(Point(rand.nextInt(w), rand.nextInt(h)));
        comeu = true; break;
      }
    }
    if (!comeu) snake.removeLast();

    // --- RENDERIZADOR ---
    var buf = StringBuffer('\x1B[H');
    String colorBorda = berserkTimer > 0 ? '\x1B[38;2;255;255;0m' : '\x1B[38;2;0;255;255m';
    
    buf.writeln('$colorBorda╔${'═' * (w * 2)}╗$reset');
    buf.writeln('$colorBorda║$reset SCORE: $score | ${berserkTimer > 0 ? '🔥 BERSERK: $berserkTimer' : 'STATUS: NORMAL'} ${' ' * 5}$colorBorda║$reset');
    buf.writeln('$colorBorda╠${'═' * (w * 2)}╣$reset');

    for (int y = 0; y < h; y++) {
      buf.write('$colorBorda║$reset');
      for (int x = 0; x < w; x++) {
        Point p = Point(x, y);
        if (p == next) buf.write(berserkTimer > 0 ? '\x1B[33m██$reset' : '\x1B[32m██$reset');
        else if (snake.contains(p)) buf.write(berserkTimer > 0 ? '\x1B[33m▒▒$reset' : '\x1B[32m▒▒$reset');
        else if (p == enemy) buf.write(berserkTimer > 0 ? '\x1B[34m😱$reset' : '\x1B[31m👾$reset');
        else if (p == powerUp) buf.write('\x1B[35m⚡$reset');
        else if (fruits.contains(p)) buf.write('\x1B[31m🍎$reset');
        else buf.write('\x1B[38;2;40;40;40m. $reset');
      }
      buf.writeln('$colorBorda║$reset');
    }
    buf.writeln('$colorBorda╚${'═' * (w * 2)}╝$reset');
    stdout.write(buf.toString());
  });
}

const String reset = '\x1B[0m';
