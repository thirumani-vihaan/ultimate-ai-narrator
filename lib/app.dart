import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/peblo_theme.dart';
import 'state/providers.dart';
import 'ui/create_story_screen.dart';
import 'ui/story_screen.dart';

/// Root widget. Real implementations are injected in [main] via a
/// `ProviderScope` (see `main.dart`).
class UltimateAiNarratorApp extends StatelessWidget {
  const UltimateAiNarratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate AI Narrator',
      debugShowCheckedModeBanner: false,
      theme: PebloTheme.light(),
      home: const _Home(),
    );
  }
}

/// Shows the "create your story" flow until a story has been generated, then the
/// story + quiz experience.
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStory = ref.watch(activeStoryProvider) != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      child: hasStory
          ? const StoryScreen(key: ValueKey<String>('story'))
          : const CreateStoryScreen(key: ValueKey<String>('create')),
    );
  }
}
