class QuestionModel {
  final String id;
  final String question;
  final String? questionBn;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int points;
  final int timeLimitSec;

  QuestionModel({
    required this.id,
    required this.question,
    this.questionBn,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.points = 10,
    this.timeLimitSec = 15,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      questionBn: json['question_bn'],
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'] ?? '',
      points: json['points'] ?? 10,
      timeLimitSec: json['time_limit_sec'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'question_bn': questionBn,
      'options': options,
      'correct_index': correctIndex,
      'explanation': explanation,
      'points': points,
      'time_limit_sec': timeLimitSec,
    };
  }
}
