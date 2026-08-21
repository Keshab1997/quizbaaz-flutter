import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firestore service for managing shop items and avatars
///
/// Collection Structure:
/// shop_items/{item_id} - Shop items
/// avatars/{avatar_id} - Avatars
class ShopService {
  static const _shopItems = 'shop_items';
  static const _avatars = 'avatars';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static bool get isReady => Firebase.apps.isNotEmpty;


  // ═══════════════════════════════════════════════════════════════════════
  // 👥 USERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get users from Firestore for the admin panel.
  static Future<List<Map<String, dynamic>>> getUsers({bool guestsOnly = false}) async {
    if (!isReady) return [];
    try {
      Query<Map<String, dynamic>> query = _db.collection('users');
      if (guestsOnly) {
        query = query.where('is_guest', isEqualTo: true);
      }
      final snapshot = await query.limit(200).get();
      final users = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
      users.sort((a, b) {
        final aName = (a['username'] ?? a['full_name'] ?? '').toString().toLowerCase();
        final bName = (b['username'] ?? b['full_name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
      return users;
    } catch (e) {
      debugPrint('ShopService: getUsers error - $e');
      return [];
    }
  }

  /// Update admin-editable user fields.
  static Future<bool> updateUser(String userId, Map<String, dynamic> fields) async {
    if (!isReady || userId.isEmpty) return false;
    try {
      await _db.collection('users').doc(userId).set({
        ...fields,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('ShopService: updateUser error - $e');
      return false;
    }
  }

  /// Delete a user document from Firestore.
  static Future<bool> deleteUser(String userId) async {
    if (!isReady || userId.isEmpty) return false;
    try {
      await _db.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint('ShopService: deleteUser error - $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🛒 SHOP ITEMS
  // ═══════════════════════════════════════════════════════════════════════

  /// Save a shop item to Firestore
  static Future<bool> saveShopItem(Map<String, dynamic> item) async {
    if (!isReady) return false;
    try {
      final id = item['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _db.collection(_shopItems).doc(id).set({
        ...item,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('ShopService: saveShopItem error - $e');
      return false;
    }
  }

  /// Get all shop items from Firestore
  static Future<List<Map<String, dynamic>>> getShopItems() async {
    if (!isReady) return [];
    try {
      final snapshot = await _db.collection(_shopItems)
          .where('is_active', isEqualTo: true)
          .get();
      final items = snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      items.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      return items;
    } catch (e) {
      debugPrint('ShopService: getShopItems error - $e');
      return [];
    }
  }

  /// Delete a shop item (soft delete - set is_active to false)
  static Future<bool> deleteShopItem(String itemId) async {
    if (!isReady) return false;
    try {
      await _db.collection(_shopItems).doc(itemId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('ShopService: deleteShopItem error - $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🎨 AVATARS
  // ═══════════════════════════════════════════════════════════════════════

  /// Save an avatar to Firestore
  static Future<bool> saveAvatar(Map<String, dynamic> avatar) async {
    if (!isReady) return false;
    try {
      final id = avatar['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _db.collection(_avatars).doc(id).set({
        ...avatar,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('ShopService: saveAvatar error - $e');
      return false;
    }
  }

  /// Get all avatars from Firestore
  static Future<List<Map<String, dynamic>>> getAvatars({String? category}) async {
    if (!isReady) return [];
    try {
      Query query = _db.collection(_avatars).where('is_active', isEqualTo: true);
      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }
      final snapshot = await query.get();
      final avatars = snapshot.docs.map((doc) => {
        ...(doc as DocumentSnapshot).data() as Map<String, dynamic>,
        'id': doc.id,
      }).toList();
      avatars.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      return avatars;
    } catch (e) {
      debugPrint('ShopService: getAvatars error - $e');
      return [];
    }
  }

  /// Delete an avatar (soft delete)
  static Future<bool> deleteAvatar(String avatarId) async {
    if (!isReady) return false;
    try {
      await _db.collection(_avatars).doc(avatarId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('ShopService: deleteAvatar error - $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 📊 ADMIN STATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get admin dashboard stats
  static Future<Map<String, int>> getAdminStats() async {
    if (!isReady) return {};
    final stats = <String, int>{};
    try {
      // Total users
      final users = await _db.collection('users').count().get();
      stats['total_users'] = users.count ?? 0;

      // Guest users
      final guests = await _db.collection('users').where('is_guest', isEqualTo: true).count().get();
      stats['guest_users'] = guests.count ?? 0;

      // Today's players
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final players = await _db.collection('leaderboard').doc(dateKey).collection('scores').count().get();
      stats['players_today'] = players.count ?? 0;

      // Shop items
      final items = await _db.collection(_shopItems).where('is_active', isEqualTo: true).count().get();
      stats['shop_items'] = items.count ?? 0;

      // Avatars
      final avatars = await _db.collection(_avatars).where('is_active', isEqualTo: true).count().get();
      stats['avatars'] = avatars.count ?? 0;

    } catch (e) {
      debugPrint('ShopService: getAdminStats error - $e');
    }
    return stats;
  }
}
