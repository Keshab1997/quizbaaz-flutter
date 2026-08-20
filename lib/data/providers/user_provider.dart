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

  UserModel _user = UserModel.defaultUser();
  List<ChampionModel> _champions = [];
  List<LeaderboardItem> _leaderboard = [];
  bool _isLoading = false;

  UserModel get user => _user;
  List<ChampionModel> get champions => _champions;
  List<LeaderboardItem> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;

  ChampionModel? get yesterdayTopChampion =>
      _champions.isNotEmpty ? _champions.first : null;

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

  void addRewards(int coinsWon, int gemsWon) {
    _user.coins += coinsWon;
    _user.gems += gemsWon;
    _user.playedTodayDailyQuiz = true;
    notifyListeners();
    _persist();
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

      if (coins != null) _user.coins = coins;
      if (gems != null) _user.gems = gems;
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
    } catch (e) {
      debugPrint('Failed to persist state: $e');
    }
  }
}
