import 'question_model.dart';

/// What happened with a single question during a quiz.
enum AnswerStatus { answered, timedOut, skipped }

/// A record of one question answered in a quiz, kept for the review screen.
class AnswerRecord {
  final QuestionModel question;

  /// The option index the player picked (null when timed out / skipped).
  final int? selectedIndex;
  final AnswerStatus status;

  const AnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.status,
  });

  bool get wasCorrect =>
      status == AnswerStatus.answered && selectedIndex == question.correctIndex;
}
