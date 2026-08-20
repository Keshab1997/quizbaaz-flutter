import 'dart:async';
import 'package:flutter/material.dart';
import '../models/answer_record.dart';
import '../models/question_model.dart';
import '../models/shop_item.dart';
import '../repositories/quiz_repository.dart';
import 'user_provider.dart';

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

  // Lifelines
  bool _fiftyFiftyUsed = false;
  bool _freezeUsed = false;
  List<int> _disabledOptionIndices = [];

  // Quiz type + rewards
  bool _isDailyQuiz = false;
  int _earnedCoins = 0;
  int _earnedGems = 0;
  bool _dailyRewardSkipped = false;

  // Answer history (for the review screen)
  final List<AnswerRecord> _answerRecords = [];

  // Total time spent answering the current quiz (seconds).
  double _totalTimeSeconds = 0;

  // Timer
  int _secondsRemaining = 15;
  Timer? _timer;

  // Getters
  List<QuestionModel> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswerSubmitted => _isAnswerSubmitted;
  bool get isQuizCompleted => _isQuizCompleted;
  int get secondsRemaining => _secondsRemaining;
  List<int> get disabledOptionIndices => _disabledOptionIndices;

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

  // Initialize Daily Quiz
  Future<void> startDailyQuiz() async {
    _resetQuizState();
    _isDailyQuiz = true;
    _questions = await _repository.getDailyQuizQuestions();
    _startTimer();
    notifyListeners();
  }

  // Initialize Chapter Quiz
  Future<void> startChapterQuiz(String jsonFilePath) async {
    _resetQuizState();
    _isDailyQuiz = false;
    _questions = await _repository.getChapterQuestions(jsonFilePath);
    if (_questions.isEmpty) {
      _questions = await _repository.getDailyQuizQuestions();
    }
    _startTimer();
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
    _secondsRemaining = 15;
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 15;
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

  void selectOption(int index) {
    if (_isAnswerSubmitted || _disabledOptionIndices.contains(index)) return;

    _selectedOptionIndex = index;
    _isAnswerSubmitted = true;
    _timer?.cancel();
    _totalTimeSeconds += 15 - _secondsRemaining;

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
        AnswerRecord(question: q, selectedIndex: index, status: AnswerStatus.answered),
      );
    }

    notifyListeners();

    // Auto next after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      nextQuestion();
    });
  }

  void _handleTimeout() {
    if (_isAnswerSubmitted) return;
    _isAnswerSubmitted = true;
    _wrongCount++;
    _totalTimeSeconds += 15;

    final q = currentQuestion;
    if (q != null) {
      _answerRecords.add(
        AnswerRecord(question: q, selectedIndex: null, status: AnswerStatus.timedOut),
      );
    }

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1800), () {
      nextQuestion();
    });
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

  /// Calculates the coins & gems for the finished quiz and credits them to the
  /// player's account (once — daily quiz rewards are limited to once per day).
  void _grantRewards() {
    int coins;
    int gems;

    if (_isDailyQuiz) {
      coins = _correctCount * 50;
      if (_correctCount == _questions.length) coins += 100; // perfect bonus
      gems = _correctCount == _questions.length
          ? 10
          : (_correctCount >= 8 ? 5 : 0);
    } else {
      // Chapter quiz = practice mode: smaller rewards, always claimable.
      coins = _correctCount * 25;
      gems = _correctCount == _questions.length ? 5 : 0;
    }

    // Save a new personal best on the daily leaderboard (independent of the
    // once-per-day reward limit — replays can still improve your rank).
    if (_isDailyQuiz) {
      _userProvider.updateDailyBest(
        score: _score,
        timeSeconds: _totalTimeSeconds,
      );
    }

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

  // Lifelines

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
    List<int> wrongOptions = [0, 1, 2, 3]..remove(correct);
    wrongOptions.shuffle();
    _disabledOptionIndices = wrongOptions.take(2).toList();
    notifyListeners();
    return true;
  }

  /// Adds 10 seconds to the timer. Consumes one unit from the player's
  /// inventory. Can be used once per question.
  /// Returns false if it can't be used.
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
    _totalTimeSeconds += 15 - _secondsRemaining;

    final q = currentQuestion;
    if (q != null) {
      _answerRecords.add(
        AnswerRecord(question: q, selectedIndex: null, status: AnswerStatus.skipped),
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
