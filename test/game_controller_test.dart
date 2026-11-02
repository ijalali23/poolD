import 'package:flutter_test/flutter_test.dart';
import 'package:poold_app/game/board.dart';
import 'package:poold_app/game/game_controller.dart';

void main() {
  late GameController game;

  setUp(() {
    game = GameController(
      Level.parse(number: 1, par: 2, rows: ['r.O', '...', '8..']),
    );
  });

  test('counts only tilts that move something', () {
    expect(game.tilt(Direction.left), isFalse);
    expect(game.moves, 0);
    expect(game.tilt(Direction.right), isTrue);
    expect(game.moves, 1);
  });

  test('undo and restart rewind the table', () {
    game.tilt(Direction.right);
    game.tilt(Direction.left);
    game.undo();
    expect(game.moves, 1);
    expect(game.positions, [null, 8]);
    game.restart();
    expect(game.moves, 0);
    expect(game.positions, game.level.start);
    expect(game.canUndo, isFalse);
  });

  test('ignores tilts once the game is over', () {
    game.tilt(Direction.right);
    game.tilt(Direction.up);
    expect(game.status, GameStatus.won);
    expect(game.tilt(Direction.left), isFalse);
  });

  test('hint suggests the first move of a solution', () {
    expect(game.hint(), Direction.right);
  });
}
