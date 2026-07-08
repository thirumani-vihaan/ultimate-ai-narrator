import 'package:flutter/foundation.dart';

import '../quiz/quiz_models.dart';

/// The child's choices that seed a personalised story.
@immutable
class StoryRequest {
  const StoryRequest({
    required this.heroName,
    required this.companion,
    required this.place,
  });

  final String heroName;
  final String companion; // e.g. "a curious fox"
  final String place; // e.g. "the Whispering Woods"

  @override
  bool operator ==(Object other) =>
      other is StoryRequest &&
      other.heroName == heroName &&
      other.companion == companion &&
      other.place == place;

  @override
  int get hashCode => Object.hash(heroName, companion, place);
}

/// A generated story plus a quiz derived from its own facts. The quiz reuses the
/// same immutable [Question] contract as the rest of the app, so the renderer,
/// validation and tests are all shared.
@immutable
class StoryPackage {
  const StoryPackage({
    required this.title,
    required this.story,
    required this.quiz,
  });

  final String title;
  final String story;
  final List<Question> quiz;
}
