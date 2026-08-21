import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static String? lastError;

  static void _clearError() => lastError = null;

  static void _setError(String scope, Object error) {
    lastError = '$scope: $error';
    debugPrint('ShopService: $scope error - $error');
  }

  static Future<void> _logAdminAction({
    required String action,
    required String entity,
    required String entityId,
    Map<String, dynamic>? details,
  }) async {
    if (!isReady) return;
    try {
      final actor = FirebaseAuth.instance.currentUser;
      await _db.collection('admin_audit_logs').add({
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'actor_uid': actor?.uid,
        'actor_email': actor?.email,
        'details': details ?? const <String, dynamic>{},
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ShopService: audit log error - $e');
    }
  }

  static bool _isAllowedShopCategory(String category) =>
      const {'power_ups', 'shields', 'boosters', 'avatars', 'badges', 'effects', 'packs'}.contains(category);

  static bool _isAllowedAvatarCategory(String category) =>
      const {'male', 'female', 'premium'}.contains(category);

  static Future<bool> _hasDuplicateName({
    required String collection,
    required String name,
    required String currentId,
  }) async {
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty) return false;
    final snapshot = await _db.collection(collection).where('name_key', isEqualTo: cleanName).limit(5).get();
    return snapshot.docs.any((doc) => doc.id != currentId && doc.data()['is_active'] == true);
  }


  // ═══════════════════════════════════════════════════════════════════════
  // 👥 USERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get users from Firestore for the admin panel.
  static Future<List<Map<String, dynamic>>> getUsers({bool guestsOnly = false}) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return []; }
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
      _clearError();
      return users;
    } catch (e) {
      _setError('getUsers', e);
      return [];
    }
  }

  /// Update admin-editable user fields.
  static Future<bool> updateUser(String userId, Map<String, dynamic> fields) async {
    if (!isReady || userId.isEmpty) { lastError = 'Firebase is not ready or user id is empty'; return false; }
    try {
      await _db.collection('users').doc(userId).set({
        ...fields,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAdminAction(action: 'update', entity: 'user', entityId: userId, details: fields);
      _clearError();
      return true;
    } catch (e) {
      _setError('updateUser', e);
      return false;
    }
  }

  /// Delete a user document from Firestore.
  static Future<bool> deleteUser(String userId) async {
    if (!isReady || userId.isEmpty) { lastError = 'Firebase is not ready or user id is empty'; return false; }
    try {
      await _db.collection('users').doc(userId).delete();
      await _logAdminAction(action: 'delete', entity: 'user', entityId: userId);
      _clearError();
      return true;
    } catch (e) {
      _setError('deleteUser', e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🛒 SHOP ITEMS
  // ═══════════════════════════════════════════════════════════════════════

  /// Save a shop item to Firestore
  static Future<bool> saveShopItem(Map<String, dynamic> item) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return false; }
    try {
      final id = item['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      final name = (item['name'] ?? '').toString().trim();
      final category = (item['category'] ?? '').toString();
      final price = (item['price'] as num?)?.toInt() ?? 0;
      if (name.isEmpty) { lastError = 'Item name is required'; return false; }
      if (!_isAllowedShopCategory(category)) { lastError = 'Invalid shop category'; return false; }
      if (price < 0) { lastError = 'Price cannot be negative'; return false; }
      if (await _hasDuplicateName(collection: _shopItems, name: name, currentId: id)) {
        lastError = 'Duplicate item name: $name';
        return false;
      }
      await _db.collection(_shopItems).doc(id).set({
        ...item,
        'name': name,
        'name_key': name.toLowerCase(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAdminAction(action: 'save', entity: 'shop_item', entityId: id, details: {'name': name, 'category': category});
      _clearError();
      return true;
    } catch (e) {
      _setError('saveShopItem', e);
      return false;
    }
  }

  /// Get all shop items from Firestore
  static Future<List<Map<String, dynamic>>> getShopItems() async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return []; }
    try {
      final snapshot = await _db.collection(_shopItems)
          .where('is_active', isEqualTo: true)
          .get();
      final items = snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      items.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      _clearError();
      return items;
    } catch (e) {
      _setError('getShopItems', e);
      return [];
    }
  }

  /// Delete a shop item (soft delete - set is_active to false)
  static Future<bool> deleteShopItem(String itemId) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return false; }
    try {
      await _db.collection(_shopItems).doc(itemId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _logAdminAction(action: 'delete', entity: 'shop_item', entityId: itemId);
      _clearError();
      return true;
    } catch (e) {
      _setError('deleteShopItem', e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🎨 AVATARS
  // ═══════════════════════════════════════════════════════════════════════

  /// Save an avatar to Firestore
  static Future<bool> saveAvatar(Map<String, dynamic> avatar) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return false; }
    try {
      final id = avatar['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      final name = (avatar['name'] ?? '').toString().trim();
      final category = (avatar['category'] ?? '').toString();
      final imageUrl = (avatar['image_url'] ?? '').toString().trim();
      final price = (avatar['price'] as num?)?.toInt() ?? 0;
      if (name.isEmpty) { lastError = 'Avatar name is required'; return false; }
      if (imageUrl.isEmpty) { lastError = 'Avatar image is required'; return false; }
      if (!_isAllowedAvatarCategory(category)) { lastError = 'Invalid avatar category'; return false; }
      if (price < 0) { lastError = 'Price cannot be negative'; return false; }
      if (await _hasDuplicateName(collection: _avatars, name: name, currentId: id)) {
        lastError = 'Duplicate avatar name: $name';
        return false;
      }
      await _db.collection(_avatars).doc(id).set({
        ...avatar,
        'name': name,
        'image_url': imageUrl,
        'name_key': name.toLowerCase(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAdminAction(action: 'save', entity: 'avatar', entityId: id, details: {'name': name, 'category': category});
      _clearError();
      return true;
    } catch (e) {
      _setError('saveAvatar', e);
      return false;
    }
  }

  /// Get all avatars from Firestore
  static Future<List<Map<String, dynamic>>> getAvatars({String? category}) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return []; }
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
      _clearError();
      return avatars;
    } catch (e) {
      _setError('getAvatars', e);
      return [];
    }
  }

  /// Delete an avatar (soft delete)
  static Future<bool> deleteAvatar(String avatarId) async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return false; }
    try {
      await _db.collection(_avatars).doc(avatarId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _logAdminAction(action: 'delete', entity: 'avatar', entityId: avatarId);
      _clearError();
      return true;
    } catch (e) {
      _setError('deleteAvatar', e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 📊 ADMIN STATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get admin dashboard stats
  static Future<Map<String, int>> getAdminStats() async {
    if (!isReady) { lastError = 'Firebase is not ready or offline'; return {}; }
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

      _clearError();
    } catch (e) {
      _setError('getAdminStats', e);
    }
    return stats;
  }
}
