import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';
import '../models/shop_item.dart';
import '../repositories/quiz_repository.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

/// Result of a shop purchase attempt.
enum PurchaseStatus { success, insufficientFunds, alreadyOwned }

class UserProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

  // SharedPreferences keys
  static const _kCoins = 'quizbaaz_coins';
  static const _kGems = 'quizbaaz_gems';
  static const _kInventory = 'quizbaaz_inventory';
  static const _kLastDailyReward = 'quizbaaz_last_daily_reward';
  static const _kBestDailyScore = 'quizbaaz_best_daily_score';
  static const _kBestDailyTime = 'quizbaaz_best_daily_time';
  static const _kHasPlayedDaily = 'quizbaaz_has_played_daily';

  UserModel _user = UserModel.defaultUser();
  List<ChampionModel> _champions = [];
  List<LeaderboardItem> _leaderboard = [];
  bool _isLoading = false;
  String? _lastDailyRewardDate;
  int _bestDailyScore = 0;
  double _bestDailyTime = 0;
  bool _hasPlayedDaily = false;
  bool _firestoreAvailable = true;

  UserModel get user => _user;
  List<ChampionModel> get champions => _champions;
  List<LeaderboardItem> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;

  ChampionModel? get yesterdayTopChampion =>
      _champions.isNotEmpty ? _champions.first : null;

  int get bestDailyScore => _bestDailyScore;
  double get bestDailyTime => _bestDailyTime;
  bool get hasPlayedDailyQuiz => _hasPlayedDaily;

  bool updateDailyBest({required int score, required double timeSeconds}) {
    _hasPlayedDaily = true;
    final isBest = score > _bestDailyScore ||
        (score == _bestDailyScore && score > 0 && timeSeconds < _bestDailyTime);
    if (isBest) {
      _bestDailyScore = score;
      _bestDailyTime = timeSeconds;
      _syncLeaderboardEntry(score, timeSeconds);
    }
    notifyListeners();
    _persist();
    return isBest;
  }

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

  Future<void> initialize() async {
    await _loadPersistedState();
    await loadInitialData();
    _firestoreAvailable = true;
    await _syncFromFirestoreIfNeeded();
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

  int inventoryCount(String itemId) => _user.inventoryCount(itemId);
  bool hasItem(String itemId) => inventoryCount(itemId) > 0;
  bool canAfford(ShopItem item) => item.costsCoins
      ? _user.coins >= item.cost
      : _user.gems >= item.cost;

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

  bool consumeItem(String itemId) {
    final count = inventoryCount(itemId);
    if (count <= 0) return false;

    _user.inventory[itemId] = count - 1;
    notifyListeners();
    _persist();
    return true;
  }

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
      _user.playedTodayDailyQuiz = true;
    }

    _user.coins += coins;
    _user.gems += gems;
    notifyListeners();
    _persist();
    return true;
  }

  void toggleGender() {
    _user.toggleGender();
    notifyListeners();
    _persistUserToServices();
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

  void updateUsername(String newUsername) {
    _user.username = newUsername;
    notifyListeners();
    _persistUserToServices();
  }

  void updateGender(UserGender gender) {
    _user.setGender(gender);
    notifyListeners();
    _persistUserToServices();
  }

  void linkGoogleAccount(String fullName, String email) {
    final wasGuest = _user.isGuest;
    _user = UserModel(
      userId: email,
      username: email.split('@').first,
      fullName: fullName,
      avatarPath: 'assets/images/avatars/quizbaaz_avatar_boy.png',
      coins: _user.coins + (wasGuest ? 500 : 0),
      gems: _user.gems + (wasGuest ? 20 : 0),
      dailyStreak: _user.dailyStreak,
      isGuest: false,
      inventory: _user.inventory,
    );
    notifyListeners();
    _persist();
    _syncToFirestore();
  }

  void saveProfile({
    required String username,
    required String fullName,
    required UserGender gender,
  }) {
    _user = UserModel(
      userId: _user.userId,
      username: username,
      fullName: fullName,
      avatarPath: gender == UserGender.male
          ? 'assets/images/avatars/quizbaaz_avatar_boy.png'
          : 'assets/images/avatars/quizbaaz_avatar_girl.png',
      gender: gender,
      coins: _user.coins,
      gems: _user.gems,
      dailyStreak: _user.dailyStreak,
      isGuest: _user.isGuest,
      playedTodayDailyQuiz: _user.playedTodayDailyQuiz,
      inventory: _user.inventory,
    );
    notifyListeners();
    _persistUserToServices();
  }

  // ------------------------------------------------------------- Sync ---

  Future<void> _persistUserToServices() async {
    await HiveService.saveUser(_user);
    if (_firestoreAvailable) {
      await _syncToFirestore();
    }
  }

  Future<void> _syncToFirestore() async {
    if (!_firestoreAvailable || _user.isGuest) return;
    await FirestoreService.saveUser(_user);
  }

  Future<void> _syncLeaderboardEntry(int score, double timeSeconds) async {
    if (!_firestoreAvailable || _user.isGuest) return;
    await FirestoreService.saveLeaderboardEntry(
      userId: _user.userId,
      username: _user.username,
      avatarPath: _user.avatarPath,
      score: score,
      timeSeconds: timeSeconds,
      date: DateTime.now(),
    );
  }

  Future<void> _syncFromFirestoreIfNeeded() async {
    if (_user.isGuest) return;
    try {
      final firebaseUser = await FirestoreService.loadUser(_user.userId);
      if (firebaseUser != null) {
        if (_user.coins == 0 && firebaseUser.coins > 0) {
          _user.coins = firebaseUser.coins;
        }
        if (_user.gems == 0 && firebaseUser.gems > 0) {
          _user.gems = firebaseUser.gems;
        }
        notifyListeners();
        _persist();
      }
    } catch (e) {      debugPrint('Firestore sync error: $e');
    }
  }

  // ---------------------------------------------------------- Persistence ---

  Future<void> _loadPersistedState() async {
    // Try Hive first
    final hiveUser = HiveService.loadUser();
    if (hiveUser != null) {
      _user = hiveUser;
    }

    // Load game progress from Hive
    final progress = HiveService.loadGameProgress();
    _bestDailyScore = progress['bestScore'] as int? ?? 0;
    _bestDailyTime = progress['bestTime'] as double? ?? 0.0;
    _lastDailyRewardDate = progress['lastRewardDate'] as String?;
    _hasPlayedDaily = progress['hasPlayedDaily'] as bool? ?? false;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Migrate from SharedPreferences if Hive had no data
      if (hiveUser == null) {
        final coins = prefs.getInt(_kCoins);
        final gems = prefs.getInt(_kGems);
        if (coins != null) _user.coins = coins;
        if (gems != null) _user.gems = gems;
        final inventoryRaw = prefs.getString(_kInventory);
        if (inventoryRaw != null) {
          final decoded = jsonDecode(inventoryRaw) as Map<String, dynamic>;
          _user.inventory = decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
        }
      }
      if (_bestDailyScore == 0) {
        _bestDailyScore = prefs.getInt(_kBestDailyScore) ?? 0;
      }
      if (_bestDailyTime == 0.0) {
        _bestDailyTime = prefs.getDouble(_kBestDailyTime) ?? 0.0;
      }
      _lastDailyRewardDate ??= prefs.getString(_kLastDailyReward);
      if (!_hasPlayedDaily) {
        _hasPlayedDaily = prefs.getBool(_kHasPlayedDaily) ?? false;
      }
    } catch (e) {
      debugPrint('Failed to load SharedPreferences: $e');
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    await HiveService.saveUser(_user);
    await HiveService.saveGameProgress(
      bestScore: _bestDailyScore,
      bestTime: _bestDailyTime,
      lastRewardDate: _lastDailyRewardDate,
      hasPlayedDaily: _hasPlayedDaily,
    );
    if (_firestoreAvailable && !_user.isGuest) {
      await _syncToFirestore();
    }

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
      debugPrint('Failed to persist to SharedPreferences: $e');
    }
  }
}