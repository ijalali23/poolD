import 'board.dart';

/// Finds a shortest sequence of tilts that solves [level] from [positions].
///
/// Returns `null` when the level cannot be solved from this position, or when
/// more than [maxStates] distinct positions would have to be explored.
List<Direction>? solve(
  Level level,
  List<int?> positions, {
  int maxStates = 200000,
}) {
  switch (level.statusOf(positions)) {
    case GameStatus.won:
      return const [];
    case GameStatus.lost:
      return null;
    case GameStatus.playing:
      break;
  }

  final startKey = _key(positions);
  final parents = <String, ({String parent, Direction direction})?>{
    startKey: null,
  };
  var frontier = [(key: startKey, positions: positions)];

  while (frontier.isNotEmpty) {
    final nextFrontier = <({String key, List<int?> positions})>[];
    for (final node in frontier) {
      for (final direction in Direction.values) {
        final result = level.tilt(node.positions, direction);
        if (!result.changed) continue;
        final key = _key(result.positions);
        if (parents.containsKey(key)) continue;
        parents[key] = (parent: node.key, direction: direction);
        switch (level.statusOf(result.positions)) {
          case GameStatus.won:
            return _path(parents, key);
          case GameStatus.lost:
            continue;
          case GameStatus.playing:
            if (parents.length > maxStates) return null;
            nextFrontier.add((key: key, positions: result.positions));
        }
      }
    }
    frontier = nextFrontier;
  }
  return null;
}

String _key(List<int?> positions) => positions.map((p) => p ?? -1).join(',');

List<Direction> _path(
  Map<String, ({String parent, Direction direction})?> parents,
  String goal,
) {
  final path = <Direction>[];
  var step = parents[goal];
  while (step != null) {
    path.add(step.direction);
    step = parents[step.parent];
  }
  return path.reversed.toList();
}
