import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/board.dart';
import 'palette.dart';

/// Rail thickness, in cells.
const double railCells = 0.45;

/// Time a ball takes to roll one cell, and to drop into a pocket.
const int msPerCell = 55;
const int sinkMs = 170;

/// Total length of the animation for one tilt.
int tiltDurationMs(List<BallMove> moves, int width) {
  var longest = 0;
  for (final move in moves) {
    longest = math.max(
      longest,
      _travelMs(move, width) + (move.sunk ? sinkMs : 0),
    );
  }
  return longest;
}

int _distance(BallMove move, int width) =>
    (move.to % width - move.from % width).abs() +
    (move.to ~/ width - move.from ~/ width).abs();

int _travelMs(BallMove move, int width) =>
    40 + _distance(move, width) * msPerCell;

/// Draws the pool table, its cushions and pockets, and the balls.
///
/// While a tilt animates, balls listed in [moves] are drawn part-way between
/// their old and new cells according to [elapsedMs].
class TablePainter extends CustomPainter {
  TablePainter({
    required this.level,
    required this.positions,
    required this.moves,
    required this.elapsedMs,
  });

  final Level level;
  final List<int?> positions;
  final List<BallMove> moves;
  final double elapsedMs;

  static double aspectRatio(Level level) =>
      (level.width + railCells * 2) / (level.height + railCells * 2);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(
      size.width / (level.width + railCells * 2),
      size.height / (level.height + railCells * 2),
    );
    final tableSize = Size(
      cell * (level.width + railCells * 2),
      cell * (level.height + railCells * 2),
    );
    canvas.save();
    canvas.translate(
      (size.width - tableSize.width) / 2,
      (size.height - tableSize.height) / 2,
    );

    _paintRail(canvas, tableSize, cell);
    canvas.translate(cell * railCells, cell * railCells);
    _paintFelt(canvas, cell);
    _paintTiles(canvas, cell);
    _paintBalls(canvas, cell);
    canvas.restore();
  }

  void _paintRail(Canvas canvas, Size tableSize, double cell) {
    final rect = Offset.zero & tableSize;
    final rail = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.5));
    canvas.drawShadow(Path()..addRRect(rail), Colors.black, cell * 0.25, false);
    canvas.drawRRect(
      rail,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.railLight, Palette.railDark],
        ).createShader(rect),
    );

    // Sights along the rail, as on a real table.
    final sight = Paint()..color = const Color(0xFFE9DCC4);
    final inset = cell * railCells / 2;
    for (var x = 1; x < level.width; x += 2) {
      final dx = cell * (railCells + x);
      canvas.drawCircle(Offset(dx, inset), cell * 0.05, sight);
      canvas.drawCircle(
        Offset(dx, tableSize.height - inset),
        cell * 0.05,
        sight,
      );
    }
    for (var y = 1; y < level.height; y += 2) {
      final dy = cell * (railCells + y);
      canvas.drawCircle(Offset(inset, dy), cell * 0.05, sight);
      canvas.drawCircle(
        Offset(tableSize.width - inset, dy),
        cell * 0.05,
        sight,
      );
    }
  }

  void _paintFelt(Canvas canvas, double cell) {
    final rect = Rect.fromLTWH(0, 0, cell * level.width, cell * level.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.12)),
      Paint()
        ..shader = const RadialGradient(
          radius: 0.9,
          colors: [Palette.feltLight, Palette.felt],
        ).createShader(rect),
    );
  }

  void _paintTiles(Canvas canvas, double cell) {
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        switch (level.tileAt(x, y)) {
          case Tile.floor:
            break;
          case Tile.cushion:
            _paintCushion(canvas, rect, cell);
          case Tile.pocket:
            _paintPocket(canvas, rect.center, cell);
        }
      }
    }
  }

  void _paintCushion(Canvas canvas, Rect rect, double cell) {
    final block = RRect.fromRectAndRadius(
      rect.deflate(cell * 0.06),
      Radius.circular(cell * 0.2),
    );
    canvas.drawRRect(
      block.shift(Offset(0, cell * 0.05)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRRect(block, Paint()..color = Palette.cushion);
    canvas.drawRRect(
      block.deflate(cell * 0.03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.04
        ..color = Palette.cushionEdge.withValues(alpha: 0.6),
    );
  }

  void _paintPocket(Canvas canvas, Offset center, double cell) {
    canvas.drawCircle(
      center,
      cell * 0.42,
      Paint()..color = Palette.cushion.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      center,
      cell * 0.36,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.3),
          colors: [Palette.pocket, Palette.pocket, const Color(0xFF1B2620)],
          stops: const [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: cell * 0.36)),
    );
  }

  void _paintBalls(Canvas canvas, double cell) {
    final movesById = {for (final move in moves) move.ballId: move};
    for (final ball in level.balls) {
      final move = movesById[ball.id];
      if (move == null) {
        final cellIndex = positions[ball.id];
        if (cellIndex != null) {
          _paintBall(canvas, ball, _centerOf(cellIndex, cell), cell, 1);
        }
        continue;
      }

      final travelMs = _travelMs(move, level.width);
      final t = Curves.easeInQuad.transform(
        (elapsedMs / travelMs).clamp(0.0, 1.0),
      );
      final center =
          Offset.lerp(_centerOf(move.from, cell), _centerOf(move.to, cell), t)!;
      var scale = 1.0;
      if (move.sunk) {
        final sinkT = ((elapsedMs - travelMs) / sinkMs).clamp(0.0, 1.0);
        scale = 1 - Curves.easeIn.transform(sinkT);
      }
      if (scale > 0) _paintBall(canvas, ball, center, cell, scale);
    }
  }

  Offset _centerOf(int cellIndex, double cell) => Offset(
    (cellIndex % level.width + 0.5) * cell,
    (cellIndex ~/ level.width + 0.5) * cell,
  );

  void _paintBall(
    Canvas canvas,
    Ball ball,
    Offset center,
    double cell,
    double scale,
  ) {
    final radius = cell * 0.38 * scale;
    final color = Palette.ball(ball.kind);

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(cell * 0.04, radius * 0.75),
        width: radius * 1.8,
        height: radius * 0.7,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3 * scale)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.04),
    );

    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.45)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(bounds),
    );

    if (ball.isEight) {
      final badge = center + Offset(radius * 0.06, radius * 0.08);
      canvas.drawCircle(badge, radius * 0.46, Paint()..color = Colors.white);
      final label = TextPainter(
        text: TextSpan(
          text: '8',
          style: TextStyle(
            color: Colors.black,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, badge - Offset(label.width / 2, label.height / 2));
      label.dispose();
    }

    canvas.drawCircle(
      center + Offset(-radius * 0.38, -radius * 0.42),
      radius * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(TablePainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.positions != positions ||
      oldDelegate.moves != moves ||
      oldDelegate.elapsedMs != elapsedMs;
}
