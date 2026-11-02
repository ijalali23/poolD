/// Core rules of the tilt puzzle, independent of any UI.
///
/// The table is a grid of tiles. Tilting it in a [Direction] makes every ball
/// roll until it is stopped by a cushion block, the rail or another ball.
/// A ball that rolls over a pocket drops in. The puzzle is solved when every
/// ball has been pocketed, with the 8-ball going in last.
library;

enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Direction(this.dx, this.dy);

  final int dx;
  final int dy;
}

enum Tile { floor, cushion, pocket }

enum BallKind { red, yellow, blue, green, purple, orange, eight }

enum GameStatus { playing, won, lost }

class Ball {
  const Ball(this.id, this.kind);

  /// Index of this ball in a [Level]'s position list.
  final int id;
  final BallKind kind;

  bool get isEight => kind == BallKind.eight;
}

/// Where a single ball travelled during one tilt.
class BallMove {
  const BallMove({
    required this.ballId,
    required this.from,
    required this.to,
    required this.sunk,
  });

  final int ballId;

  /// Cell indices (`y * width + x`).
  final int from;
  final int to;

  /// Whether the ball dropped into the pocket at [to].
  final bool sunk;
}

class TiltResult {
  const TiltResult(this.positions, this.moves);

  /// Ball positions after the tilt, indexed by ball id. `null` means sunk.
  final List<int?> positions;

  /// Only the balls that actually moved.
  final List<BallMove> moves;

  bool get changed => moves.isNotEmpty;
}

class Level {
  Level._({
    required this.number,
    required this.width,
    required this.height,
    required this.tiles,
    required this.balls,
    required this.start,
    required this.par,
  });

  /// Parses a level from rows of characters:
  ///
  /// * `.` floor
  /// * `#` cushion block
  /// * `O` pocket
  /// * `r` `y` `b` `g` `p` `o` coloured balls (on floor)
  /// * `8` the 8-ball (on floor)
  factory Level.parse({
    required int number,
    required int par,
    required List<String> rows,
  }) {
    if (rows.isEmpty || rows.first.isEmpty) {
      throw FormatException('Level $number is empty');
    }
    final width = rows.first.length;
    final height = rows.length;
    final tiles = <Tile>[];
    final balls = <Ball>[];
    final start = <int?>[];
    for (var y = 0; y < height; y++) {
      final row = rows[y];
      if (row.length != width) {
        throw FormatException('Level $number row $y has the wrong width');
      }
      for (var x = 0; x < width; x++) {
        final char = row[x];
        final kind = _ballKinds[char];
        if (kind != null) {
          balls.add(Ball(balls.length, kind));
          start.add(y * width + x);
          tiles.add(Tile.floor);
          continue;
        }
        tiles.add(switch (char) {
          '.' => Tile.floor,
          '#' => Tile.cushion,
          'O' => Tile.pocket,
          _ => throw FormatException('Level $number has unknown tile "$char"'),
        });
      }
    }
    if (balls.where((b) => b.isEight).length > 1) {
      throw FormatException('Level $number has more than one 8-ball');
    }
    if (!balls.any((b) => !b.isEight)) {
      throw FormatException('Level $number has no coloured balls');
    }
    if (!tiles.contains(Tile.pocket)) {
      throw FormatException('Level $number has no pockets');
    }
    return Level._(
      number: number,
      width: width,
      height: height,
      tiles: List.unmodifiable(tiles),
      balls: List.unmodifiable(balls),
      start: List.unmodifiable(start),
      par: par,
    );
  }

  static const _ballKinds = {
    'r': BallKind.red,
    'y': BallKind.yellow,
    'b': BallKind.blue,
    'g': BallKind.green,
    'p': BallKind.purple,
    'o': BallKind.orange,
    '8': BallKind.eight,
  };

  final int number;
  final int width;
  final int height;
  final List<Tile> tiles;
  final List<Ball> balls;

  /// Starting cell of each ball, indexed by ball id.
  final List<int?> start;

  /// Fewest moves needed to solve the level.
  final int par;

  bool get hasEight => balls.any((b) => b.isEight);

  Tile tileAt(int x, int y) => tiles[y * width + x];

  /// Star rating for finishing in [moves] moves.
  int starsFor(int moves) {
    if (moves <= par) return 3;
    if (moves <= par + 2) return 2;
    return 1;
  }

  /// Applies one tilt to [positions] and reports how each ball moved.
  TiltResult tilt(List<int?> positions, Direction direction) {
    final next = List<int?>.of(positions);
    final occupied = <int>{
      for (final p in positions)
        if (p != null) p,
    };

    // Balls closest to the side the table tilts towards settle first, so the
    // balls behind them stop against them.
    final order = [
      for (var id = 0; id < positions.length; id++)
        if (positions[id] != null) id,
    ]..sort(
      (a, b) => _progress(
        positions[b]!,
        direction,
      ).compareTo(_progress(positions[a]!, direction)),
    );

    final moves = <BallMove>[];
    for (final id in order) {
      final from = positions[id]!;
      occupied.remove(from);
      var x = from % width;
      var y = from ~/ width;
      var sunk = false;
      while (true) {
        final nx = x + direction.dx;
        final ny = y + direction.dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) break;
        final cell = ny * width + nx;
        if (tiles[cell] == Tile.cushion || occupied.contains(cell)) break;
        x = nx;
        y = ny;
        if (tiles[cell] == Tile.pocket) {
          sunk = true;
          break;
        }
      }
      final to = y * width + x;
      if (sunk) {
        next[id] = null;
      } else {
        next[id] = to;
        occupied.add(to);
      }
      if (to != from) {
        moves.add(BallMove(ballId: id, from: from, to: to, sunk: sunk));
      }
    }
    return TiltResult(List.unmodifiable(next), List.unmodifiable(moves));
  }

  /// The 8-ball must be the last ball pocketed. Sinking it in the same tilt
  /// as the final coloured ball counts as a win.
  GameStatus statusOf(List<int?> positions) {
    var coloursLeft = false;
    var eightSunk = false;
    for (final ball in balls) {
      final onTable = positions[ball.id] != null;
      if (ball.isEight) {
        eightSunk = !onTable;
      } else if (onTable) {
        coloursLeft = true;
      }
    }
    if (eightSunk && coloursLeft) return GameStatus.lost;
    if (coloursLeft || (hasEight && !eightSunk)) return GameStatus.playing;
    return GameStatus.won;
  }

  int _progress(int cell, Direction direction) =>
      (cell % width) * direction.dx + (cell ~/ width) * direction.dy;
}
