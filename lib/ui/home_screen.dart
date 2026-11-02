import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/levels.dart';
import '../game/progress.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'palette.dart';
import 'table_painter.dart';

/// A tiny table used as the title artwork.
final Level _logoTable = Level.parse(
  number: 0,
  par: 0,
  rows: const ['r.#O', '.y8.'],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.progress});

  final ProgressStore progress;

  Level get _nextLevel => levels.firstWhere(
    (level) => !progress.isSolved(level.number),
    orElse: () => levels.last,
  );

  void _showRules(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _Rules(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ListenableBuilder(
                listenable: progress,
                builder: (context, _) {
                  final next = _nextLevel;
                  final started = progress.isSolved(1);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: AspectRatio(
                          aspectRatio: TablePainter.aspectRatio(_logoTable),
                          child: CustomPaint(
                            painter: TablePainter(
                              level: _logoTable,
                              positions: _logoTable.start,
                              moves: const [],
                              elapsedMs: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'poolD',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tilt the table. Sink every ball.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: Palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => GameScreen(
                                      level: next,
                                      progress: progress,
                                    ),
                              ),
                            ),
                        child: Text(
                          started ? 'Continue - level ${next.number}' : 'Play',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) =>
                                        LevelSelectScreen(progress: progress),
                              ),
                            ),
                        child: const Text('Levels'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _showRules(context),
                        child: const Text('How to play'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const rules = [
      (
        Icons.swipe_rounded,
        'Swipe to tilt the table. Every ball rolls until '
            'it hits a cushion, the rail or another ball.',
      ),
      (Icons.circle, 'A ball that rolls over a pocket drops in.'),
      (Icons.flag_rounded, 'Sink every coloured ball to clear the table.'),
      (Icons.filter_8_rounded, 'If there is an 8-ball, it must go in last.'),
      (Icons.star_rounded, 'Clear the table in par moves for three stars.'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to play', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final (icon, text) in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Palette.accent, size: 22),
                    const SizedBox(width: 14),
                    Expanded(child: Text(text, style: textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
