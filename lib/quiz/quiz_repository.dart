import 'quiz_models.dart';

/// Thrown when questions cannot be loaded (I/O, network, empty payload). Carries
/// the underlying [cause] for logging; the UI never shows it directly.
class QuizLoadException implements Exception {
  const QuizLoadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'QuizLoadException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Supplies quiz questions "as if served by our backend". Injectable so the app
/// never depends on a concrete source (asset today, HTTP tomorrow).
abstract interface class QuizRepository {
  Future<List<Question>> loadQuestions();
}
