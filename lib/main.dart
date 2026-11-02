import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/progress.dart';
import 'ui/home_screen.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await ProgressStore.load();
  runApp(PooldApp(progress: progress));
}

class PooldApp extends StatelessWidget {
  const PooldApp({super.key, required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Palette.felt,
      brightness: Brightness.dark,
      surface: Palette.surface,
      primary: Palette.accent,
      onPrimary: Palette.background,
    );
    return MaterialApp(
      title: 'poolD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Palette.background,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Palette.text,
          displayColor: Palette.text,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: HomeScreen(progress: progress),
    );
  }
}
