import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';

/// Local persistence layer using Hive.
///
/// All user data is first written here, then optionally synced to Firestore.
/// This ensures the app works offline and feels instant.
class HiveService {
  static const _boxName = 'quizbaaz_box';
  static const _userKey = 'current_user';
  static const _bestScoreKey = 'best_daily_score';
  static const _bestTimeKey = 'best_daily_time';
  static const _lastRewardKey = 'last_daily_reward_date';
  static const _playedDailyKey = 'has_played_daily';

  static late Box _box;

  // ------------------------------------------------------------------ Init --

  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  // ------------------------------------------------------------ User Data --

  /// Saves the current user model to Hive.
  static Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, jsonEncode(user.toJson()));
  }

  /// Loads the previously saved user model, or null.
  static UserModel? loadUser() {
    final raw = _box.get(_userKey) as String?;
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Hive: failed to decode user – $e');
      return null;
    }
  }

  /// Clears the persisted user (on sign-out).
  static Future<void> clearUser() async {
    await _box.delete(_userKey);
  }

  // ------------------------------------------------------ Game Progress --

  static Future<void> saveBestScore(int score) async {
    await _box.put(_bestScoreKey, score);
  }

  static int? loadBestScore() => _box.get(_bestScoreKey) as int?;

  static Future<void> saveBestTime(double time) async {
    await _box.put(_bestTimeKey, time);
  }

  static double? loadBestTime() => _box.get(_bestTimeKey) as double?;

  static Future<void> saveLastRewardDate(String date) async {
    await _box.put(_lastRewardKey, date);
  }

  static String? loadLastRewardDate() => _box.get(_lastRewardKey) as String?;

  static Future<void> saveHasPlayedDaily(bool played) async {
    await _box.put(_playedDailyKey, played);
  }

  static bool? loadHasPlayedDaily() => _box.get(_playedDailyKey) as bool?;

  /// Save all game progress at once.
  static Future<void> saveGameProgress({
    int? bestScore,
    double? bestTime,
    String? lastRewardDate,
    bool? hasPlayedDaily,
  }) async {
    if (bestScore != null) await saveBestScore(bestScore);
    if (bestTime != null) await saveBestTime(bestTime);
    if (lastRewardDate != null) await saveLastRewardDate(lastRewardDate);
    if (hasPlayedDaily != null) await saveHasPlayedDaily(hasPlayedDaily);
  }

  /// Load all game progress.
  static Map<String, dynamic> loadGameProgress() {
    return {
      'bestScore': loadBestScore() ?? 0,
      'bestTime': loadBestTime() ?? 0.0,
      'lastRewardDate': loadLastRewardDate(),
      'hasPlayedDaily': loadHasPlayedDaily() ?? false,
    };
  }

  // ------------------------------------------------------------ General --

  /// Completely wipes the local box.
  static Future<void> clearAll() async {
    await _box.clear();
  }
}