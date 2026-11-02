import 'package:flutter/foundation.dart';

import 'board.dart';
import 'solver.dart';

/// Playable state of one level: the current position, move count and history.
class GameController extends ChangeNotifier {
  GameController(this.level) : _positions = level.start;

  final Level level;

  List<int?> _positions;
  final List<List<int?>> _history = [];

  /// How the balls moved on the most recent tilt, for animation.
  /// Cleared by [undo] and [restart], which snap instead of animating.
  List<BallMove> lastMoves = const [];

  List<int?> get positions => _positions;
  int get moves => _history.length;
  bool get canUndo => _history.isNotEmpty;
  GameStatus get status => level.statusOf(_positions);

  /// Tilts the table. Returns whether any ball moved.
  bool tilt(Direction direction) {
    if (status != GameStatus.playing) return false;
    final result = level.tilt(_positions, direction);
    if (!result.changed) return false;
    _history.add(_positions);
    _positions = result.positions;
    lastMoves = result.moves;
    notifyListeners();
    return true;
  }

  void undo() {
    if (_history.isEmpty) return;
    _positions = _history.removeLast();
    lastMoves = const [];
    notifyListeners();
  }

  void restart() {
    if (_history.isEmpty) return;
    _history.clear();
    _positions = level.start;
    lastMoves = const [];
    notifyListeners();
  }

  /// The first tilt of a shortest solution from here, or `null` if the
  /// current position can no longer be solved.
  Direction? hint() {
    final path = solve(level, _positions);
    return path == null || path.isEmpty ? null : path.first;
  }
}
