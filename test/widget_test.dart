import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poold_app/game/board.dart';
import 'package:poold_app/game/levels.dart';
import 'package:poold_app/game/progress.dart';
import 'package:poold_app/game/solver.dart';
import 'package:poold_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const swipes = {
  Direction.up: Offset(0, -120),
  Direction.down: Offset(0, 120),
  Direction.left: Offset(-120, 0),
  Direction.right: Offset(120, 0),
};

final table = find.bySemanticsLabel('Pool table. Swipe to tilt it.');

Future<ProgressStore> loadProgress([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return ProgressStore.load();
}

void main() {
  testWidgets('plays level 1 to a win and unlocks level 2', (tester) async {
    final progress = await loadProgress();
    await tester.pumpWidget(PooldApp(progress: progress));

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);

    final solution = solve(levels.first, levels.first.start)!;
    for (final direction in solution) {
      expect(find.text('Table cleared!'), findsNothing);
      await tester.drag(table, swipes[direction]!);
      await tester.pumpAndSettle();
    }

    expect(find.text('Table cleared!'), findsOneWidget);
    expect(progress.bestMoves(1), levels.first.par);
    expect(progress.isUnlocked(2), isTrue);

    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
  });

  testWidgets('undo rewinds a move', (tester) async {
    final progress = await loadProgress();
    await tester.pumpWidget(PooldApp(progress: progress));
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    await tester.drag(table, swipes[Direction.up]!);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('locked levels cannot be opened', (tester) async {
    final progress = await loadProgress({'best_moves_1': 2});
    await tester.pumpWidget(PooldApp(progress: progress));
    expect(find.text('Continue - level 2'), findsOneWidget);

    await tester.tap(find.text('Levels'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Level 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Level 3, locked'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Level 3, locked'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });
}
