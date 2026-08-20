import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';
import '../models/shop_item.dart';
import '../repositories/quiz_repository.dart';

/// Result of a shop purchase attempt.
enum PurchaseStatus { success, insufficientFunds, alreadyOwned }

class UserProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

  // SharedPreferences keys
  static const _kCoins = 'quizcraft_coins';
  static const _kGems = 'quizcraft_gems';
  static const _kInventory = 'quizcraft_inventory';
  static const _kLastDailyReward = 'quizcraft_last_daily_reward';
  static const _kBestDailyScore = 'quizcraft_best_daily_score';
  static const _kBestDailyTime = 'quizcraft_best_daily_time';
  static const _kHasPlayedDaily = 'quizcraft_has_played_daily';

  UserModel _user = UserModel.defaultUser();
  List<ChampionModel> _champions = [];
  List<LeaderboardItem> _leaderboard = [];
  bool _isLoading = false;
  String? _lastDailyRewardDate;
  int _bestDailyScore = 0;
  double _bestDailyTime = 0;
  bool _hasPlayedDaily = false;

  UserModel get user => _user;
  List<ChampionModel> get champions => _champions;
  List<LeaderboardItem> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;

  ChampionModel? get yesterdayTopChampion =>
      _champions.isNotEmpty ? _champions.first : null;

  // ------------------------------------------------------ Leaderboard / Rank --

  /// The player's best daily-quiz score so far (0 = never played).
  int get bestDailyScore => _bestDailyScore;

  /// Time taken for the best daily-quiz run, in seconds.
  double get bestDailyTime => _bestDailyTime;

  /// Whether the player has finished at least one daily quiz.
  bool get hasPlayedDailyQuiz => _hasPlayedDaily;

  /// Saves a finished daily-quiz result as the new personal best, if it is
  /// better than the previous one (higher score wins; on a tie, faster wins).
  /// Returns true when the record was updated.
  bool updateDailyBest({required int score, required double timeSeconds}) {
    _hasPlayedDaily = true;
    final isBest = score > _bestDailyScore ||
        (score == _bestDailyScore && score > 0 && timeSeconds < _bestDailyTime);
    if (isBest) {
      _bestDailyScore = score;
      _bestDailyTime = timeSeconds;
    }
    notifyListeners();
    _persist();
    return isBest;
  }

  /// The player's rank (1-based) on today's leaderboard, computed by inserting
  /// their best score into the loaded list. Returns null if not played yet.
  int? get playerRank {
    if (!hasPlayedDailyQuiz) return null;
    var rank = 1;
    for (final item in _leaderboard) {
      final isAhead = item.score > _bestDailyScore ||
          (item.score == _bestDailyScore && item.timeSeconds < _bestDailyTime);
      if (isAhead) rank++;
    }
    return rank;
  }

  /// Loads persisted coins/gems/inventory (from a previous session) and then
  /// fetches the champion + leaderboard data.
  Future<void> initialize() async {
    await _loadPersistedState();
    await loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _champions = await _repository.getYesterdayChampions();
      _leaderboard = await _repository.getLiveLeaderboard();
    } catch (e) {
      debugPrint('Error loading user/champ data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Shop ----

  /// How many units of [itemId] the user currently owns.
  int inventoryCount(String itemId) => _user.inventoryCount(itemId);

  /// Whether the user owns at least one unit of [itemId].
  bool hasItem(String itemId) => inventoryCount(itemId) > 0;

  /// Whether the user has enough coins/gems to buy [item].
  bool canAfford(ShopItem item) => item.costsCoins
      ? _user.coins >= item.cost
      : _user.gems >= item.cost;

  /// Buys [item], deducts the balance and adds it to the inventory.
  /// Returns a [PurchaseStatus] so the UI can show the right feedback.
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
    _persist();
    return PurchaseStatus.success;
  }

  /// Consumes one unit of [itemId] (e.g. when a lifeline is used in a quiz).
  /// Returns false if the user owns none.
  bool consumeItem(String itemId) {
    final count = inventoryCount(itemId);
    if (count <= 0) return false;

    _user.inventory[itemId] = count - 1;
    notifyListeners();
    _persist();
    return true;
  }

  // ------------------------------------------------------- Rewards / Auth ---

  /// "yyyy-MM-dd" key for today (local time) — used to limit the daily
  /// quiz reward to once per day.
  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Whether the player can still claim the daily quiz reward today.
  bool get canEarnDailyRewards => _lastDailyRewardDate != _todayKey();

  /// Grants coins & gems earned from a finished quiz.
  ///
  /// - Daily quiz rewards are granted at most once per calendar day to stop
  ///   reward farming (returns false if already claimed today).
  /// - Chapter quiz (practice) always grants, but earns fewer coins.
  bool grantQuizRewards({
    required int coins,
    required int gems,
    required bool isDailyQuiz,
  }) {
    if (isDailyQuiz) {
      final today = _todayKey();
      if (_lastDailyRewardDate == today) return false;
      _lastDailyRewardDate = today;
      _user.playedTodayDailyQuiz = true;
    }

    _user.coins += coins;
    _user.gems += gems;
    notifyListeners();
    _persist();
    return true;
  }

  void setGuestMode(bool isGuest) {
    if (isGuest) {
      _user = UserModel.guestUser();
    } else {
      _user = UserModel.defaultUser();
    }
    notifyListeners();
    _persist();
  }

  void upgradeGuestToFullAccount(String name, String username) {
    _user = UserModel(
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      fullName: name,
      avatarPath: 'assets/images/characters/hero_boy_3d.png',
      coins: _user.coins + 500, // Welcome bonus
      gems: _user.gems + 20,
      dailyStreak: _user.dailyStreak,
      isGuest: false,
      // Keep everything the guest earned or bought.
      inventory: _user.inventory,
    );
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------- Persistence ---

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coins = prefs.getInt(_kCoins);
      final gems = prefs.getInt(_kGems);
      final inventoryRaw = prefs.getString(_kInventory);
      final lastDailyReward = prefs.getString(_kLastDailyReward);
      final bestScore = prefs.getInt(_kBestDailyScore);
      final bestTime = prefs.getDouble(_kBestDailyTime);
      final hasPlayed = prefs.getBool(_kHasPlayedDaily);

      if (coins != null) _user.coins = coins;
      if (gems != null) _user.gems = gems;
      if (lastDailyReward != null) _lastDailyRewardDate = lastDailyReward;
      if (bestScore != null) _bestDailyScore = bestScore;
      if (bestTime != null) _bestDailyTime = bestTime;
      if (hasPlayed != null) _hasPlayedDaily = hasPlayed;
      if (inventoryRaw != null) {
        final decoded = jsonDecode(inventoryRaw) as Map<String, dynamic>;
        _user.inventory =
            decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    } catch (e) {
      debugPrint('Failed to load persisted state: $e');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCoins, _user.coins);
      await prefs.setInt(_kGems, _user.gems);
      await prefs.setString(_kInventory, jsonEncode(_user.inventory));
      if (_lastDailyRewardDate != null) {
        await prefs.setString(_kLastDailyReward, _lastDailyRewardDate!);
      }
      await prefs.setInt(_kBestDailyScore, _bestDailyScore);
      await prefs.setDouble(_kBestDailyTime, _bestDailyTime);
      await prefs.setBool(_kHasPlayedDaily, _hasPlayedDaily);
    } catch (e) {
      debugPrint('Failed to persist state: $e');
    }
  }
}
