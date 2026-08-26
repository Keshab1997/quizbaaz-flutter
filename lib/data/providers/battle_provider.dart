import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../l10n/app_strings.dart';
import '../models/battle_room.dart';
import '../models/battle_scoring.dart';
import '../models/question_model.dart';
import '../services/battle_question_generator.dart';
import '../services/battle_room_service.dart';
import '../services/hive_service.dart';
import 'user_provider.dart';

enum BattleDifficulty { easy, normal, hard }

enum BattlePhase { setup, searching, found, countdown, question, reveal, finished }

/// Who the player is fighting this match.
class BattleOpponent {
  final String name;
  final String avatar; // asset path or https URL
  final bool isBot;
  final String? uid;

  const BattleOpponent({
    required this.name,
    required this.avatar,
    required this.isBot,
    this.uid,
  });
}

/// Points a single question just paid out, for the reveal summary.
class BattleRoundPoints {
  final int base;
  final int timeBonus;
  final int streakBonus;

  const BattleRoundPoints({
    required this.base,
    required this.timeBonus,
    required this.streakBonus,
  });

  int get total => base + timeBonus + streakBonus;

  static const zero = BattleRoundPoints(base: 0, timeBonus: 0, streakBonus: 0);
}

/// Drives a 1-vs-1 battle — live room or bot.
///
/// ## Flow (per `docs/12_BATTLE_1V1_REAL_PLAYER_PLAN.md`)
///
/// ```text
/// setup → searching ── real player found ──→ found(VS intro) → countdown
///              │                                            → question ×5
///              └── bot fallback (guest/offline/timeout) ──→  (same, local bot)
///                                                      │
///                                                      → reveal → finished
/// ```
///
/// * **Live rooms** sync through Firestore (`battle_rooms/{roomId}`): the room
///   is the source of truth for answers/scores. Pacing is anchored to the
///   creator-written `countdown_until` and each question's `reveal_until`, so
///   both clients run the same schedule (drift cannot accumulate).
/// * **Bot matches** reuse the same phase machine locally, with the bot's
///   difficulty-driven accuracy and think-delay feeding the same scoring
///   formula, so the scoreboard is always symmetric.
/// * **Scoring** per correct answer: `base + speed bonus + streak bonus`
///   (config-driven; default max = 100 + 100 + 25 per question).
class BattleProvider extends ChangeNotifier {
  BattleProvider(this._userProvider);

  final UserProvider _userProvider;
  final BattleRoomService _roomService = BattleRoomService();
  final Random _rng = Random();

  // ----------------------------------------------------------- questions --

  List<QuestionModel> _questions = [];
  int _currentIndex = 0;

  // ----------------------------------------------------------- opponent --

  BattleOpponent? _opponent;
  bool _isBotMatch = true;

  // -------------------------------------------------------------- player --

  int _playerScore = 0;
  int _playerCorrect = 0;
  int _playerStreak = 0;
  int? _playerSelected;
  bool _playerAnswered = false;
  bool _playerTimedOut = false;
  BattleRoundPoints _lastRoundPlayer = BattleRoundPoints.zero;

  // ------------------------------------------------------------ opponent --

  int _opponentScore = 0;
  int _opponentCorrect = 0;
  int _opponentStreak = 0;
  int? _opponentSelected;
  bool _opponentAnswered = false;
  BattleRoundPoints _lastRoundOpponent = BattleRoundPoints.zero;

  // -------------------------------------------------------------- timing --

  BattlePhase _phase = BattlePhase.setup;
  BattleDifficulty _difficulty = BattleDifficulty.normal;

  int _secondsRemaining = 0;
  int _countdownValue = 3;

  int _countdownUntilMs = 0;
  int _questionDeadlineMs = 0;
  int _questionDurationSec = 15;
  int _revealUntilMs = 0;
  int _botAnswerAtMs = 0;

  int _searchStartMs = 0;
  int _searchDurationMs = 0;
  String _userId = '';
  bool _liveCapable = false;

  Timer? _tickTimer; // 200 ms — drives every phase
  Timer? _pollTimer; // 1.5 s — matchmaking probe

  // ---------------------------------------------------------------- live --

  String? _roomId;
  String _side = 'a';
  BattleRoomData? _room;
  StreamSubscription<BattleRoomData?>? _roomSub;
  int _lastHeartbeatMs = 0;
  bool _forfeitWin = false;

  // ------------------------------------------------------------- results --

  int _earnedCoins = 0;
  int _earnedGems = 0;
  bool _emptyBank = false;

  // -------------------------------------------------------------- getters --

  BattlePhase get phase => _phase;
  BattleDifficulty get difficulty => _difficulty;
  BattleOpponent? get opponent => _opponent;
  bool get isLive => _opponent?.isBot == false;
  bool get isBotMatch => _isBotMatch;
  bool get isForfeit => _forfeitWin;
  bool get hasNoQuestions => _emptyBank;

  int get countdownValue => _countdownValue;
  int get secondsRemaining => _secondsRemaining;
  int get questionTimeSec => _questionDurationSec;

  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  List<QuestionModel> get questions => List.unmodifiable(_questions);

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  String get opponentName => _opponent?.name ?? 'Opponent';
  String get opponentAvatar => _opponent?.avatar ?? '';
  int get opponentScore => isLive ? (_room?.opponentOf(_side)?.score ?? _opponentScore) : _opponentScore;
  int get opponentCorrect => isLive ? (_room?.opponentOf(_side)?.correct ?? _opponentCorrect) : _opponentCorrect;
  int get opponentStreak => isLive ? (_room?.opponentOf(_side)?.streak ?? _opponentStreak) : _opponentStreak;

  int get playerScore => _playerScore;
  int get playerCorrect => _playerCorrect;
  int get playerStreak => _playerStreak;

  int? get playerSelected => _playerSelected;
  bool get playerAnswered => _playerAnswered;
  bool get playerTimedOut => _playerTimedOut;

  int? get opponentSelected {
    if (isLive) {
      return _room?.opponentOf(_side)?.answerFor(_currentIndex)?.selected;
    }
    return _opponentSelected;
  }

  bool get opponentAnswered {
    if (isLive) {
      return _room?.opponentOf(_side)?.answerFor(_currentIndex) != null;
    }
    return _opponentAnswered;
  }

  bool get opponentTimedOut {
    // Bot matches never time out: the bot always answers inside its delay,
    // which is shorter than any question window.
    if (isLive) {
      return _room?.opponentOf(_side)?.answerFor(_currentIndex)?.timedOut ?? false;
    }
    return false;
  }

  BattleRoundPoints get lastRoundPlayer => _lastRoundPlayer;
  int get lastRoundPlayerPts => _lastRoundPlayer.total;
  BattleRoundPoints get lastRoundOpponent => _lastRoundOpponent;
  int get lastRoundOpponentPts => _lastRoundOpponent.total;

  bool get isPlayerWin => playerScore > opponentScore;
  bool get isDraw => playerScore == opponentScore;

  /// Seconds left in the matchmaking window (for the searching view).
  int get searchSecondsRemaining {
    final remaining = _searchDurationMs -
        (DateTime.now().millisecondsSinceEpoch - _searchStartMs);
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  int get earnedCoins => _earnedCoins;
  int get earnedGems => _earnedGems;

  String get revealMessage {
    if (_forfeitWin) return '🏆 $opponentName forfeited — you win!';
    if (playerTimedOut) return '⏰ You ran out of time!';
    if (opponentTimedOut) return '🤖 $opponentName ran out of time!';
    if (isPlayerCorrect && isOpponentCorrect) return '⚡ Both got it right!';
    if (isPlayerCorrect) return '🔥 You took this round!';
    if (isOpponentCorrect) return '🤖 $opponentName took this round!';
    return '😅 Nobody got it!';
  }

  bool get isPlayerCorrect =>
      _playerSelected != null && _playerSelected == currentQuestion?.correctIndex;

  bool get isOpponentCorrect =>
      opponentSelected != null && opponentSelected == currentQuestion?.correctIndex;

  /// Language of the questions, independent of the app language.
  String? _displayLanguage;
  String get displayLanguage => _displayLanguage ?? S.code;

  List<String> get availableLanguages {
    final question = currentQuestion;
    if (question == null) return const [];
    return kSupportedLanguageCodes
        .where((code) => question.questionText.has(code))
        .toList();
  }

  void setDisplayLanguage(String code) {
    if (_displayLanguage == code) return;
    _displayLanguage = code;
    notifyListeners();
  }

  int get battleQuestionCount => _userProvider.config.battleQuestionCount;
  int get battleBasePoints => _userProvider.config.battleBasePoints;
  int get battleTimeBonusMax => _userProvider.config.battleTimeBonusMax;
  int get battleStreakBonus => _userProvider.config.battleStreakBonus;

  /// Total matchmaking window in whole seconds (for the searching progress bar).
  int get searchSecondsTotal => (_searchDurationMs / 1000).ceil();

  // ------------------------------------------------------------ controls --

  Future<void> startBattle(BattleDifficulty difficulty) async {
    _disposeTimers();
    await _roomSub?.cancel();
    _roomSub = null;

    final user = _userProvider.user;
    _userId = user.userId;
    _liveCapable = !user.isGuest && !_userId.startsWith('local_');

    _difficulty = difficulty;
    _phase = BattlePhase.searching;
    _forfeitWin = false;
    _emptyBank = false;
    _opponent = null;
    _isBotMatch = true;
    _room = null;
    _roomId = null;

    _questions = [];
    _currentIndex = 0;

    _playerScore = 0;
    _playerCorrect = 0;
    _playerStreak = 0;
    _playerSelected = null;
    _playerAnswered = false;
    _playerTimedOut = false;
    _lastRoundPlayer = BattleRoundPoints.zero;

    _opponentScore = 0;
    _opponentCorrect = 0;
    _opponentStreak = 0;
    _opponentSelected = null;
    _opponentAnswered = false;
    _lastRoundOpponent = BattleRoundPoints.zero;

    _earnedCoins = 0;
    _earnedGems = 0;

    _searchStartMs = DateTime.now().millisecondsSinceEpoch;
    _searchDurationMs = _liveCapable ? _searchSeconds * 1000 : 3000;

    if (_liveCapable) {
      await _roomService.joinQueue(
        uid: user.userId,
        name: user.username.isEmpty ? user.fullName : user.username,
        avatar: user.effectiveAvatar,
        difficulty: _difficulty.name,
      );
    }

    notifyListeners();
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _tick(),
    );
    if (_liveCapable) {
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _pollMatchmaking(),
      );
    }
  }

  Future<void> rematch() => startBattle(_difficulty);

  void cancelSearch() {
    if (_phase != BattlePhase.searching) return;
    if (_liveCapable) _roomService.leaveQueue(_userId);
    _disposeTimers();
    _phase = BattlePhase.setup;
    notifyListeners();
  }

  int get _searchSeconds =>
      min(_userProvider.config.battleSearchSeconds, 10);

  // -------------------------------------------------------- matchmaking --

  Future<void> _pollMatchmaking() async {
    if (_phase != BattlePhase.searching || !_liveCapable) return;

    final found = await _roomService.findOpponent(
      myUid: _userId,
      difficulty: _difficulty.name,
    );
    if (found == null || _phase != BattlePhase.searching) return;

    _roomId = BattleRoomService.roomIdFor(_userId, found.uid);
    _side = _userId.compareTo(found.uid) < 0 ? 'a' : 'b';

    _opponent = BattleOpponent(
      name: found.name,
      avatar: found.avatar,
      isBot: false,
      uid: found.uid,
    );
    _phase = BattlePhase.found;
    _pollTimer?.cancel();
    notifyListeners();

    _roomSub = _roomService.watchRoom(_roomId!).listen(_onRoomUpdate);

    if (_side == 'a') {
      // Creator: generate the shared question set, then publish the room.
      final questions = await BattleQuestionGenerator()
          .generateBattleQuestions(count: battleQuestionCount);
      if (questions.isEmpty || _phase != BattlePhase.found) {
        await _abandonLiveMatch();
        return;
      }
      _questions = questions;
      _countdownUntilMs = DateTime.now().millisecondsSinceEpoch + 8000;
      await _roomService.createRoom(
        roomId: _roomId!,
        difficulty: _difficulty.name,
        questions: questions,
        countdownUntilMs: _countdownUntilMs,
        me: BattleRoomPlayerInfo(
          uid: _userId,
          name: _userProvider.user.username,
          avatar: _userProvider.user.effectiveAvatar,
        ),
        opponent: BattleRoomPlayerInfo(uid: found.uid, name: found.name, avatar: found.avatar),
      );
      await _writeMyPlayer({'last_seen': DateTime.now().millisecondsSinceEpoch});
    }
  }

  Future<void> _abandonLiveMatch() async {
    _roomService.leaveQueue(_userId);
    if (_roomId != null) {
      await _roomService.advanceState(_roomId!, {'phase': 'finished', 'abandoned': true});
    }
    _phase = BattlePhase.setup;
    notifyListeners();
  }

  void _onRoomUpdate(BattleRoomData? room) {
    if (_phase == BattlePhase.setup) return;
    if (room == null) {
      // Room document deleted — the other side vanished.
      if (isLive && _phase != BattlePhase.finished) {
        _forfeitWin = true;
        _finishBattle();
      }
      return;
    }
    _room = room;

    if (_questions.isEmpty && room.hasQuestions) {
      _questions = room.questions;
    }

    if (room.isFinished) {
      if (_phase != BattlePhase.finished) _finishBattle();
      return;
    }

    // Creator's schedule arrives with the room.
    if (room.countdownUntilMs > 0) {
      _countdownUntilMs = room.countdownUntilMs;
    }

    // Both answered → local reveal (the first client to see it writes the
    // shared reveal_until so both clients advance on the same clock).
    if (_phase == BattlePhase.question &&
        room.hasBothAnswered(_currentIndex) &&
        _revealUntilMs == 0) {
      _beginReveal(DateTime.now().millisecondsSinceEpoch);
    }

    // Re-anchor the reveal clock to the room value: both clients then leave
    // the reveal window and start the next question at the same instant.
    if (_phase == BattlePhase.reveal && room.revealUntilMs > 0) {
      _revealUntilMs = room.revealUntilMs;
    }

    // Both ready → advance to the next question.
    if (_phase == BattlePhase.reveal &&
        room.bothReadyFor(_currentIndex + 1) &&
        DateTime.now().millisecondsSinceEpoch >= _revealUntilMs) {
      _goToNextQuestionLive();
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------- tick --

  void _tick() {
    if (_phase == BattlePhase.setup || _phase == BattlePhase.finished) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Heartbeat while live (every phase, not only questions — otherwise a
    // fresh match could look "stale" the moment question 0 starts).
    if (isLive && now - _lastHeartbeatMs > 5000) {
      _lastHeartbeatMs = now;
      _writeMyPlayer({'last_seen': now});
    }

    switch (_phase) {
      case BattlePhase.searching:
        if (now - _searchStartMs >= _searchDurationMs) {
          _pollTimer?.cancel();
          _beginBotMatch();
        } else {
          notifyListeners();
        }
      case BattlePhase.found:
        _tickFound(now);
      case BattlePhase.countdown:
        _tickCountdown(now);
      case BattlePhase.question:
        _tickQuestion(now);
      case BattlePhase.reveal:
        _tickReveal(now);
      case BattlePhase.setup:
      case BattlePhase.finished:
        break;
    }
  }

  void _tickFound(int now) {
    // VS intro plays until 2.8 s before countdown starts.
    if (_countdownUntilMs <= 0) return;
    if (now >= _countdownUntilMs - 2800) {
      _phase = BattlePhase.countdown;
      notifyListeners();
    }
  }

  void _tickCountdown(int now) {
    if (isLive && _room == null) {
      // Room never appeared — don't hang the player, run the bot instead.
      if (now - _searchStartMs > 12000) _beginBotMatch();
      return;
    }
    final remainingMs = _countdownUntilMs - now;
    final seconds = remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
    if (seconds <= 3 && seconds != _countdownValue) {
      _countdownValue = seconds.clamp(1, 3);
      notifyListeners();
    }
    if (remainingMs <= 0) {
      _startQuestion(now);
    }
  }

  // --------------------------------------------------------- bot fallback --

  Future<void> _beginBotMatch() async {
    _pollTimer?.cancel();
    await _roomSub?.cancel();
    _roomSub = null;
    _room = null;
    _roomId = null;

    if (isLive) {
      _roomService.leaveQueue(_userId);
    }
    _opponent = BattleOpponent(
      name: _randomBotName(),
      avatar: _botAvatar,
      isBot: true,
    );
    _isBotMatch = true;

    _questions = await BattleQuestionGenerator()
        .generateBattleQuestions(count: battleQuestionCount);
    if (_questions.isEmpty) {
      _emptyBank = true;
      _phase = BattlePhase.setup;
      notifyListeners();
      return;
    }

    _countdownUntilMs = DateTime.now().millisecondsSinceEpoch + 5600;
    _phase = BattlePhase.found;
    notifyListeners();
  }

  String get _botAvatar => 'assets/images/characters/quizbaaz_mascot_boy.png';

  String _randomBotName() {
    const names = [
      'NeoMind', 'QuizBot X', 'ByteBrain', 'RoboRaj',
      'BlazeBhai', 'MegaMind', 'ChipChamp', 'QuantumQ',
    ];
    return names[_rng.nextInt(names.length)];
  }

  // ----------------------------------------------------------- questions --

  void _startQuestion(int now) {
    final question = currentQuestion;
    if (question == null) {
      _finishBattle();
      return;
    }

    _questionDurationSec = question.timeLimitSec > 0
        ? question.timeLimitSec
        : _userProvider.config.secondsPerQuestion;
    _questionDeadlineMs = now + _questionDurationSec * 1000;
    _secondsRemaining = _questionDurationSec;

    _playerSelected = null;
    _playerAnswered = false;
    _playerTimedOut = false;
    _revealUntilMs = 0;

    _opponentSelected = null;
    _opponentAnswered = false;

    _phase = BattlePhase.question;
    notifyListeners();

    if (!isLive) {
      _scheduleBotAnswer(now);
    }
  }

  void _scheduleBotAnswer(int questionStartMs) {
    final (minT, maxT) = _botDelayRange;
    final delay = minT + _rng.nextDouble() * (maxT - minT);
    _botAnswerAtMs = questionStartMs + (delay * 1000).round();
  }

  void _tickQuestion(int now) {
    // Forfeit watch for live matches.
    if (isLive) {
      final opponentPlayer = _room?.opponentOf(_side);
      if (opponentPlayer != null &&
          now - opponentPlayer.lastSeenMs > 20000 &&
          !opponentAnswered) {
        _forfeitWin = true;
        _roomService.finishRoom(_roomId!, _side);
        _finishBattle();
        return;
      }
    }

    // Bot locks in its answer at its "think" deadline.
    if (!isLive && !_opponentAnswered && now >= _botAnswerAtMs) {
      _applyBotAnswer(now);
    }

    final remainingMs = _questionDeadlineMs - now;
    _secondsRemaining = remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
    if (remainingMs <= 0) {
      if (!_playerAnswered) {
        _handlePlayerTimeout();
      } else if (!opponentAnswered) {
        // The opponent's own client times them out; give a grace period
        // before declaring a forfeit.
        if (now - _questionDeadlineMs > 8000) {
          _forfeitWin = true;
          if (isLive) _roomService.finishRoom(_roomId!, _side);
          _finishBattle();
          return;
        }
      }
    }

    // Live: both answered → reveal.
    if (isLive && _playerAnswered && opponentAnswered && _revealUntilMs == 0) {
      _beginReveal(now);
    }

    notifyListeners();
  }

  void _applyBotAnswer(int now) {
    final question = currentQuestion;
    if (question == null) return;

    if (_rng.nextDouble() < _botAccuracy) {
      _opponentSelected = question.correctIndex;
    } else {
      final wrong = [
        for (var i = 0; i < question.options.length; i++) i
      ]..remove(question.correctIndex);
      _opponentSelected = wrong.isEmpty
          ? question.correctIndex
          : wrong[_rng.nextInt(wrong.length)];
    }
    _opponentAnswered = true;

    final remaining = max(
      0,
      ((_questionDeadlineMs - now) / 1000).round(),
    );
    if (_opponentSelected == question.correctIndex) {
      _lastRoundOpponent = _computePoints(
        correct: true,
        remainingSec: remaining,
        totalSec: _questionDurationSec,
        streak: _opponentStreak,
      );
      _opponentStreak += 1;
      _opponentCorrect += 1;
      _opponentScore += _lastRoundOpponent.total;
    } else {
      _lastRoundOpponent = BattleRoundPoints.zero;
      _opponentStreak = 0;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ answers --

  void answerQuestion(int index) {
    if (_phase != BattlePhase.question || _playerAnswered) return;
    _playerSelected = index;
    _playerAnswered = true;
    _playerTimedOut = false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final question = currentQuestion;
    final right = question != null && index == question.correctIndex;
    final remaining = max(
      0,
      ((_questionDeadlineMs - now) / 1000).round(),
    );

    if (right) {
      _lastRoundPlayer = _computePoints(
        correct: true,
        remainingSec: remaining,
        totalSec: _questionDurationSec,
        streak: _playerStreak,
      );
      _playerStreak += 1;
      _playerCorrect += 1;
      _playerScore += _lastRoundPlayer.total;
    } else {
      _lastRoundPlayer = BattleRoundPoints.zero;
      _playerStreak = 0;
    }

    if (isLive) {
      _writeMyAnswer(selected: index, right: right, remaining: remaining);
    }
    notifyListeners();
    _maybeReveal(now);
  }

  void _handlePlayerTimeout() {
    if (_phase != BattlePhase.question || _playerAnswered) return;
    _playerAnswered = true;
    _playerTimedOut = true;
    _playerSelected = null;
    _lastRoundPlayer = BattleRoundPoints.zero;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (isLive) {
      _writeMyAnswer(selected: -1, right: false, remaining: 0);
    }
    notifyListeners();
    _maybeReveal(now);
  }

  void _maybeReveal(int now) {
    if (_phase != BattlePhase.question) return;
    if (!_playerAnswered || !opponentAnswered) return;
    if (_revealUntilMs != 0) return;
    _beginReveal(now);
  }

  /// Transitions question → reveal and publishes the shared reveal clock.
  void _beginReveal(int now) {
    if (_phase != BattlePhase.question) return;

    // Opponent's round points: bot mode computed them when the bot answered;
    // live mode reads them from the room's answer record.
    if (isLive) {
      final answer = _room?.opponentOf(_side)?.answerFor(_currentIndex);
      if (answer != null) {
        _lastRoundOpponent = BattleRoundPoints(
          base: answer.points - answer.timeBonus - answer.streakBonus,
          timeBonus: answer.timeBonus,
          streakBonus: answer.streakBonus,
        );
      }
    }

    _phase = BattlePhase.reveal;
    _revealUntilMs = now + 1800;
    notifyListeners();

    if (isLive) {
      _roomService.advanceState(_roomId!, {'reveal_until': _revealUntilMs});
    }
  }

  void _tickReveal(int now) {
    if (now < _revealUntilMs) return;
    if (isLive) {
      _goToNextQuestionLive();
    } else {
      _goToNextQuestion();
    }
  }

  /// Thin wrapper over the pure [BattleScoring] with the live config values.
  /// Kept as a method so the provider stays readable at its call sites.
  BattleRoundPoints _computePoints({
    required bool correct,
    required int remainingSec,
    required int totalSec,
    required int streak,
  }) {
    final cfg = _userProvider.config;
    final parts = BattleScoring.compute(
      correct: correct,
      remainingSec: remainingSec,
      totalSec: totalSec,
      streak: streak,
      basePoints: cfg.battleBasePoints,
      timeBonusMax: cfg.battleTimeBonusMax,
      streakBonus: cfg.battleStreakBonus,
    );
    return BattleRoundPoints(
      base: parts.base,
      timeBonus: parts.timeBonus,
      streakBonus: parts.streakBonus,
    );
  }

  // ------------------------------------------------------------- advance --

  void _goToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _startQuestion(DateTime.now().millisecondsSinceEpoch);
    } else {
      _finishBattle();
    }
  }

  void _goToNextQuestionLive() {
    _writeMyPlayer({'ready_for_next': _currentIndex + 1});
    final room = _room;
    if (room != null && room.bothReadyFor(_currentIndex + 1)) {
      final nextStart = _revealUntilMs + 300;
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _startQuestion(
          nextStart > DateTime.now().millisecondsSinceEpoch
              ? nextStart
              : DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        _finishBattle();
      }
    }
  }

  // -------------------------------------------------------------- finish --

  void _finishBattle() {
    _disposeTimers();
    _phase = BattlePhase.finished;

    final config = _userProvider.config;

    if (isLive) {
      final winner =
          isPlayerWin ? _side : isDraw ? 'draw' : (_side == 'a' ? 'b' : 'a');
      _roomService.finishRoom(_roomId!, winner);

      // Single-award guard: a room can never pay twice on this device.
      if (HiveService.isBattleRoomProcessed(_roomId!)) {
        notifyListeners();
        return;
      }
      HiveService.markBattleRoomProcessed(_roomId!);
    }

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

    _userProvider.recordBattleResult(won: isPlayerWin);
    _userProvider.recordQuizResult(
      answered: _questions.length,
      correct: _playerCorrect,
      timeSeconds: (_questions.length * _questionDurationSec).toDouble(),
      isDaily: false,
    );

    if (_liveCapable) _roomService.leaveQueue(_userId);
    notifyListeners();
  }

  // -------------------------------------------------------- live writers --

  void _writeMyAnswer({
    required int selected,
    required bool right,
    required int remaining,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final answer = BattleAnswer(
      selected: selected,
      correct: right,
      points: _lastRoundPlayer.total,
      timeBonus: _lastRoundPlayer.timeBonus,
      streakBonus: _lastRoundPlayer.streakBonus,
      timedOut: selected < 0,
    );
    _writeMyPlayer({
      'last_seen': now,
      'score': _playerScore,
      'correct': _playerCorrect,
      'streak': _playerStreak,
      'answers.$_currentIndex': answer.toJson(),
    });
  }

  Future<void> _writeMyPlayer(Map<String, dynamic> fields) async {
    if (_roomId == null) return;
    await _roomService.updateMyPlayer(_roomId!, _side, fields);
  }

  // ---------------------------------------------------------------- bot --

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

  // ----------------------------------------------------------------- misc --

  void _disposeTimers() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _disposeTimers();
    _roomSub?.cancel();
    _roomSub = null;
    if (_liveCapable) {
      _roomService.leaveQueue(_userId);
    }
    super.dispose();
  }
}
