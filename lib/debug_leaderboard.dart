// Quick debug script to check leaderboard flow
// Import and call debugLeaderboard() from anywhere in your app

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> debugLeaderboard() async {
  print('=== LEADERBOARD DEBUG ===');

  // 1. Check Firebase initialized
  print('1. Firebase apps: ${Firebase.apps.length}');
  if (Firebase.apps.isEmpty) {
    print('   Firebase NOT initialized!');
    return;
  }
  print('   Firebase initialized');

  // 2. Check Firestore connection
  try {
    final testDoc = await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('2026-08-21')
        .collection('scores')
        .limit(1)
        .get();
    print('2. Firestore connection: OK');
    print('   Documents found: ${testDoc.docs.length}');
  } catch (e) {
    print('2. Firestore connection: FAILED');
    print('   Error: $e');
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
    print('3. Write test: OK');

    // Clean up
    await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('2026-08-21')
        .collection('scores')
        .doc('debug_test')
        .delete();
    print('   Cleaned up test doc');
  } catch (e) {
    print('3. Write test: FAILED');
    print('   Error: $e');
    print('   Check Firestore rules!');
  }

  print('=== END DEBUG ===');
}
