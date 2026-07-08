import 'package:flutter/material.dart';

import 'core/theme/peblo_theme.dart';
import 'ui/story_screen.dart';

/// Root widget. Kept free of any dependency construction — real implementations
/// are injected in [main] via a `ProviderScope` (see `main.dart`).
class UltimateAiNarratorApp extends StatelessWidget {
  const UltimateAiNarratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate AI Narrator',
      debugShowCheckedModeBanner: false,
      theme: PebloTheme.light(),
      home: const StoryScreen(),
    );
  }
}
