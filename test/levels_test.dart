import 'package:flutter_test/flutter_test.dart';
import 'package:poold_app/game/board.dart';
import 'package:poold_app/game/levels.dart';
import 'package:poold_app/game/solver.dart';

void main() {
  test('levels are numbered in order', () {
    expect(levels.map((l) => l.number), [
      for (var i = 1; i <= levels.length; i++) i,
    ]);
  });

  for (final level in levels) {
    test('level ${level.number} is solvable in exactly par moves', () {
      expect(level.statusOf(level.start), GameStatus.playing);
      final solution = solve(level, level.start);
      expect(solution, isNotNull);
      expect(solution, hasLength(level.par));

      var positions = level.start;
      for (final direction in solution!) {
        positions = level.tilt(positions, direction).positions;
      }
      expect(level.statusOf(positions), GameStatus.won);
    });
  }

  test('solver reports unsolvable positions', () {
    // The ball can never reach the pocket behind the cushions.
    final level = Level.parse(number: 1, par: 1, rows: ['r.#O', '..##']);
    expect(solve(level, level.start), isNull);
  });
}
