import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore-backed challenge system for 1v1 battles.
///
/// ## Collection
///
/// ```text
/// battle_challenges/{challengeId}
/// {
///   from_uid: String,
///   from_name: String,
///   from_avatar: String,
///   from_avatar_url: String?,
///   from_level: int,
///   to_uid: String,
///   to_name: String,
///   to_avatar: String,
///   to_avatar_url: String?,
///   difficulty: String,
///   status: String,  // pending | accepted | rejected | expired | cancelled
///   created_at: int (ms),
///   expires_at: int (ms),
///   accepted_at: int (ms)?,
/// }
/// ```
///
/// ## Flow
///
/// ```
/// Sender: sends challenge → status = 'pending'
///   ↓
/// Receiver: sees notification → accepts/rejects
///   ↓  accept
/// Both clients: create deterministic battle room (existing logic)
///   ↓  reject/timeout
/// Sender: notified → can challenge someone else
/// ```
///
/// ## Challenge lifecycle
///
/// - Pending: 30 seconds to accept before auto-expire
/// - Accepted: immediately triggers battle room creation
/// - Rejected/Expired/Cancelled: clean up
class ChallengeService {
  ChallengeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collection = 'battle_challenges';
  static const Duration challengeExpiry = Duration(seconds: 30);

  // ----------------------------------------- Send Challenge ---------------

  /// Sends a battle challenge to another user.
  /// Returns the challenge ID, or null on failure.
  Future<String?> sendChallenge({
    required String fromUid,
    required String fromName,
    required String fromAvatar,
    String? fromAvatarUrl,
    int fromLevel = 1,
    required String toUid,
    required String toName,
    required String toAvatar,
    String? toAvatarUrl,
    String difficulty = 'normal',
  }) async {
    try {
      // Check if there's already a pending challenge between these users
      final existingPending = await _hasPendingChallenge(fromUid, toUid);
      if (existingPending) {
        debugPrint('ChallengeService: pending challenge already exists');
        return null;
      }

      final challengeId = 'ch_${fromUid}_$toUid_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.collection(collection).doc(challengeId).set({
        'from_uid': fromUid,
        'from_name': fromName,
        'from_avatar': fromAvatar,
        'from_avatar_url': fromAvatarUrl ?? '',
        'from_level': fromLevel,
        'to_uid': toUid,
        'to_name': toName,
        'to_avatar': toAvatar,
        'to_avatar_url': toAvatarUrl ?? '',
        'difficulty': difficulty,
        'status': 'pending',
        'created_at': now,
        'expires_at': now + challengeExpiry.inMilliseconds,
      });

      return challengeId;
    } catch (e) {
      debugPrint('ChallengeService: sendChallenge failed – $e');
      return null;
    }
  }

  /// Accepts a pending challenge.
  Future<bool> acceptChallenge(String challengeId) async {
    try {
      await _db.collection(collection).doc(challengeId).update({
        'status': 'accepted',
        'accepted_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      debugPrint('ChallengeService: acceptChallenge failed – $e');
      return false;
    }
  }

  /// Rejects a pending challenge.
  Future<bool> rejectChallenge(String challengeId) async {
    try {
      await _db.collection(collection).doc(challengeId).update({
        'status': 'rejected',
      });
      return true;
    } catch (e) {
      debugPrint('ChallengeService: rejectChallenge failed – $e');
      return false;
    }
  }

  /// Cancels a sent challenge (by the sender).
  Future<bool> cancelChallenge(String challengeId) async {
    try {
      await _db.collection(collection).doc(challengeId).update({
        'status': 'cancelled',
      });
      return true;
    } catch (e) {
      debugPrint('ChallengeService: cancelChallenge failed – $e');
      return false;
    }
  }

  // ----------------------------------- Watch Incoming Challenges ----------

  /// Watches for incoming challenges addressed to [myUid].
  /// Returns a stream of challenge data.
  Stream<ChallengeData?> watchIncomingChallenges(String myUid) {
    return _db
        .collection(collection)
        .where('to_uid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ChallengeData.fromDoc(snapshot.docs.first);
    }).handleError((e) {
      debugPrint('ChallengeService: watchIncoming – $e');
      return null;
    });
  }

  /// Watches for status changes on a specific challenge.
  Stream<ChallengeData?> watchChallengeStatus(String challengeId) {
    return _db
        .collection(collection)
        .doc(challengeId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return ChallengeData.fromDoc(snap);
    }).handleError((e) {
      debugPrint('ChallengeService: watchStatus – $e');
      return null;
    });
  }

  /// Watches for outgoing challenges sent by [myUid].
  Stream<ChallengeData?> watchOutgoingChallenge(String myUid) {
    // Watch challenges from this user that are pending or just accepted
    return _db
        .collection(collection)
        .where('from_uid', isEqualTo: myUid)
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ChallengeData.fromDoc(snapshot.docs.first);
    }).handleError((e) {
      debugPrint('ChallengeService: watchOutgoing – $e');
      return null;
    });
  }

  // ----------------------------------------- Helpers --------------------

  /// Check if there's already a pending challenge between two users.
  Future<bool> _hasPendingChallenge(String uid1, String uid2) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fromUid = data['from_uid']?.toString() ?? '';
        final toUid = data['to_uid']?.toString() ?? '';
        if ((fromUid == uid1 && toUid == uid2) ||
            (fromUid == uid2 && toUid == uid1)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clean up expired challenges (older than 2x expiry time).
  Future<void> cleanupExpiredChallenges() async {
    try {
      final cutoff = DateTime.now()
          .subtract(challengeExpiry * 4)
          .millisecondsSinceEpoch;

      final snapshot = await _db
          .collection(collection)
          .where('created_at', isLessThan: cutoff)
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('ChallengeService: cleanup failed – $e');
    }
  }

  /// Mark any pending challenges to/from a user as expired
  /// when they go offline.
  Future<void> expireMyChallenges(String myUid) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['from_uid'] == myUid || data['to_uid'] == myUid) {
          batch.update(doc.reference, {'status': 'expired'});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('ChallengeService: expireMyChallenges failed – $e');
    }
  }
}

/// Model for challenge data.
class ChallengeData {
  final String challengeId;
  final String fromUid;
  final String fromName;
  final String fromAvatar;
  final String? fromAvatarUrl;
  final int fromLevel;
  final String toUid;
  final String toName;
  final String toAvatar;
  final String? toAvatarUrl;
  final String difficulty;
  final String status; // pending | accepted | rejected | expired | cancelled
  final int createdAtMs;
  final int expiresAtMs;
  final int? acceptedAtMs;

  const ChallengeData({
    required this.challengeId,
    required this.fromUid,
    required this.fromName,
    required this.fromAvatar,
    this.fromAvatarUrl,
    this.fromLevel = 1,
    required this.toUid,
    required this.toName,
    required this.toAvatar,
    this.toAvatarUrl,
    this.difficulty = 'normal',
    this.status = 'pending',
    this.createdAtMs = 0,
    this.expiresAtMs = 0,
    this.acceptedAtMs,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  /// Seconds remaining before this challenge expires.
  int get secondsRemaining {
    if (!isPending) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = expiresAtMs - now;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  bool get hasExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiresAtMs;
  }

  /// Best avatar URL for the challenger.
  String get fromEffectiveAvatar =>
      (fromAvatarUrl != null && fromAvatarUrl!.isNotEmpty)
          ? fromAvatarUrl!
          : fromAvatar;

  factory ChallengeData.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChallengeData(
      challengeId: doc.id,
      fromUid: data['from_uid']?.toString() ?? '',
      fromName: data['from_name']?.toString() ?? 'Player',
      fromAvatar: data['from_avatar']?.toString() ?? '',
      fromAvatarUrl: data['from_avatar_url']?.toString(),
      fromLevel: (data['from_level'] as num?)?.toInt() ?? 1,
      toUid: data['to_uid']?.toString() ?? '',
      toName: data['to_name']?.toString() ?? 'Player',
      toAvatar: data['to_avatar']?.toString() ?? '',
      toAvatarUrl: data['to_avatar_url']?.toString(),
      difficulty: data['difficulty']?.toString() ?? 'normal',
      status: data['status']?.toString() ?? 'pending',
      createdAtMs: (data['created_at'] as num?)?.toInt() ?? 0,
      expiresAtMs: (data['expires_at'] as num?)?.toInt() ?? 0,
      acceptedAtMs: (data['accepted_at'] as num?)?.toInt(),
    );
  }
}
