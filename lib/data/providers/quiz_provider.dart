import 'dart:async';
import 'package:flutter/material.dart';
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

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  // Initialize Daily Quiz
  Future<void> startDailyQuiz() async {
    _resetQuizState();
    _questions = await _repository.getDailyQuizQuestions();
    _startTimer();
    notifyListeners();
  }

  // Initialize Chapter Quiz
  Future<void> startChapterQuiz(String jsonFilePath) async {
    _resetQuizState();
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

    final correctIndex = currentQuestion?.correctIndex ?? 0;
    if (index == correctIndex) {
      _correctCount++;
      // Score calculation: 10 base points + time bonus
      final bonus = _secondsRemaining * 2;
      _score += 10 + bonus;
    } else {
      _wrongCount++;
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
    }
    notifyListeners();
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
    nextQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
