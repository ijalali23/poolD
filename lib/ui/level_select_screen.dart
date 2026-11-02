import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/levels.dart';
import '../game/progress.dart';
import 'game_screen.dart';
import 'palette.dart';
import 'stars.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: const Text('Levels'),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: progress,
            builder: (context, _) {
              final earned = levels.fold(
                0,
                (sum, level) => sum + progress.starsFor(level),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Palette.accent),
                    const SizedBox(width: 4),
                    Text('$earned / ${levels.length * 3}'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: progress,
        builder:
            (context, _) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 88,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: levels.length,
              itemBuilder:
                  (context, index) =>
                      _LevelTile(level: levels[index], progress: progress),
            ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.progress});

  final Level level;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isUnlocked(level.number);
    final solved = progress.isSolved(level.number);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: unlocked,
      label:
          unlocked ? 'Level ${level.number}' : 'Level ${level.number}, locked',
      child: Material(
        color: unlocked ? Palette.surfaceHigh : Palette.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              unlocked
                  ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => GameScreen(level: level, progress: progress),
                    ),
                  )
                  : null,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (unlocked)
                  Text(
                    '${level.number}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  const Icon(Icons.lock_rounded, color: Palette.textMuted),
                const SizedBox(height: 4),
                if (solved)
                  Stars(count: progress.starsFor(level), size: 14)
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
