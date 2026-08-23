import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../repositories/quiz_repository.dart';
import 'user_provider.dart';

enum BattleDifficulty { easy, normal, hard }

enum BattlePhase { setup, countdown, question, reveal, finished }

/// Manages a 1-vs-1 battle against a bot opponent.
///
/// For now the opponent is a local bot (this can later be swapped for a
/// realtime player once the user base grows). The provider drives the whole
/// match: countdown -> questions -> reveal -> result, and grants coins/gems.
class BattleProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();
  final UserProvider _userProvider;

  BattleProvider(this._userProvider);

  /// Battle length and per-question time come from the remote/Hive config.
  int get _battleQuestionCount => _userProvider.config.battleQuestionCount;
  int get _questionTimeSec => _userProvider.config.secondsPerQuestion;

  final Random _rng = Random();

  List<QuestionModel> _questions = [];
  int _currentIndex = 0;

  int _playerScore = 0;
  int _botScore = 0;
  int _playerCorrect = 0;
  int _botCorrect = 0;

  int? _playerSelected;
  int? _botSelected;
  bool _playerAnswered = false;
  bool _botAnswered = false;
  bool _playerTimedOut = false;

  int _lastRoundPlayerPts = 0;
  int _lastRoundBotPts = 0;

  BattlePhase _phase = BattlePhase.setup;
  BattleDifficulty _difficulty = BattleDifficulty.normal;
  String _botName = 'QuizBot X';

  int _countdownValue = 3;
  int _secondsRemaining = 0;

  int _earnedCoins = 0;
  int _earnedGems = 0;

  Timer? _questionTimer;
  Timer? _botTimer;
  Timer? _revealTimer;
  Timer? _countdownTimer;

  // ---------------------------------------------------------------- Getters --

  BattlePhase get phase => _phase;
  BattleDifficulty get difficulty => _difficulty;
  String get botName => _botName;
  int get countdownValue => _countdownValue;
  int get secondsRemaining => _secondsRemaining;

  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;

  /// Read-only view of the match questions, used by the translate button to
  /// warm the translation cache for the whole battle in one pass.
  List<QuestionModel> get questions => List.unmodifiable(_questions);
  int get playerScore => _playerScore;
  int get botScore => _botScore;
  int get playerCorrect => _playerCorrect;
  int get botCorrect => _botCorrect;

  int? get playerSelected => _playerSelected;
  int? get botSelected => _botSelected;
  bool get playerAnswered => _playerAnswered;
  bool get botAnswered => _botAnswered;
  bool get playerTimedOut => _playerTimedOut;

  int get lastRoundPlayerPts => _lastRoundPlayerPts;
  int get lastRoundBotPts => _lastRoundBotPts;
  int get earnedCoins => _earnedCoins;
  int get earnedGems => _earnedGems;

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  bool get isPlayerCorrect =>
      _playerSelected != null &&
      _playerSelected == currentQuestion?.correctIndex;

  bool get isBotCorrect =>
      _botSelected != null && _botSelected == currentQuestion?.correctIndex;

  /// Total questions in this battle (config-driven).
  int get battleQuestionCount => _battleQuestionCount;

  /// Seconds allowed per battle question (config-driven).
  int get questionTimeSec => _questionTimeSec;

  /// True when no question bank was available for the battle.
  bool get hasNoQuestions => _questions.isEmpty;

  bool get isPlayerWin => _playerScore > _botScore;
  bool get isDraw => _playerScore == _botScore;

  String get revealMessage {
    if (playerTimedOut) return '⏰ You ran out of time!';
    if (isPlayerCorrect && isBotCorrect) return '⚡ Both got it right!';
    if (isPlayerCorrect) return '🔥 You took this round!';
    if (isBotCorrect) return '🤖 Bot took this round!';
    return '😅 Nobody got it!';
  }

  // ------------------------------------------------------------ Bot config --

  double get _botAccuracy {
    switch (_difficulty) {
      case BattleDifficulty.easy:
        return 0.45;
      case BattleDifficulty.normal:
        return 0.62;
      case BattleDifficulty.hard:
        return 0.78;
    }
  }

  (double, double) get _botDelayRange {
    switch (_difficulty) {
      case BattleDifficulty.easy:
        return (4.0, 8.0);
      case BattleDifficulty.normal:
        return (2.5, 6.0);
      case BattleDifficulty.hard:
        return (1.5, 4.0);
    }
  }

  String _randomBotName() {
    const names = ['NeoMind', 'QuizBot X', 'ByteBrain', 'RoboRaj', 'BlazeBhai', 'MegaMind'];
    return names[_rng.nextInt(names.length)];
  }

  // -------------------------------------------------------------- Controls --

  Future<void> startBattle(BattleDifficulty difficulty) async {
    _difficulty = difficulty;
    _botName = _randomBotName();

    _questions = await _repository.getDailyQuizQuestions();
    _questions.shuffle(_rng);
    if (_questions.length > _battleQuestionCount) {
      _questions = _questions.sublist(0, _battleQuestionCount);
    }

    _currentIndex = 0;
    _playerScore = 0;
    _botScore = 0;
    _playerCorrect = 0;
    _botCorrect = 0;
    _earnedCoins = 0;
    _earnedGems = 0;

    _phase = BattlePhase.countdown;
    _countdownValue = 3;
    notifyListeners();
    _startCountdown();
  }

  Future<void> rematch() => startBattle(_difficulty);

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdownValue > 1) {
        _countdownValue--;
        notifyListeners();
      } else {
        t.cancel();
        _phase = BattlePhase.question;
        _startQuestion();
        notifyListeners();
      }
    });
  }

  void _startQuestion() {
    _secondsRemaining = _questionTimeSec;
    _playerSelected = null;
    _botSelected = null;
    _playerAnswered = false;
    _botAnswered = false;
    _playerTimedOut = false;

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phase != BattlePhase.question) {
        t.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        t.cancel();
        _handlePlayerTimeout();
      }
    });

    _scheduleBotAnswer();
  }

  /// The bot "thinks" for a while, then locks in an answer (correct with a
  /// probability that depends on the chosen difficulty).
  void _scheduleBotAnswer() {
    _botTimer?.cancel();
    final (minT, maxT) = _botDelayRange;
    final delaySec = minT + _rng.nextDouble() * (maxT - minT);
    _botTimer = Timer(Duration(milliseconds: (delaySec * 1000).round()), () {
      if (_phase != BattlePhase.question || _botAnswered) return;

      final correctIndex = currentQuestion?.correctIndex ?? 0;
      if (_rng.nextDouble() < _botAccuracy) {
        _botSelected = correctIndex;
      } else {
        final optionsCount = currentQuestion?.options.length ?? 4;
        final wrong = [for (var i = 0; i < optionsCount; i++) i]
          ..remove(correctIndex);
        _botSelected = wrong[_rng.nextInt(wrong.length)];
      }
      _botAnswered = true;
      notifyListeners();
      _maybeReveal();
    });
  }

  void answerQuestion(int index) {
    if (_phase != BattlePhase.question || _playerAnswered) return;
    _playerSelected = index;
    _playerAnswered = true;
    _questionTimer?.cancel();
    notifyListeners();
    _maybeReveal();
  }

  void _handlePlayerTimeout() {
    if (_phase != BattlePhase.question || _playerAnswered) return;
    _playerAnswered = true;
    _playerTimedOut = true;
    _playerSelected = null;
    notifyListeners();
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_phase != BattlePhase.question) return;
    if (!_playerAnswered || !_botAnswered) return;

    final correctIndex = currentQuestion?.correctIndex ?? 0;
    _lastRoundPlayerPts = 0;
    _lastRoundBotPts = 0;

    if (_playerSelected == correctIndex) {
      _playerCorrect++;
      _lastRoundPlayerPts = 10 + (_secondsRemaining * 2);
      _playerScore += _lastRoundPlayerPts;
    }
    if (_botSelected == correctIndex) {
      _botCorrect++;
      _lastRoundBotPts = 10;
      _botScore += _lastRoundBotPts;
    }

    _phase = BattlePhase.reveal;
    notifyListeners();

    _revealTimer = Timer(const Duration(milliseconds: 1800), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _phase = BattlePhase.question;
      _startQuestion();
      notifyListeners();
    } else {
      _finishBattle();
    }
  }

  void _finishBattle() {
    _questionTimer?.cancel();
    _botTimer?.cancel();
    _revealTimer?.cancel();
    _phase = BattlePhase.finished;

    final config = _userProvider.config;
    if (isPlayerWin) {
      _earnedCoins = config.coinsPerCorrectPractice * 2;
      _earnedGems = config.gemsHighScore;
    } else if (isDraw) {
      _earnedCoins = config.coinsPerCorrectPractice;
      _earnedGems = 0;
    } else {
      _earnedCoins = (config.coinsPerCorrectPractice / 2).round();
      _earnedGems = 0;
    }

    _userProvider.grantQuizRewards(
      coins: _earnedCoins,
      gems: _earnedGems,
      isDailyQuiz: false,
    );

    // Persist the battle into the Hive-backed stats (win rate, accuracy) and
    // mirror it to Firestore.
    _userProvider.recordBattleResult(won: isPlayerWin);
    _userProvider.recordQuizResult(
      answered: _questions.length,
      correct: _playerCorrect,
      timeSeconds: (_questions.length * _questionTimeSec).toDouble(),
      isDaily: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _botTimer?.cancel();
    _revealTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
