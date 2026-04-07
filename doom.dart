import 'dart:io';
import 'dart:async';
import 'dart:math';

void main() {
  const int mapSize = 16;
  const map = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
    [1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  const screenW = 100; 
  const screenH = 25;

  double px = 2.0, py = 2.0, pa = 0.0;
  const fov = pi / 3.0;
  
  List<Map<String, dynamic>> enemies = [
    {'x': 14.0, 'y': 2.0, 'hp': 1},
    {'x': 14.0, 'y': 14.0, 'hp': 1},
    {'x': 2.0, 'y': 14.0, 'hp': 1},
    {'x': 8.0, 'y': 8.0, 'hp': 1},
    {'x': 5.0, 'y': 10.0, 'hp': 1},
  ];
  List<Map<String, dynamic>> bullets = [];

  int score = 0;
  bool firing = false;

  stdin.echoMode = false;
  stdin.lineMode = false;
  stdout.write('\x1B[?25l');

  stdin.listen((List<int> codes) {
    if (codes.isEmpty) return;
    var k = codes.first;
    double move = 0.4;
    if (k == 119) { // W
      double nx = px + cos(pa) * move; double ny = py + sin(pa) * move;
      if (map[nx.toInt()][ny.toInt()] == 0) { px = nx; py = ny; }
    }
    if (k == 115) { // S
      double nx = px - cos(pa) * move; double ny = py - sin(pa) * move;
      if (map[nx.toInt()][ny.toInt()] == 0) { px = nx; py = ny; }
    }
    if (k == 97) pa -= 0.15; // A
    if (k == 100) pa += 0.15; // D
    if (k == 32) { // TIRO
      firing = true;
      bullets.add({'x': px, 'y': py, 'vx': cos(pa) * 0.7, 'vy': sin(pa) * 0.7});
      Future.delayed(Duration(milliseconds: 100), () => firing = false);
    }
    if (k == 113) { stdout.write('\x1B[?25h\x1B[0m'); exit(0); }
  });

  Timer.periodic(Duration(milliseconds: 40), (timer) {
    // IA - Persegue mas NÃO causa dano (IMORTALIDADE ATIVA)
    for (var e in enemies.where((e) => e['hp'] > 0)) {
      double dx = px - e['x']; double dy = py - e['y'];
      double dist = sqrt(dx*dx + dy*dy);
      if (dist < 12.0 && dist > 0.6) {
        e['x'] += (dx / dist) * 0.07;
        e['y'] += (dy / dist) * 0.07;
      }
      // Dano removido aqui!
    }

    // Lógica de Balas
    for (var i = bullets.length - 1; i >= 0; i--) {
      var b = bullets[i];
      b['x'] += b['vx']; b['y'] += b['vy'];
      if (map[b['x'].toInt()][b['y'].toInt()] == 1) { bullets.removeAt(i); continue; }
      for (var e in enemies.where((e) => e['hp'] > 0)) {
        if (sqrt(pow(b['x'] - e['x'], 2) + pow(b['y'] - e['y'], 2)) < 0.6) {
          e['hp'] = 0; score += 100; bullets.removeAt(i); break;
        }
      }
    }

    StringBuffer out = StringBuffer('\x1B[H');
    // HP travado em INFINITO ou 100%
    out.writeln('\x1B[1;37m MODO: \x1B[1;32mIMORTAL\x1B[1;37m | HP: \x1B[1;32m∞\x1B[1;37m | SCORE: \x1B[1;33m$score\x1B[1;37m | ALVOS: ${enemies.where((e)=>e['hp']>0).length}\x1B[0m');
    
    List<List<String>> screen = List.generate(screenH, (_) => List.generate(screenW, (_) => ' '));
    List<double> depthBuffer = List.filled(screenW, 20.0);

    // Render das paredes
    for (int x = 0; x < screenW; x++) {
      double rayA = (pa - fov / 2.0) + (x / screenW) * fov;
      double dist = 0.0; bool hit = false;
      while (!hit && dist < 16.0) {
        dist += 0.1;
        if (map[(px + cos(rayA) * dist).toInt()][(py + sin(rayA) * dist).toInt()] == 1) hit = true;
      }
      depthBuffer[x] = dist;
      int h = (screenH / (dist * 0.8)).toInt();
      int start = (screenH / 2 - h / 2).clamp(0, screenH - 1).toInt();
      int end = (screenH / 2 + h / 2).clamp(0, screenH - 1).toInt();
      for (int y = start; y <= end; y++) screen[y][x] = dist < 5 ? '\x1B[34m█\x1B[0m' : '\x1B[90m░\x1B[0m';
    }

    // Render dos inimigos menores
    for (var e in enemies.where((e) => e['hp'] > 0)) {
      double dx = e['x'] - px; double dy = e['y'] - py;
      double dist = sqrt(dx*dx + dy*dy);
      double ang = atan2(dy, dx) - pa;
      if (ang < -pi) ang += 2 * pi; if (ang > pi) ang -= 2 * pi;
      if (ang.abs() < fov / 2 && dist < 16) {
        int sx = ((0.5 * (ang / (fov / 2)) + 0.5) * screenW).toInt();
        int sz = (screenH / (dist * 2)).toInt();
        if (sx >= 0 && sx < screenW && dist < depthBuffer[sx]) {
          for (int y = (screenH/2 - sz/2).toInt().clamp(0, screenH-1); y < (screenH/2 + sz/2).toInt().clamp(0, screenH-1); y++) {
            screen[y][sx] = '\x1B[1;41;37m!\x1B[0m'; 
          }
        }
      }
    }

    // Render das balas
    for (var b in bullets) {
      double dx = b['x'] - px; double dy = b['y'] - py;
      double dist = sqrt(dx*dx + dy*dy);
      double ang = atan2(dy, dx) - pa;
      if (ang.abs() < fov / 2) {
        int sx = ((0.5 * (ang / (fov / 2)) + 0.5) * screenW).toInt();
        if (sx >= 0 && sx < screenW && dist < depthBuffer[sx]) screen[screenH ~/ 2][sx] = '\x1B[1;33m*\x1B[0m';
      }
    }

    // Painel e Frame final
    for (int y = 0; y < screenH; y++) {
      out.write(screen[y].join(''));
      if (y < mapSize) {
        out.write('  ');
        for (int mx = 0; mx < mapSize; mx++) {
          if (mx == px.toInt() && y == py.toInt()) out.write('\x1B[93m@\x1B[0m');
          else if (enemies.any((e)=>e['x'].toInt()==mx && e['y'].toInt()==y && e['hp']>0)) out.write('\x1B[1;31m!\x1B[0m');
          else if (map[mx][y] == 1) out.write('\x1B[37m#\x1B[0m');
          else out.write(' ');
        }
      }
      out.write('\n');
    }
    out.writeln(' ' * (screenW ~/ 2 - 5) + (firing ? '\x1B[1;31m💥\x1B[0m' : '\x1B[1;37m||||\x1B[0m'));
    stdout.write(out.toString());
  });
}
