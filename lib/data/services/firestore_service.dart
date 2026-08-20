import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Firestore persistence layer.
///
/// All writes happen AFTER the corresponding Hive write succeeds.
/// Reads from Firestore are used only when the user signs in on a new device,
/// to restore their data.
class FirestoreService {
  static const _collection = 'users';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ---------------------------------------------------------- User CRUD --

  /// Saves (upserts) the user document to Firestore.
  static Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection(_collection).doc(user.userId).set(
        user.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore: saveUser error – $e');
    }
  }

  /// Loads a user document from Firestore by [userId].
  static Future<UserModel?> loadUser(String userId) async {
    try {
      final doc =
          await _db.collection(_collection).doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Firestore: loadUser error – $e');
      return null;
    }
  }

  /// Update specific fields on the user document.
  static Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _db.collection(_collection).doc(userId).update(fields);
    } catch (e) {
      debugPrint('Firestore: updateUserFields error – $e');
    }
  }

  /// Delete a user document.
  static Future<void> deleteUser(String userId) async {
    try {
      await _db.collection(_collection).doc(userId).delete();
    } catch (e) {
      debugPrint('Firestore: deleteUser error – $e');
    }
  }

  // --------------------------------------------------------- Leaderboard --

  /// Updates or creates the daily leaderboard entry for this user.
  static Future<void> saveLeaderboardEntry({
    required String userId,
    required String username,
    required String avatarPath,
    required int score,
    required double timeSeconds,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _db
          .collection('leaderboard')
          .doc(dateStr)
          .collection('scores')
          .doc(userId)
          .set({
        'user_id': userId,
        'username': username,
        'avatar_path': avatarPath,
        'score': score,
        'time_seconds': timeSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore: saveLeaderboardEntry error – $e');
    }
  }

  /// Fetches the top N scores for a given date.
  static Future<List<Map<String, dynamic>>> getLeaderboard(
    DateTime date, {
    int limit = 20,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final snapshot = await _db
          .collection('leaderboard')
          .doc(dateStr)
          .collection('scores')
          .orderBy('score', descending: true)
          .orderBy('time_seconds', descending: false)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Firestore: getLeaderboard error – $e');
      return [];
    }
  }
}