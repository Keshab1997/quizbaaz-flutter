import 'question_model.dart';

/// Phase of a live 1v1 room, mirrored in Firestore under `state.phase`.
enum BattleRoomPhase {
  /// Room created, questions being written by the creator.
  lobby,

  /// Deliberate pause before question 0 (players' clients run it locally).
  countdown,

  /// A question is live; both players answer.
  question,

  /// Both answers are in; the reveal window is running locally.
  reveal,

  /// Match over; `winner` is set.
  finished,
}

/// One answer a player locked in for a single question.
class BattleAnswer {
  final int selected; // -1 when timed out
  final bool correct;
  final int points;
  final int timeBonus;
  final int streakBonus;
  final bool timedOut;

  const BattleAnswer({
    required this.selected,
    required this.correct,
    required this.points,
    required this.timeBonus,
    required this.streakBonus,
    required this.timedOut,
  });

  Map<String, dynamic> toJson() => {
        'selected': selected,
        'correct': correct,
        'points': points,
        'time_bonus': timeBonus,
        'streak_bonus': streakBonus,
        'timed_out': timedOut,
      };

  factory BattleAnswer.fromJson(Map<String, dynamic> json) => BattleAnswer(
        selected: (json['selected'] as num?)?.toInt() ?? -1,
        correct: json['correct'] as bool? ?? false,
        points: (json['points'] as num?)?.toInt() ?? 0,
        timeBonus: (json['time_bonus'] as num?)?.toInt() ?? 0,
        streakBonus: (json['streak_bonus'] as num?)?.toInt() ?? 0,
        timedOut: json['timed_out'] as bool? ?? false,
      );
}

/// One side of a live room — corresponds to `players.a` / `players.b`.
class BattleRoomPlayer {
  final String uid;
  final String name;
  final String avatar; // asset path or https URL
  final int score;
  final int correct;
  final int streak;
  final int readyForNext;
  final int lastSeenMs;
  final Map<int, BattleAnswer> answers;

  const BattleRoomPlayer({
    required this.uid,
    required this.name,
    required this.avatar,
    this.score = 0,
    this.correct = 0,
    this.streak = 0,
    this.readyForNext = 0,
    this.lastSeenMs = 0,
    this.answers = const {},
  });

  BattleAnswer? answerFor(int questionIndex) => answers[questionIndex];

  bool get timedOutLast => answers.isEmpty
      ? false
      : answers.values.last.timedOut;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'avatar': avatar,
        'score': score,
        'correct': correct,
        'streak': streak,
        'ready_for_next': readyForNext,
        'last_seen': lastSeenMs,
        'answers': answers.map(
          (index, entry) => MapEntry('$index', entry.toJson()),
        ),
      };

  factory BattleRoomPlayer.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? const {};
    return BattleRoomPlayer(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Player',
      avatar: json['avatar']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      readyForNext: (json['ready_for_next'] as num?)?.toInt() ?? 0,
      lastSeenMs: (json['last_seen'] as num?)?.toInt() ?? 0,
      answers: rawAnswers.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          BattleAnswer.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }
}

/// The whole room document (`battle_rooms/{roomId}`).
class BattleRoomData {
  final String roomId;
  final String difficulty;
  final String status; // active | finished | abandoned
  final List<QuestionModel> questions;
  final BattleRoomPhase phase;
  final int questionIndex;
  final int countdownUntilMs;
  final int questionUntilMs;
  final int revealUntilMs;
  final int nextQuestion;
  final int createdAtMs;
  final BattleRoomPlayer? playerA;
  final BattleRoomPlayer? playerB;
  final String? winner; // 'a' | 'b' | 'draw' | null

  const BattleRoomData({
    required this.roomId,
    required this.difficulty,
    required this.status,
    this.questions = const [],
    this.phase = BattleRoomPhase.lobby,
    this.questionIndex = 0,
    this.countdownUntilMs = 0,
    this.questionUntilMs = 0,
    this.revealUntilMs = 0,
    this.nextQuestion = 0,
    this.createdAtMs = 0,
    this.playerA,
    this.playerB,
    this.winner,
  });

  bool get isFinished => phase == BattleRoomPhase.finished;

  /// Read-only mapping: 'a'/'b' -> player.
  BattleRoomPlayer? playerOf(String side) =>
      side == 'a' ? playerA : side == 'b' ? playerB : null;

  BattleRoomPlayer? opponentOf(String side) =>
      side == 'a' ? playerB : side == 'b' ? playerA : null;

  bool hasBothAnswered(int index) =>
      (playerA?.answerFor(index) != null) &&
      (playerB?.answerFor(index) != null);

  bool bothReadyFor(int nextIndex) =>
      (playerA?.readyForNext ?? 0) >= nextIndex &&
      (playerB?.readyForNext ?? 0) >= nextIndex;

  bool get hasQuestions => questions.isNotEmpty;

  factory BattleRoomData.fromJson(
    String roomId,
    Map<String, dynamic> json,
  ) {
    final state = json['state'] as Map<String, dynamic>? ?? const {};
    final players = json['players'] as Map<String, dynamic>? ?? const {};
    final rawQuestions = json['questions'] as List? ?? const [];

    return BattleRoomData(
      roomId: roomId,
      difficulty: json['difficulty']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'active',
      questions: rawQuestions
          .whereType<Map>()
          .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
      phase: BattleRoomPhase.values.firstWhere(
        (p) => p.name == state['phase'],
        orElse: () => BattleRoomPhase.lobby,
      ),
      questionIndex: (state['q_index'] as num?)?.toInt() ?? 0,
      countdownUntilMs: (state['countdown_until'] as num?)?.toInt() ?? 0,
      questionUntilMs: (state['question_until'] as num?)?.toInt() ?? 0,
      revealUntilMs: (state['reveal_until'] as num?)?.toInt() ?? 0,
      nextQuestion: (state['next_q'] as num?)?.toInt() ?? 0,
      createdAtMs: (json['created_at'] as num?)?.toInt() ?? 0,
      playerA: players['a'] is Map
          ? BattleRoomPlayer.fromJson(
              Map<String, dynamic>.from(players['a'] as Map),
            )
          : null,
      playerB: players['b'] is Map
          ? BattleRoomPlayer.fromJson(
              Map<String, dynamic>.from(players['b'] as Map),
            )
          : null,
      winner: json['winner']?.toString(),
    );
  }
}

/// A record on the `battle_queue/{uid}` collection.
class BattleQueueEntry {
  final String uid;
  final String name;
  final String avatar;
  final String difficulty;
  final int createdAtMs;

  const BattleQueueEntry({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.difficulty,
    required this.createdAtMs,
  });

  factory BattleQueueEntry.fromId(String id, Map<String, dynamic> json) =>
      BattleQueueEntry(
        uid: id,
        name: json['name']?.toString() ?? 'Player',
        avatar: json['avatar']?.toString() ?? '',
        difficulty: json['difficulty']?.toString() ?? 'normal',
        createdAtMs: (json['created_at'] as num?)?.toInt() ?? 0,
      );
}
