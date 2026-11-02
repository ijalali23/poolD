import 'package:flutter_test/flutter_test.dart';
import 'package:poold_app/game/board.dart';

Level parse(List<String> rows) => Level.parse(number: 1, par: 1, rows: rows);

/// Renders positions back to rows so expectations read like the levels.
List<String> render(Level level, List<int?> positions) {
  final chars = [
    for (final tile in level.tiles)
      switch (tile) {
        Tile.floor => '.',
        Tile.cushion => '#',
        Tile.pocket => 'O',
      },
  ];
  const ballChars = {
    BallKind.red: 'r',
    BallKind.yellow: 'y',
    BallKind.blue: 'b',
    BallKind.green: 'g',
    BallKind.purple: 'p',
    BallKind.orange: 'o',
    BallKind.eight: '8',
  };
  for (final ball in level.balls) {
    final cell = positions[ball.id];
    if (cell != null) chars[cell] = ballChars[ball.kind]!;
  }
  return [
    for (var y = 0; y < level.height; y++)
      chars.sublist(y * level.width, (y + 1) * level.width).join(),
  ];
}

void main() {
  group('Level.parse', () {
    test('reads tiles and balls', () {
      final level = parse(['r#O', '.8.']);
      expect(level.width, 3);
      expect(level.height, 2);
      expect(level.tileAt(1, 0), Tile.cushion);
      expect(level.tileAt(2, 0), Tile.pocket);
      expect(level.balls.map((b) => b.kind), [BallKind.red, BallKind.eight]);
      expect(level.start, [0, 4]);
      expect(level.hasEight, isTrue);
    });

    test('rejects malformed levels', () {
      expect(() => parse(['r.O', '..']), throwsFormatException);
      expect(() => parse(['r.x']), throwsFormatException);
      expect(() => parse(['r..']), throwsFormatException);
      expect(() => parse(['8.O']), throwsFormatException);
      expect(() => parse(['r88O']), throwsFormatException);
    });
  });

  group('tilt', () {
    test('rolls a ball to the rail', () {
      final level = parse(['r...', '...O']);
      final result = level.tilt(level.start, Direction.right);
      expect(render(level, result.positions), ['...r', '...O']);
      expect(result.moves.single.sunk, isFalse);
    });

    test('stops against a cushion', () {
      final level = parse(['r.#.', '...O']);
      final result = level.tilt(level.start, Direction.right);
      expect(render(level, result.positions), ['.r#.', '...O']);
    });

    test('balls stack against each other in tilt order', () {
      final level = parse(['ry..', '...O']);
      final result = level.tilt(level.start, Direction.right);
      expect(render(level, result.positions), ['..ry', '...O']);
      expect(result.moves, hasLength(2));
    });

    test('a ball drops into a pocket it rolls over', () {
      final level = parse(['r.O.']);
      final result = level.tilt(level.start, Direction.right);
      expect(result.positions, [null]);
      expect(result.moves.single.to, 2);
      expect(result.moves.single.sunk, isTrue);
    });

    test('a pocket swallows several balls in one tilt', () {
      final level = parse(['O.ry']);
      final result = level.tilt(level.start, Direction.left);
      expect(result.positions, [null, null]);
    });

    test('reports no change when nothing can move', () {
      final level = parse(['r..O']);
      expect(level.tilt(level.start, Direction.left).changed, isFalse);
      expect(level.tilt(level.start, Direction.up).changed, isFalse);
    });
  });

  group('statusOf', () {
    test('wins when every coloured ball is sunk', () {
      final level = parse(['r.O']);
      expect(level.statusOf(level.start), GameStatus.playing);
      expect(level.statusOf([null]), GameStatus.won);
    });

    test('the 8-ball must go in last', () {
      final level = parse(['r8.O']);
      expect(level.statusOf([0, null]), GameStatus.lost);
      expect(level.statusOf([null, 1]), GameStatus.playing);
      expect(level.statusOf([null, null]), GameStatus.won);
    });

    test('sinking the 8-ball with the last colour in one tilt wins', () {
      final level = parse(['r8.O']);
      final result = level.tilt(level.start, Direction.right);
      expect(level.statusOf(result.positions), GameStatus.won);
    });
  });

  test('starsFor rates moves against par', () {
    final level = Level.parse(number: 1, par: 4, rows: ['r..O']);
    expect(level.starsFor(4), 3);
    expect(level.starsFor(6), 2);
    expect(level.starsFor(7), 1);
  });
}
