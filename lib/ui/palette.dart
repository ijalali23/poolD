import 'package:flutter/material.dart';

import '../game/board.dart';

/// Colours shared across the app.
abstract final class Palette {
  static const background = Color(0xFF0D1B24);
  static const surface = Color(0xFF16303D);
  static const surfaceHigh = Color(0xFF1E3F4F);
  static const text = Color(0xFFF1F5F4);
  static const textMuted = Color(0xFF9DB4B9);
  static const accent = Color(0xFFF2C14E);
  static const danger = Color(0xFFFF7A6B);

  static const felt = Color(0xFF1E7A4F);
  static const feltLight = Color(0xFF26935F);
  static const cushion = Color(0xFF115234);
  static const cushionEdge = Color(0xFF2E9A66);
  static const railLight = Color(0xFF7A4D2B);
  static const railDark = Color(0xFF4A2B16);
  static const pocket = Color(0xFF060A08);

  static Color ball(BallKind kind) => switch (kind) {
    BallKind.red => const Color(0xFFE53935),
    BallKind.yellow => const Color(0xFFFDD835),
    BallKind.blue => const Color(0xFF1E88E5),
    BallKind.green => const Color(0xFF43A047),
    BallKind.purple => const Color(0xFF8E24AA),
    BallKind.orange => const Color(0xFFFB8C00),
    BallKind.eight => const Color(0xFF15181A),
  };
}
