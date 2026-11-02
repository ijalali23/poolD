import 'package:flutter/material.dart';

import 'palette.dart';

/// A row of three stars with [count] of them filled in.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.count, this.size = 16});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count of 3 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < count ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < count ? Palette.accent : Palette.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
