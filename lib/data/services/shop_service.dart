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
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
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
      final snapshot = await query.orderBy('created_at', descending: true).get();
      return snapshot.docs.map((doc) => {
        ...(doc as DocumentSnapshot).data() as Map<String, dynamic>,
        'id': doc.id,
      }).toList();
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
