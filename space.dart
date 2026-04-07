import 'dart:io';
import 'dart:async';
import 'dart:math';

class Entity {
  int x, y;
  Entity(this.x, this.y);
}

void main() async {
  try { stdin.lineMode = false; stdin.echoMode = false; } catch (_) {}

  final rand = Random();
  const int w = 50;
  const int h = 20;
  
  int terraHP = 100;
  int score = 0;
  int frames = 0;
  bool vivo = true;
  
  Entity player = Entity(w ~/ 2, h - 2);
  List<Entity> bullets = [];
  List<Entity> enemies = [];
  List<Entity> enemyBullets = [];

  Timer? gameTimer;

  void start() {
    terraHP = 100; score = 0; frames = 0; vivo = true;
    player = Entity(w ~/ 2, h - 2);
    bullets.clear(); enemies.clear(); enemyBullets.clear();
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (!vivo) return;
      frames++;

      // 1. Movimento Tiros Player (Rápido)
      for (var b in bullets) b.y--;
      bullets.removeWhere((b) => b.y < -1);

      // 2. Spawn Inimigos (Bem espaçado agora)
      if (frames % 35 == 0) enemies.add(Entity(rand.nextInt(w - 4) + 2, 0));
      
      // 3. Movimento Inimigos (Lentos e fáceis)
      if (frames % 15 == 0) {
        for (var e in enemies) {
          e.y++;
          if (rand.nextInt(100) > 95) enemyBullets.add(Entity(e.x, e.y + 1));
        }
      }

      // 4. COLISÃO NINJA (O segredo pra não serem imortais)
      for (var b in List.from(bullets)) {
        for (var e in List.from(enemies)) {
          // Checa se o X bate e se o Y está no mesmo ponto ou um acima (compensando o lag)
          if (b.x == e.x && (b.y == e.y || b.y == e.y - 1)) {
            enemies.remove(e);
            bullets.remove(b);
            score += 100; // Pontos pra valer
            break;
          }
        }
      }

      // 5. Invasão da Terra
      enemies.removeWhere((e) {
        if (e.y >= h - 1) { terraHP -= 5; return true; }
        return false;
      });

      // 6. Tiros Inimigos
      for (var eb in enemyBullets) eb.y++;
      enemyBullets.removeWhere((eb) => eb.y >= h);

      // 7. Dano no Player
      for (var eb in enemyBullets) {
        if (eb.x == player.x && eb.y == player.y) terraHP -= 2;
      }

      if (terraHP <= 0) { terraHP = 0; vivo = false; timer.cancel(); }

      // --- RENDERIZADOR ---
      var buf = StringBuffer('\x1B[H');
      buf.writeln('\x1B[36m╔${'═' * w}╗\x1B[0m');
      buf.writeln('\x1B[36m║\x1B[37m TERRA HP: \x1B[32m$terraHP%\x1B[37m | SCORE: $score | [R] RESET \x1B[36m║\x1B[0m');
      buf.writeln('\x1B[36m╠${'═' * w}╣\x1B[0m');

      for (int y = 0; y < h; y++) {
        buf.write('\x1B[36m║\x1B[0m');
        for (int x = 0; x < w; x++) {
          bool d = false;
          if (x == player.x && y == player.y) {
            buf.write('\x1B[32m▲\x1B[0m'); d = true;
          } else {
            // Desenha Inimigos
            for (var e in enemies) if (e.x == x && e.y == y) { buf.write('\x1B[31m🛸\x1B[0m'); d = true; break; }
            // Desenha Tiros Player
            if (!d) for (var b in bullets) if (b.x == x && b.y == y) { buf.write('\x1B[33m⚡\x1B[0m'); d = true; break; }
            // Desenha Tiros Inimigos
            if (!d) for (var eb in enemyBullets) if (eb.x == x && eb.y == y) { buf.write('\x1B[31m!\x1B[0m'); d = true; break; }
          }
          if (!d) buf.write(' ');
        }
        buf.writeln('\x1B[36m║\x1B[0m');
      }
      buf.writeln('\x1B[36m╚${'═' * w}╝\x1B[0m');
      if (!vivo) buf.writeln('\x1B[31m   💥 FIM DA LINHA! [R] PARA RECOMEÇAR \x1B[0m');
      stdout.write(buf.toString());
    });
  }

  stdin.asBroadcastStream().listen((bytes) {
    int k = bytes.last;
    if ((k == 97 || k == 65) && player.x > 2) player.x -= 2;
    if ((k == 100 || k == 68) && player.x < w - 3) player.x += 2;
    if (k == 32 && vivo) bullets.add(Entity(player.x, player.y - 1));
    if (k == 114 || k == 82) start();
    if (k == 113) { stdout.write('\x1B[0m'); exit(0); }
  });

  start();
}
