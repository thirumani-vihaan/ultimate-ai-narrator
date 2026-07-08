import 'dart:math';

import '../quiz/quiz_models.dart';
import 'story_models.dart';

// Story templates contain both apostrophes and quoted dialogue, so double quotes
// read more cleanly here.
// ignore_for_file: prefer_single_quotes

/// Turns a child's choices into a personalised story + quiz. Injectable so the
/// app can swap the on-device generator for a real LLM without touching callers.
abstract interface class StoryGenerator {
  Future<StoryPackage> generate(StoryRequest request);
}

/// A real, on-device generative engine — **no API key, no network**. It weaves
/// the child's choices together with seeded-random story elements (a lost
/// object, a colour, an obstacle, a helper, a lesson) into a coherent tale, then
/// builds a quiz whose questions and answers are **derived from that tale's
/// facts** (not hard-coded). Same inputs reproduce the same story (seeded), while
/// different inputs yield genuinely different stories and quizzes.
class TemplateStoryGenerator implements StoryGenerator {
  const TemplateStoryGenerator();

  static const List<String> _objects = <String>[
    'Key',
    'Gear',
    'Star',
    'Shell',
    'Crown',
    'Lantern',
    'Feather',
    'Compass',
  ];
  static const List<String> _colours = <String>[
    'Red',
    'Blue',
    'Green',
    'Golden',
    'Purple',
    'Silver',
    'Pink',
  ];
  static const List<String> _obstacles = <String>[
    'a rushing river',
    'a snoring giant',
    'a maze of brambles',
    'a ticklish whirlwind',
    'a grumpy troll bridge',
  ];
  static const List<String> _helpers = <String>[
    'a friendly firefly',
    'a singing bluebird',
    'a wise old turtle',
    'a dancing moonbeam',
  ];
  static const List<String> _lessons = <String>[
    'being brave',
    'never giving up',
    'helping a friend',
    'being kind',
    'believing in yourself',
  ];

  @override
  Future<StoryPackage> generate(StoryRequest request) async {
    final rng = Random(_seed(request));

    final object = _pick(_objects, rng);
    final colour = _pick(_colours, rng);
    final obstacle = _pick(_obstacles, rng);
    final helper = _pick(_helpers, rng);
    final lesson = _pick(_lessons, rng);

    final hero = request.heroName.trim().isEmpty
        ? 'a little explorer'
        : request.heroName.trim();
    final companion = request.companion;
    final place = request.place;
    final thing = '${colour.toLowerCase()} ${object.toLowerCase()}';

    final title = '$hero and the $colour $object';

    final story = _template(rng.nextBool())
        .replaceAll('{hero}', hero)
        .replaceAll('{companion}', companion)
        .replaceAll('{place}', place)
        .replaceAll('{thing}', thing)
        .replaceAll('{obstacle}', obstacle)
        .replaceAll('{helper}', helper)
        .replaceAll('{lesson}', lesson);

    final quiz = <Question>[
      _question(
        'What did $hero lose?',
        object,
        _objects,
        rng,
        distractors: 3,
      ),
      _question(
        'What colour was the $object?',
        colour,
        _colours,
        rng,
        distractors: 4,
      ),
      _question(
        'Who went on the adventure with $hero?',
        companion,
        const <String>[
          'a curious fox',
          'a sleepy dragon',
          'a giggly bunny',
          'a tiny robot',
          'a wise owl',
        ],
        rng,
        distractors: 2,
      ),
      _question(
        'Where did the adventure happen?',
        place,
        const <String>[
          'the Whispering Woods',
          'Outer Space',
          'the Coral Sea',
          'Candy Mountain',
          'the Cloud Kingdom',
        ],
        rng,
        distractors: 3,
      ),
    ];

    return StoryPackage(title: title, story: story, quiz: quiz);
  }

  int _seed(StoryRequest r) =>
      Object.hash(r.heroName, r.companion, r.place) & 0x7fffffff;

  String _pick(List<String> pool, Random rng) => pool[rng.nextInt(pool.length)];

  /// Builds a question with the correct answer plus [distractors] distinct
  /// wrong options drawn from [pool], all shuffled.
  Question _question(
    String prompt,
    String answer,
    List<String> pool,
    Random rng, {
    required int distractors,
  }) {
    final options = <String>[answer];
    final others = pool.where((e) => e != answer).toList()..shuffle(rng);
    options.addAll(others.take(distractors));
    options.shuffle(rng);
    return Question(prompt: prompt, options: options, answer: answer);
  }

  String _template(bool variant) {
    if (variant) {
      return "Once upon a time, {hero} and {companion} set off on a grand "
          "adventure in {place}. But oh no — {hero} had lost a shiny "
          "{thing}! \"Don't worry, we'll find it together!\" said {companion} "
          "with a smile. Along the winding path they met {helper}, who "
          "pointed the way. They tiptoed carefully past {obstacle}, giggling "
          "the whole time. At last, {hero} spotted the {thing} sparkling in "
          "the sunlight. Hooray! On the way home, {hero} learned all about "
          "{lesson}. The end.";
    }
    return "Deep in {place}, {hero} and {companion} were playing when — "
        "whoosh! — {hero}'s favourite {thing} tumbled away and vanished. "
        "\"Let's go on a quest!\" cheered {companion}. They asked {helper} "
        "for a clue, then bravely crossed {obstacle} together. Just when "
        "they were about to give up, the {thing} twinkled from a cosy little "
        "nook. {hero} hugged {companion} tight, happy to have learned about "
        "{lesson}. The end.";
  }
}
