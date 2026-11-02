import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../game/board.dart';
import '../game/game_controller.dart';
import '../game/levels.dart';
import '../game/progress.dart';
import 'palette.dart';
import 'stars.dart';
import 'table_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level, required this.progress});

  final Level level;
  final ProgressStore progress;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  /// How far a finger must travel before a swipe counts as a tilt.
  static const _swipeThreshold = 24.0;

  late final GameController _game = GameController(widget.level);
  late final AnimationController _animation = AnimationController(vsync: this)
    ..addStatusListener((_) => setState(() {}));

  Offset _swipe = Offset.zero;
  bool _swipeUsed = false;
  Direction? _hint;
  bool _noHint = false;

  Level get _level => widget.level;

  @override
  void dispose() {
    _animation.dispose();
    _game.dispose();
    super.dispose();
  }

  void _tilt(Direction direction) {
    if (!_game.tilt(direction)) return;
    final durationMs = tiltDurationMs(_game.lastMoves, _level.width);
    _animation.duration = Duration(milliseconds: durationMs);
    _animation.forward(from: 0);
    if (_game.lastMoves.any((move) => move.sunk)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (_game.status == GameStatus.won) {
      widget.progress.recordWin(_level, _game.moves);
    }
    setState(() {
      _hint = null;
      _noHint = false;
    });
  }

  void _undo() {
    _animation.value = 1;
    _game.undo();
    setState(() => _hint = null);
  }

  void _restart() {
    _animation.value = 1;
    _game.restart();
    setState(() => _hint = null);
  }

  void _showHint() {
    final hint = _game.hint();
    setState(() {
      _hint = hint;
      _noHint = hint == null;
    });
  }

  void _openLevel(Level level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(level: level, progress: widget.progress),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final direction = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => Direction.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => Direction.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => Direction.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD => Direction.right,
      _ => null,
    };
    if (direction != null) {
      _tilt(direction);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyZ || key == LogicalKeyboardKey.backspace) {
      _undo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _restart();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_swipeUsed) return;
    _swipe += details.delta;
    if (_swipe.distance < _swipeThreshold) return;
    _swipeUsed = true;
    final horizontal = _swipe.dx.abs() > _swipe.dy.abs();
    _tilt(
      horizontal
          ? (_swipe.dx > 0 ? Direction.right : Direction.left)
          : (_swipe.dy > 0 ? Direction.down : Direction.up),
    );
  }

  void _resetSwipe() {
    _swipe = Offset.zero;
    _swipeUsed = false;
  }

  @override
  Widget build(BuildContext context) {
    final status = _game.status;
    final settled = !_animation.isAnimating;
    final showResult = status != GameStatus.playing && settled;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(
                    title: 'Level ${_level.number}',
                    onHint: status == GameStatus.playing ? _showHint : null,
                  ),
                  _StatsRow(
                    moves: _game.moves,
                    par: _level.par,
                    best: widget.progress.bestMoves(_level.number),
                  ),
                  Expanded(child: _buildTable()),
                  _HintText(hint: _hint, noHint: _noHint),
                  _Controls(
                    onUndo: _game.canUndo ? _undo : null,
                    onRestart: _game.canUndo ? _restart : null,
                  ),
                ],
              ),
              if (showResult)
                Positioned.fill(
                  child:
                      status == GameStatus.won
                          ? _WinOverlay(
                            level: _level,
                            moves: _game.moves,
                            onReplay: () => _openLevel(_level),
                            onNext:
                                _level.number < levels.length
                                    ? () => _openLevel(levels[_level.number])
                                    : null,
                            onLevels: () => Navigator.of(context).pop(),
                          )
                          : _LostOverlay(onUndo: _undo, onRestart: _restart),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Center(
        child: AspectRatio(
          aspectRatio: TablePainter.aspectRatio(_level),
          child: Semantics(
            container: true,
            label: 'Pool table. Swipe to tilt it.',
            customSemanticsActions: {
              for (final direction in Direction.values)
                CustomSemanticsAction(label: 'Tilt ${direction.name}'):
                    () => _tilt(direction),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _resetSwipe(),
              onPanUpdate: _onPanUpdate,
              onPanEnd: (_) => _resetSwipe(),
              onPanCancel: _resetSwipe,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder:
                        (context, _) => CustomPaint(
                          painter: TablePainter(
                            level: _level,
                            positions: _game.positions,
                            moves:
                                _animation.isAnimating
                                    ? _game.lastMoves
                                    : const [],
                            elapsedMs:
                                _animation.value *
                                (_animation.duration?.inMilliseconds ?? 0),
                          ),
                        ),
                  ),
                  if (_hint != null)
                    LayoutBuilder(
                      builder:
                          (context, constraints) => Padding(
                            // Keep the arrow on the felt, inside the rail.
                            padding: EdgeInsets.all(
                              constraints.maxWidth /
                                      (_level.width + railCells * 2) *
                                      railCells +
                                  4,
                            ),
                            child: _HintArrow(direction: _hint!),
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onHint});

  final String title;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to levels',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Hint',
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: onHint,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.moves, required this.par, required this.best});

  final int moves;
  final int par;
  final int? best;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Stat(label: 'Moves', value: '$moves'),
          const SizedBox(width: 12),
          _Stat(label: 'Par', value: '$par'),
          const SizedBox(width: 12),
          _Stat(label: 'Best', value: best == null ? '-' : '$best'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: Palette.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText({required this.hint, required this.noHint});

  final Direction? hint;
  final bool noHint;

  @override
  Widget build(BuildContext context) {
    final text = switch ((hint, noHint)) {
      (final Direction d, _) => 'Try tilting ${d.name}.',
      (null, true) => 'No way out from here. Undo or restart.',
      _ => 'Swipe to tilt the table.',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: noHint ? Palette.danger : Palette.textMuted,
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.onUndo, required this.onRestart});

  final VoidCallback? onUndo;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Undo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Restart'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintArrow extends StatelessWidget {
  const _HintArrow({required this.direction});

  final Direction direction;

  @override
  Widget build(BuildContext context) {
    final quarterTurns = switch (direction) {
      Direction.up => 0,
      Direction.right => 1,
      Direction.down => 2,
      Direction.left => 3,
    };
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Align(
          alignment: Alignment(
            direction.dx.toDouble(),
            direction.dy.toDouble(),
          ),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Palette.background.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Palette.accent, width: 2),
            ),
            child: RotatedBox(
              quarterTurns: quarterTurns,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 32,
                color: Palette.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder:
          (context, t, child) => ColoredBox(
            color: Colors.black.withValues(alpha: 0.55 * t),
            child: Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
            ),
          ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _WinOverlay extends StatelessWidget {
  const _WinOverlay({
    required this.level,
    required this.moves,
    required this.onReplay,
    required this.onNext,
    required this.onLevels,
  });

  final Level level;
  final int moves;
  final VoidCallback onReplay;
  final VoidCallback? onNext;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stars = level.starsFor(moves);
    final isLast = onNext == null;
    return _OverlayCard(
      children: [
        Stars(count: stars, size: 44),
        const SizedBox(height: 16),
        Text(
          isLast ? 'Every table cleared!' : 'Table cleared!',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          stars == 3
              ? 'Solved in $moves moves. That is par.'
              : 'Solved in $moves moves. Par is ${level.par}.',
          style: textTheme.bodyLarge?.copyWith(color: Palette.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext ?? onLevels,
            child: Text(isLast ? 'Back to levels' : 'Next level'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onReplay,
                child: const Text('Replay'),
              ),
            ),
            if (!isLast)
              Expanded(
                child: TextButton(
                  onPressed: onLevels,
                  child: const Text('Levels'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LostOverlay extends StatelessWidget {
  const _LostOverlay({required this.onUndo, required this.onRestart});

  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _OverlayCard(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Palette.danger,
        ),
        const SizedBox(height: 12),
        Text(
          '8-ball down too early',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'The 8-ball must be the last ball in.',
          style: textTheme.bodyLarge?.copyWith(color: Palette.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Undo last move'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: onRestart, child: const Text('Restart')),
        ),
      ],
    );
  }
}
