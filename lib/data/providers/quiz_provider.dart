import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../repositories/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

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
      _startTimer();
    } else {
      _isQuizCompleted = true;
      _timer?.cancel();
    }
    notifyListeners();
  }

  // Lifelines
  void useFiftyFifty() {
    if (_fiftyFiftyUsed || _isAnswerSubmitted || currentQuestion == null) return;
    _fiftyFiftyUsed = true;
    final correct = currentQuestion!.correctIndex;
    List<int> wrongOptions = [0, 1, 2, 3]..remove(correct);
    wrongOptions.shuffle();
    _disabledOptionIndices = wrongOptions.take(2).toList();
    notifyListeners();
  }

  void useFreezeTime() {
    _secondsRemaining += 10;
    notifyListeners();
  }

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
