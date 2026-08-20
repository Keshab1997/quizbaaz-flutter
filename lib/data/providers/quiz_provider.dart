import 'dart:async';

import 'package:flutter/material.dart';

import '../models/answer_record.dart';
import '../models/question_model.dart';
import '../models/shop_item.dart';
import '../repositories/quiz_repository.dart';
import 'user_provider.dart';

/// Drives a quiz run. All timings and reward amounts come from
/// [UserProvider.config] (Hive/Firestore), never from magic numbers here.
class QuizProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();
  final UserProvider _userProvider;

  QuizProvider(this._userProvider);

  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int? _selectedOptionIndex;
  bool _isAnswerSubmitted = false;
  bool _isQuizCompleted = false;
  bool _isLoading = false;

  // Lifelines
  bool _fiftyFiftyUsed = false;
  bool _freezeUsed = false;
  List<int> _disabledOptionIndices = [];

  // Quiz type + rewards
  bool _isDailyQuiz = false;
  String? _chapterId;
  String? _categoryTitle;
  String? _categoryTitleBn;
  String? _chapterTitle;
  String? _chapterTitleBn;
  int _earnedCoins = 0;
  int _earnedGems = 0;
  bool _dailyRewardSkipped = false;

  // Answer history (for the review screen)
  final List<AnswerRecord> _answerRecords = [];

  // Total time spent answering the current quiz (seconds).
  double _totalTimeSeconds = 0;

  // Timer
  int _secondsRemaining = 0;
  Timer? _timer;

  // ---------------------------------------------------------------- Getters --

  /// Seconds allowed per question (remote-configurable).
  int get questionTimeSec => _userProvider.config.secondsPerQuestion;

  List<QuestionModel> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswerSubmitted => _isAnswerSubmitted;
  bool get isQuizCompleted => _isQuizCompleted;
  bool get isLoading => _isLoading;
  int get secondsRemaining => _secondsRemaining;
  List<int> get disabledOptionIndices => _disabledOptionIndices;

  /// True when the question bank was empty — the screen shows an empty state
  /// instead of placeholder questions.
  bool get hasNoQuestions => !_isLoading && _questions.isEmpty;

  /// Remaining stock of the 50-50 lifeline owned by the player.
  int get fiftyFiftyStock => _userProvider.inventoryCount(ShopItemIds.fiftyFifty);

  /// Remaining stock of the +10s freeze lifeline owned by the player.
  int get freezeTimeStock => _userProvider.inventoryCount(ShopItemIds.freezeTime);

  /// Coins actually credited for the finished quiz (0 if replay denied).
  int get earnedCoins => _earnedCoins;

  /// Gems actually credited for the finished quiz (0 if replay denied).
  int get earnedGems => _earnedGems;

  /// True when this daily quiz earned nothing because today's reward was
  /// already claimed.
  bool get dailyRewardSkipped => _dailyRewardSkipped;

  /// The player's answer history for the finished quiz (for the review screen).
  List<AnswerRecord> get answerRecords => List.unmodifiable(_answerRecords);

  /// Total seconds spent answering the finished quiz.
  double get totalTimeSeconds => _totalTimeSeconds;

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  // ------------------------------------------------------------- Lifecycle --

  /// Initialize the Daily Quiz.
  Future<void> startDailyQuiz() async {
    _resetQuizState();
    _isDailyQuiz = true;
    _isLoading = true;
    notifyListeners();

    _questions = await _repository.getDailyQuizQuestions();
    _isLoading = false;
    if (_questions.isNotEmpty) _startTimer();
    notifyListeners();
  }

  /// Initialize a Chapter Quiz. [chapterId] is used for per-chapter stats.
  Future<void> startChapterQuiz(
    String jsonFilePath, {
    String? chapterId,
    String? categoryTitle,
    String? categoryTitleBn,
    String? chapterTitle,
    String? chapterTitleBn,
  }) async {
    _resetQuizState();
    _isDailyQuiz = false;
    _chapterId = chapterId ?? jsonFilePath;
    _categoryTitle = categoryTitle;
    _categoryTitleBn = categoryTitleBn;
    _chapterTitle = chapterTitle;
    _chapterTitleBn = chapterTitleBn;
    _isLoading = true;
    notifyListeners();

    _questions = await _repository.getChapterQuestions(jsonFilePath);
    _isLoading = false;
    if (_questions.isNotEmpty) _startTimer();
    notifyListeners();
  }

  void _resetQuizState() {
    _timer?.cancel();
    _currentIndex = 0;
    _score = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _selectedOptionIndex = null;
    _isAnswerSubmitted = false;
    _isQuizCompleted = false;
    _fiftyFiftyUsed = false;
    _freezeUsed = false;
    _disabledOptionIndices = [];
    _earnedCoins = 0;
    _earnedGems = 0;
    _dailyRewardSkipped = false;
    _answerRecords.clear();
    _totalTimeSeconds = 0;
    _chapterId = null;
    _categoryTitle = null;
    _categoryTitleBn = null;
    _chapterTitle = null;
    _chapterTitleBn = null;
    _questions = [];
    _secondsRemaining = questionTimeSec;
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = questionTimeSec;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  // ---------------------------------------------------------------- Playing --

  void selectOption(int index) {
    if (_isAnswerSubmitted || _disabledOptionIndices.contains(index)) return;

    _selectedOptionIndex = index;
    _isAnswerSubmitted = true;
    _timer?.cancel();
    _totalTimeSeconds += questionTimeSec - _secondsRemaining;

    final correctIndex = currentQuestion?.correctIndex ?? 0;
    if (index == correctIndex) {
      _correctCount++;
      // Score calculation: 10 base points + time bonus
      final bonus = _secondsRemaining * 2;
      _score += 10 + bonus;
    } else {
      _wrongCount++;
    }

    final q = currentQuestion;
    if (q != null) {
      _answerRecords.add(
        AnswerRecord(
          question: q,
          selectedIndex: index,
          status: AnswerStatus.answered,
        ),
      );
    }

    notifyListeners();

    // Auto next after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), nextQuestion);
  }

  void _handleTimeout() {
    if (_isAnswerSubmitted) return;
    _isAnswerSubmitted = true;
    _wrongCount++;
    _totalTimeSeconds += questionTimeSec.toDouble();

    final q = currentQuestion;
    if (q != null) {
      _answerRecords.add(
        AnswerRecord(
          question: q,
          selectedIndex: null,
          status: AnswerStatus.timedOut,
        ),
      );
    }

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1800), nextQuestion);
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedOptionIndex = null;
      _isAnswerSubmitted = false;
      _disabledOptionIndices = [];
      _fiftyFiftyUsed = false;
      _freezeUsed = false;
      _startTimer();
    } else {
      _isQuizCompleted = true;
      _timer?.cancel();
      _grantRewards();
    }
    notifyListeners();
  }

  /// Calculates coins & gems from the remote config, saves the run into the
  /// Hive-backed stats and credits the player (daily rewards once per day).
  void _grantRewards() {
    final config = _userProvider.config;
    final total = _questions.length;
    final isPerfect = total > 0 && _correctCount == total;

    int coins;
    int gems;

    if (_isDailyQuiz) {
      coins = _correctCount * config.coinsPerCorrectDaily;
      if (isPerfect) coins += config.perfectBonusCoins;
      gems = isPerfect
          ? config.gemsPerfect
          : (_correctCount >= config.highScoreThreshold
              ? config.gemsHighScore
              : 0);
    } else {
      // Chapter quiz = practice mode: smaller rewards, always claimable.
      coins = _correctCount * config.coinsPerCorrectPractice;
      gems = isPerfect ? config.gemsHighScore : 0;
    }

    // Persist accuracy / streak / per-chapter progress to Hive and mirror it
    // to Firestore (the leaderboard entry is pushed from there too).
    _userProvider.recordQuizResult(
      answered: _answerRecords.length,
      correct: _correctCount,
      timeSeconds: _totalTimeSeconds,
      isDaily: _isDailyQuiz,
      score: _score,
      chapterId: _isDailyQuiz ? null : _chapterId,
      categoryTitle: _isDailyQuiz ? null : _categoryTitle,
      categoryTitleBn: _isDailyQuiz ? null : _categoryTitleBn,
      chapterTitle: _isDailyQuiz ? null : _chapterTitle,
      chapterTitleBn: _isDailyQuiz ? null : _chapterTitleBn,
      coinsEarned: coins,
      gemsEarned: gems,
    );

    final granted = _userProvider.grantQuizRewards(
      coins: coins,
      gems: gems,
      isDailyQuiz: _isDailyQuiz,
    );

    if (granted) {
      _earnedCoins = coins;
      _earnedGems = gems;
      _dailyRewardSkipped = false;
    } else {
      _earnedCoins = 0;
      _earnedGems = 0;
      _dailyRewardSkipped = true;
    }
  }

  // -------------------------------------------------------------- Lifelines --

  /// Uses the 50-50 lifeline. Consumes one unit from the player's inventory.
  /// Returns false if it can't be used (already used this question, no stock,
  /// or answer already submitted).
  bool useFiftyFifty() {
    if (_fiftyFiftyUsed || _isAnswerSubmitted || currentQuestion == null) {
      return false;
    }
    if (!_userProvider.consumeItem(ShopItemIds.fiftyFifty)) {
      return false;
    }
    _fiftyFiftyUsed = true;
    final correct = currentQuestion!.correctIndex;
    final wrongOptions = <int>[0, 1, 2, 3]..remove(correct);
    wrongOptions.shuffle();
    _disabledOptionIndices = wrongOptions.take(2).toList();
    notifyListeners();
    return true;
  }

  /// Adds extra seconds to the timer. Consumes one unit from the player's
  /// inventory. Can be used once per question.
  bool useFreezeTime() {
    if (_freezeUsed || _isAnswerSubmitted || currentQuestion == null) {
      return false;
    }
    if (!_userProvider.consumeItem(ShopItemIds.freezeTime)) {
      return false;
    }
    _freezeUsed = true;
    _secondsRemaining += 10;
    notifyListeners();
    return true;
  }

  /// Skips the current question without scoring. Free to use.
  void useSkipQuestion() {
    _timer?.cancel();
    _totalTimeSeconds += questionTimeSec - _secondsRemaining;

    final q = currentQuestion;
    if (q != null) {
      _answerRecords.add(
        AnswerRecord(
          question: q,
          selectedIndex: null,
          status: AnswerStatus.skipped,
        ),
      );
    }

    nextQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
