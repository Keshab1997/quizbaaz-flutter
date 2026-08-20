import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';
import '../models/quiz_result_history.dart';
import '../models/shop_item.dart';
import '../models/user_model.dart';
import '../models/user_stats.dart';
import '../repositories/leaderboard_repository.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';

/// Result of a shop purchase attempt.
enum PurchaseStatus { success, insufficientFunds, alreadyOwned }

/// Owns the player's profile, stats and ranking data.
///
/// **Hive is the source of truth.** Every mutation writes to Hive first and
/// then asks [SyncService] to mirror it to Firestore (queued when offline).
/// Nothing in this class invents data: a fresh install starts at zero.
class UserProvider extends ChangeNotifier {
  final LeaderboardRepository _rankings = LeaderboardRepository();

  UserModel _user = UserModel.newPlayer();
  UserStats _stats = UserStats.empty();
  AppConfig _config = const AppConfig();

  List<ChampionModel> _champions = const [];
  List<LeaderboardItem> _leaderboard = const [];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _lastDailyRewardDate;

  // ------------------------------------------------------------- Getters --

  UserModel get user => _user;
  UserStats get stats => _stats;
  AppConfig get config => _config;
  List<ChampionModel> get champions => _champions;
  List<LeaderboardItem> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Yesterday's #1, or null when no champion has been published yet.
  ChampionModel? get yesterdayTopChampion =>
      _champions.isNotEmpty ? _champions.first : null;

  /// Only real admins (Firestore flag or the config allow-list) see the panel.
  bool get isAdmin => _user.isAdmin || _config.isAdmin(_user.userId);

  int get bestDailyScore => _stats.bestDailyScore;
  double get bestDailyTime => _stats.bestDailyTimeSeconds;
  bool get hasPlayedDailyQuiz => _stats.totalQuizzes > 0 && _playedDailyToday;
  bool get hasStats => _stats.hasData;

  bool get _playedDailyToday => _user.playedTodayDailyQuiz;

  /// When the ranking data was last refreshed from Firestore.
  DateTime? get rankingsUpdatedAt => _rankings.lastUpdated;

  /// Position among the cached leaderboard rows, or null when not ranked yet.
  int? get playerRank {
    if (!hasPlayedDailyQuiz) return null;
    var rank = 1;
    for (final item in _leaderboard) {
      if (item.username == _user.username) continue;
      final isAhead = item.score > _stats.bestDailyScore ||
          (item.score == _stats.bestDailyScore &&
              item.timeSeconds < _stats.bestDailyTimeSeconds);
      if (isAhead) rank++;
    }
    return rank;
  }

  /// "Top X%" text for the dashboard, or null when there is nothing to rank.
  String? get percentileLabel {
    final rank = playerRank;
    if (rank == null || _leaderboard.isEmpty) return null;
    final total = _leaderboard.length;
    final percent = ((rank / total) * 100).clamp(1, 100).round();
    return 'Top $percent% today';
  }

  // ---------------------------------------------------------------- Init --

  /// Loads everything from Hive (instant), then refreshes from Firestore.
  Future<void> initialize() async {
    if (_isInitialized) {
      await refreshRankings();
      return;
    }
    _isInitialized = true;

    _loadFromHive();
    notifyListeners();

    await loadInitialData();
    await _syncWithRemote();
  }

  /// Reads the persisted profile, stats and cached rankings out of Hive.
  void _loadFromHive() {
    final storedUser = HiveService.loadUser();
    if (storedUser != null) {
      _user = storedUser;
      _user.refreshDailyFlags(DateTime.now());
    }
    _stats = HiveService.loadStats();
    _config = SyncService.cachedConfig();
    _lastDailyRewardDate = HiveService.getMeta<String>('last_daily_reward_date');
    _champions = _rankings.cachedChampions();
    _leaderboard = _rankings.cachedLeaderboard();
  }

  /// Refreshes rankings, using the Hive cache while the network call runs.
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _champions = _rankings.cachedChampions();
    _leaderboard = _rankings.cachedLeaderboard();

    await refreshRankings();

    _isLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh entry point.
  Future<void> refreshRankings({bool force = false}) async {
    try {
      if (force || !_rankings.isLeaderboardFresh(_config.leaderboardTtl)) {
        _leaderboard = await _rankings.refreshLeaderboard();
      }
      if (force || !_rankings.areChampionsFresh(_config.leaderboardTtl)) {
        _champions = await _rankings.refreshChampions();
      }
    } catch (e) {
      debugPrint('UserProvider: ranking refresh failed – $e');
    }
    notifyListeners();
  }

  /// Drains the offline queue and merges remote profile/stats/config.
  Future<void> _syncWithRemote() async {
    if (!SyncService.isOnline) return;
    try {
      await SyncService.drainPending();

      final remoteConfig = await SyncService.pullConfig();
      if (remoteConfig != null) _config = remoteConfig;

      if (!_user.isGuest) {
        _user = await SyncService.pullUser(_user);
        _stats = await SyncService.pullStats(_user.userId, _stats);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider: remote sync failed – $e');
    }
  }

  // ------------------------------------------------------------- Settings --

  /// Toggle settings persisted in Hive (`qb_meta`) and mirrored to Firestore
  /// with the profile, so they survive reinstalls.
  static const settingNotifications = 'setting_notifications';
  static const settingSound = 'setting_sound';
  static const settingVibration = 'setting_vibration';
  static const settingDarkMode = 'setting_dark_mode';

  bool setting(String key, {bool defaultValue = true}) =>
      HiveService.getMeta<bool>(key) ?? defaultValue;

  Future<void> setSetting(String key, bool value) async {
    await HiveService.setMeta(key, value);
    notifyListeners();
  }

  // ------------------------------------------------------------ Inventory --

  int inventoryCount(String itemId) => _user.inventoryCount(itemId);
  bool hasItem(String itemId) => inventoryCount(itemId) > 0;

  bool canAfford(ShopItem item) =>
      item.costsCoins ? _user.coins >= item.cost : _user.gems >= item.cost;

  PurchaseStatus purchaseItem(ShopItem item) {
    if (item.isCosmetic && hasItem(item.id)) {
      return PurchaseStatus.alreadyOwned;
    }
    if (!canAfford(item)) {
      return PurchaseStatus.insufficientFunds;
    }

    if (item.costsCoins) {
      _user.coins -= item.cost;
    } else {
      _user.gems -= item.cost;
    }
    _user.inventory[item.id] = inventoryCount(item.id) + item.quantity;

    notifyListeners();
    _persistUser();
    return PurchaseStatus.success;
  }

  bool consumeItem(String itemId) {
    final count = inventoryCount(itemId);
    if (count <= 0) return false;

    _user.inventory[itemId] = count - 1;
    notifyListeners();
    _persistUser();
    return true;
  }

  // -------------------------------------------------------------- Rewards --

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  bool get canEarnDailyRewards => _lastDailyRewardDate != _todayKey();

  bool grantQuizRewards({
    required int coins,
    required int gems,
    required bool isDailyQuiz,
  }) {
    if (isDailyQuiz) {
      final today = _todayKey();
      if (_lastDailyRewardDate == today) return false;
      _lastDailyRewardDate = today;
      HiveService.setMeta('last_daily_reward_date', today);
    }

    _user.coins += coins;
    _user.gems += gems;
    notifyListeners();
    _persistUser();
    return true;
  }

  // ---------------------------------------------------------------- Stats --

  /// Records a finished quiz: updates [UserStats], the daily streak and the
  /// leaderboard entry. Everything lands in Hive first.
  Future<void> recordQuizResult({
    required int answered,
    required int correct,
    required double timeSeconds,
    required bool isDaily,
    int? score,
    String? chapterId,
    String? categoryTitle,
    String? categoryTitleBn,
    String? chapterTitle,
    String? chapterTitleBn,
    int? coinsEarned,
    int? gemsEarned,
  }) async {
    _stats.recordQuiz(
      answered: answered,
      correct: correct,
      timeSeconds: timeSeconds,
      chapterId: chapterId,
      isDaily: isDaily,
      dailyScore: score,
    );

    if (isDaily) {
      _user.registerPlayOn(DateTime.now());
      _stats.touchStreak(_user.dailyStreak);
    }

    notifyListeners();

    await HiveService.saveStats(_stats);
    await HiveService.saveUser(_user);

    // Save quiz result history
    final wrong = answered - correct;
    final accuracy = answered > 0 ? (correct / answered) * 100 : 0.0;
    final history = QuizResultHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _user.userId,
      quizType: isDaily ? 'daily' : 'chapter',
      categoryTitle: categoryTitle,
      categoryTitleBn: categoryTitleBn,
      chapterTitle: chapterTitle,
      chapterTitleBn: chapterTitleBn,
      chapterId: chapterId,
      totalQuestions: answered,
      correctAnswers: correct,
      wrongAnswers: wrong,
      score: score ?? 0,
      coinsEarned: coinsEarned ?? 0,
      gemsEarned: gemsEarned ?? 0,
      timeSeconds: timeSeconds,
      accuracy: accuracy,
      playedAt: DateTime.now(),
    );
    await _saveQuizHistory(history);

    if (isDaily && !_user.isGuest) {
      await SyncService.pushLeaderboardEntry(
        user: _user,
        score: _stats.bestDailyScore,
        timeSeconds: _stats.bestDailyTimeSeconds,
      );
      await refreshRankings(force: true);
    }
    await SyncService.pushUser(_user);
    await SyncService.pushStats(_user.userId, _stats);
  }

  /// Saves quiz history to Hive and mirrors to Firestore.
  Future<void> _saveQuizHistory(QuizResultHistory history) async {
    final json = history.toJson();
    await HiveService.saveQuizHistory(json);
    if (!_user.isGuest) {
      await SyncService.pushQuizHistory(_user.userId, json);
    }
  }

  /// Loads quiz history from Hive (instant) then refreshes from Firestore.
  Future<List<QuizResultHistory>> loadQuizHistory({int limit = 50}) async {
    // Load from Hive first (instant)
    final localData = HiveService.loadQuizHistory();
    var history =
        localData.map(QuizResultHistory.fromJson).toList();

    // Refresh from Firestore if online
    if (!_user.isGuest && SyncService.isOnline) {
      try {
        final remoteData =
            await SyncService.pullQuizHistory(_user.userId, limit: limit);
        if (remoteData.isNotEmpty) {
          history = remoteData.map(QuizResultHistory.fromJson).toList();
        }
      } catch (e) {
        debugPrint('UserProvider: quiz history refresh failed – $e');
      }
    }

    return history;
  }

  /// Records a battle result.
  Future<void> recordBattleResult({required bool won}) async {
    _stats.recordBattle(won: won);
    notifyListeners();
    await HiveService.saveStats(_stats);
    await SyncService.pushStats(_user.userId, _stats);
  }

  /// Kept for older call sites: updates the personal best only.
  bool updateDailyBest({required int score, required double timeSeconds}) {
    final isBest = score > _stats.bestDailyScore ||
        (score == _stats.bestDailyScore &&
            score > 0 &&
            (_stats.bestDailyTimeSeconds == 0 ||
                timeSeconds < _stats.bestDailyTimeSeconds));
    if (isBest) {
      _stats.bestDailyScore = score;
      _stats.bestDailyTimeSeconds = timeSeconds;
      notifyListeners();
      HiveService.saveStats(_stats);
    }
    return isBest;
  }

  // -------------------------------------------------------------- Profile --

  void toggleGender() {
    _user.toggleGender();
    notifyListeners();
    _persistUser();
  }

  void setGuestMode(bool isGuest) {
    _user = UserModel.newPlayer(isGuest: isGuest);
    _stats = UserStats.empty();
    notifyListeners();
    HiveService.saveStats(_stats);
    _persistUser();
  }

  void updateUsername(String newUsername) {
    _user.username = newUsername;
    notifyListeners();
    _persistUser();
  }

  void updateGender(UserGender gender) {
    _user.setGender(gender);
    notifyListeners();
    _persistUser();
  }

  /// Links a Google account, keeping all local progress.
  Future<void> linkGoogleAccount(
    String fullName,
    String email, {
    String? photoURL,
    String? uid,
  }) async {
    final wasGuest = _user.isGuest;
    _user = UserModel(
      userId: uid ?? email,
      username: email.split('@').first,
      fullName: fullName,
      avatarPath: _user.avatarPath,
      avatarUrl: photoURL,
      gender: _user.gender,
      coins: _user.coins + (wasGuest ? _config.signupBonusCoins : 0),
      gems: _user.gems + (wasGuest ? _config.signupBonusGems : 0),
      dailyStreak: _user.dailyStreak,
      isGuest: false,
      playedTodayDailyQuiz: _user.playedTodayDailyQuiz,
      isAdmin: _user.isAdmin,
      lastStreakDate: _user.lastStreakDate,
      inventory: _user.inventory,
    );
    notifyListeners();

    await HiveService.saveUser(_user);
    _user = await SyncService.pullUser(_user);
    _stats = await SyncService.pullStats(_user.userId, _stats);
    notifyListeners();
    await SyncService.pushUser(_user);
    await SyncService.pushStats(_user.userId, _stats);
  }

  void saveProfile({
    required String username,
    required String fullName,
    required UserGender gender,
  }) {
    _user = _user.copyWith(
      username: username,
      fullName: fullName,
      gender: gender,
      avatarPath: gender == UserGender.male
          ? 'assets/images/avatars/quizbaaz_avatar_boy.png'
          : 'assets/images/avatars/quizbaaz_avatar_girl.png',
    );
    notifyListeners();
    _persistUser();
  }

  /// Sign-out: clears the local profile and every cached value.
  Future<void> signOutLocal() async {
    await HiveService.clearAll();
    _user = UserModel.newPlayer();
    _stats = UserStats.empty();
    _champions = const [];
    _leaderboard = const [];
    _lastDailyRewardDate = null;
    notifyListeners();
  }

  // ---------------------------------------------------------- Persistence --

  Future<void> _persistUser() async {
    await HiveService.saveUser(_user);
    await SyncService.pushUser(_user);
  }
}
