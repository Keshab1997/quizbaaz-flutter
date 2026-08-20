// Quick debug script to check leaderboard flow
// Import and call debugLeaderboard() from anywhere in your app

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> debugLeaderboard() async {
  debugPrint('=== LEADERBOARD DEBUG ===');

  // 1. Check Firebase initialized
  debugPrint('1. Firebase apps: ${Firebase.apps.length}');
  if (Firebase.apps.isEmpty) {
    debugPrint('   Firebase NOT initialized!');
    return;
  }
  debugPrint('   Firebase initialized');

  // 2. Check Firestore connection
  try {
    final testDoc = await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('2026-08-21')
        .collection('scores')
        .limit(1)
        .get();
    debugPrint('2. Firestore connection: OK');
    debugPrint('   Documents found: ${testDoc.docs.length}');
  } catch (e) {
    debugPrint('2. Firestore connection: FAILED');
    debugPrint('   Error: $e');
  }

  // 3. Try to write a test entry
  try {
    await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('2026-08-21')
        .collection('scores')
        .doc('debug_test')
        .set({
      'test': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
    debugPrint('3. Write test: OK');

    // Clean up
    await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('2026-08-21')
        .collection('scores')
        .doc('debug_test')
        .delete();
    debugPrint('   Cleaned up test doc');
  } catch (e) {
    debugPrint('3. Write test: FAILED');
    debugPrint('   Error: $e');
    debugPrint('   Check Firestore rules!');
  }

  debugPrint('=== END DEBUG ===');
}
