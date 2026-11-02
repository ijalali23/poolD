import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board.dart';

/// Remembers the best result for each level on this device.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs);

  static Future<ProgressStore> load() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static String _key(int levelNumber) => 'best_moves_$levelNumber';

  /// Fewest moves the level has been solved in, or `null` if never solved.
  int? bestMoves(int levelNumber) => _prefs.getInt(_key(levelNumber));

  bool isSolved(int levelNumber) => bestMoves(levelNumber) != null;

  /// Levels unlock one at a time as the previous one is solved.
  bool isUnlocked(int levelNumber) =>
      levelNumber <= 1 || isSolved(levelNumber - 1);

  int starsFor(Level level) {
    final best = bestMoves(level.number);
    return best == null ? 0 : level.starsFor(best);
  }

  Future<void> recordWin(Level level, int moves) async {
    final best = bestMoves(level.number);
    if (best != null && best <= moves) return;
    await _prefs.setInt(_key(level.number), moves);
    notifyListeners();
  }
}
