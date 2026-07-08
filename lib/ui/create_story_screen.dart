import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/peblo_theme.dart';
import '../state/providers.dart';
import '../story/story_models.dart';
import 'widgets/brand_background.dart';
import 'widgets/buddy_character.dart';
import 'widgets/pressable.dart';

class _Option {
  const _Option(this.emoji, this.label, this.value);
  final String emoji;
  final String label;
  final String value;
}

const List<_Option> _companions = <_Option>[
  _Option('🦊', 'Fox', 'a curious fox'),
  _Option('🐉', 'Dragon', 'a sleepy dragon'),
  _Option('🐰', 'Bunny', 'a giggly bunny'),
  _Option('🤖', 'Robot', 'a tiny robot'),
  _Option('🦉', 'Owl', 'a wise owl'),
];

const List<_Option> _places = <_Option>[
  _Option('🌲', 'Whispering Woods', 'the Whispering Woods'),
  _Option('🚀', 'Outer Space', 'Outer Space'),
  _Option('🐚', 'Coral Sea', 'the Coral Sea'),
  _Option('🍭', 'Candy Mountain', 'Candy Mountain'),
  _Option('☁️', 'Cloud Kingdom', 'the Cloud Kingdom'),
];

/// The child designs their own adventure — name, buddy, place — and the AI
/// Story Buddy conjures a unique story + quiz just for them.
class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final TextEditingController _name = TextEditingController();
  String _companion = _companions.first.value;
  String _place = _places.first.value;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _makeStory() async {
    final generator = ref.read(storyGeneratorProvider);
    ref.read(generatingProvider.notifier).state = true;
    final package = await generator.generate(
      StoryRequest(
        heroName: _name.text.trim(),
        companion: _companion,
        place: _place,
      ),
    );
    if (!mounted) return;
    ref.read(storyControllerProvider.notifier).resetToIdle();
    ref.read(activeStoryProvider.notifier).state = package;
    ref.read(generatingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final generating = ref.watch(generatingProvider);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: BrandBackground(reduceMotion: reduceMotion),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    "Let's make YOUR story! ✨",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: PebloColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pick a few things and I\'ll invent a tale, just for you.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: PebloColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ExcludeSemantics(
                      child: BuddyCharacter(
                        mood: generating ? BuddyMood.talking : BuddyMood.idle,
                        size: 128,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('👋 What\'s your name?'),
                  const SizedBox(height: 8),
                  _NameField(controller: _name),
                  const SizedBox(height: 20),
                  const _SectionLabel('🐾 Choose a story buddy'),
                  const SizedBox(height: 10),
                  _Chips(
                    options: _companions,
                    selected: _companion,
                    onSelect: (v) => setState(() => _companion = v),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('🗺️ Choose a magical place'),
                  const SizedBox(height: 10),
                  _Chips(
                    options: _places,
                    selected: _place,
                    onSelect: (v) => setState(() => _place = v),
                  ),
                  const SizedBox(height: 28),
                  if (generating)
                    const _Conjuring()
                  else
                    _MakeButton(onTap: _makeStory),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: PebloColors.primaryDark,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: PebloColors.ink,
      ),
      decoration: InputDecoration(
        hintText: 'Type your name…',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: PebloColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PebloColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final o in options)
          _PickChip(
            emoji: o.emoji,
            label: o.label,
            selected: o.value == selected,
            onTap: () => onSelect(o.value),
          ),
      ],
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? PebloColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? PebloColors.primary
                : PebloColors.primary.withValues(alpha: 0.15),
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: PebloColors.primary
                  .withValues(alpha: selected ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : PebloColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MakeButton extends StatelessWidget {
  const _MakeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF8B6DFF), PebloColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: PebloColors.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Text(
          '✨ Make My Story!',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Conjuring extends StatelessWidget {
  const _Conjuring();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PebloColors.accent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(34),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: PebloColors.primaryDark,
            ),
          ),
          SizedBox(width: 12),
          Text(
            '✨ Conjuring your story…',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PebloColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
