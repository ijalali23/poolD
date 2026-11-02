# poolD

A puzzle game played on a pool table, built with Flutter for iOS and Android.

## How to play

Swipe to tilt the table.
Every ball rolls until it hits a cushion block, the rail or another ball.
A ball that rolls over a pocket drops in.
Sink every coloured ball to clear the table.
If there is an 8-ball, it must go in last.
Clear the table in par moves for three stars.

Undo, restart and hints are always available.
On a keyboard, use the arrow keys or WASD to tilt, Z to undo and R to restart.

## Project layout

- `lib/game/board.dart` - the rules: levels, tilting and win or loss detection.
- `lib/game/solver.dart` - a breadth-first solver used for hints and to verify par.
- `lib/game/levels.dart` - the level pack.
- `lib/game/progress.dart` - saved best scores and level unlocking.
- `lib/ui/` - screens and the table renderer.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

`test/levels_test.dart` checks that every level is solvable and that its `par` matches the shortest solution.
Run it after adding or changing a level.
